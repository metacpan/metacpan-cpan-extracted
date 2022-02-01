######################################################################
# Test suite for OAuth::Cmdline
# by Ian Gibbs
######################################################################
use warnings;
use strict;
use Test::More;
use JSON qw( from_json );
use OAuth::Cmdline::MicrosoftOnline;

BEGIN {
    if(exists $ENV{"LIVE_TESTS"}) {
        plan tests => 2;
    } else {
        plan skip_all => "- only with LIVE_TESTS";
    }
}

my $msonline = OAuth::Cmdline::MicrosoftOnline->new( resource => "https://graph.microsoft.com" );

if( ! -f $msonline->cache_file_path ) {
    die "You need a fully initialized ", 
        $msonline->cache_file_path, " for testing.";
}

my $ua = LWP::UserAgent->new();
$ua->default_header(
    $msonline->authorization_headers );

my $resp = $ua->get( "https://graph.microsoft.com/v1.0/users?\$top=1" );

if( $resp->is_error ) {
    die "Fetching user list failed: ", $resp->message();
}

ok 1, "Fetching user list";

my $data = from_json( $resp->content() );

is ref $data->{ value }, "ARRAY", "got an array of items";
