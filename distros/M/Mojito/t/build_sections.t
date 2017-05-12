use strictures 1;
use 5.010;
use Test::More;
use Test::Differences;
use FindBin qw($Bin);
use lib "$Bin/data";
use Fixture;
use Mojito::Page::Parse;
use Data::Dumper::Concise;

my $parser = Mojito::Page::Parse->new(page => $Fixture::implicit_normal_starting_section);
my $sections = $parser->sections;
#say Dumper $sections;
is_deeply($sections, $Fixture::sections, 'build sections');

done_testing();