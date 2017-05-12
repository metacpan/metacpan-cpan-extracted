use Test::More;

BEGIN {

    if (!$ENV{TEST_SPREAD}) {

       plan skip_all => "Enable TEST_SPREAD environment variable to test Spread connectivity. This assumes a Spread server at port 4803 on localhost";
       exit;
       
    } else {

       plan tests => 17;
       use_ok('Spread::Messaging::Content');
    }
    
}

my $spread = Spread::Messaging::Content->new();
ok( defined $spread );
ok( $spread->isa('Spread::Messaging::Content') );

#
# Check basic connection.
#

is( $spread->port, "4803", "port" );
is( $spread->host, "localhost", "localhost" );
is( $spread->timeout, "5", "timeout" );
is( $spread->service_type, SAFE_MESS, "service_type" );

#
# Check communications
#

eval { $spread->join_group("test1") }; if ($@) { ok(0, "join_group()") } else { ok(1) };
eval { $spread->group("test1") }; if ($@) { ok(0, "group()") } else { ok(1) };
eval { $spread->type("0") }; if ($@) { ok(0, "type()") } else { ok(1) };
eval { $spread->message("testing"); }; if ($@) { ok(0, "message()") } else { ok(1) };
eval { $spread->send() }; if ($@) { ok(0, "send()") } else { ok(1) };
ok ( $spread->poll() );
eval { $spread->recv() }; if ($@) { ok(0, "recv()") } else { ok(1) };
ok ( printf("%s\n", $spread->message) );

#
# Disconnect and reconnect
#

eval { $spread->disconnect() }; if ($@) { ok(0, "disconnect()") } else { ok(1) };
eval { $spread->connect() }; if ($@) { ok(0, "connect()") } else { ok(1) };

