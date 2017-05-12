use Test::More tests => 6;
use Test::Exception;
use Riak::Client;

dies_ok { Riak::Client->new } "should ask for port and host";
dies_ok { Riak::Client->new( host => '127.0.0.1' ) } "should ask for port";
dies_ok { Riak::Client->new( port => 8087 ) } "should ask for host";

subtest "new and default attrs values" => sub {
    my $client = new_ok(
        'Riak::Client' => [
            host            => '127.0.0.1',
            port            => 9087,
 	    no_auto_connect => 1
        ],
        "a new client"
    );
    is( $client->connection_timeout, 5, "default timeout should be 0.5" );
    is( $client->read_timeout, 5, "default timeout should be 0.5" );
    is( $client->write_timeout, 5, "default timeout should be 0.5" );
    is( $client->r,       2,   "default r  should be 2" );
    is( $client->w,       2,   "default w  should be 2" );
    is( $client->dw,      1,   "default dw should be 1" );
};

subtest "new and other attrs values" => sub {
    my $client = new_ok(
        'Riak::Client' => [
            host               => '127.0.0.1',
            port               => 9087,
            connection_timeout => 0.2,
            r                  => 1,
            w                  => 1,
            dw                 => 1,
            no_auto_connect    => 1
        ],
        "a new client"
    );
    is( $client->connection_timeout, 0.2, "timeout should be 0.2" );
    is( $client->r,       1,   "r  should be 1" );
    is( $client->w,       1,   "w  should be 1" );
    is( $client->dw,      1,   "dw should be 1" );
};

subtest "should be a riak::light instance" => sub {
    isa_ok(
        Riak::Client->new( host => 'host', port => 9999, no_auto_connect => 1),
        'Riak::Client'
    );
  }
