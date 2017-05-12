use strict;
use warnings;
use Test::More qw( no_plan );

# synchronizes the {error,standard} output of this test.
# use IO::Handle;
# STDOUT->autoflush(1);
# STDERR->autoflush(1);

our $class;
BEGIN { $class = 'Net::Whois::Generic'; use_ok $class; }

can_ok $class,

  # Read-Only Accessors
  qw( ios socket ),

  # Read-Write Accessors
  qw( hostname port timeout referral recursive grouping ),

  # Connection Methods
  qw( connect disconnect reconnect is_connected ),

  # Query Methods
  qw( query object_types send ),

  # OO Support
  qw( DESTROY );

{
    my $c = Net::Whois::Generic->new( disconnected => 1, unfiltered => 1 );
    isa_ok $c, $class;

}

    my $c = $class->new( disconnected => 1 );

    # connect()
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
    # Test here
    #diag('count='.$c->ios->count); 

    # socket()
    isa_ok $c->socket, 'IO::Socket';

    # query() RIPE
    {
        my $as_set;
        eval { ($as_set) = $c->query('AS-JAGUAR', {type => 'AsSet'}) };
        ok !$@, q{Client performs queries without dying $@};
        isa_ok $as_set, 'Net::Whois::Object::AsSet';
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

my @objects;

eval { @objects = Net::Whois::Generic->query('AS30781', {attribute => 'remarks'}) };

SKIP: {
    skip "Network issue",14 if ( $@ =~ /IO::Socket::INET/ );

    for my $object (@objects) {
        ok(!ref($object), "query() : String returned for 'remarks' attribute filter")
    }
}

eval {    @objects = Net::Whois::Generic->query('AS30781') };

SKIP: {
    skip "Network issue",14 if ( $@ =~ /IO::Socket::INET/ );
    for my $object (@objects) {
        ok(ref($object) =~ /Net::Whois::Object/ , "query() : Object ".ref($object)." returned for 'remarks' attribute filter")
    }

}

eval {    @objects = Net::Whois::Generic->query('AS30781', {type => 'asblock', attribute => 'admin_c' })} ;

SKIP: {
    skip "Network issue",14 if ( $@ =~ /IO::Socket::INET/ );
    for my $object (@objects) {
        ok($object eq 'CREW-RIPE' , "query() : 'CREW-RIPE' returned for AsBlock and admin-c filter");
        diag($object);
    }
}
