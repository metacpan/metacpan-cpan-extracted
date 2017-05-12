#!/usr/bin/perl
#
# This file is part of POE-Component-SSLify
#
# This software is copyright (c) 2014 by Apocalypse.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;

# Test contributed by mire@irc which used this to hit the WRITE_WANTS_READ case
# mire created package Ub because he couldn't reproduce it with poco-cl-http :(
# tweaked slightly to turn it into a real testcase ( not done yet )

BEGIN {
#  sub POE::Kernel::ASSERT_DEFAULT () { 1 }
#  sub POE::Kernel::TRACE_STATISTICS () { 0 } # makes POE hang, it's been removed in git but not in 1.299 heh
#  sub POE::Kernel::TRACE_DEFAULT () { 1 }
#  sub POE::Kernel::CATCH_EXCEPTIONS () { 0 } # make sure we die right away so it's easier to debug
}

use Test::More;
BEGIN {
	plan skip_all => "AUTHOR TEST";
}

use strict;
use warnings;
use POE;
use Test::FailWarnings;

our $DEBUG=0;

package Ub;
use strict;
use warnings;
use POE qw( Component::Client::TCP Filter::Stream );
use POE::Component::SSLify qw( Client_SSLify );

# non-core deps
BEGIN {
	eval "use POE::Filter::HTTPChunk; use HTTP::Parser; use HTTP::Response;";
	if ( $@ ) {
		use Test::More;
		plan skip_all => "Unable to load deps: $@";
	}
}

sub new {
    my $this = shift;
    my %p = @_;

    my $class = ref($this) || $this;
    my $self = {};
    bless $self, $class;

    $self->{'_p'} = \%p;

    return $self;
}

