use strict;
use warnings;
use Test::More tests => 6;
use Net::Stripe::Simple qw(data_object);

my $e = data_object( { foo => 'bar' } );

is $e->foo, 'bar', 'autoloading works';
like $e, qr/^Net::Stripe::Simple::Data=HASH\(0x[a-f0-9]++\)$/,
  'correct stringification with no id';

$e = data_object( { id => 'bar' } );
is $e, 'bar', 'correct stringification with id';

$e = data_object( { foo => { bar => 'baz' } } );
is $e->foo->bar, 'baz', 'construction is recursive';

my $ub = $e->unbless;
is ref $ub, 'HASH', 'unblessing removes blessing';
is ref $ub->{foo}, 'HASH', 'unblessing is recursive';

done_testing();

