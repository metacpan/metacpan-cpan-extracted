# -*- perl -*-
#
#  Net::Server::HTTP - Extensible Perl HTTP base server
#
#  $Id$
#
#  Copyright (C) 2010-2012
#
#    Paul Seamons
#    paul@seamons.com
#    http://seamons.com/
#
#  This package may be distributed under the terms of either the
#  GNU General Public License
#    or the
#  Perl Artistic License
#
################################################################

package Net::Server::HTTP;

use strict;
use base qw(Net::Server::MultiType);
use Scalar::Util qw(weaken blessed);
use IO::Handle ();
use re 'taint'; # most of our regular expressions setting ENV should not be clearing taint
use POSIX ();
use Time::HiRes qw(time);
my $has_xs_parser;
BEGIN {$has_xs_parser = $ENV{'USE_XS_PARSER'} && eval { require HTTP::Parser::XS } };

sub net_server_type { __PACKAGE__ }

sub options {
    my $self = shift;
    my $ref  = $self->SUPER::options(@_);
    my $prop = $self->{'server'};
    $ref->{$_} = \$prop->{$_} for qw(timeout_header timeout_idle server_revision max_header_size
                                     access_log_format access_log_file enable_dispatch);
    return $ref;
}

sub timeout_header  { shift->{'server'}->{'timeout_header'}  }
sub timeout_idle    { shift->{'server'}->{'timeout_idle'}    }
sub server_revision { shift->{'server'}->{'server_revision'} }
sub max_header_size { shift->{'server'}->{'max_header_size'} }

sub default_port { 80 }

sub default_server_type { 'PreFork' }

sub post_configure {
    my $self = shift;
    $self->SUPER::post_configure(@_);
    my $prop = $self->{'server'};

    # set other defaults
    my $d = {
        timeout_header  => 15,
        timeout_idle    => 60,
        server_revision => __PACKAGE__."/$Net::Server::VERSION",
        max_header_size => 100_000,
        access_log_format => '%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"',
    };
    $prop->{$_} = $d->{$_} foreach grep {!defined($prop->{$_})} keys %$d;

    $self->_init_access_log;

    $self->_tie_client_stdout;
}

sub post_bind {
    my $self = shift;
    $self->SUPER::post_bind(@_);

    $self->_check_dispatch;
}

