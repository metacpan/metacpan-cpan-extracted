# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl IDspace.t'

#########################

BEGIN {
    eval { require Test; };
    use Test;    
    plan tests => 16;
}

#########################

use OBO::Core::IDspace;
use strict;

# three new IDspace's
my $ref1 = OBO::Core::IDspace->new();
my $ref2 = OBO::Core::IDspace->new();
my $ref3 = OBO::Core::IDspace->new();

$ref1->local_idspace('APO');
$ref1->uri('http://www.cellcycle.org/ontology/APO');
$ref1->description('cell cycle ontology terms');

ok($ref1->local_idspace() eq 'APO');
ok($ref1->uri() eq 'http://www.cellcycle.org/ontology/APO');
ok($ref1->description() eq 'cell cycle ontology terms');

$ref2->local_idspace('APO');
$ref2->uri('http://www.cellcycle.org/ontology/APO');
$ref2->description('cell cycle ontology terms');

ok($ref2->local_idspace() eq 'APO');
ok($ref2->uri() eq 'http://www.cellcycle.org/ontology/APO');
ok($ref2->description() eq 'cell cycle ontology terms');

ok(!$ref2->equals($ref3));
ok(!$ref1->equals($ref3));
ok($ref1->equals($ref2));
ok($ref1->equals($ref1));
ok($ref2->equals($ref2));

$ref3 = $ref2;
ok($ref3->equals($ref1));
ok($ref3->equals($ref2));
ok($ref3->as_string() eq 'APO http://www.cellcycle.org/ontology/APO "cell cycle ontology terms"');

my $ref4 = OBO::Core::IDspace->new();
ok($ref4->as_string() eq '');

ok(1);