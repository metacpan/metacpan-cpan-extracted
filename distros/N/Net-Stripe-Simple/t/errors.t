use strict;
use warnings;
use Test::More tests => 5;
use Net::Stripe::Simple;

sub error { goto &Net::Stripe::Simple::_hash_to_error }

my $e = error();

is $e, 'Error: unknown - [no message]', 'stringification works';
like $e->trace, qr/trace/i, 'trace available';

$e = error( { foo => 'bar' } );

is $e->foo, 'bar', 'autoloading works';

$e = error( foo => 'bar' );
is $e->foo, 'bar', 'named parameters work as well as hash references';

$e = error( message => 'foo', type => 'bar' );
is $e, 'Error: bar - foo', 'stringification works with non-default parameters';

done_testing();

