use Test::More;
use lib qw(t/inc);


for my $class ( map { 'TestClass' . $_ } qw( 1 2 3 4 ) ) { 
   diag "testing class $class";
   use_ok( $class );
   my $obj = new_ok( $class );

   is( $obj->test_method('Blarg'), 1, 'Checking method ' . $class );
}

diag 'testing TestClass5 (returning a list)';
use_ok( 'TestClass5');
my $obj = new_ok('TestClass5');
my @list =  $obj->test_method('blark');
is_deeply( \@list, ['a list', 'of things'], 'Checking array' );


done_testing();
