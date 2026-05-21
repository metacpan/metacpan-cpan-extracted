use Test::More;

use utf8;
use strict;
use warnings;
use Pass::OTP;

open my $original_in, '<&', \*STDIN or die $!;
open my $fake_in, '<', \'otpauth://totp/Test?secret=abcdefgh&now=1' or die $!;

*STDIN = $fake_in;
my $otp = eval { Pass::OTP::otp() };
*STDIN = $original_in;

ok(!$@, 'otp() did not fail');
is($otp, '328482', 'otptool <<<"otpauth://totp/Test?secret=abcdefgh"');

done_testing(2);
