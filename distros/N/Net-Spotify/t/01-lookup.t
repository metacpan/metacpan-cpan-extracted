#!perl -T

use Test::More tests => 21;

BEGIN {
	use_ok( 'Net::Spotify::Lookup' );
}

# constructor
my $lookup = Net::Spotify::Lookup->new();

isa_ok($lookup, 'Net::Spotify::Lookup');

# methods
my @methods = qw(
    base_url format format_request make_request ua version
);

can_ok($lookup, @methods);

# base_url
is($lookup->base_url(), $lookup->{base_url});#, 'base_url() returns the stored value');
is($lookup->base_url(), 'http://ws.spotify.com');

# format
is($lookup->format(), $lookup->{format});
is($lookup->format(), 'xml');

# version
is($lookup->version(), $lookup->{version});
is($lookup->version(), '1');

# ua
my $ua = $lookup->ua();
isa_ok($ua, 'LWP::UserAgent');

require_ok('Net::Spotify');
is($ua->agent(), 'Net::Spotify/' . Net::Spotify->VERSION);

# format_request
my @test_cases = (
    [
        {uri => 'spotify:track:1234567890'},
        'http://ws.spotify.com/lookup/1/?uri=spotify%3Atrack%3A1234567890'
    ],
    [
        {uri => 'spotify:artist:abcdefghi', extras => 'albumdetail'},
        'http://ws.spotify.com/lookup/1/?uri=spotify%3Aartist%3Aabcdefghi&extras=albumdetail'
    ],
    [
        {uri => 'spotify:album:a1b2c3d4e5', extras => 'trackdetail'},
        'http://ws.spotify.com/lookup/1/?uri=spotify%3Aalbum%3Aa1b2c3d4e5&extras=trackdetail'
    ],
);

foreach my $test (@test_cases) {
    my ($parameters, $expected_uri) = @$test;

    my $request = $lookup->format_request(%$parameters);

    isa_ok($request, 'HTTP::Request');

    is($request->method(), 'GET');
    is($request->uri(), $expected_uri);
}
