#!perl -T

use Test::More tests => 21;

BEGIN {
	use_ok( 'Net::Spotify::Search' );
}

# constructor
my $search = Net::Spotify::Search->new();

isa_ok($search, 'Net::Spotify::Search');

# methods
my @methods = qw(
    base_url format format_request make_request ua version
);
can_ok($search, @methods);

# base_url
is($search->base_url(), $search->{base_url});
is($search->base_url(), 'http://ws.spotify.com');

# format
is($search->format(), $search->{format});
is($search->format(), 'xml');

# version
is($search->version(), $search->{version});
is($search->version(), '1');

# ua
my $ua = $search->ua();
isa_ok($ua, 'LWP::UserAgent');

require_ok('Net::Spotify');
is($ua->agent(), 'Net::Spotify/' . Net::Spotify->VERSION);

# format_request
my @test_cases = (
    [
        ['artist', q => 'Björk'],
        'http://ws.spotify.com/search/1/artist.xml?q=Bj%C3%B6rk'
    ],
    [
        ['track', q => 'june tune', page => 1],
        'http://ws.spotify.com/search/1/track.xml?q=june+tune&page=1'
    ],
    [
        ['album', q => 'best', page => 17],
        'http://ws.spotify.com/search/1/album.xml?q=best&page=17'
    ],
);

foreach my $test (@test_cases) {
    my ($parameters, $expected_uri) = @$test;

    my $request = $search->format_request(@{$parameters});

    isa_ok($request, 'HTTP::Request');

    is($request->method(), 'GET');
    is($request->uri(), $expected_uri);
}
