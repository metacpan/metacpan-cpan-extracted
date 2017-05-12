# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Dbxref.t'

#########################

BEGIN {
    eval { require Test; };
    use Test;    
    plan tests => 20;
}

#########################

use OBO::Core::Dbxref;
use strict;

# three new dbxref's
my $ref1 = OBO::Core::Dbxref->new();
my $ref2 = OBO::Core::Dbxref->new();
my $ref3 = OBO::Core::Dbxref->new();

$ref1->name('APO:vm');
$ref1->description('this is a description');
$ref1->modifier('{opt=123}');
ok($ref1->name() eq 'APO:vm');
$ref2->name('APO:ls');
ok($ref2->name() eq 'APO:ls');
$ref3->db('APO');
$ref3->acc('ea');
ok($ref3->name() eq 'APO:ea');
ok($ref3->db() eq 'APO');
ok($ref3->acc() eq 'ea');

ok(!$ref2->equals($ref3));
ok(!$ref1->equals($ref3));
ok(!$ref1->equals($ref2));
ok($ref1->equals($ref1));
ok($ref2->equals($ref2));
ok($ref3->equals($ref3));

my $ref4 = $ref3;
ok($ref4->name() eq $ref3->name() && $ref4->description() eq $ref3->description() && $ref4->modifier() eq $ref3->modifier());

my $ref5 = OBO::Core::Dbxref->new();
$ref5->name('APO:vm');
$ref5->description('this is a description');
$ref5->modifier('{opt=123}');
ok($ref5->name() eq 'APO:vm');

ok($ref1->equals($ref5));

ok($ref1->as_string() eq 'APO:vm "this is a description" {opt=123}');

my $ref6 = OBO::Core::Dbxref->new();
$ref6->name('IUPAC:1');
ok($ref6->name() eq 'IUPAC:1');

my $ref7 = OBO::Core::Dbxref->new();
$ref7->name('NIST_Chemistry_WebBook:1');
ok($ref7->name() eq 'NIST_Chemistry_WebBook:1');

my $ref8 = OBO::Core::Dbxref->new();
$ref8->name('http://mydomain.com/key1=value1&key2=value2');
ok($ref8->name() eq 'http://mydomain.com/key1=value1&key2=value2');

my $ref9 = OBO::Core::Dbxref->new();
$ref9->name("http\://en.wikipedia.org/wiki/Saint-Louis-du-Ha\!_Ha\!%2C_Quebec");
ok($ref9->name() eq "http\://en.wikipedia.org/wiki/Saint-Louis-du-Ha\!_Ha\!%2C_Quebec");

ok(1);