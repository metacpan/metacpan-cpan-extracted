package Net::Squid::ReverseProxy;

use 5.006;
use strict;
use Carp qw/croak/;

use vars qw/$VERSION/;
$VERSION = '0.04';


sub new {

    my $class = shift;
    my %arg = @_;

    unless (defined $arg{'squid_version'} &&
            defined $arg{'squid_conf'} &&
            defined $arg{'squid'} ) {
        croak "the path to both squid and squid.conf as well as squid version are required";
    }

    unless (-f $arg{'squid_conf'} && -w $arg{'squid_conf'} ) {
        croak "squid config file doesn't exist or isn't writable";
    }

    unless (-f $arg{'squid'} && -x $arg{'squid'} ) {
        croak "squid program doesn't exist or isn't executable";
    }

    bless \%arg, $class;
}

sub init_reverseproxy {

    my $self = shift;
    my %arg = @_;

    my $cfg = $self->{'squid_conf'};
    my $squid = $self->{'squid'};
    my $version = $self->{'squid_version'};

    my $cache_mem = $arg{'cache_mem'} || 50;
    my $maximum_object_size = $arg{'maximum_object_size'} || 2048;
    my $maximum_object_size_in_memory = $arg{'maximum_object_size_in_memory'} || 64;
    my $cache_dir_size = $arg{'cache_dir_size'} || 50;
    my $visible_hostname = $arg{'visible_hostname'} || 'localhost.localdomain';

    if ($arg{'cache_dir'} ) {
        my $uid = (stat $arg{'cache_dir'})[4];
        my $user = (getpwuid $uid)[0];

        if ($user ne 'nobody') {
            croak "init failed, $arg{'cache_dir'} must be owned by nobody";
        } 
    }

    my $cache_dir = $arg{'cache_dir'} || '/tmp/squidcache';

    my $module_dir = $INC{'Net/Squid/ReverseProxy.pm'};
    $module_dir =~ s/\.pm$//;

    my @cfg; my $fd;

    open $fd, "<", "$module_dir/squidcfg" or croak "can't open template file $!";
    while (<$fd>) {
        push @cfg,$_;

        if (/ARG INPUT BEGIN/) {
            push @cfg,
                "cache_mem $cache_mem MB\n",
                "maximum_object_size $maximum_object_size KB\n",
                "maximum_object_size_in_memory $maximum_object_size_in_memory KB\n",
                "cache_dir ufs $cache_dir $cache_dir_size 16 256\n",
                "visible_hostname $visible_hostname\n";

            if ( $version < 3.0 ) {
                push @cfg, "acl all src all\n";
	    }
        }
    }
    close $fd;

    open $fd, "<", $cfg or croak $!;
    my @oldcfg = <$fd>;
    close $fd;

    my $fdw;

    open $fdw,">",$cfg or croak $!;
    print $fdw @cfg;
    close $fdw;

    system "$squid -k kill >/dev/null 2>&1";
    system "$squid -z >/dev/null 2>&1 && $squid";

    if ($? == 0) {
        return 1;

    } else {

        open $fdw,">",$cfg or croak $!;
        print $fdw @oldcfg;
        close $fdw;

        croak "init failed, can't run 'squid -z' and startup squid";
    }
}


sub add_dstdomain_proxy {

    my $self = shift;
    my %arg = @_;

    my $cfg = $self->{'squid_conf'};
    my $squid = $self->{'squid'};

    my $site_dst = $arg{'dstdomain'};
    my @ip = @{$arg{'original_server'}};
    my $algor = $arg{'load_balance'} || '';

    unless ($site_dst && @ip) {
	return;
    }

    my @newconf;
    my %cache_peer_access;
    my $fd;

    $cache_peer_access{'origin'} = 'origin_0_0';
    open $fd, "<", $cfg or croak $!;
    while(<$fd>) {
        last if /SITE END/;
        if (/^cache_peer_access/) {
            $cache_peer_access{'origin'} = (split)[1];
        }
    }
    close $fd;

    my $idmax = (split /\_/, $cache_peer_access{'origin'})[-2];
    $idmax++;

    open $fd, "<", $cfg or croak $!;
    while(<$fd>) {

        if (/SITE END/) {
            my $int = 1;
            for my $ip (@ip) {
                my ($site_ip,$site_port) = split/\:/,$ip;
                $site_port ||= 80;
                push @newconf, 
                "cache_peer $site_ip parent $site_port 0 no-query originserver name=origin_${idmax}_$int $algor\n";
                $int++;
            }

            push @newconf,"acl service_$idmax dstdomain $site_dst\n";

            for my $int (1 .. scalar(@ip) ) {
                push @newconf, "cache_peer_access origin_${idmax}_$int allow service_$idmax\n";
            }
        }

        push @newconf,$_;
    }
    close $fd;

    open $fd, "<", $cfg or croak $!;
    my @oldcfg = <$fd>;
    close $fd;

    my $fdw;

    open $fdw, ">", $cfg or croak $!;
    print $fdw @newconf;
    close $fdw;

    my @err = `$squid -k reconfig 2>&1`;
    if (@err) {

        open $fdw,">",$cfg or croak $!;
        print $fdw @oldcfg;
        close $fdw;

	system "$squid -k reconfig >/dev/null 2>&1";
        return;

    } else {
        return 1;
    }
}


