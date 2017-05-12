use strictures 1;
use 5.010;
#use Test::More;
#use Test::Differences;
use FindBin qw($Bin);
use lib "$Bin/data";
use Fixture;
use Mojito::Page::Parse;
use Mojito::Page::CRUD;
use Mojito::Page::Render;
use Mojito::Model::Link;
use Data::Dumper::Concise;
use Time::HiRes qw/ time /;

my $start = time;
#my $parser = Mojito::Page::Parse->new(page => $Fixture::implicit_section);
#my $page_struct = $parser->page_structure;
#
my $linker = Mojito::Model::Link->new;
#my $id = $editer->create($page_struct);
##say "id: $id";
#$id = '4d532f9651683bd673000000';
#my $doc = $editer->read($id);
#say Dumper $doc;
#say "title: ", $doc->{title};

my $cursor = $linker->get_most_recent_docs;
while (my $doc = $cursor->next) {
    say "title: ", $doc->{title}, "id: ", $doc->{_id}, " last_modified: ", $doc->{last_modified};
}
my $links = $linker->recent_links;
say "Links: ", Dumper $links;


#my $render = Mojito::Page::Render->new;
#my $page = $render->render_page($page_struct);
##print 'raw: ', Dumper $raw;
##print 'rendered: ', Dumper $rendered;
#say $page;
say "took: ", (time - $start);

#ok(1);
#done_testing();