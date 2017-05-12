use Benchmark qw(:all);
use FindBin qw($Bin);
use lib "$Bin/../data";
use Fixture;
use Mojito::Page::Render;

my $page_struct =$Fixture::page_structure;
Mojito::Page::Render->new->render_page($page_struct);

