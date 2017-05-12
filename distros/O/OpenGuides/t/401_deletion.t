use strict;
use OpenGuides;
use OpenGuides::Template;
use OpenGuides::Test;
use OpenGuides::CGI;
use Test::More tests => 3;

my $config = OpenGuides::Test->make_basic_config;
$config->site_name( "Test Site" );
$config->script_url( "/" );

my $guide = OpenGuides->new( config => $config );
my $wiki = $guide->wiki;

my $output = OpenGuides::Template->output(
    wiki     => $wiki,
    config   => $config,
    template => "node.tt",
);
unlike( $output, qr/action=delete/,
        "doesn't offer page deletion link by default" );
$config->enable_page_deletion( "y" );
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

$output = OpenGuides::Template->output(
    wiki     => $wiki,
    config   => $config,
    template => "node.tt",
);
like( $output, qr/action=delete/,
      "...but does when enable_page_deletion is set to 'y' and is_admin is 1" );
$config->enable_page_deletion( 1 );
$output = OpenGuides::Template->output(
    wiki     => $wiki,
    config   => $config,
    template => "node.tt",
);
like( $output, qr/action=delete/,
      "...and when enable_page_deletion is set to '1' and is_admin is 1" );
