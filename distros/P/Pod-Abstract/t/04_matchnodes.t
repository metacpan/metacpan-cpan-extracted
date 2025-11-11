#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 19;
use Pod::Abstract;
use Pod::Abstract::BuildNode qw(node nodes);

my @h = ( );
my @h2 = ( );

my $count_1 = 1;

foreach my $t (qw(test TEST foo foo Test)) {
    my $h1 = node->head1($t);
    push @h, $h1;
    $h1->push(node->paragraph("test"));
    foreach my $t (qw(TEST biscuit test cheese)) {
        if( $t eq 'cheese' ) {
            $h1->push(node->head2("$t-$count_1"));
        } else {
            $h1->push(node->head2($t));
        }
    }

    $count_1 ++;
}
my $root = node->root;
$root->nest(@h);

my @ci =  # case insensitive
    $root->select('/head1[@heading =~ {test}i]');
my @cs =  # case sensitive
    $root->select('/head1[@heading =~ {TEST}]');
my @eq =  # equality - simple
    $root->select('/head1[@heading eq \'Test\']');
my @ec =  # equality - complex
    $root->select('/head1[@heading eq /head2@heading]');
my @ec_s = # equality - complex - successor
    $root->select('/head1[>>@heading eq @heading]');
my @root = # Only one root node for all:
    $root->select('//^'); # Horribly ineffient NOP. This catches the
                          # filter_unique behaviour.
my @union = $root->select('/head1(0) | /head1(1) | /head1(2) | /head1(0)');
my @intersect = # Union/Intersect evaluate right to left
    $root->select(
        '//[@heading =~ {test}i] & //head2(0) | //head1(4) | head1(3)'
    );

# Really serious now: head2s or paragraphs of the first head1 but only
# those head2s having heading matching 'test', but case insensitive.
my @union_select =
    $root->select(
        '/head1(0)/head2 :paragraph[ :paragraph | head2[@heading =~ {^test$}i]]'
    );

# head2s of the first head1 matching "test" (insensitive), but only
# those that also have a preceding paragraph.
my @intersect_select =
    $root->select(
        '/head1(0)/head2[ head2[<<:paragraph] & head2[@heading =~ {^test$}i]]'
   );

# Match head2 nodes which match top level head1 nodes -
# expands/restricts a lot of nodes.
my @tt = $root->select('//head2[@heading eq ^/head1@heading]');
my @h2_para = $root->select('/head1(0)/:paragraph head2');

# Negative index into headings
my @neg_hdg = $root->select('/head1(-1)');

ok(@cs == 1, "Case sensitive match 1");
ok(@ci == 3, "Case insensitive match 3");
ok(@eq == 1, "Exact match 1");
ok(@ec == 2, "Complex match 2");
ok(@ec_s == 1, "Complex Successor match 1");
ok($_->detach, "Detach matched node") foreach @ec_s;

my @ec_p = # equality - complex - preceding
    $root->select('/head1[<<@heading eq @heading]');

ok(@ec_p == 0, "Complex Preceding match 0");
ok(@root == 1, "One root node only");
ok(@tt == 10, "Match 10 head2 nodes");
ok(@h2_para == 5, "Match 5 head2 or para under first head1");
ok(@union == 3, "Union match three nodes");

for ( my $i = 1; $i < 4; $i++ ) {
    my $n = $union[$i - 1]; # Out by one.
    ok( $n->pod =~ m/cheese-$i/, "Matched the expected node =head2 cheese-$i in the unioned head1 sections" );
}

ok(@intersect == 2, "Intersect match two nodes");

ok(@union_select == 3, "Union in select match three nodes");
ok(@intersect_select == 1, "Intersect in select matches one node only");

ok(@neg_hdg == 1, "Negative index matched one node");
ok($neg_hdg[0]->param('heading')->pod eq 'Test', "Last head1 is 'Test'");

1;

