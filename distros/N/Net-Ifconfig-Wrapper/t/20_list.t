
use warnings;
use strict;

use Data::Dumper;
use Test::More;

use blib;

use Net::Ifconfig::Wrapper qw( Ifconfig );

my $rh = Ifconfig('list');
isa_ok($rh, 'HASH');
# warn Dumper($rh);
my @a = keys %$rh;
my $iCount = scalar @a;
diag "found $iCount adapters";
cmp_ok(1, '<=', $iCount, 'at least one adapter found');

done_testing();

__END__
