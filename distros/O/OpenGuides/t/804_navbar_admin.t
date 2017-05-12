use strict;
use OpenGuides;
use OpenGuides::Test;
use Test::More;
use Wiki::Toolkit::Setup::SQLite;
use OpenGuides::Config;
use OpenGuides::CGI;

eval { require DBD::SQLite; };
if ( $@ ) {
    plan skip_all => "DBD::SQLite not installed - no database to test with";
    exit 0;
}

eval { require Test::HTML::Content; };
if ( $@ ) {
    plan skip_all => "Test::HTML::Content not installed";
    exit 0;
}

sub get_recent_changes {
    my ($guide) = @_;

    my $output = $guide->display_recent_changes( return_output => 1 );
    $output =~ s/^Content-Type.*[\r\n]+//m;

    return $output;
}

sub get_preferences {
    my ($guide) = @_;

    return OpenGuides::Template->output(
        wiki         => $guide->wiki,
        config       => $guide->config,
        template     => "preferences.tt",
        noheaders    => 1,
        vars         => {
                          not_editable => 1,
                          show_form    => 1
                        },
    );
}

plan tests => 2;

my ( $config, $guide, $wiki, $output );

# Clear out the database from any previous runs.
OpenGuides::Test::refresh_db();

# Make a guide
$config = OpenGuides::Test->make_basic_config;
$guide = OpenGuides->new( config => $config );

# set is_admin to 1
my $cookie = OpenGuides::CGI->make_prefs_cookie(
    config                     => $config,
    username                   => "bob",
    include_geocache_link      => 1,
    preview_above_edit_box     => 1,
    omit_help_links            => 1,
    show_minor_edits_in_rc     => 1,
    default_edit_type          => "tidying",
    cookie_expires             => "never",
    track_recent_changes_views => 1,
    is_admin => 1,
);
$ENV{HTTP_COOKIE} = $cookie;
OpenGuides::Test->write_data(
                              guide      => $guide,
                              node       => "Test Page",
                            );

$output = $guide->display_node(
                                return_output => 1,
                                noheaders => 1,
                                id => "Test Page",
                              );

# check navbar_admin div is shown.
Test::HTML::Content::tag_ok( $output, "div", { id => "navbar_admin" },
                             "admin section displayed in navbar" );

# set is_admin to 0
$cookie = OpenGuides::CGI->make_prefs_cookie(
    config                     => $config,
    username                   => "bob",
    include_geocache_link      => 1,
    preview_above_edit_box     => 1,
    omit_help_links            => 1,
    show_minor_edits_in_rc     => 1,
    default_edit_type          => "tidying",
    cookie_expires             => "never",
    track_recent_changes_views => 1,
    is_admin => 0,
);
$ENV{HTTP_COOKIE} = $cookie;

$output = $guide->display_node(
                                return_output => 1,
                                noheaders => 1,
                                id => "Test Page",
                              );

# check that the navbar_admin div isnt shown
Test::HTML::Content::no_tag( $output, "div", { id => "navbar_admin" },
                             "navbar not shown" );
