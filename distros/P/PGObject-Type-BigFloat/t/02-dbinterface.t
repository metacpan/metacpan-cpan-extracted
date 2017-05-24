use Test::More tests => 39;
use PGObject::Type::BigFloat;

my @values = (1.234, 1000, 1234.34, -12333.23, 12143234523, 4233143455, 
              43324324, undef);

for my $val (@values){
   my $testvar = PGObject::Type::BigFloat->from_db($val);
   ok($testvar, "Object creation, value $val") if defined $val;
   ok($testvar->isa('Math::BigFloat'), 
      "Object isa Math::BigFloat,  value $val");
   ok($testvar->isa('PGObject::Type::BigFloat'), 
      "Object isa PGObject::Type::BigFloat, value $val");
   my $out = $testvar->to_db;
   is(ref $out, '', "Output is not an object");
   is($out, $val, "Value matches on output");
}
