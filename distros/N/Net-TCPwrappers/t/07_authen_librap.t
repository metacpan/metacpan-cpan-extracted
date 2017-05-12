#!/usr/bin/perl
#
# $Id: 07_authen_librap.t 161 2004-12-31 04:00:52Z james $
#

use strict;
use warnings;

BEGIN {
    use Test::More;
    use Test::Exception;
    our $tests = 19;
    eval "use Test::NoWarnings";
    $tests++ unless( $@ );
    plan tests => $tests;
}

# these tests were brought over from Authen::Libwrap.  They represent
# functionality of Authen::Libwrap which should work under Net::TCPwrappers. 
# Right now, quite a few of them fail, but all for the same reason, so
# we only specify the reason once for all of the TODO blocks
my $todo = "not all of Authen::Libwrap's functionality has been integrated";
  
use_ok('Net::TCPwrappers');
Net::TCPwrappers->import(':all');
ok( defined(&hosts_ctl), "'hosts_ctl' function is exported");
TODO: {
    local $TODO = $todo;
    ok( defined(&STRING_UNKNOWN), "'STRING_UNKNOWN' constant is exported");
}

my $daemon = "tcp_wrappers_test";
my $hostname = "localhost";
my $hostaddr = "127.0.0.1";
my $username = 'me';

# these tests aren't very comprehensive because the path to hosts.allow
# is set when libwrap is built and I can't tell what the user's rules
# are.  I can make sure they don't croak, but I can't really tell
# if any call to hosts_ctl should give back a true or false value

# call with all four arguments explicitly
lives_ok { hosts_ctl($daemon, $hostname, $hostaddr, $username) }
    'call hosts_ctl with four explicit args';

# use a default user
lives_ok { hosts_ctl($daemon, $hostname, $hostaddr) }
    'call hosts_ctl without a username';

# give something that is blessed but not a IO::Socket
my $thingy = bless {}, 'Foo';
TODO: {
    local $TODO = $todo;
    throws_ok { hosts_ctl($daemon, $thingy) }
        qr/can't use/, 'cannot use a non-socket as a socket';
}

# pass an IO::Socket that is not initialized
use IO::Socket::INET;
my $sock = IO::Socket::INET->new;
TODO: {
    local $TODO = $todo;
    throws_ok { hosts_ctl($daemon, $sock) }
        qr/can't get peer/, 'call hosts_ctl an uninitialized IO::Socket';
}

# set up a listening socket and connect to it
my $listener;
lives_and {
    $listener = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1',
        Proto => 'tcp',
        Listen => 10,
    );
    isa_ok($listener, 'IO::Socket::INET');
} 'create listener socket';
lives_and {
    $sock = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1',
        PeerPort => $listener->sockport,
        Proto => 'tcp'
    );
    isa_ok($sock, 'IO::Socket::INET');
} 'connect to listener';

# use an IO::Socket with a username
lives_ok { hosts_ctl($daemon, $sock, $username) }
    'call hosts_ctl with a glob and username';

# use an IO::Socket without a username
TODO: {
    local $TODO = $todo;
    lives_ok { hosts_ctl($daemon, $sock) }
        'call hosts_ctl with a glob and username';
}

# close the IO::Socket
$sock->close;
TODO: {
    local $TODO = $todo;
    throws_ok { hosts_ctl($daemon, $sock) }
        qr/can't get peer/, 'call hosts_ctl an uninitialized IO::Socket';
}

# try with an uninitialized glob 
TODO: {
    local $TODO = $todo;
    throws_ok { hosts_ctl($daemon, *SOCK) }
        qr/can't get peer/, 'call hosts_ctl an uninitialized GLOB';
}

# connect to the listening socket
lives_and {
    my $proto = getprotobyname('tcp');
    socket(SOCK, PF_INET, SOCK_STREAM, $proto);
    my $iaddr = inet_aton('127.0.0.1');
    my $paddr = sockaddr_in($listener->sockport, $iaddr);
    connect(SOCK,$paddr);
} 'connect to listener';

# use a glob with a username
lives_ok { hosts_ctl($daemon, *SOCK, $username) }
    'call hosts_ctl with a glob and username';

# use a glob without a username
TODO: {
    local $TODO = $todo;
    lives_ok { hosts_ctl($daemon, *SOCK) }
        'call hosts_ctl with a glob and username';
}

# close the glob
close SOCK;
TODO: {
    local $TODO = $todo;
    throws_ok { hosts_ctl($daemon, *SOCK) }
        qr/can't get peer/, 'call hosts_ctl an uninitialized GLOB';
}

# try with an uninitialized globref 
TODO: {
    local $TODO = $todo;
    throws_ok { hosts_ctl($daemon, \*SOCK) }
        qr/can't get peer/, 'call hosts_ctl an uninitialized GLOBREF';
}

# connect to the listening socket
lives_and {
    my $proto = getprotobyname('tcp');
    socket(SOCK, PF_INET, SOCK_STREAM, $proto);
    my $iaddr = inet_aton('127.0.0.1');
    my $paddr = sockaddr_in($listener->sockport, $iaddr);
    connect(SOCK,$paddr);
} 'connect to listener';

# use a globref with a username
lives_ok { hosts_ctl($daemon, \*SOCK, $username) }
    'call hosts_ctl with a glob and username';

# use a globref without a username
TODO: {
    local $TODO = $todo;
    lives_ok { hosts_ctl($daemon, \*SOCK) }
        'call hosts_ctl with a glob and username';
}

#
# EOF