sub remove_dstdomain_proxy {

    my $self = shift;
    my $domain = shift || return;

    my $cfg = $self->{'squid_conf'};
    my $squid = $self->{'squid'};

    $domain = quotemeta($domain);

    my @id; my $fd;

    open $fd, "<", $cfg or croak $!;
    while(<$fd>) {
	if (/^acl\s+service_(\d+)\s+dstdomain\s+$domain$/) {
	    push @id, $1;
	}
    }
    close $fd;

    my @cfg;
    open $fd, "<", $cfg or croak $!;
    while(<$fd>) {
	my $next = 0;
	for my $id (@id) {
	    $next=1 if (/origin_${id}_/ || /service_${id}\s+/);
	}
	next if $next;
        push @cfg,$_;
    }
    close $fd;
    
    open $fd, "<", $cfg or croak $!;
    my @oldcfg = <$fd>;
    close $fd;

    my $fdw;

    open $fdw, ">", $cfg or croak $!;
    print $fdw @cfg;
    close $fdw;

    my @err = `$squid -k reconfig 2>&1`;
    if (@err) {

        open $fdw,">",$cfg or croak $!;
        print $fdw @oldcfg;
        close $fdw;

	system "$squid -k reconfig >/dev/null 2>&1";
        return;

    } else {
        return 1;
    }
}


sub exists_dstdomain_proxy {

    my $self = shift;
    my $domain = shift || return;

    $domain = quotemeta($domain);
    my $cfg = $self->{'squid_conf'};
    my $exist = 0;
    my $fd;

    open $fd,"<",$cfg or croak $!;
    while (<$fd>) {
        if (/^acl\s+service_(\d+)\s+dstdomain\s+$domain$/) {
            $exist = 1;
            last;
        }
    }
    close $fd;

    return $exist;
}


sub _get_dstdomain_sites {

    my $self = shift;

    my $cfg = $self->{'squid_conf'};
    my %sites;
    my %service;
    my %peers;
    my $fd;

    open $fd, "<", $cfg or croak $!;
    while(<$fd>) {
        if (/SITE BEGIN/) {
            while(<$fd>) {
                last if /SITE END/;
                chomp;

                my @elem = split;

                if ($elem[0] eq 'cache_peer_access') {
                    push @{$service{$elem[3]}}, $elem[1];
                }
            }
        }
    }
    close $fd;
                    
    open $fd, "<", $cfg or croak $!;
    for my $s (keys %service) {
        my @lines = grep {/^acl\s+$s\s+/} <$fd>;
        my $line = shift @lines;
        chomp $line;
        $sites{$s} = (split/\s+/,$line)[-1];
        seek($fd,0,0);
    }
    close $fd;                

    open $fd, "<", $cfg or croak $!;
    for my $s (keys %service) {
        for my $p (@{$service{$s}}) {
            my @lines = grep {/name=$p\s+/} <$fd>;
            my $line = shift @lines;
            chomp $line;
            $peers{$p} = [ (split/\s+/,$line)[1,3,-1] ];
            seek($fd,0,0);
        }
    }
    close $fd;

    return \%service,\%sites,\%peers;
}


sub list_dstdomain_proxies {

    my $self = shift;

    my ($svr,$site,$peer) = $self->_get_dstdomain_sites();
    my @exist;
    
    for my $s ( sort { (split/\_/,$a)[-1] <=> (split/\_/,$b)[-1] } keys %$site ) {
        my @ip;
        my $algor = '';
        my $domain = $site->{$s};
        my $original = $svr->{$s};

        for my $name (@$original) {
            push @ip, $peer->{$name}->[0] . ":" . $peer->{$name}->[1];
            if ($peer->{$name}->[2] !~ /name=/) {
                $algor = $peer->{$name}->[2];
            }
        }

        push @exist, [$s,$domain,$algor,[@ip]];
    }

    return \@exist;
}


1;


=head1 NAME

Net::Squid::ReverseProxy - setup a HTTP reverse proxy with Squid

=head1 VERSION

Version 0.04


=head1 SYNOPSIS

    use Net::Squid::ReverseProxy;

    my $squid = Net::Squid::ReverseProxy->new(
                     'squid' => '/path/to/squid',
                     'squid_conf' => '/path/to/squid.conf',
                     'squid_version' => '3.0');

    $squid->init_reverseproxy;
    sleep 1;

    $squid->add_dstdomain_proxy('dstdomain' => 'www.example.com',
                           'original_server' => ['192.168.1.10'])
            or die "can't add dstdomain";

    $squid->add_dstdomain_proxy('dstdomain' => 'mail.example.com',
                          'original_server' => ['192.168.1.20',
                                                '192.168.1.30:8080'],
			     'load_balance' => 'round-robin')
            or die "can't add dstdomain";

    print "The dstdomain www.example.com exists? ";
    print $squid->exists_dstdomain_proxy('www.example.com') ? "yes\n" : "no\n";

    use Data::Dumper;
    print Dumper $squid->list_dstdomain_proxies;

    $squid->remove_dstdomain_proxy('www.example.com')
            or die "can't remove dstdomain";

