use strict;
use Cwd;
use OpenGuides;
use OpenGuides::CGI;
use OpenGuides::Test;
use Test::More;

eval { require DBD::SQLite; };
if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all =>
        "DBD::SQLite could not be used - no database to test with. ($error)";
}

plan tests => 10;

# Clear out the database from any previous runs.
OpenGuides::Test::refresh_db();

my $config = OpenGuides::Test->make_basic_config;
my $guide = OpenGuides->new( config => $config );
my $wiki = $guide->wiki;

# First we need to make sure that the preferences are accessible
# from the recent changes view.  Can't test this using return_tt_vars
# because the prefs TT var is set in OpenGuides::Template->output(),
# and if return_tt_vars is set then execution never gets that far.
# So write a custom navbar template that just prints the variable we're
# interested in.

$config->custom_template_path( cwd . "/t/templates/" );
eval {
    unlink cwd . "/t/templates/navbar.tt";
};
open( FILE, ">", cwd . "/t/templates/navbar.tt" )
  or die $!;
print FILE <<EOF;
PREFS_IS_ADMIN: [% prefs.is_admin %]
EOF
close FILE or die $!;

$ENV{HTTP_COOKIE} = make_cookie( is_admin => 1 );
my $output = $guide->display_recent_changes( return_output => 1 );
like( $output, qr/PREFS_IS_ADMIN:\s+1/,
      "prefs available as TT var on recent changes" );

# Make sure this still works when they have a recent changes tracking cookie.
$ENV{HTTP_COOKIE} = make_cookie( is_admin => 1, track_rc => 1 );
$output = $guide->display_recent_changes( return_output => 1 );
like( $output, qr/PREFS_IS_ADMIN:\s+1/,
      "...even when there's a recent changes tracking cookie set" );

# Clean up.
unlink cwd . "/t/templates/navbar.tt";

# Write a node from an IPv6 address.  We can't use OG::Test->write_data()
# for this, because it calls make_cgi_object(), which overwrites REMOTE_ADDR.
my $q = OpenGuides::Test->make_cgi_object();
$ENV{REMOTE_ADDR} = "2001:db8:ca94:869f:226:8ff:fef9:453d";
$guide->commit_node( id => "Red Lion", cgi_obj => $q, return_output => 1 );

# View recent changes with admin links switched off.
$ENV{HTTP_COOKIE} = make_cookie();
$output = $guide->display_recent_changes( return_output => 1 );
unlike( $output, qr/2001/,
       "Recent changes omits IP address when admin links switched off" );
$ENV{HTTP_COOKIE} = make_cookie( track_rc => 1 );
$output = $guide->display_recent_changes( return_output => 1 );
unlike( $output, qr/2001/,
       "...also with recent changes tracking on" );

# And with them switched on.
$ENV{HTTP_COOKIE} = make_cookie( is_admin => 1 );
$output = $guide->display_recent_changes( return_output => 1 );
like( $output, qr/">2001/,
      "Recent changes shows IP address when admin links switched on" );
unlike( $output, qr/">2001:db8:ca94:869f:226:8ff:fef9:453d/,
        "...but not the full thing, if it's too long" );
$ENV{HTTP_COOKIE} = make_cookie( is_admin => 1, track_rc => 1 );
$output = $guide->display_recent_changes( return_output => 1 );
like( $output, qr/">2001/,
      "IP address also shown when admin links and rc tracking both on" );
unlike( $output, qr/">2001:db8:ca94:869f:226:8ff:fef9:453d/,
        "...and again, full thing not shown if it's too long" );

# Now try it from an IPv4 address, which should fit.
$q = OpenGuides::Test->make_cgi_object();
$ENV{REMOTE_ADDR} = "198.51.100.255";
$guide->commit_node( id => "Yellow Lion", cgi_obj => $q, return_output => 1 );
$ENV{HTTP_COOKIE} = make_cookie( is_admin => 1 );
$output = $guide->display_recent_changes( return_output => 1 );
like( $output, qr/">198.51.100.255/, "Full IP address shown if short enough" );
$ENV{HTTP_COOKIE} = make_cookie( is_admin => 1, track_rc => 1 );
$output = $guide->display_recent_changes( return_output => 1 );
like( $output, qr/">198.51.100.255/,
      "...also if recent changes tracking is on" );

sub make_cookie {
    my %args = @_;

    my $prefs_cookie = OpenGuides::CGI->make_prefs_cookie(
        config => $config,
        username => "Kake",
        is_admin => $args{is_admin} || 0,
        track_recent_changes_views => $args{track_rc} || 0,
    );

    if ( $args{track_rc} ) {
        my $rc_cookie = OpenGuides::CGI->make_recent_changes_cookie(
                                                    config => $config,
                                                  );
        my @prefs_bits = split( qr/\s*;\s*/, $prefs_cookie );
        my @rc_bits = split( qr/\s*;\s*/, $rc_cookie );
        return $prefs_bits[0] . "; " . $rc_bits[0];
    }

    return $prefs_cookie;
}
