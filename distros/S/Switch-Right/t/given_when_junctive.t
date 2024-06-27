use v5.36;
use strict;
use warnings;


use Test2::V0;

#plan tests => 139;

no feature 'switch';
use Switch::Right;

sub odd ($n) { $n % 2 }

my (@oddorbig, @evenandsmall);
for (1..11) {
    when (any  => [\&odd, qr/\d\d/]) { push @oddorbig, $_ }
    when (none => [\&odd, qr/\d\d/]) { push @evenandsmall, $_ }
}
is \@oddorbig,     [1,3,5,7,9,10,11] => '@oddorbig';
is \@evenandsmall, [2,4,6,8]         => '@evenandsmall';

given (none => @evenandsmall) {
    when (2) { fail 'none @evenandsmall' }
    when (3) { pass 'none @evenandsmall' }
    default  { fail 'none @evenandsmall' }
}

given (none => @evenandsmall) {
    when (any => @oddorbig) { pass 'none @evenandsmall any @oddorbig' }
    default                 { pass 'none @evenandsmall any @oddorbig' }
}

given (any => [2,3,5,7,11,13,17,'many']) {
    when (all => [\&odd, qr/\d\d/]) { pass 'odd and big' }
    default {                         fail 'odd and big' }
}

given (all => [2,3,5,7,11,13,17,'many']) {
    when (any => [\&odd, qr/\d\d/]) { fail 'odd or big' }
    default {                         pass 'odd or big' }
}

done_testing();

__DATA__

