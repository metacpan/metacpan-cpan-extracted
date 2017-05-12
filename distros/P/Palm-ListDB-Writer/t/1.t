#! perl -w
use strict;
use warnings;
use Test::More tests => 10;

BEGIN { use_ok('Palm::ListDB::Writer') };
diag( "Testing Palm::ListDB::Writer $Palm::ListDB::Writer::VERSION, Perl $], $^X" );
-d "t" && chdir("t");
ok(eval { require "./dbcmp.pl" }, "require dbcmp.pl");

my @dels = qw(1.pdb);
unlink(@dels);

my $x = Palm::ListDB::Writer->new("MyDataBase",
				  cat => [qw(aaa bbb ccc)]) ;
ok($x, "object created");

$x->{autocat} = 1;

ok($x->add_cat("bbqf"), "add category");
ok($x->add("bbqf","One","Two","Three"), "add record one");
ok($x->add("bbqq","XXOne","XXTwo","XXThree"), "add record two");
is(scalar($x->categories), 5, "categories");

$x->write("1.pdb");

dbcmp("1.pdb", "1.ref", 648) && unlink(@dels);


