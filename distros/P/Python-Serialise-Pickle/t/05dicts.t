use Test::More qw/no_plan/;
use strict;
use_ok('Python::Serialise::Pickle');


ok(my $ps = Python::Serialise::Pickle->new('t/dicts'));

is_deeply ($ps->load(), { a=>1, b=>2 },   "simple hash");
is_deeply ($ps->load(), { a=>[1, 2, 3] }, "hash with list");
is_deeply ($ps->load(), { a=>{ b=>2 }},   "hash with hash");
#is_deeply ($ps->load(), { a=>[1, 2, 3] }, "hash with tuple");


#ok(my $pw = Python::Serialise::Pickle->new('>t/tmp'));


#ok ($pw->dump( { a=>1, b=>2 }   ), "simple hash");
#ok ($pw->dump( { a=>[1, 2, 3] } ), "hash with list");
#ok ($pw->dump( { a=>{ b=>2 }}   ), "hash with hash");
#ok ($pw->dump( { a=>[1, 2, 3] } ), "hash with tuple");

#ok($pw->close());



#ok(my $pr = Python::Serialise::Pickle->new('t/tmp'));

#is_deeply ($pr->load(), { a=>1, b=>2 },   "simple hash");
#is_deeply ($pr->load(), { a=>[1, 2, 3] }, "hash with list");
#is_deeply ($pr->load(), { a=>{ b=>2 }},   "hash with hash");
#is_deeply ($pr->load(), { a=>[1, 2, 3] }, "hash with tuple");