sub spawn {
my $self = shift;

    my $session_id =  POE::Session->create(
        inline_states => {
_child => sub {},
_start => sub {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    ($heap->{'self'})   = @_[ARG0..$#_];
    print 'INFO: ' . __PACKAGE__ . "_start\n"
        if $main::DEBUG;
    $kernel->alias_set( 'ub' );
    #$_[KERNEL]->refcount_increment($_[SESSION]->ID, 'ub');
},
_stop => sub {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    print 'INFO: ' . __PACKAGE__ . "_stop\n"
        if $main::DEBUG;
    $heap = {};
},
on_shutdown => sub {
    print 'INFO: ' . __PACKAGE__ . "on_shutdown\n"
        if $main::DEBUG;
},
_shutdown => sub {
    print 'INFO: ' . __PACKAGE__ . "_shutdown\n"
        if $main::DEBUG;
},
r => sub {
    my ($kernel, $heap, $ev_res, $cont_ref, $host, $port, $do_ssl) = @_[KERNEL, HEAP, ARG0..$#_];

    my $s_res = $_[SENDER]->ID;

    # TODO pravi alarm za ubijanje konekcije
    my $tcp_sid = POE::Component::Client::TCP->new(
    #SessionParams => [ options => { debug => 1, trace => 1 } ],
#    SessionParams => [ options => { debug => 1 } ],
    Args => [$s_res, $ev_res, $cont_ref, $do_ssl],
    Filter => "POE::Filter::Stream",
    RemoteAddress => $host,
    RemotePort    => $port,
    ConnectTimeout => 30,
    Started => sub {
        my ($kernel, $heap) = @_[KERNEL, HEAP];
        print "INFO: Started\n"
            if $main::DEBUG;
        (@$heap{qw|s_res ev_res cont_ref do_ssl|}) = @_[ARG0..$#_];
    },
    PreConnect => sub {
        my ($kernel, $heap) = @_[KERNEL, HEAP];

        print "INFO: PreConnect\n"
            if $main::DEBUG;

        $heap->{'parser'} = HTTP::Parser->new(response => 1);

        return $_[ARG0]
            unless $heap->{'do_ssl'};

        # Convert the socket into an SSL socket.
        my $socket = eval { Client_SSLify($_[ARG0]) };

        # Disconnect if SSL failed.
        if ($@) {
            warn $@ if $main::DEBUG;
            return;
        }
        # Return the SSL-ified socket.
        return $socket;
    },
    ConnectError => sub {
        my ($kernel, $heap) = @_[KERNEL, HEAP];
        #print Dumper $heap; exit;
        my ($operation, $error_number, $error_string) = @_[ARG0..ARG2];
        print "ERROR: ConnectError $operation error $error_number occurred: $error_string\n"
            if $main::DEBUG;
        my $dc = '';
        $kernel->post($heap->{'s_res'}, $heap->{'ev_res'}, {'error' => 1, 'error_type' => 'connect_error', 'content' => \$dc});
        $_[KERNEL]->yield('shutdown');
    },
    ServerError => sub {
        my ($kernel, $heap) = @_[KERNEL, HEAP];
        my ($operation, $error_number, $error_string) = @_[ARG0..ARG2];

        print "not informing master session, ERROR: ServerError $operation error $error_number occurred: $error_string\n"
            if $main::DEBUG;
        $kernel->yield('shutdown');
    },
    Connected     => sub {
        my ($kernel, $heap) = @_[KERNEL, HEAP];
        print "INFO: Connected\n"
            if $main::DEBUG;
        $heap->{server}->put(${$heap->{'cont_ref'}});
        # start timeout thing
        #   za pravu shutdown funkciju
        $heap->{'al_cest_id'} = $_[KERNEL]->alarm_set( shutdown => time + 60 );
    },
    ServerInput   => sub {
        my ($kernel, $heap) = @_[KERNEL, HEAP];
        print "INFO: ServerInput\n"
            if $main::DEBUG;
        my $input = $_[ARG0];
        #print 'from server: ' . Dumper $input;
        eval {
            $heap->{'parser'}->add($input);
        };
        # TODO error response
        $kernel->yield('shutdown')
            if $@;
    },
    ServerFlushed => sub {
        print "INFO: ServerFlushed\n"
            if $main::DEBUG;
    },
    Disconnected => sub {
        my ($kernel, $heap) = @_[KERNEL, HEAP];
        print "INFO: disconnected ;)\n"
            if $main::DEBUG;
        my $dc = '';
        $dc = $heap->{'parser'}->object->decoded_content
            if $heap->{'parser'}->object;
        $kernel->post($heap->{'s_res'}, $heap->{'ev_res'}, {'error' => 0, 'error_type' => '', 'content' => \$dc});
        $_[KERNEL]->alarm_remove(delete $heap->{'al_cest_id'})
            if (exists $heap->{'al_cest_id'} and $heap->{'al_cest_id'});
        $_[KERNEL]->yield('shutdown');
    },

    );
    print "tcp_sid: $tcp_sid\n"
        if $main::DEBUG;

},
},
    'args' => [$self],
)->ID;

    return $session_id;
}

1;

package main;

my $ub = Ub->new()->spawn();




    my $session_id_test =  POE::Session->create(
        inline_states => {
_start => sub {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    ($heap->{'self'})   = @_[ARG0..$#_];
    print 'INFO: ' . __PACKAGE__ . "_start\n"
        if $main::DEBUG;
    $kernel->yield('test');
},
_stop => sub {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    print 'INFO: ' . __PACKAGE__ . "_stop\n"
        if $main::DEBUG;
    $heap = {};
},
on_shutdown => sub {
    print 'INFO: ' . __PACKAGE__ . "on_shutdown\n"
        if $main::DEBUG;
},
_shutdown => sub {
    print 'INFO: ' . __PACKAGE__ . "_shutdown\n"
        if $main::DEBUG;
},
test => sub {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    my ($cont, $host, $port, $do_ssl);

    $kernel->refcount_increment($_[SESSION]->ID, 'test');

    if (1) {
        $host = '0ne.us';
        $port = 443;
        $do_ssl = 1;

        $cont = <<'EOF';
GET /get.php HTTP/1.1
Host: osadmin.com
User-Agent: proba 123
Connection: close


EOF

    }
    $kernel->post('ub', 'r', 'test_res', \$cont, $host, $port, $do_ssl);

},
test_res => sub {
    my ($kernel, $heap, $dat) = @_[KERNEL, HEAP, ARG0..$#_];
    $kernel->refcount_decrement($_[SESSION]->ID, 'test');
    my $cont = ${$dat->{'content'}};
    chomp $cont;
    warn $cont;
die "HIT BUG" if length $cont == 0;
    $kernel->yield('test');
    return;
},
},)->ID;

POE::Kernel->run();
done_testing;
