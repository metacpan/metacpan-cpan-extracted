use strict;
use Cwd;
use OpenGuides;
use OpenGuides::Template;
use OpenGuides::Test;
use Test::More tests => 5;

my $config = OpenGuides::Test->make_basic_config;
$config->template_path( cwd . "/t/templates" );

my $guide = OpenGuides->new( config => $config );
my $wiki = $guide->wiki;

eval {
    OpenGuides::Template->output( wiki     => $wiki,
                                  config   => $config,
                                  template => "15_test.tt" );
};
is( $@, "", "is happy doing output" );

my $output = OpenGuides::Template->output(
    wiki     => $wiki,
    config   => $config,
    template => "15_test.tt"
);
like( $output, qr/^Content-Type: text\/html/,
      "Content-Type header included and defaults to text/html" );

# Now supply a http charset
$config->http_charset( "UTF-8" );

$output = OpenGuides::Template->output(
    wiki     => $wiki,
    config   => $config,
    template => "15_test.tt"
);
like( $output, qr/^Content-Type: text\/html; charset=UTF-8/,
      "Content-Type header included charset" );

# Suppy charset and content type
$output = OpenGuides::Template->output(
    wiki     => $wiki,
    config   => $config,
    content_type => "text/xml",
    template => "15_test.tt"
);
like( $output, qr/^Content-Type: text\/xml; charset=UTF-8/,
      "Content-Type header included charset" );

# Content type but no charset
$config->http_charset( "" );
$output = OpenGuides::Template->output(
    wiki     => $wiki,
    config   => $config,
    content_type => "text/xml",
    template => "15_test.tt"
);
like( $output, qr/^Content-Type: text\/xml/,
      "Content-Type header didn't include charset" );
