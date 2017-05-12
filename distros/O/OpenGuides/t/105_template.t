use strict;
use Cwd;
use CGI::Cookie;
use Wiki::Toolkit::Formatter::UseMod;
use OpenGuides;
use OpenGuides::Template;
use OpenGuides::Test;
use Test::More tests => 29;

my $config = OpenGuides::Test->make_basic_config;
$config->template_path( cwd . "/t/templates" );
$config->site_name( "Wiki::Toolkit Test Site" );
$config->script_url( "http://wiki.example.com/" );
$config->script_name( "mywiki.cgi" );
$config->contact_email( 'wiki@example.com' );
$config->stylesheet_url( "http://wiki.example.com/styles.css" );
$config->home_name( "Home Page" );
$config->formatting_rules_node( "Rules" );
$config->formatting_rules_link( "" );

my $guide = OpenGuides->new( config => $config );
my $wiki = $guide->wiki;

eval { OpenGuides::Template->output( wiki   => $wiki,
                                     config => $config ); };
ok( $@, "->output croaks if no template file supplied" );

eval {
    OpenGuides::Template->output( wiki     => $wiki,
                                  config   => $config,
                                  template => "105_test.tt" );
};
is( $@, "", "...but not if one is" );

my $output = OpenGuides::Template->output(
    wiki     => $wiki,
    config   => $config,
    template => "105_test.tt",
    vars     => { foo => "bar" }
);
like( $output, qr/^Content-Type: text\/html/,
      "Content-Type header included and defaults to text/html" );
like( $output, qr/FOO: bar/, "variables substituted" );

$output = OpenGuides::Template->output(
    wiki         => $wiki,
    config       => $config,
    template     => "105_test.tt",
    content_type => ""
);
unlike( $output, qr/^Content-Type: text\/html/,
        "Content-Type header omitted if content_type arg explicitly blank" );

$output = OpenGuides::Template->output(
    wiki          => $wiki,
    config        => $config,
    template      => "105_test.tt",
    noheaders      => 1,
    http_response => 500
);

unlike( $output, qr/^Status: /,
        "Headers omitted if noheaders arg given" );

$output = OpenGuides::Template->output(
    wiki     => $wiki,
    config   => $config,
    template => "15_idonotexist.tt"
);
like( $output, qr/Failed to process template/, "fails nice on TT error" );

# Test TT variables are auto-set from config.
$output = OpenGuides::Template->output(
    wiki     => $wiki,
    config   => $config,
    template => "105_test.tt"
);

like( $output, qr/SITE NAME: Wiki::Toolkit Test Site/, "site_name var set" );
like( $output, qr/CGI URL: mywiki.cgi/, "cgi_url var set" );
like( $output, qr/FULL CGI URL: http:\/\/wiki.example.com\/mywiki.cgi/,
      "full_cgi_url var set" );
like( $output, qr/CONTACT EMAIL: wiki\@example.com/, "contact_email var set" );
like( $output, qr/STYLESHEET: http:\/\/wiki.example.com\/styles.css/,
      "stylesheet var set" );
like( $output, qr/HOME LINK: http:\/\/wiki.example.com\/mywiki.cgi/, "home_link var set" );
like( $output, qr/HOME NAME: Home Page/, "home_name var set" );
like( $output,
      qr/FORMATTING RULES LINK: http:\/\/wiki.example.com\/mywiki.cgi\?Rules/,
      "formatting_rules_link var set" );

# Test openguides_version TT variable.
like( $output, qr/OPENGUIDES VERSION: 0\.\d\d/,
      "openguides_version set" );

# Test TT variables auto-set from node name.
$output = OpenGuides::Template->output(
    wiki     => $wiki,
    config   => $config,
    node     => "Test Node",
    template => "105_test.tt"
);

like( $output, qr/NODE NAME: Test Node/, "node_name var set" );
like( $output, qr/NODE PARAM: Test_Node/, "node_param var set" );

# Test that cookies go in.
my $cookie = CGI::Cookie->new( -name => "x", -value => "y" );
$output = OpenGuides::Template->output(
    wiki     => $wiki,
    config   => $config,
    template => "105_test.tt",
    cookies  => $cookie
);
like( $output, qr/Set-Cookie: $cookie/, "cookie in header" );

