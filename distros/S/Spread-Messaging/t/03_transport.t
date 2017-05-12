use Test::More;

BEGIN {

    if (!$ENV{TEST_SPREAD}) {

        plan skip_all => "Enable TEST_SPREAD environment variable to test Spread connectivity. This assumes a Spread server at port 4803 on localhost";
        exit;

    } else {

        plan tests => 18;
        use_ok('Spread::Messaging::Transport');
    
    }
       
}

my $spread = Spread::Messaging::Transport->new();
ok( defined $spread );
ok( $spread->isa('Spread::Messaging::Transport') );

#
# Check basic connection
#

is( $spread->port, "4803", "port" );
is( $spread->host, "localhost", "localhost" );
is( $spread->timeout, "5", "timeout" );
is( $spread->service_type, SAFE_MESS, "service_type" );

#
# Check communications
#

eval { $spread->join_group("test1") }; if ($@) { ok(0, "join_group()") } else { ok(1) };
eval { $spread->send("test1", "testing", 0) }; if ($@) { ok(0, "send()") } else { ok(1) };
#eval { $spread->poll() }; if ($@) { ok(0,  "poll()" ) } else { ok(1) };
ok( $spread->recv(), "recv()" );
eval { $spread->leave_group("test1") }; if ($@) { ok(0, "leave_group()") } else { ok(1) };

#
# Disconnect and reconnect
#

eval { $spread->disconnect() }; if ($@) { ok(0, "disconnect()") } else { ok(1) };
eval { $spread->connect() }; if ($@) { ok(0, "connect()") } else { ok(1) };

#
# Check communications again
#

eval { $spread->join_group("test1") }; if ($@) { ok(0, "join_group()") } else { ok(1) };
eval { $spread->send("test1", "testing", 0) }; if ($@) { ok(0, "send()") } else { ok(1) };
ok( $spread->poll(), "poll()" );
ok( $spread->recv(), "recv()" );
eval { $spread->leave_group("test1") }; if ($@) { ok(0, "leave_group()") } else { ok(1) };

