use strictures 1;
use 5.010;
use Test::More;
use Test::Differences;
use Test::Exception;
use FindBin qw($Bin);
use lib "$Bin/data";
use Fixture;
use Mojito::Page::Parse;

my $parser = Mojito::Page::Parse->new(page => $Fixture::nested_section);
isa_ok($parser, 'Mojito::Page::Parse');
ok($parser->has_nested_section,  'nested section');
$parser->sections;
is( $parser->message_string, 'haz nested sexes', 'nested sex message');

# Change content to not be nested
$parser->page($Fixture::not_nested_section);
ok(!$parser->has_nested_section, 'not nested section');

$parser->page($Fixture::simple_non_implicit_section);
my $sectioned_page = $parser->add_implicit_sections;
eq_or_diff($sectioned_page, $Fixture::parsed_simple_non_implicit_section, 'simple non-implicit section');

$parser->page($Fixture::simple_implicit_section);
$sectioned_page = $parser->add_implicit_sections;
eq_or_diff($sectioned_page, $Fixture::parsed_simple_implicit_section, 'simple implicit section');

# Change content to test implicit section addition
$parser->page($Fixture::implicit_section);
$sectioned_page = $parser->add_implicit_sections;
eq_or_diff($sectioned_page, $Fixture::parsed_implicit_section, 'implicit section');

# Change content to test implicit section with a normal section
$parser->page($Fixture::implicit_normal_section);
$sectioned_page = $parser->add_implicit_sections;
eq_or_diff($sectioned_page, $Fixture::parsed_implicit_normal_section, 'implicit normal section');

# Change content to test implicit section with a normal starting section
$parser->page($Fixture::implicit_normal_starting_section);
$sectioned_page = $parser->add_implicit_sections;
eq_or_diff($sectioned_page, $Fixture::parsed_implicit_normal_starting_section, 'implicit normal starting section');

done_testing();