# Test that external URLs for text formatting work.
$config = OpenGuides::Config->new(
       vars => {
                 template_path         => cwd . '/t/templates',
                 site_name             => 'Wiki::Toolkit Test Site',
                 script_url            => 'http://wiki.example.com/',
                 script_name           => 'mywiki.cgi',
		 formatting_rules_node => 'Some External Help',
                 formatting_rules_link => 'http://www.example.com/wikitext',
               }
);
$output = OpenGuides::Template->output(
    wiki     => $wiki,
    config   => $config,
    template => "105_test.tt"
);
like ( $output, qr/FORMATTING RULES LINK: http:\/\/www.example.com\/wikitext/,
      "formatting_rules_link var honoured for explicit URLs" );

# Test that home_link is set correctly when script_name is blank.
$config = OpenGuides::Config->new(
       vars => {
                 template_path         => cwd . '/t/templates',
                 site_name             => 'Wiki::Toolkit Test Site',
                 script_url            => 'http://wiki.example.com/',
                 script_name           => '',
               }
);
$output = OpenGuides::Template->output(
    wiki     => $wiki,
    config   => $config,
    template => "105_test.tt"
);
like( $output, qr/HOME LINK: http:\/\/wiki.example.com/,
      "home_link var set OK when script_name blank" );

# Test that full_cgi_url comes out right if the trailing '/' is
# missing from script_url in the config file.
$config = OpenGuides::Config->new(
       vars => {
                 template_path         => cwd . '/t/templates',
                 site_name             => 'Wiki::Toolkit Test Site',
                 script_url            => 'http://wiki.example.com',
                 script_name           => 'wiki.cgi',
               }
);
$output = OpenGuides::Template->output(
    wiki     => $wiki,
    config   => $config,
    template => "105_test.tt"
);
like( $output, qr/FULL CGI URL: http:\/\/wiki.example.com\/wiki.cgi/,
      "full_cgi_url OK when trailing '/' missed off script_url" );

# Test that TT vars are picked up from user cookie prefs.
$cookie = OpenGuides::CGI->make_prefs_cookie(
    config                 => $config,
    omit_formatting_link   => 1,
);
$ENV{HTTP_COOKIE} = $cookie;
$output = OpenGuides::Template->output(
    wiki     => $wiki,
    config   => $config,
    template => "105_test.tt"
);
like( $output, qr/FORMATTING RULES LINK: /,
      "formatting_rules_link TT var blank as set in cookie" );

# Test that explicitly supplied vars override vars in cookie.
$output = OpenGuides::Template->output(
    wiki     => $wiki,
    config   => $config,
    template => "105_test.tt",
    vars     => { omit_formatting_link => "fish" },
);
like( $output, qr/OMIT FORMATTING LINK: fish/,
      "explicitly supplied TT vars override cookie ones" );

# Test that enable_page_deletion is set correctly in various circumstances.
$config = OpenGuides::Config->new(
    vars => {
              template_path => cwd . "/t/templates",
              site_name     => "Test Site",
              script_url    => "/",
              script_name   => "",
            },
);

$output = OpenGuides::Template->output(
    wiki     => $wiki,
    config   => $config,
    template => "105_test.tt",
);
like( $output, qr/ENABLE PAGE DELETION: 0/,
      "enable_page_deletion var set correctly when not specified in conf" );

$config->enable_page_deletion( "n" );
$output = OpenGuides::Template->output(
    wiki     => $wiki,
    config   => $config,
    template => "105_test.tt",
);
like( $output, qr/ENABLE PAGE DELETION: 0/,
      "enable_page_deletion var set correctly when set to 'n' in conf" );

$config->enable_page_deletion( "y" );
$output = OpenGuides::Template->output(
    wiki     => $wiki,
    config   => $config,
    template => "105_test.tt",
);
like( $output, qr/ENABLE PAGE DELETION: 1/,
      "enable_page_deletion var set correctly when set to 'y' in conf" );

$config->enable_page_deletion( 0 );
$output = OpenGuides::Template->output(
    wiki     => $wiki,
    config   => $config,
    template => "105_test.tt",
);
like( $output, qr/ENABLE PAGE DELETION: 0/,
      "enable_page_deletion var set correctly when set to '0' in conf" );

$config->enable_page_deletion( 1 );
$output = OpenGuides::Template->output(
    wiki     => $wiki,
    config   => $config,
    template => "105_test.tt",
);
like( $output, qr/ENABLE PAGE DELETION: 1/,
      "enable_page_deletion var set correctly when set to '1' in conf" );
