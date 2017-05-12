use strict;
use JSON;
use OpenGuides;
use OpenGuides::JSON;
use OpenGuides::Test;
use Test::More;

eval { require DBD::SQLite; };
if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all => "DBD::SQLite could not be used - no database to test with ($error)";
}

eval { require Test::HTML::Content; };
if ( $@ ) {
    plan skip_all => "Test::HTML::Content not installed";
    exit 0;
}

plan tests => 21;

OpenGuides::Test::refresh_db();

my $config = OpenGuides::Test->make_basic_config;
my $guide = OpenGuides->new( config => $config );
my $wiki = $guide->wiki;

# Make sure "return_to" TT var is set iff referrer domain is correct.
$config->script_url( "http://example.com/" );
$config->script_name( "wiki.cgi" );
my $good_return_to = "http://example.com/wiki.cgi?Test_Page";
my $evil_return_to = "http://example.org/naughty-script";

$ENV{HTTP_REFERER} = $good_return_to;
my %tt_vars = $guide->display_prefs_form( return_tt_vars => 1 );
is( $tt_vars{return_to_url}, $good_return_to,
    "Return URL set when referrer matches script URL/name" );
my $output = $guide->display_prefs_form( return_output => 1, noheaders => 1 );
Test::HTML::Content::tag_ok( $output,
  "input", { type => "hidden", name => "return_to_url" },
    "...corresponding hidden input is there in the form" );
Test::HTML::Content::tag_ok( $output,
  "input", { type => "hidden", name => "return_to_url",
             value => $good_return_to },
    "...with correct value" );

$ENV{HTTP_REFERER} = $evil_return_to;
%tt_vars = $guide->display_prefs_form( return_tt_vars => 1 );
ok( !$tt_vars{return_to_url},
    "Return URL not set when referrer doesn't match script URL/name" );
$output = $guide->display_prefs_form( return_output => 1, noheaders => 1 );
Test::HTML::Content::no_tag( $output,
  "input", { type => "hidden", name => "return_to_url" },
    "...and no corresponding hidden input in form" );

# If we have a google API key and node maps are enabled, we should see the
# checkbox for this pref.
$config->gmaps_api_key( "This is not a real API key." );
$config->show_gmap_in_node_display( 1 );

my $cookie = OpenGuides::CGI->make_prefs_cookie(
                                                 config => $config,
                                                 display_google_maps => 1,
                                               );
$ENV{HTTP_COOKIE} = $cookie;
$output = $guide->display_prefs_form( return_output => 1, noheaders => 1 );
Test::HTML::Content::tag_ok( $output,
  "input", { type => "checkbox", name => "display_google_maps" },
  "Node map preference checkbox shown when we have a GMaps API key." );

# But not if the node map is globally disabled
$config->show_gmap_in_node_display( 0 );
$output = $guide->display_prefs_form( return_output => 1, noheaders => 1 );
Test::HTML::Content::no_tag( $output,
  "input", { type => "checkbox", name => "display_google_maps" },
  "...but not when node maps are globally disabled." );

# Now test with Leaflet enabled and no Google API key.
$config->gmaps_api_key( "" );
$config->show_gmap_in_node_display( 1 );
$config->use_leaflet( 1 );

$cookie = OpenGuides::CGI->make_prefs_cookie(
                                              config => $config,
                                              display_google_maps => 1,
                                            );
$ENV{HTTP_COOKIE} = $cookie;
$output = $guide->display_prefs_form( return_output => 1, noheaders => 1 );
Test::HTML::Content::tag_ok( $output,
  "input", { type => "checkbox", name => "display_google_maps" },
  "Node map preference checkbox shown when we're using Leaflet." );

$config->show_gmap_in_node_display( 0 );
$output = $guide->display_prefs_form( return_output => 1, noheaders => 1 );
Test::HTML::Content::no_tag( $output,
  "input", { type => "checkbox", name => "display_google_maps" },
  "...but not when node maps are globally disabled." );

