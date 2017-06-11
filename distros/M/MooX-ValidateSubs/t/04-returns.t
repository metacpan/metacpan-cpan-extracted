use Test::More;

use lib '.';
use t::odea::Returns;

my $maybe = t::odea::Returns->new();

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
is_deeply(\@list, [ 'a', ['b'], { four => 'ahh' }, 'd' ]);
eval { $maybe->a_list };
my $errors = $@;
like( $errors, qr/Error - Invalid count in returns for sub - a_list - expected - 4 - got - 1/, "a list fails");

my @okay = $maybe->okay_test;
is_deeply(\@okay, [ 'a', ['b'], { four => 'ahh' }, 'd' ]);

my $arrayref = $maybe->a_single_arrayref([ 'a', ['b'], { four => 'ahh' } ]);
is_deeply($arrayref, [ 'a', ['b'], { four => 'ahh' }, 'd' ]);

eval { $maybe->a_single_arrayref };
my $errors = $@;
like( $errors, qr/Error - Invalid count in returns for sub - a_single_arrayref - expected - 4 - got - 1/, "an arrayref fails");

done_testing();

