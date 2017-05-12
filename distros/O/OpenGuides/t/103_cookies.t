use strict;
use OpenGuides::Config;
use OpenGuides::CGI;
use Time::Piece;
use Time::Seconds;
use Test::More tests => 30;

eval { OpenGuides::CGI->make_prefs_cookie; };
ok( $@, "->make_prefs_cookie dies if no config object supplied" );

eval { OpenGuides::CGI->make_prefs_cookie( config => "foo" ); };
ok( $@, "...or if config isn't an OpenGuides::Config" );

my $config = OpenGuides::Config->new( vars => { site_name => "Test Site" } );

eval { OpenGuides::CGI->make_prefs_cookie( config => $config ); };
is( $@, "", "...but not if it is" );

# Use nonsense values here to make sure the test is a good one regardless
# of defaults - can't do this for cookie_expires, unfortunately.
my $cookie = OpenGuides::CGI->make_prefs_cookie(
    config                     => $config,
    username                   => "un_pref",
    include_geocache_link      => "gc_pref",
    preview_above_edit_box     => "pv_pref",
    latlong_traditional        => "ll_pref",
    omit_help_links            => "hl_pref",
    show_minor_edits_in_rc     => "me_pref",
    default_edit_type          => "et_pref",
    cookie_expires             => "never",
    track_recent_changes_views => "rc_pref",
    display_google_maps        => "gm_pref",
    is_admin                   => "admin_pref",
);
isa_ok( $cookie, "CGI::Cookie", "->make_prefs_cookie returns a cookie" );

my $expiry_string = $cookie->expires;
# Hack off the timezone bit since strptime can't parse it portably.
# Timezones taken from RFC 822.
$expiry_string =~ s/ (UT|GMT|EST|EDT|CST|CDT|MST|MDT|PST|PDT|1[A-IK-Z]|\+\d\d\d\d|-\d\d\d\d)$//;
print "# (String hacked to $expiry_string)\n";
my $expiry = Time::Piece->strptime( $expiry_string, "%a, %d-%b-%Y %T");
print "# Expires: " . $cookie->expires . ", ie $expiry\n";
my $now = localtime;
print "# cookie should still be valid in a year, ie " . ($now + ONE_YEAR) . "\n";
ok( $expiry - ( $now + ONE_YEAR ) > 0, "cookie expiry date correct" );

$ENV{HTTP_COOKIE} = $cookie;

eval { OpenGuides::CGI->get_prefs_from_cookie; };
ok( $@, "->get_prefs_from_cookie dies if no config object supplied" );

eval { OpenGuides::CGI->get_prefs_from_cookie( config => "foo" ); };
ok( $@, "...or if config isn't an OpenGuides::Config" );

eval { OpenGuides::CGI->get_prefs_from_cookie( config => $config ); };
is( $@, "", "...but not if it is" );

my %prefs = OpenGuides::CGI->get_prefs_from_cookie( config => $config );
is( $prefs{username}, "un_pref", "get_prefs_from_cookie can find username" );
is( $prefs{include_geocache_link}, "gc_pref", "...and geocache prefs" );
is( $prefs{preview_above_edit_box}, "pv_pref", "...and preview prefs" );
is( $prefs{latlong_traditional}, "ll_pref", "...and latlong prefs" );
is( $prefs{omit_help_links}, "hl_pref", "...and help link prefs" );
is( $prefs{show_minor_edits_in_rc}, "me_pref", "...and minor edits prefs" );
is( $prefs{default_edit_type}, "et_pref", "...and default edit prefs" );
is( $prefs{cookie_expires}, "never", "...and requested cookie expiry" );
is( $prefs{track_recent_changes_views}, "rc_pref",
                                     "...and recent changes tracking" );
is( $prefs{display_google_maps}, "gm_pref",
                                     "...and map display preference" );
is( $prefs{is_admin}, "admin_pref",
                                     "...and admin preference" );
# Now make sure that true/false preferences are taken account of when
# they're false.
$cookie = OpenGuides::CGI->make_prefs_cookie(
    config                     => $config,
    include_geocache_link      => 0,
    preview_above_edit_box     => 0,
    latlong_traditional        => 0,
    omit_help_links            => 0,
    show_minor_edits_in_rc     => 0,
    track_recent_changes_views => 0,
    display_google_maps        => 0,
    is_admin                   => 0,
);

$ENV{HTTP_COOKIE} = $cookie;

%prefs = OpenGuides::CGI->get_prefs_from_cookie( config => $config );
ok( !$prefs{include_geocache_link}, "geocache prefs taken note of when false");
ok( !$prefs{preview_above_edit_box}, "...and preview prefs" );
ok( !$prefs{latlong_traditional}, "...and latlong prefs" );
ok( !$prefs{omit_help_links}, "...and help link prefs" );
ok( !$prefs{show_minor_edits_in_rc}, "...and minor edits prefs" );
ok( !$prefs{track_recent_changes_views}, "...and recent changes prefs" );
ok( !$prefs{display_google_maps}, "...and Google Maps prefs" );
ok( !$prefs{is_admin}, "...and admin prefs" );

# Check that cookie parsing fails nicely if no cookie set.
delete $ENV{HTTP_COOKIE};
%prefs = eval { OpenGuides::CGI->get_prefs_from_cookie( config => $config ); };
is( $@, "", "->get_prefs_from_cookie doesn't die if no cookie set" );
is( keys %prefs, 11, "...and returns ten default values" );

# Check that the prefs cookie is still looked for even if we send along a
# non-prefs cookie.
my $rc_cookie = OpenGuides::CGI->make_recent_changes_cookie(
                    config => $config );
my $prefs_cookie = OpenGuides::CGI->make_prefs_cookie(
                    config => $config, is_admin => 1 );
$ENV{HTTP_COOKIE} = $prefs_cookie;
%prefs = OpenGuides::CGI->get_prefs_from_cookie( config => $config,
                                                 cookies => [ $rc_cookie ] );
ok( $prefs{is_admin},
    "->get_prefs_from_cookie still works with ENV if we send RC cookie" );
