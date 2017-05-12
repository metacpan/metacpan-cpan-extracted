use Mojito::Page::CRUD;
use Mojito::Model::Config;
use Data::Skeleton;
use Data::Dumper::Concise;
my $crud = Mojito::Page::CRUD->new(config => Mojito::Model::Config->new->config);
my $cursor = $crud->get_all;
my $page = $cursor->next;
my $ds = Data::Skeleton->new;
print "PAGE: ", Dumper $ds->deflesh($page);
