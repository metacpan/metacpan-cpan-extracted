#! perl -w -I.
use t::Test::abeltje;
use Test::MockObject;

{
    package TestClass;
    use Moo;
    with 'MooX::Role::HTTP::Tiny';

    sub call {
        my $self = shift;
        return \@_;
    }
    1;
}

{
    my $client = TestClass->new(base_uri => 'http://localhost/');
    isa_ok($client, 'TestClass');
    isa_ok($client->ua, 'HTTP::Tiny');
    isa_ok($client->base_uri, 'URI::http');
}

{
    # Test::MockObject doesn't seem to work here, so oldskool :'(
    my $cj = bless({}, 'Mock::CookieJar');
    sub Mock::CookieJar::add { return $_[2] }
    sub Mock::CookieJar::cookie_header { return $_[1] }

    my $client = TestClass->new(
        base_uri   => 'http://localhost/',
        ua_options => { cookie_jar => $cj },
    );
    isa_ok($client, 'TestClass');
    isa_ok($client->ua, 'HTTP::Tiny');
    isa_ok($client->ua->cookie_jar, 'Mock::CookieJar');
}

{
    (   my $ua = Test::MockObject->new(
        )
    )->set_isa('HTTP::Tiny');
    my $client = TestClass->new(
        base_uri => 'http://localhost/',
        ua       => $ua,
    );
    isa_ok($client, 'TestClass');

    my @arguments = (GET => '', {param => 'blah'});
    my $response = $client->call(@arguments);
    is_deeply($response, \@arguments, "->call() works");
}

abeltje_done_testing();
