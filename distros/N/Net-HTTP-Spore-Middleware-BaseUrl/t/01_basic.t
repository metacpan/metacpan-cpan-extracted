use Test::More tests => 2;
use Test::MockObject;
use Net::HTTP::Spore;
use Net::HTTP::Spore::Middleware::BaseUrl;

subtest 'basic' => sub {
    plan tests => 1;
    my $base_url = 'http://foo.bar';
    my $middleware =
      Net::HTTP::Spore::Middleware::BaseUrl->new( base_url => $base_url );

    my $request = Test::MockObject->new();

    $request->mock(
        host => sub {
            my ( $self, $host ) = @_;
            is( $host, $base_url, "should call request->host with base_url" );
        }
    );

    $middleware->call($request);
};

subtest 'should be load without problem' => sub {
    my $json = <<EOF;
  {
    "version":"1.0",
    "base_url":"http://www.cpan.org"
  }
EOF

    my $client = Net::HTTP::Spore->new_from_string($json);
    eval { $client->enable( 'BaseUrl', base_url => "metacpan.org" ); };
    ok( !$@, "should be elabled without problems" );
};
