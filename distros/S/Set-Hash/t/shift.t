use Test::More qw(no_plan);
BEGIN{
   use_ok('Set::Hash');
}
require_ok('Set::Hash');

my $len;
my $sh1 = Set::Hash->new(qw/name dan age 33/);

$len = $sh1->length;
is($len,2, "Expected 2, got [$len]");

my($key,$val) = $sh1->shift;

$len = $sh1->length;
is($len,1, "Expected 1, got [$len]");

like($key,qr/name|age/,"key error");
like($val,qr/dan|33/,"value error");
