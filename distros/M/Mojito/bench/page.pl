use Benchmark qw(:all);
use FindBin qw($Bin);
use lib "$Bin/../data";
use Fixture;
use Mojito::Page::Parse;
use Mojito::Page::Render;
use Mojito::Page::CRUD;
use Data::Dumper::Concise;

my $page = $Fixture::implicit_section;
my $page_struct = Mojito::Page::Parse->new( page => $page )->page_structure;
my $editer = Mojito::Page::CRUD->new( db_name => 'bench' );

my $count = $ARGV[0] || 1000;

my $result = cmpthese(
    $count,
    {
        'parse' => sub {
            Mojito::Page::Parse->new( page => $page )->page_structure;
        },
        'render' => sub { Mojito::Page::Render->new->render_page($page_struct) },
        'edit'   => sub {
            my $id = $editer->create($page_struct);
            my $page = $editer->read($id);
        },
    }
);

#my $result = timethis($count, sub { Mojito::Page::Parse->new(page => $Fixture::implicit_section)->page_structure });
