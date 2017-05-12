use strict;
use warnings;
use Test::More qw( no_plan );

# synchronizes the {error,standard} output of this test.
use IO::Handle;
STDOUT->autoflush(1);
STDERR->autoflush(1);

our $class;
BEGIN { $class = 'Net::Whois::RIPE'; use_ok $class; }

can_ok $class,

  # Read-Only Accessors
  qw( ios socket ),

  # Read-Write Accessors
  qw( hostname port timeout keepalive referral recursive grouping ),

  # Connection Methods
  qw( connect disconnect reconnect is_connected ),

  # Query Methods
  qw( query object_types send ),

  # OO Support
  qw( DESTROY );

{
    my $c = Net::Whois::RIPE->new( disconnected => 1, unfiltered => 1 );
    isa_ok $c, $class;

    # hostname()
    ok $c->hostname eq 'whois.ripe.net', q{default hostname used as expected.};
    $c->hostname('nowhere.net');
    ok $c->hostname eq 'nowhere.net', q{setting the hostname works.};

    # port()
    ok $c->port == 43, q{default port used as expected.};
    $c->port('invalid');
    ok $c->port == 43, q{ignoring invalid values when setting 'port'.};
    $c->port(4343);
    ok $c->port == 4343, q{valid ports are accepted.};

    # timeout()
    ok $c->timeout == 5, q{default timeout used as expected.};
    $c->timeout('invalid');
    ok $c->timeout == 5, q{ignoring invalid values when setting 'timeout'.};
    $c->timeout(1);
    ok $c->timeout == 1, q{valid timeouts are accepted.};

    # keepalive()
    ok !$c->keepalive, q{keepalive is 'off' by default.};
    $c->keepalive('yes');
    ok $c->keepalive, q{true values are interpreted as true for keepalive.};
    $c->keepalive(0);
    ok !$c->keepalive, q{and 0 is probably the only way to turn it off.};

    # referral()
    ok !$c->referral, q{referral is 'off' by default.};
    $c->referral('yes');
    ok $c->referral, q{true values are interpreted as true for referral.};
    $c->referral(0);
    ok !$c->referral, q{and 0 is probably the only way to turn it off.};

    # recursive()
    ok !$c->recursive, q{recursive is 'off' by default.};
    $c->recursive('yes');
    ok $c->recursive, q{true values are interpreted as true for recursive.};
    $c->recursive(0);
    ok !$c->recursive, q{and 0 is probably the only way to turn it off.};

    # grouping()
    ok $c->grouping, q{grouping is 'on' by default.};
    $c->grouping(0);
    ok !$c->grouping, q{and 0 is probably the only way to turn it off.};
    $c->grouping('yes');
    ok $c->grouping, q{true values are interpreted as true for grouping.};

    ok $c->unfiltered, '->new can set the unfiltered flag';
}

    my $c = $class->new( disconnected => 1 );

    # connect()
    # TODO: implement a test that doesn't requires internet connection
    eval { $c->connect };

SKIP: {
    skip "Network issue",14 if ( $@ =~ /IO::Socket::INET/ );

    ok (!$@, "The client connected without dying. $@");

    # is_connected()
    ok $c->is_connected, 'The client is connected.';

    # reconnect()
    eval {$c->reconnect };
    ok !$@,'The client re-connected without dying.';
    ok $c->is_connected, 'The client is connected (once more).';

    # ios()
    isa_ok $c->ios, 'IO::Select';
    ok $c->ios->count >= 1,
      q{There's at least one handle registered with the IO::Select object.};

    # socket()
    isa_ok $c->socket, 'IO::Socket';

    # query()
    {
        my $iter;
        eval { $iter = $c->query('LMC-RIPE') };
        ok !$@, q{Client performs queries without dying};
        isa_ok $iter, 'Iterator';
        last unless $iter;
        ok $iter->isnt_exhausted, q{Iterator contains at least one result};
    }

    # object_types()
    {
        my @types;
        eval { @types = $c->object_types };
        ok !$@ , q{Client can retrieve available object types without dying.};
        is $#types, 20,
          q{There are 21 known object types in the RIPE Database};
    }

    # send()

    # disconnect()
    eval { $c->disconnect };
    ok !$@ , 'The client disconnected without dying.';
    ok !$c->is_connected, 'The client is not connected (anymore).';

    # DESTROY()
}
