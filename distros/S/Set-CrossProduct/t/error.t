use Test::More 0.95;

my $class = 'Set::CrossProduct';
use_ok( $class );

my @apples  = ('Granny Smith', 'Washington', 'Red Delicious');
my @oranges = ('Navel', 'Florida');

my $cross = Set::CrossProduct->new( [ \@apples ] );
ok( !( defined $cross ), 'Single array returns undef' );

done_testing();
