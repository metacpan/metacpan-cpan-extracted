use Test::More qw(no_plan);
BEGIN{
   use_ok('Set::Hash');
}
require_ok('Set::Hash');

ok(Set::Hash->new(name=>"dan",age=>33),"basic constructor");
ok(Set::Hash->new("name","dan"),"comma constructor");     
ok(Set::Hash->new(qw/name dan age 33/),"qw constructor");
