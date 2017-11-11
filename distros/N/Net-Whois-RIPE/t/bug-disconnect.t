use strict;
use warnings;
use Test::More qw( no_plan );

# synchronizes the {error,standard} output of this test.
# use IO::Handle;
# STDOUT->autoflush(1);
# STDERR->autoflush(1);

our $class;
BEGIN { $class = 'Net::Whois::Generic'; use_ok $class; }

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

    # socket()
    isa_ok $c->socket, 'IO::Socket';

    # query() RIPE
    {
        my $as_set;
        eval { ($as_set) = $c->query('AS-JAGUAR', {type => 'AsSet'}) };
        ok !$@, q{Client performs queries without dying $@};
        ok($as_set, "Net::Whois::Object::AsSet returned for 'AS-JAGUAR' query");
        isa_ok $as_set, 'Net::Whois::Object::AsSet';
    }

    # disconnect()
    eval { $c->disconnect };
    ok !$@ , 'The client disconnected without dying.';
    ok !$c->is_connected, 'The client is not connected (anymore).';

    # DESTROY()
}
