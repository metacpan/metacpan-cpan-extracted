######################################################################
# Test suite for OAuth::Cmdline
# by Mike Schilli <cpan@perlmeister.com>
######################################################################
use warnings;
use strict;
use Test::More;
use JSON qw( from_json );
use OAuth::Cmdline::Spotify;

BEGIN {
    if(exists $ENV{"LIVE_TESTS"}) {
        plan tests => 2;
    } else {
        plan skip_all => "- only with LIVE_TESTS";
    }
}

my $spotify = OAuth::Cmdline::Spotify->new( );

if( ! -f $spotify->cache_file_path ) {
    die "You need a fully initialized ", 
        $spotify->cache_file_path, " for testing.";
}

my $user = $spotify->cache_read->{ user };

if( !defined $user ) {
    die "Please add a 'user:' field with your user name to your ", 
        $spotify->cache_file_path, " for testing.";
}

my $ua = LWP::UserAgent->new();
$ua->default_header(
    $spotify->authorization_headers );

my $resp = $ua->get(
    "https://api.spotify.com/v1" .
    "/users/$user/playlists" );

if( $resp->is_error ) {
    die "Fetching user playlists failed: ", $resp->message();
}

ok 1, "Fetching user playlists";

my $data = from_json( $resp->content() );

is ref $data->{ items }, "ARRAY", "got an array of items";
