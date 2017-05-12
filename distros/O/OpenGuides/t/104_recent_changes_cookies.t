use strict;
use Wiki::Toolkit::Setup::SQLite;
use OpenGuides::Config;
use OpenGuides;
use OpenGuides::CGI;
use OpenGuides::Test;
use Time::Piece;
use Time::Seconds;
use Test::More tests => 11;

eval { OpenGuides::CGI->make_recent_changes_cookie; };
ok( $@, "->make_recent_changes_cookie dies if no config object supplied" );

eval { OpenGuides::CGI->make_recent_changes_cookie( config => "foo" ); };
ok( $@, "...or if config isn't an OpenGuides::Config" );

my $config = OpenGuides::Config->new( vars => { site_name => "Test Site" } );

eval { OpenGuides::CGI->make_recent_changes_cookie( config => $config ); };
is( $@, "", "...but not if it is" );

my $cookie = OpenGuides::CGI->make_recent_changes_cookie( config => $config );
isa_ok( $cookie, "CGI::Cookie",
        "->make_recent_changes_cookie returns a cookie" );

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

eval { OpenGuides::CGI->get_last_recent_changes_visit_from_cookie; };
ok( $@, "->get_last_recent_changes_visit_from_cookie dies if no config object supplied" );

eval { OpenGuides::CGI->get_last_recent_changes_visit_from_cookie( config => "foo" ); };
ok( $@, "...or if config isn't an OpenGuides::Config" );

eval { OpenGuides::CGI->get_last_recent_changes_visit_from_cookie( config => $config ); };
is( $@, "", "...but not if it is" );

# Check that cookie parsing fails nicely if no cookie set.
delete $ENV{HTTP_COOKIE};
eval { OpenGuides::CGI->get_last_recent_changes_visit_from_cookie( config => $config ); };
is( $@, "", "->get_last_recent_changes_visit_from_cookie doesn't die if no cookie set" );

# Now test that the prefs option is taken note of.
my $have_sqlite = 1;
my $sqlite_error;

eval { require DBD::SQLite; };
if ( $@ ) {
    ($sqlite_error) = $@ =~ /^(.*?)\n/;
    $have_sqlite = 0;
}

SKIP: {
    skip "DBD::SQLite could not be used - no database to test with. ($sqlite_error)", 2
      unless $have_sqlite;
    OpenGuides::Test::refresh_db();


    my $config = OpenGuides::Config->new(
           vars => {
                     dbtype             => "sqlite",
                     dbname             => "t/node.db",
                     indexing_directory => "t/indexes",
                     script_name        => "wiki.cgi",
                     script_url         => "http://example.com/",
                     site_name          => "Test Site",
                     template_path      => "./templates",
                     home_name          => "Home",
                   }
    );
    eval { require Wiki::Toolkit::Search::Plucene; };
    if ( $@ ) { $config->use_plucene ( 0 ) };

    my $guide = OpenGuides->new( config => $config );

    my $prefs_cookie = OpenGuides::CGI->make_prefs_cookie(
        config => $config,
        track_recent_changes_views => 1,
    );
    my $rc_cookie = OpenGuides::CGI->make_recent_changes_cookie(
        config => $config
    );
    $ENV{HTTP_COOKIE} = $prefs_cookie . "; " . $rc_cookie;
    my $output = $guide->display_node(
                                       id            => "RecentChanges",
                                       return_output => 1,
                                     );
    like( $output, qr/Set-Cookie:/, "recent changes cookie set when asked" );

    $prefs_cookie = OpenGuides::CGI->make_prefs_cookie(
        config => $config,
        track_recent_changes_views => 0,
    );
    $ENV{HTTP_COOKIE} = $prefs_cookie . "; " . $rc_cookie;
    $output = $guide->display_node(
                                    id            => "RecentChanges",
                                    return_output => 1,
                                  );
    unlike( $output, qr/Set-Cookie:/, "...and not when not" );
}