# Make sure the default is for preferences to never expire.
delete $ENV{HTTP_COOKIE};
$output = $guide->display_prefs_form( return_output => 1, noheaders => 1 );
Test::HTML::Content::tag_ok( $output,
  "option", { value => "never", "selected" => "1" },
  "Default for preferences expiry choice is \"never\"." );

$cookie = OpenGuides::CGI->make_prefs_cookie( config => $config,
                                              cookie_expires => "never" );
$ENV{HTTP_COOKIE} = $cookie;
$output = $guide->display_prefs_form( return_output => 1, noheaders => 1 );
Test::HTML::Content::tag_ok( $output,
  "option", { value => "never", "selected" => "1" },
  "...choice set to \"never\" if already set as such in cookie" );

$cookie = OpenGuides::CGI->make_prefs_cookie( config => $config,
                                              cookie_expires => "year" );
$ENV{HTTP_COOKIE} = $cookie;
$output = $guide->display_prefs_form( return_output => 1, noheaders => 1 );
Test::HTML::Content::tag_ok( $output,
  "option", { value => "year", "selected" => "1" },
  "...choice set to \"year\" if already set as such in cookie" );

$cookie = OpenGuides::CGI->make_prefs_cookie( config => $config,
                                              cookie_expires => "month" );
$ENV{HTTP_COOKIE} = $cookie;
$output = $guide->display_prefs_form( return_output => 1, noheaders => 1 );
Test::HTML::Content::tag_ok( $output,
  "option", { value => "month", "selected" => "1" },
  "...choice set to \"month\" if already set as such in cookie" );

# Test JSON version of prefs page.
my $json_writer = OpenGuides::JSON->new( wiki   => $wiki,
                                         config => $config );
delete $ENV{HTTP_COOKIE};
$output = eval {
    $json_writer->make_prefs_json();
};
ok( !$@, "->make_prefs_json() doesn't die when no cookie set." );
if ( $@ ) { warn "#   Error was: $@"; }
# Need to strip out the Content-Type: header or the decoder gets confused.
$output =~ s/^Content-Type:.*\n//s;
my $parsed = eval {
    local $SIG{__WARN__} = sub { die $_[0]; };
    decode_json( $output );
};
ok( !$@, "...and its output looks like JSON." );
if ( $@ ) { warn "#   Warning was: $@"; }
ok( $parsed->{username}, "...and a username is included in the output" );
#use Data::Dumper; print Dumper $parsed; exit 0;

$ENV{HTTP_COOKIE} = OpenGuides::CGI->make_prefs_cookie( config => $config );
$output = eval {
    $json_writer->make_prefs_json();
};
ok( !$@, "->make_prefs_json() doesn't die when cookie set with all defaults.");
if ( $@ ) { warn "#   Error was: $@"; }
$output =~ s/^Content-Type:.*\n//s;
$parsed = eval {
    local $SIG{__WARN__} = sub { die $_[0]; };
    decode_json( $output );
};
ok( !$@, "...and its output looks like JSON." );
if ( $@ ) { warn "#   Warning was: $@"; }
# We don't get a username set in this case.

$ENV{HTTP_COOKIE} = OpenGuides::CGI->make_prefs_cookie( config => $config,
    username => "Kake" );
$output = eval {
    $json_writer->make_prefs_json();
};
ok( !$@,
    "->make_prefs_json() doesn't die when cookie set with given username.");
if ( $@ ) { warn "#   Error was: $@"; }
$output =~ s/^Content-Type:.*\n//s;
$parsed = eval {
    local $SIG{__WARN__} = sub { die $_[0]; };
    decode_json( $output );
};
ok( !$@, "...and its output looks like JSON." );
if ( $@ ) { warn "#   Warning was: $@"; }
is( $parsed->{username}, "Kake",
    "...and the correct username is included in the output" );
