# vim: set ft=perl:
use lib 't', 'lib';

use Oryx;
use YAML;

use Test::More qw(no_plan);
use Oryx::Class(auto_deploy => 1);
use CMS::Schema;

my $storage = Oryx->connect(['dbi:SQLite:dbname=test'], CMS::Schema);

# this class is defined in XML (in t/XMLSchema.pm) and is here at
# compile time, neat eh?
use CMS::Page( auto_deploy => 1 );
use CMS::Paragraph( auto_deploy => 1 );
my $page = CMS::Page->create({ title => "my page" });

my $paras = [
    CMS::Paragraph->create({ content => "This is paragraph 1" }),
    CMS::Paragraph->create({ content => "This is paragraph 2" }),
    CMS::Paragraph->create({ content => "This is paragraph 3" }),
];
$page->paragraphs( $paras );
$page->update;
$page->commit;
my $page1_id = $page->id;
$page->remove_from_cache();
my $page2 = CMS::Page->retrieve($page->id);
is($page2->paragraphs->[0]->content, "This is paragraph 1");
is($page2->paragraphs->[1]->content, "This is paragraph 2");
is($page2->paragraphs->[2]->content, "This is paragraph 3");
