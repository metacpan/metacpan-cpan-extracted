# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl SynonymTypeDef.t'

#########################

BEGIN {
    eval { require Test; };
    use Test;    
    plan tests => 8;
}

#########################

use OBO::Core::SubsetDef;

use strict;

my $std1 = OBO::Core::SubsetDef->new();
my $std2 = OBO::Core::SubsetDef->new();


# name
$std1->name("GO_SLIM");
ok ($std1->name() eq "GO_SLIM");
$std2->name("APO_SLIM");
ok ($std2->name() eq "APO_SLIM");

# description
$std1->description("GO slim");
ok ($std1->description() eq "GO slim");
$std2->description("APO slim");
ok ($std2->description() eq "APO slim");

# synonym type def as string
my $std3 = OBO::Core::SubsetDef->new();
$std3->as_string("GO_SLIM", "GO slim");
ok($std1->as_string() eq "GO_SLIM \"GO slim\"");
ok($std3->as_string() eq "GO_SLIM \"GO slim\"");
ok($std1->equals($std3));

ok(1);
