use strict;
use Cwd;
use OpenGuides;
use OpenGuides::Template;
use OpenGuides::Test;
use Test::More tests => 3;

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

unlike( $output, qr/^Status:/,
      "HTTP status not printed when not explicitly specified ");

# Now supply a http status

$output = OpenGuides::Template->output(
    wiki     => $wiki,
    config   => $config,
    template => "15_test.tt",
    http_status => '404'
);
like( $output, qr/^Status: 404/,
      "Correct HTTP status printed when specified" );