=head1 METHODS

=head2 new()

Create an object. Please specify the full path of both squid 
executable program and squid config file, with the version number
of squid. Currently squid-2.7, 3.0, 3.1 branches were tested.

   my $squid = Net::Squid::ReverseProxy->new(
                     'squid' => '/path/to/squid',
                     'squid_conf' => '/path/to/squid.conf',
                     'squid_version' => '3.0');

Before using this module, you must have squid installed in
the system. You could get the latest source from its official
website squid-cache.org, then install it following the words in
INSTALL document. For example,

        % ./configure --prefix=/usr/local/squid
        % make
        # make install


=head2 init_reverseproxy()

Warnning: the config file will be overwritten by this method, you 
should execute the method only once at the first time of using this 
module. It's used to initialize the setting for squid reverse proxy. 

To keep backward compatibility, there is a method of
init_squid_for_reverseproxy() which is an alias to this method.

You could pass the additional arguments like below to the method:

    $squid->init_reverseproxy(
      'cache_mem' => 200,
      'maximum_object_size' => 4096,
      'maximum_object_size_in_memory' => 64,
      'cache_dir_size' => 1024,
      'visible_hostname' => 'squid.domain.com',
      'cache_dir' => '/data/squidcache',
    );

cache_mem: how large memory (MB) squid will use for cache, default 50

maximum_object_size: the maximum object size (KB) squid will cache with,
default 2048

maximum_object_size_in_memory: the maximum object size (KB) squid will
cache with in memory, default 64

cache_dir_size: how large disk (MB) squid will use for cache, default 50

visible_hostname: visiable hostname, default localhost.localdomain

cache_dir: path to cache dir, default /tmp/squidcache


After calling this method, you MUST sleep at least one second to wait for 
squid to finish starting up before any further operation.

If initialized correctly, it will make squid run and listen on TCP port
80 for HTTP requests. If initialized failed, you may check /tmp/cache.log
for details.


=head2 add_dstdomain_proxy()

Add a rule of reverseproxy based on dstdomain (destination domain).
For example, you want to reverse-proxy the domain www.example.com,
whose backend webserver is 192.168.1.10, then do:

    $squid->add_dstdomain_proxy('dstdomain' => 'www.example.com',
                          'original_server' => ['192.168.1.10']);

Here 'dstdomain' means destination domain, 'original_server' means backend
webserver. If you have two backend webservers, one is 192.168.1.20, whose 
http port is 80 (the default), another is 192.168.1.30, whose http port is 
8080, then do:

    $squid->add_dstdomain_proxy('dstdomain' => 'www.example.com',
                          'original_server' => ['192.168.1.20',
                                                '192.168.1.30:8080'],
			     'load_balance' => 'round-robin');

Here 'load_balance' specifies an algorithm for balancing http requests among
webservers. The most common used algorithms are round-robin and sourcehash.
The latter is used for session persistence mostly. See squid.conf's document
for details. If you want all traffic go to the first webserver, and only when 
the first webserver gets down, the traffic go to the second webserver,
then don't specify a load_balance algorithm here.


=head2 exists_dstdomain_proxy()

Whether a reverseproxy rule for the specified destination domain exists.

    $squid->exists_dstdomain_proxy('www.example.com');

Returns 1 for exists, 0 for non-exists.


=head2 list_dstdomain_proxies()

List all reverseproxy rules in the config file. It returns a data structure
of a reference to AoA, so you will dump it with Data::Dumper.

    use Data::Dumper;
    print Dumper $squid->list_dstdomain_proxies;


=head2 remove_dstdomain_proxy()

Remove reverseproxy rule(s) for the specified destination domain.

    $squid->remove_dstdomain_proxy('www.example.com');


=head1 AUTHOR

Jeff Pang <pangj@arcor.de>


=head1 BUGS/LIMITATIONS

If you have found bugs, please send email to <pangj@arcor.de>, I will
appreciate it much.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Squid::ReverseProxy

For the general knowledge of installing and setup squid, please reference
documents and wiki on squid-cache.org, or subscribe to squid user's mailing
list, or, you can email me in private. For Chinese you could download and
read the Chinese version of "Squid: The Definitive Guide" translated by me:

    http://squidcn.spaces.live.com/blog/cns!B49104BB65206A10!229.entry


=head1 COPYRIGHT & LICENSE

Copyright 2009 Jeff Pang, all rights reserved.

This program is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself.