sub _init_access_log {
    my $self = shift;
    my $prop = $self->{'server'};
    my $log = $prop->{'access_log_file'};
    return if ! $log || $log eq '/dev/null';
    return if ! $prop->{'access_log_format'};
    $prop->{'access_log_format'} =~ s/\\([\\\"nt])/$1 eq 'n' ? "\n" : $1 eq 't' ? "\t" : $1/eg;
    if ($log eq 'STDERR') {
        $prop->{'access_log_function'} = sub { print STDERR @_,"\n" };
    } else {
        open my $fh, '>>', $log or die "Could not open access_log_file \"$log\": $!";
        $fh->autoflush(1);
        push @{ $prop->{'chown_files'} }, $log;
        $prop->{'access_log_function'} = sub { print $fh @_,"\n" };
    }
}

sub _tie_client_stdout {
    my $self = shift;
    my $prop = $self->{'server'};

    # install a callback that will handle our outbound header negotiation for the clients similar to what apache does for us
    my $copy = $self;
    $prop->{'tie_client_stdout'} = 1;
    $prop->{'tied_stdout_callback'} = sub {
        my $client = shift;
        my $method = shift;
        alarm($copy->timeout_idle); # reset timeout

        my $request_info = $copy->{'request_info'};
        if ($request_info->{'headers_sent'}) { # keep track of how much has been printed
            my ($resp, $len);
            if ($method eq 'print') {
                $resp = $client->print(my $str = join '', @_);
                $len = length $str;
            } elsif ($method eq 'printf') {
                $resp = $client->print(my $str = sprintf(shift, @_));
                $len = length $str;
            } elsif ($method eq 'say') {
                $resp = $client->print(my $str = join '', @_, "\n");
                $len = length $str;
            } elsif ($method eq 'write') {
                my $buf = shift;
                $buf = substr($buf, $_[1] || 0, $_[0]) if @_;
                $resp = $client->print($buf);
                $len = length $buf;
            } elsif ($method eq 'syswrite') {
                $len = $resp = $client->syswrite(@_);
            } else {
                return $client->$method(@_);
            }
            $request_info->{'response_size'} = ($request_info->{'response_size'} || 0) + $len if defined $len;
            return $resp;
        }

        die "All headers must only be sent via print ($method)\n" if $method ne 'print';

        my $headers = ${*$client}{'headers'} ||= {unparsed => '', parsed => ''};
        $headers->{'unparsed'} .= join('', @_);
        while ($headers->{'unparsed'} =~ s/^(.*?)\015?\012//) {
            my $line = $1;

            if (!$headers->{'parsed'} && $line =~ m{^HTTP/(1.[01]) \s+ (\d+) (?: | \s+ .+)$ }x) {
                $headers->{'status'} = [];
                $headers->{'parsed'} .= "$line\015\012";
                $prop->{'request_info'}->{'http_version'} = $1;
                $prop->{'request_info'}->{'response_status'} = $2;
            }
            elsif (! length $line) {
                my $s = $headers->{'status'} || die "Premature end of script headers\n";
                delete ${*$client}{'headers'};
                $copy->send_status(@$s) if @$s;
                $client->print($headers->{'parsed'}."\015\012");
                $request_info->{'headers_sent'} = 1;
                $request_info->{'response_header_size'} += length($headers->{'parsed'})+2;
                $request_info->{'response_size'} = length($headers->{'unparsed'});
                return $client->print($headers->{'unparsed'});
            } elsif ($line !~ s/^(\w+(?:-(?:\w+))*):\s*//) {
                my $invalid = ($line =~ /(.{0,120})/) ? "$1..." : '';
                $invalid =~ s/</&lt;/g;
                die "Premature end of script headers: $invalid<br>\n";
            } else {
                my $key = "\u\L$1";
                $key =~ y/_/-/;
                push @{ $request_info->{'response_headers'} }, [$key, $line];
                if ($key eq 'Status' && $line =~ /^(\d+) (?:|\s+(.+?))$/ix) {
                    $headers->{'status'} = [$1, $2 || '-'];
                }
                elsif ($key eq 'Location') {
                    $headers->{'status'} = [302, 'bouncing'];
                }
                elsif ($key eq 'Content-type') {
                    $headers->{'status'} ||= [200, 'OK'];
                }
                $headers->{'parsed'} .= "$key: $line\015\012";
            }
        }
    };
    weaken $copy;
}

sub _check_dispatch {
    my $self = shift;
    if (! $self->{'server'}->{'enable_dispatch'}) {
        return if __PACKAGE__->can('process_request') ne $self->can('process_request');
        return if __PACKAGE__->can('process_http_request') ne $self->can('process_http_request');
    }

    my $app = $self->{'server'}->{'app'};
    if (! $app || (ref($app) eq 'ARRAY' && !@$app)) {
        $app = [];
        $self->configure({app => $app});
    }

    my %dispatch;
    my $first;
    my @dispatch;
    foreach my $a (ref($app) eq 'ARRAY' ? @$app : $app) {
        next if ! $a;
        my @pairs = ref($a) eq 'ARRAY' ? @$a
                  : ref($a) eq 'HASH'  ? %$a
                  : ref($a) eq 'CODE'  ? ('/', $a)
                  : $a =~ m{^(.+?)\s+(.+)$} ? ($1, $2)
                  : $a =~ m{^(.+?)=(.+)$}   ? ($1, $2)
                  : ($a, $a);
        for (my $i = 0; $i < @pairs; $i+=2) {
            my ($key, $val) = ("/$pairs[$i]", $pairs[$i+1]);
            $key =~ s{/\./}{/}g;
            $key =~ s{(?:/[^/]+|)/\../}{/}g;
            $key =~ s{//+}{/}g;
            if ($dispatch{$key}) {
                $self->log(2, "Already found a path matching \"$key\" - skipping.");
                next;
            }
            $dispatch{$key} = $val;
            push @dispatch, $key;
            $first ||= $key;
            $self->log(2, "  Dispatch: $key => $val");
        }
    }
    if (@dispatch) {
        if (! $dispatch{'/'} && $first) {
            $dispatch{'/'} = $dispatch{$first};
            push @dispatch, '/';
            $self->log(2, "  Dispatch: / => $dispatch{$first} (default)");
        }
        $self->{'dispatch_qr'} = join "|", map {"\Q$_\E"} @dispatch;
        $self->{'dispatch'} = \%dispatch;
    }
}

sub http_base_headers {
    my $self = shift;
    return [
        [Date => gmtime()." GMT"],
        [Connection => 'close'],
        [Server => $self->server_revision],
    ];
}

sub send_status {
    my ($self, $status, $msg, $body) = @_;
    $msg ||= ($status == 200) ? 'OK' : '-';
    my $request_info = $self->{'request_info'};

    my $out = "HTTP/1.0 $status $msg\015\012";
    foreach my $row (@{ $self->http_base_headers }) {
        $out .= "$row->[0]: $row->[1]\015\012";
        push @{ $request_info->{'response_headers'} }, $row;
    }
    $self->{'server'}->{'client'}->print($out);
    $request_info->{'http_version'} = '1.0';
    $request_info->{'response_status'} = $status;
    $request_info->{'response_header_size'} += length $out;

    if ($body) {
        push @{ $request_info->{'response_headers'} }, ['Content-type', 'text/html'];
        $out = "Content-type: text/html\015\012\015\012";
        $request_info->{'response_header_size'} += length $out;
        $self->{'server'}->{'client'}->print($out);
        $request_info->{'headers_sent'} = 1;
        $self->{'server'}->{'client'}->print($body);
        $request_info->{'response_size'} += length $body;
    }
}

sub send_500 {
    my ($self, $err) = @_;
    $self->send_status(500, 'Internal Server Error',
                       "<h1>Internal Server Error</h1><p>$err</p>");
}

###----------------------------------------------------------------###

sub run_client_connection {
    my $self = shift;
    local $self->{'request_info'} = {};
    return $self->SUPER::run_client_connection(@_);
}

sub get_client_info {
    my $self = shift;
    $self->SUPER::get_client_info(@_);
    $self->clear_http_env;
}

sub clear_http_env {
    my $self = shift;
    %ENV = ();
}

sub process_request {
    my $self = shift;
    my $client = shift || $self->{'server'}->{'client'};

    my $ok = eval {
        local $SIG{'ALRM'} = sub { die "Server Timeout on headers\n" };
        alarm($self->timeout_header);
        $self->process_headers($client);

        $SIG{'ALRM'} = sub { die "Server Timeout on process\n" };
        alarm($self->timeout_idle);
        $self->process_http_request($client);

        alarm(0);
        1;
    };
    alarm(0);

    if (! $ok) {
        my $err = "$@" || "Something happened";
        $self->log(1, $err);
        $self->send_500($err);
    }
}

sub script_name { shift->{'script_name'} || '' }

sub process_headers {
    my $self = shift;
    my $client = shift || $self->{'server'}->{'client'};

    $ENV{'REMOTE_PORT'} = $self->{'server'}->{'peerport'};
    $ENV{'REMOTE_ADDR'} = $self->{'server'}->{'peeraddr'};
    $ENV{'SERVER_PORT'} = $self->{'server'}->{'sockport'};
    $ENV{'SERVER_ADDR'} = $self->{'server'}->{'sockaddr'};
    $ENV{'HTTPS'} = 'on' if $self->{'server'}->{'client'}->NS_proto =~ /SSL/;

    my ($ok, $headers) = $client->read_until($self->max_header_size, qr{\n\r?\n});
    my ($req, $len, @parsed);
    die "Could not parse http headers successfully\n" if $ok != 1;
    if ($has_xs_parser) {
        $len = HTTP::Parser::XS::parse_http_request($headers, \%ENV);
        die "Corrupt request" if $len == -1;
        die "Incomplete request" if $len == -2;
        $req = "$ENV{'REQUEST_METHOD'} $ENV{'REQUEST_URI'} $ENV{'SERVER_PROTOCOL'}";
    } else {
        ($req, my @lines) = split /\r?\n/, $headers;
        die "Missing request\n" if ! defined $req;

        if (!defined($req) || $req !~ m{ ^\s*(GET|POST|PUT|DELETE|PUSH|HEAD|OPTIONS)\s+(.+)\s+(HTTP/1\.[01])\s*$ }ix) {
            die "Invalid request\n";
        }
        $ENV{'REQUEST_METHOD'}  = uc $1;
        $ENV{'REQUEST_URI'}     = $2;
        $ENV{'SERVER_PROTOCOL'} = $3;
        $ENV{'QUERY_STRING'}    = $1 if $ENV{'REQUEST_URI'} =~ m{ \?(.*)$ }x;
        $ENV{'PATH_INFO'}       = $1 if $ENV{'REQUEST_URI'} =~ m{^([^\?]+)};

        foreach my $l (@lines) {
            my ($key, $val) = split /\s*:\s*/, $l, 2;
            push @parsed, [$key, $val];
            $key = uc($key);
            $key = 'COOKIE' if $key eq 'COOKIES';
            $key =~ y/-/_/;
            $key =~ s/^\s+//;
            $key = "HTTP_$key" if $key !~ /^CONTENT_(?:LENGTH|TYPE)$/;
            $val =~ s/\s+$//;
            if (exists $ENV{$key}) {
                $ENV{$key} .= ", $val";
            } else {
                $ENV{$key} = $val;
            }
        }
        $len = length $headers;
    }
    $ENV{'SCRIPT_NAME'} = $self->script_name($ENV{'PATH_INFO'}) || '';

    my $type = $Net::Server::HTTP::ISA[0];
    $type = $Net::Server::MultiType::ISA[0] if $type eq 'Net::Server::MultiType';
    $ENV{'NET_SERVER_TYPE'} = $type;
    $ENV{'NET_SERVER_SOFTWARE'} = $self->server_revision;

    $self->_init_http_request_info($req, \@parsed, $len);
}

sub http_request_info { shift->{'request_info'} }

sub _init_http_request_info {
    my ($self, $req, $parsed, $len) = @_;
    my $prop = $self->{'server'};
    my $info = $self->{'request_info'};
    @$info{qw(sockaddr sockport peeraddr peerport)} = @$prop{qw(sockaddr sockport peeraddr peerport)};
    $info->{'peerhost'} = $prop->{'peerhost'} || $info->{'peeraddr'};
    $info->{'begin'} = time;
    $info->{'request'} = $req;
    $info->{'request_headers'} = $parsed;
    $info->{'query_string'} = "?$ENV{'QUERY_STRING'}" if defined $ENV{'QUERY_STRING'};
    $info->{'request_protocol'} = $ENV{'HTTPS'} ? 'https' : 'http';
    $info->{'request_method'} = $ENV{'REQUEST_METHOD'};
    $info->{'request_path'} = $ENV{'PATH_INFO'};
    $info->{'request_header_size'} = $len;
    $info->{'request_size'} = $ENV{'CONTENT_LENGTH'} || 0; # we might not actually read entire request
    $info->{'remote_user'} = '-';
}

sub http_note {
    my ($self, $key, $val) = @_;
    return $self->{'request_info'}->{'notes'}->{$key} = $val if @_ >= 3;
    return $self->{'request_info'}->{'notes'}->{$key};
}

sub http_dispatch {
    my ($self, $dispatch_qr, $dispatch_table) = @_;

    $ENV{'PATH_INFO'} =~ s{^($dispatch_qr)(?=/|$|(?<=/))}{} or die "Dispatch not found\n";
    $ENV{'SCRIPT_NAME'} = $1;
    if ($ENV{'PATH_INFO'}) {
        $ENV{'PATH_INFO'} = "/$ENV{'PATH_INFO'}" if $ENV{'PATH_INFO'} !~ m{^/};
        $ENV{'PATH_INFO'} =~ s/%([a-fA-F0-9]{2})/chr(hex $1)/eg;
    }
    my $code = $self->{'dispatch'}->{$1};
    return $self->$code() if ref $code;
    $self->exec_cgi($code);
}

sub process_http_request {
    my ($self, $client) = @_;

    if (my $table = $self->{'dispatch'}) {
        my $qr = $self->{'dispatch_qr'} or die "Dispatch was not correctly setup\n";
        return $self->http_dispatch($qr, $table)
    }

    return $self->http_echo;
}

sub http_echo {
    my $self = shift;
    print "Content-type: text/html\n\n";
    print "<form method=post action=/bam><input type=text name=foo><input type=submit></form>\n";
    if (eval { require Data::Dumper }) {
        local $Data::Dumper::Sortkeys = 1;
        my $form = {};
        if (eval { require CGI }) {  my $q = CGI->new; $form->{$_} = $q->param($_) for $q->param;  }
        print "<pre>".Data::Dumper->Dump([\%ENV, $form], ['*ENV', 'form'])."</pre>";
    }
}

sub post_process_request {
    my $self = shift;
    my $info = $self->{'request_info'};
    $info->{'begin'} = time unless defined $info->{'begin'};
    $info->{'elapsed'} = time - $info->{'begin'};
    $self->SUPER::post_process_request(@_);
    $self->log_http_request($info);
}

###----------------------------------------------------------------###

sub log_http_request {
    my ($self, $info) = @_;
    my $prop = $self->{'server'};
    my $fmt  = $prop->{'access_log_format'} || return;
    my $log  = $prop->{'access_log_function'} || return;
    $log->($self->http_log_format($fmt, $info));
}

my %fmt_map = qw(
    a peeraddr
    A sockaddr
    B response_size
    f filename
    h peerhost
    H request_protocol
    l remote_logname
    m request_method
    p sockport
    q query_string
    r request
    s response_status
    u remote_user
    U request_path
    );
my %fmt_code = qw(
    C http_log_cookie
    e http_log_env
    i http_log_header_in
    n http_log_note
    o http_log_header_out
    P http_log_pid
    t http_log_time
    v http_log_vhost
    V http_log_vhost
    X http_log_constat
);

sub http_log_format {
    my ($self, $fmt, $info, $orig) = @_;
    $fmt =~ s{ % ([<>])?                      # 1
                 (!? \d\d\d (?:,\d\d\d)* )?   # 2
                 (?: \{ ([^\}]+) \} )?        # 3
                 ([aABDfhHmpqrsTuUvVhblPtIOCeinoPtX%])  # 4
    }{
        $info = $orig if $1 && $orig && $1 eq '<';
        my $v = $2 && (substr($2,0,1) eq '!' ? index($2, $info->{'response_status'})!=-1 : index($2, $info->{'response_status'})==-1) ? '-'
              : $fmt_map{$4}  ? $info->{$fmt_map{$4}}
              : $fmt_code{$4} ? do { my $m = $fmt_code{$4}; $self->$m($info, $3, $1, $4) }
              : $4 eq 'b'     ? $info->{'response_size'} || '-' # B can be 0, b cannot
              : $4 eq 'I'     ? $info->{'request_size'} + $info->{'request_header_size'}
              : $4 eq 'O'     ? $info->{'response_size'} + $info->{'response_header_size'}
              : $4 eq 'T'     ? sprintf('%d', $info->{'elapsed'})
              : $4 eq 'D'     ? sprintf('%d', $info->{'elapsed'}/.000_001)
              : $4 eq '%'     ? '%'
              : '-';
        $v = '-' if !defined($v) || !length($v);
        $v =~ s/([^\ -\!\#-\[\]-\~])/$1 eq "\n" ? '\n' : $1 eq "\t" ? '\t' : sprintf('\x%02X', ord($1))/eg; # escape non-printable or " or \
        $v;
    }gxe;
    return $fmt;
}
sub http_log_time {
    my ($self, $info, $fmt) = @_;
    return '['.POSIX::strftime($fmt || '%d/%b/%Y:%T %z', localtime($info->{'begin'})).']';
}
sub http_log_env { $ENV{$_[2]} }
sub http_log_cookie {
    my ($self, $info, $var) = @_;
    my @c;
    for my $cookie (map {$_->[1]} grep {$_->[0] eq 'Cookie' } @{ $info->{'request_headers'} || [] }) {
        push @c, $1 if $cookie =~ /^\Q$var\E=(.*)/;
    }
    return join ', ', @c;
}
sub http_log_header_in {
    my ($self, $info, $var) = @_;
    return join ', ', map {$_->[1]} grep {$_->[0] eq $var} @{ $info->{'request_headers'} || [] };
}
sub http_log_note {
    my ($self, $info, $var) = @_;
    return $self->http_note($var);
}
sub http_log_header_out {
    my ($self, $info, $var) = @_;
    return join ', ', map {$_->[1]} grep {$_->[0] eq $var} @{ $info->{'response_headers'} || [] };
}
sub http_log_pid { $_[1]->{'pid'} || $$ } # we do not support tid yet
sub http_log_vhost {
    my ($self, $info, $fmt, $f_l, $type) = @_;
    return $self->http_log_header_in($info, 'Host') || $self->{'server'}->{'client'}->NS_host || $self->{'server'}->{'sockaddr'};
}
sub http_log_constat {
    my ($self, $info) = @_;
    return $info->{'headers_sent'} ? '-' : 'X';
}

###----------------------------------------------------------------###

sub exec_fork_hook {}

sub exec_trusted_perl {
    my ($self, $file) = @_;
    die "File $file is not executable\n" if ! -x $file;
    local $!;
    my $pid = fork;
    die "Could not spawn child process: $!\n" if ! defined $pid;
    $self->exec_fork_hook($pid, $file, 1);
    if (!$pid) {
        if (!eval { require $file }) {
            my $err = "$@" || "Error while running trusted perl script\n";
            $err =~ s{\s*Compilation failed in require at lib/Net/Server/HTTP\.pm line \d+\.\s*\z}{\n};
            die $err if !$self->{'request_info'}->{'headers_sent'};
            warn $err;
        }
        exit;
    } else {
        waitpid $pid, 0;
        return;
    }
}

sub exec_cgi {
    my ($self, $file) = @_;

    my $done = 0;
    my $pid;
    Net::Server::SIG::register_sig(CHLD => sub {
        while (defined(my $chld = waitpid(-1, POSIX::WNOHANG()))) {
            $done = ($? >> 8) || -1 if $pid == $chld;
            last unless $chld > 0;
        }
    });

    require IPC::Open3;
    require Symbol;
    my $in;
    my $out;
    my $err = Symbol::gensym();
    local $!;
    $pid = eval { IPC::Open3::open3($in, $out, $err, $file) } or die "Could not run external script $file: $!\n";
    $self->exec_fork_hook($pid, $file); # won't occur for the child
    my $len = $ENV{'CONTENT_LENGTH'} || 0;
    my $s_in  = $len ? IO::Select->new($in) : undef;
    my $s_out = IO::Select->new($out, $err);
    my $printed;
    while (!$done) {
        my ($o, $i, $e) = IO::Select->select($s_out, $s_in, undef);
        Net::Server::SIG::check_sigs();
        for my $fh (@$o) {
            read($fh, my $buf, 4096) || next;
            if ($fh == $out) {
                print $buf;
                $printed ||= 1;
            } else {
                print STDERR $buf;
            }
        }
        if (@$i) {
            my $bytes = read(STDIN, my $buf, $len);
            print $in $buf if $bytes;
            $len -= $bytes;
            $s_in = undef if $len <= 0;
        }
    }
    if (!$self->{'request_info'}->{'headers_sent'}) {
        if (!$printed) {
            $self->send_500("Premature end of script headers");
        } elsif ($done > 0) {
            $self->send_500("Script exited unsuccessfully");
        }
    }

    Net::Server::SIG::unregister_sig('CHLD');
}

1;

__END__

=head1 NAME

Net::Server::HTTP - very basic Net::Server based HTTP server class

=head1 TEST ONE LINER

    perl -e 'use base qw(Net::Server::HTTP); main->run(port => 8080)'
    # will start up an echo server

=head1 SYNOPSIS

    use base qw(Net::Server::HTTP);
    __PACKAGE__->run;

    sub process_http_request {
        my $self = shift;

        print "Content-type: text/html\n\n";
        print "<form method=post action=/bam><input type=text name=foo><input type=submit></form>\n";

        require Data::Dumper;
        local $Data::Dumper::Sortkeys = 1;

        require CGI;
        my $form = {};
        my $q = CGI->new; $form->{$_} = $q->param($_) for $q->param;

        print "<pre>".Data::Dumper->Dump([\%ENV, $form], ['*ENV', 'form'])."</pre>";
    }

=head1 DESCRIPTION

Even though Net::Server::HTTP doesn't fall into the normal parallel of
the other Net::Server flavors, handling HTTP requests is an often
requested feature and is a standard and simple protocol.

Net::Server::HTTP begins with base type MultiType defaulting to
Net::Server::Fork.  It is easy to change it to any of the other
Net::Server flavors by passing server_type => $other_flavor in the
server configurtation.  The port has also been defaulted to port 80 -
but could easily be changed to another through the server
configuration.  You can also very easily add ssl by including,
proto=>"ssl" and provide a SSL_cert_file and SSL_key_file.

For example, here is a basic server that will bind to all interfaces,
will speak both HTTP on port 8080 as well as HTTPS on 8443, and will
speak both IPv4, as well as IPv6 if it is available.

    use base qw(Net::Server::HTTP);

    __PACKAGE__->run(
        port  => [8080, "8443/ssl"],
        ipv   => '*', # IPv6 if available
        SSL_key_file  => '/my/key',
        SSL_cert_file => '/my/cert',
    );

=head1 METHODS

=over 4

=item C<_init_access_log>

Used to open and initialize any requested access_log (see access_log_file
and access_log_format).

=item C<_tie_client_stdout>

Used to initialize automatic response header parsing.

=item C<process_http_request>

Will be passed the client handle, and will have STDOUT and STDIN tied
to the client.

During this method, the %ENV will have been set to a standard CGI
style environment.  You will need to be sure to print the Content-type
header.  This is one change from the other standard Net::Server base
classes.

During this method you can read from %ENV and STDIN just like a normal
HTTP request in other web servers.  You can print to STDOUT and
Net::Server will handle the header negotiation for you.

Note: Net::Server::HTTP has no concept of document root or script
aliases or default handling of static content.  That is up to the
consumer of Net::Server::HTTP to work out.

Net::Server::HTTP comes with a basic %ENV display installed as the
default process_http_request method.

=item C<process_request>

This method has been overridden in Net::Server::HTTP - you should not
use it while using Net::Server::HTTP.  This overridden method parses
the environment and sets up request alarms and handles dying failures.
It calls process_http_request once the request is ready and headers
have been parsed.

=item C<process_headers>

Used to read in the incoming headers and set the ENV.

=item C<_init_http_request_info>

Called at the end of process_headers.  Initializes the contents of
http_request_info.

=item C<http_request_info>

Returns a hashref of information specific to the current request.
This information will be used for logging later on.

=item C<send_status>

Takes an HTTP status and a message.  Sends out the correct headers.

=item C<send_500>

Calls send_status with 500 and the argument passed to send_500.

=item c<log_http_request>

Called at the end of post_process_request.  The default method looks
for the default access_log_format and checks if logging was initilized
during _init_access_log.  If both of these exist, the http_request_info
is formatted using http_log_format and the result is logged.

=item C<http_log_format>

Takes a format string, and request_info and returns a formatted string.
The format should follow the apache mod_log_config specification.  As in
the mod_log_config specification, backslashes, quotes should be escaped
with backslashes and you may also include \n and \t characters as well.

The following is a listing of the available parameters as well as sample
output based on a very basic HTTP server.

    %%                %                 # a percent
    %a                ::1               # remote ip
    %A                ::1               # local ip
    %b                83                # response size (- if 0) Common Log Format
    %B                83                # response size
    %{bar}C           baz               # value of cookie by that name
    %D                916               # elapsed in microseconds
    %{HTTP_COOKIE}e   bar=baz           # value of %ENV by that name
    %f                -                 # filename - unused
    %h                ::1               # remote host if lookups are on, remote ip otherwise
    %H                http              # request protocol
    %{Host}i          localhost:8080    # request header by that name
    %I                336               # bytes received including headers
    %l                -                 # remote logname - unsused
    %m                GET               # request method
    %n                Just a note       # http_note by that name
    %{Content-type}o  text/html         # output header by that name
    %O                189               # response size including headers
    %p                8080              # server port
    %P                22999             # pid - does not support %{tid}P
    q                 ?hello=there      # query_string including ? (- otherwise)
    r                 GET /bam?hello=there HTTP/1.1      # the first line of the request
    %s                200               # response status
    %u                -                 # remote user - unused
    %U                /bam              # request path (no query string)
    %t                [06/Jun/2012:12:14:21 -0600]       # http_log_time standard format
    %t{%F %T %z}t     [2012-06-06 12:14:21 -0600]        # http_log_time with format
    %T                0                 # elapsed time in seconds
    %v                localhost:8080    # http_log_vhost - partial implementation
    %V                localhost:8080    # http_log_vhost - partial implementation
    %X                -                 # Connection completed and is 'close' (-)

Additionally, the log parsing allows for the following formats.

    %>s               200               # status of last request
    %<s               200               # status of original request
    %400a             -                 # remote ip if status is 400
    %!400a            ::1               # remote ip if status is not 400
    %!200a            -                 # remote ip if status is not 200

There are few bits not completely implemented:

    > and <    # There is no internal redirection
    %I         # The answer to this is based on header size and Content-length
                 instead of the more correct actual number of bytes read though
                 in common cases those would be the same.
    %X         # There is no Connection keepalive in the default server.
    %v and %V  # There are no virtual hosts in the default HTTP server.
    %{tid}P    # The default servers are not threaded.

See the C<access_log_format> option for how to set a different format as
well as to see the default string.

=item C<exec_cgi>

Allow for calling an external script as a CGI.  This will use IPC::Open3 to
fork a new process and read/write from it.

    use base qw(Net::Server::HTTP);
    __PACKAGE__->run;

    sub process_http_request {
        my $self = shift;

        if ($ENV{'PATH_INFO'} && $ENV{'PATH_INFO'} =~ s{^ (/foo) (?= $ | /) }{}x) {
           $ENV{'SCRIPT_NAME'} = $1;
           my $file = "/var/www/cgi-bin/foo"; # assuming this exists
           return $self->exec_cgi($file);
        }

        print "Content-type: text/html\n\n";
        print "<a href=/foo>Foo</a>";
    }

At this first release, the parent server is not tracking the child
script which may cause issues if the script is running when a HUP is
received.

=item C<http_log_time>

Used to implement the %t format.

=item C<http_log_env>

Used to implement the %e format.

=item C<http_log_cookie>

Used to implement the %C format.

=item C<http_log_header_in>

used to implement the %i format.

=item C<http_log_note>

Used to implement the %n format.

=item C<http_note>

Takes a key and an optional value.  If passed a key and value, sets
the note for that key.  Always returns the value.  These notes
currently only are used for %{key}n output format.

=item C<http_log_header_out>

Used to implement the %o format.

=item C<http_log_pid>

Used to implement the %P format.

=item C<http_log_vhost>

Used to implement the %v and %V formats.

=item C<http_log_constat>

Used to implement the %X format.

=item C<exec_trusted_perl>

Allow for calling an external perl script.  This method will still
fork, but instead of using IPC::Open3, it simply requires the perl
script.  That means that the running script will be able to make use
of any shared memory.  It also means that the STDIN/STDOUT/STDERR
handles the script is using are those directly bound by the server
process.

    use base qw(Net::Server::HTTP);
    __PACKAGE__->run;

    sub process_http_request {
        my $self = shift;

        if ($ENV{'PATH_INFO'} && $ENV{'PATH_INFO'} =~ s{^ (/foo) (?= $ | /) }{}x) {
           $ENV{'SCRIPT_NAME'} = $1;
           my $file = "/var/www/cgi-bin/foo"; # assuming this exists
           return $self->exec_trusted_perl($file);
        }

        print "Content-type: text/html\n\n";
        print "<a href=/foo>Foo</a>";
    }

At this first release, the parent server is not tracking the child
script which may cause issues if the script is running when a HUP is
received.

=item C<exec_fork_hook>

This method is called after the fork of exec_trusted_perl and exec_cgi
hooks.  It is passed the pid (0 if the child) and the file being ran.
Note, that the hook will not be called from the child during exec_cgi.

=item C<http_dispatch>

Called if the default process_http_request and process_request methods
have not been overridden and C<app> configuration parameters have been
passed.  In this case this replaces the default echo server.  You can
also enable this subsystem for your own direct use by setting
enable_dispatch to true during configuration.  See the C<app>
configuration item.  It will be passed a dispatch qr (regular
expression) generated during _check_dispatch, and a dispatch table.
The qr will be applied to path_info.  This mechanism could be used to
augment Net::Server::HTTP with document root and virtual host
capabilities.

=back

=head1 OPTIONS

In addition to the command line arguments of the Net::Server base
classes you can also set the following options.

=over 4

=item max_header_size

Defaults to 100_000.  Maximum number of bytes to read while parsing
headers.

=item server_revision

Defaults to Net::Server::HTTP/$Net::Server::VERSION.

=item timeout_header

Defaults to 15 - number of seconds to wait for parsing headers.

=item timeout_idle

Defaults to 60 - number of seconds a request can be idle before the
request is closed.

=item access_log_file

Defaults to undef.  If true, this represents the location of where
the access log should be written to.  If a special value of STDERR
is passed, the access log entry will be writing to the same location
as the ERROR log.

=item access_log_format

Should be a valid apache log format that will be passed to http_log_format.  See
the http_log_format method for more information.

The default value is the NCSA extended/combined log format:

    '%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"'

=item app

Takes one or more items and registers them for dispatch.  Arguments
may be supplied as an arrayref containing a location/target pairs, a
hashref containing a location/target pairs, a bare code ref that will
use "/" as the location and the codref as the target, a string with a space
indicating "location target", a string containing "location=target", or
finally a string that will be used as both location and target.  For items
passed as an arrayref or hashref, the target may be a coderef which
will be called and should handle the request.  In all other cases the
target should be a valid executable suitable for passing to exec_cgi.

The locations will be added in the order that they are configured.
They will be added to a regular expression which will be applied to
the incoming PATH_INFO string.  If the match is successful, the
$ENV{'SCRIPT_NAME'} will be set to the matched portion and the matched
portion will be removed from $ENV{'PATH_INFO'}.

Once an app has been passed, it is necessary for the server to listen
on /.  Therefore if "/" has not been specifically configured for
dispatch, the first found dispatch target will also be used to handle
"/".

For convenience, if the log_level is 2 or greater, the dispatch table
is output to the log.

This mechanism is left as a generic mechanism suitable for overriding
by servers meant to handle more complex dispatch.  At the moment there
is no handling of virtual hosts.  At some point we will add in the
default ability to play static content and likely for the ability to
configure virtual hosts - or that may have to wait for a third party
module.

    app => "/home/paul/foo.cgi",
      # Dispatch: /home/paul/foo.cgi => home/paul/foo.cgi
      # Dispatch: / => home/paul/foo.cgi (default)


    app => "../../foo.cgi",
    app => "./bar.cgi",
    app => "baz ./bar.cgi",
    app => "bim=./bar.cgi",
      # Dispatch: /foo.cgi => ../../foo.cgi
      # Dispatch: /bar.cgi => ./bar.cgi
      # Dispatch: /baz => ./bar.cgi
      # Dispatch: /bim => ./bar.cgi
      # Dispatch: / => ../../foo.cgi (default)


    app => "../../foo.cgi",
    app => "/=./bar.cgi",
      # Dispatch: /foo.cgi => ../../foo.cgi
      # Dispatch: / => ./bar.cgi

    # you could also do this on the commandline
    net-server HTTP app ../../foo.cgi app /=./bar.cgi

    # extended options when configured from code

    Net::Server::HTTP->run(app => { # loses order of matching
      '/' => sub { ... },
      '/foo' => sub { ... },
      '/bar' => '/path/to/some.cgi',
    });

    Net::Server::HTTP->run(app => [
      '/' => sub { ... },
      '/foo' => sub { ... },
      '/bar' => '/path/to/some.cgi',
    ]);

=back

=head1 TODO

Add support for writing out HTTP/1.1.

=head1 AUTHOR

Paul T. Seamons paul@seamons.com

=head1 THANKS

See L<Net::Server>

=head1 SEE ALSO

Please see also
L<Net::Server::Fork>,
L<Net::Server::INET>,
L<Net::Server::PreFork>,
L<Net::Server::PreForkSimple>,
L<Net::Server::MultiType>,
L<Net::Server::Single>
L<Net::Server::SIG>
L<Net::Server::Daemonize>
L<Net::Server::Proto>

=cut
