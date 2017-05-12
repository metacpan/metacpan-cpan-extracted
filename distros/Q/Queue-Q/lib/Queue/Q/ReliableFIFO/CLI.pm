#!/usr/bin/env perl
package Queue::Q::ReliableFIFO::CLI;
use strict;
use Redis;
use Term::ReadLine;
use Data::Dumper;
use JSON::XS;
use File::Slurp;
use Carp qw(croak);

use Queue::Q::ReliableFIFO::Redis;
use Class::XSAccessor {
    constructor => 'new',
    getters => [qw(conn prompt path redis server port db)],
    setters => { 
        set_conn => 'conn',
        set_prompt => 'prompt',
        set_path => 'path',
        set_redis => 'redis',
        set_server => 'server',
        set_port => 'port',
        set_db => 'db',
    },
};

# The path property has the following meaning:
#
# $path== undef -> not connected
# @$path==0 -> /
# @$path==1 -> /queue
# @$path==2 -> /queue/type

my @all_types = (qw(main busy failed));
my %type = map { $_ => undef } @all_types;

sub open {
    my ($self, %params) = @_;
    $params{server} || die "missing server\n";
    $params{port}   ||= 6379;
    $params{db}     ||= 0;
    $self->set_conn( Redis->new(
        reconnect => 60,
        server => $params{server} . ':' . $params{port}));
    $self->conn->select($params{db})
        if $self->conn && exists $params{db} && $params{db};
    $self->set_server($params{server});
    $self->set_port($params{port});
    $self->set_db($params{db});
    $self->set_path($self->conn ? [] : undef);
}
sub close {
    my $self = shift;
    $self->set_conn(undef);
    $self->set_path(undef);
}
sub newpath {
    my ($self, $arg) = @_;
    my @args = defined $arg ? split(/\//, $arg) : ();
    if (! defined $self->path) {
        croak("not connected");
    }
    my @path;
    if (substr($arg,0,1) eq '/') {
        @path = @args;
        shift @path;
    }
    else {
        @path = @{$self->path};
        while (my $v = shift @args) {
            if ($v eq '..') {
                pop @path;
            }
            elsif ($v ne '.') {
                push @path, $v;
            }
        }
    }
    return @path;
}
sub ls {
    my $self = shift;
    my $arg  = shift;
    my @path = $self->newpath($arg);
    my $level= @path;
    my ($queue, $type) = @path;

    if ($level == 0) {
        my %q = map { $_ => undef } 
                map { s/_(?:main|busy|failed|time)$//; $_ } 
                grep{ /_/ }
                map { $self->conn->keys('*' . '_' . $_) }
                @all_types;
        my @q = sort keys %q;
        return @q;
    }
    elsif ($level == 1) {
        return 
            map {  sprintf "%7s: %d items", 
                        $_, int($self->conn->llen($queue . '_' . $_)) 
            }
            @all_types;
    }
    elsif ($level == 2) {
        # show 10 items at the consumer side of the queue
        my $start = -10;
        my $n = 9;
        return reverse $self->conn->lrange(
            $queue . "_$type", $start, $start + $n);
    }
    else {
        print Dumper(\@path);
        croak("never thought of this...");
    }
}
sub cd {
    my $self = shift;
    my $arg  = shift;
    my @path = $self->newpath($arg);
    my @oldpath = @{$self->path};

    if (defined $path[0] && $path[0] ne $oldpath[0]) {
        $self->set_redis(Queue::Q::ReliableFIFO::Redis->new(
            redis_conn => $self->conn,
            server      => $self->server,
            port        => $self->port,
            queue_name  => $path[0]));
    }
    $self->set_path(\@path);
}
sub change_db {
    my ($self, $db) = @_;
    $db =  int($db);
    my $ret = $self->conn->select($db);
    if ($ret) {
        $self->set_db($db);
        $self->set_path([]);
    }
}
sub mv {
    my ($self, $from, $to, $limit) = @_;
    my @from = $self->newpath($from);
    my @to   = $self->newpath($to);
    die "$from[1]? expected main|busy|time|failed\n" if !exists $type{$from[1]};
    die "$to[1]? expected main|busy|time|failed\n" if !exists $type{$to[1]};
    die "Path length should be 2: " . join('/',@from) . "\n" if @from != 2;
    die "Path length should be 2: " . join('/',@to) . "\n" if @to != 2;
    die "from and to are the same\n" if join('',@from) eq join('',@to);

    my $conn = $self->conn;
    my $count = 0;
    my $redis_from = join('_', @from);
    my $redis_to = join('_', @to);
    while ($conn->rpoplpush($redis_from, $redis_to)) {
        $count++;
        last if ($limit && $count >= $limit);
    }
    return $count;
}
sub cp {
   my ($self, $from, $to, $limit) = @_;
    my @from = $self->newpath($from);
    my @to   = $self->newpath($to);
    die "$from[1]? expected main|busy|time|failed\n" if !exists $type{$from[1]};
    die "$to[1]? expected main|busy|time|failed\n" if !exists $type{$to[1]};
    die "Path length should be 2: " . join('/',@from) . "\n" if @from != 2;
    die "Path length should be 2: " . join('/',@to) . "\n" if @to != 2;
    my $conn = $self->conn;
    my $redis_from = join('_', @from);
    my $redis_to = join('_', @to);

    my $length= $conn->llen($redis_from);
    my @elements = $conn->lrange($redis_from, 0, ($limit || $length ) - 1 );
    $conn->rpush($redis_to, @elements) if @elements;
    return scalar @elements;
}

sub rm {
    my ($self, $dir, $limit) = @_;
    my @dir = $self->newpath($dir);
    die "not a complete path\n" if (@dir != 2);
    my $redisname = join '_', @dir;
    my $conn = $self->conn;
    my $count = 0;
    if ($limit) {
        while ($conn->rpop($redisname)) {
            $count++;
            last if ($count >= $limit);
        }
    }
    else {
        $self->conn->multi;
        $self->conn->llen($redisname);
        $self->conn->del($redisname);
        ($count) = $self->conn->exec;
    }
    return $count;
}
sub who {
    my $self = shift;
    return $self->conn->client_list();
}
sub cleanup {
    my ($self, $timeout, $action) = @_;
    die "not connected\n" if !defined $self->path;
    die "command not available here\n" if @{$self->path} < 1;
    my @items = $self->{redis}->handle_expired_items($timeout, $action);
    return scalar @items;
}
sub show_prompt {
    my $self = shift;
    my $s = $self->server;
    my $p = $self->port;
    my $d = $self->db;
    my $path = $self->path;
    my $pathstr = defined $path ? '/' . join('/', @$path) : '';
    my $prompt;
    if (! defined $path) { $prompt = ''; }
    else { $prompt = "$s:$p (db=$d) \[ $pathstr \]" }

    return sprintf '%s:%s-> ', FIFO => $prompt;
}

sub run {
    my ($self, %params) = @_;
    $| = 1;

    my @history;

    # take settings from previous session
    my $conf_file = "$ENV{HOME}/.reliablefifo";
    my %conf;
    if (!$params{ignore_config_file} and -f $conf_file) {
        %conf = %{decode_json(read_file($conf_file))};
        $self->open(server => $conf{server},  port => $conf{port})
            if exists $conf{server} && exists $conf{port};
        push(@history, @{$conf{history}}) if exists $conf{history};
        my ($queue, $type) = @{$conf{path}||[]};
        $self->cd($queue) if $queue;
        $self->cd($type) if $type;
    }
    my $quit = sub {
        print "\n";
        # save setting for next session
        my %conf = ();
        if (defined $self->path) {
            $conf{server} = $self->server;
            $conf{port} = $self->port;
            $conf{db} = $self->db;
            $conf{path} = $self->path;
        }
        $conf{history} = \@history;
        write_file($conf_file, encode_json(\%conf));

        exit 0;
    };

    my %commands = map { $_ => undef } (qw(
        open
        ls
        cd
        close
        db
        mv
        cp
        rm
        who
        quit
        exit
        hist
        cleanup
        ?
    ));
    my %help = (
        0 => ["open <server> [<port> [<db>]]"],
        1 => [
                "ls [<path>]",
                "cd <path>",
                "mv <path-from> <path-to> [<limit>]",
                "cp <path-from> <path-to> [<limit>]",
                "cleanup <timeout> <(requeue|fail|drop)>", 
                'rm <path> [<limit>]',
                'db <db>',
                'close',
             ],
    );
    push(@{$help{$_}}, ("?", "who", "hist", "quit")) for (0 .. 3);

    my $ver = join ".", map {ord} split(//, $^V);
    my $term = Term::ReadLine->new("perl $ver");
    $term->addhistory($_) for map {chomp; $_} @history;
    $term->ornaments( join ',' => qw/ md me /, undef, undef );

    print { $term->OUT } "Type '?' for help\n";

    while(1) {
        my $line = $term->readline($self->show_prompt);
        last if not defined $line;
        chomp $line;

        $line and push @history, $line;

        # deal with the command
        my ($cmd, @args) = split /\s+/, $line;
        if ($cmd) {
            if (exists $commands{$cmd}) {
                eval {
                    if ($cmd eq "open") {
                        $self->open(server => $args[0],
                                   port => $args[1],
                                   db => $args[2]);
                    }
                    elsif ($cmd eq "cd") {
                        $self->cd(@args);
                    }
                    elsif ($cmd eq "db") {
                        $self->change_db(@args);
                    }
                    elsif ($cmd eq "rm") {
                        printf { $term->OUT } "%d items removed\n", $self->rm(@args);
                    }
                    elsif ($cmd eq "mv") {
                        printf { $term->OUT } "%d items moved\n", $self->mv(@args);
                    }
                    elsif ($cmd eq "cp") {
                        printf { $term->OUT } "%d items copied\n", $self->cp(@args);
                    }
                    elsif ($cmd eq 'ls') {
                        print { $term->OUT } join("\n", $self->ls(@args)), "\n";
                    }
                    elsif ($cmd eq 'who') {
                        print { $term->OUT } join("\n", $self->who(@args)), "\n";
                    }
                    elsif ($cmd eq 'cleanup') {
                        my $n = $self->cleanup(@args);
                        printf { $term->OUT } "%d items affected\n", $n;
                        print { $term->OUT } "Try again after <timeout> seconds\n" if ($n ==0);
                    }
                    elsif ($cmd eq 'close') {
                        $self->close(), "\n";
                    }
                    elsif ($cmd eq 'quit' || $cmd eq 'exit') {
                        $quit->();
                    }
                    elsif ($cmd eq 'hist') {
                        print { $term->OUT } "\t", join("\n\t", @history), "\n";
                    }
                    elsif ($cmd eq '?') {
                        my $connected = defined $self->path ? 1 : 0;
                        print { $term->OUT } "available commands at this level:\n\t",
                            join("\n\t", @{$help{$connected}}), "\n";
                    }
                    1;
                }
                or do {
                    print { $term->OUT } $@;
                }
            }
            else {
                print { $term->OUT } "unknown command $cmd\n";
            }
        }
    }
    $quit->();
}

1;

__END__

=head1 NAME

Queue::Q::ReliableFIFO::CLI - Command line interface to queues in Redis

=head1 DESCRIPTION

A command line interface can be started by

    perl -MQueue::Q::ReliableFIFO::CLI \
        -e 'Queue::Q::ReliableFIFO::CLI->new->run()'

You can put that in a file e.g. called 'fifo-cli' and put that file
in your PATH.

The last state of the cli session is saved in $ENV{HOME}/.reliablefifo
(as JSON). When restarting the cli, the previous context will be
reloaded, i.e. connection, directory and history (unless the
parameter C<ignore_config_file> is passed to run()).

The command a in unix style, like "ls", "cd", "rm" and "mv". Press "?"
to get a list of available commands. A directory structure is emulated
in which the highest level is the queue name and the second level is
a type of queue, i.e. queue with busy items, queue with failed items and
main queue with waiting items.

The "mv" and "rm" resp. move and remove items. The commands accept an
extra parameter to limit the number of items they handle.

Example:

    [herald@aap redis]$ fifo-cli
    Type '?' for help
    FIFO:-> open localhost
    FIFO:localhost:6379 (db=0) [ / ]-> ls
    mytest
    FIFO:localhost:6379 (db=0) [ / ]-> cd mytest
    FIFO:localhost:6379 (db=0) [ /mytest ]-> ls
       main: 4054 items
       busy: 0 items
     failed: 2 items
    FIFO:localhost:6379 (db=0) [ /mytest ]-> ls failed
    {"b":{"k":9,"x":783348.75271916,"s":"bgky"},"t":1352319296}
    {"b":{"k":10,"x":574480.695396417,"s":"irzd"},"t":1352319296}
    FIFO:localhost:6379 (db=0) [ /mytest ]-> mv failed main  
    2 items moved
    FIFO:localhost:6379 (db=0) [ /mytest ]-> ls
       main: 4056 items
       busy: 0 items
     failed: 0 items
    FIFO:localhost:6379 (db=0) [ /mytest ]-> cd main
    FIFO:localhost:6379 (db=0) [ /mytest/main ]-> ls
    {"b":{"k":11,"x":664047.321063155,"s":"ptkx"},"t":1352319296}
    {"b":{"k":12,"x":502226.272384469,"s":"yrqb"},"t":1352319296}
    ...
    FIFO:localhost:6379 (db=0) [ /mytest/main ]-> mv . ../failed 1
    1 items moved
    FIFO:localhost:6379 (db=0) [ /mytest/main ]-> cd ..
    FIFO:localhost:6379 (db=0) [ /mytest ]-> ls
       main: 4055 items
       busy: 0 items
     failed: 1 items


=head1 AUTHOR

Herald van der Breggen, E<lt>herald.vanderbreggen@booking.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Herald van der Breggen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
