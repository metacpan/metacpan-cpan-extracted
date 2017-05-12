use strictures 1;
use 5.010;
use Test::More;
use Test::Deep;
use FindBin qw($Bin);
use lib "$Bin/data";
use Fixture;
use Mojito::Page::Parse;
use Data::Dumper::Concise;

my $parser = Mojito::Page::Parse->new(page => $Fixture::implicit_normal_starting_section);
my $page_struct = $parser->page_structure;
#say Dumper $page_struct;
#say Dumper $Fixture::page_structure;
cmp_deeply($page_struct, superhashof($Fixture::page_structure), 'page structure');


done_testing();
