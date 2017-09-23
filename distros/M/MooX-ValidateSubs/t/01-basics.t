use Test::More;

use lib '.';
use t::odea::Maybe;

my $maybe = t::odea::Maybe->new();
my %hash = $maybe->hello_hash( one => 'a', two => ['b'], three => { four => 'ahh' } );
is_deeply(\%hash, { one => 'a', two => ['b'], three => { four => 'ahh' }, four => 'd' });
eval { $maybe->hello_hash };
my $error = $@;
like( $error, qr/^Missing required parameter/, "hello hash fails");

my $hashref = $maybe->hello_hashref({ one => 'a', two => ['b'], three => { four => 'ahh' } });
is_deeply($hashref, { one => 'a', two => ['b'], three => { four => 'ahh' }, four => 'd' });
eval { $maybe->hello_hashref };
my $errorh = $@;
like( $error, qr/^Missing required parameter/, "hello hashref fails");

my @list = $maybe->a_list( 'a', ['b'], { four => 'ahh' } );
is_deeply(\@list, [ 'a', ['b'], { four => 'ahh' } ]);
eval { $maybe->a_list };
$errors = $@;
like( $errors, qr/Error - Invalid count in params for sub - a_list - expected - 3 - got - 0/, "a list fails");

my @okay = $maybe->okay_test;
is_deeply(\@okay, [ 'a', ['b'], { four => 'ahh' } ]);

my $arrayref = $maybe->a_single_arrayref([ 'a', ['b'], { four => 'ahh' } ]);
is_deeply($arrayref, [ 'a', ['b'], { four => 'ahh' } ]);
eval { $maybe->a_single_arrayref };
$errors = $@;
like( $errors, qr/Error - Invalid count in params for sub - a_single_arrayref - expected - 3 - got - 0/, "an arrayref fails");
my $arra = $maybe->coe([qw/a b c/]);
is_deeply($arra, [qw/a b c/], 'array ref without coercion');

my $stringArrayref = $maybe->coe('a b c');
is_deeply($stringArrayref, [qw/a b c/], 'array ref via coercion');

done_testing();

