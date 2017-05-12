use Test::More tests => 3;
BEGIN { use_ok('Pointy::Counter') };

my $obj1 = Pointy::Counter->new;
my $obj2 = counter;

isa_ok($obj1, 'Pointy::Counter');
isa_ok($obj2, 'Pointy::Counter');
