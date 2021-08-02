use strict;
use warnings;

use Test2::V0;
use TOML::Tiny;

require Math::BigInt;
require Math::BigFloat;

subtest 'integers' => sub{
  subtest 'decimal' => sub{
    is from_toml('x=42'), {x => 42}, 'positive';
    is from_toml('x=-42'), {x => -42}, 'negative';
    is from_toml('x=42_42'), {x => 4242}, 'underscores';

    is from_toml('x=9223372036854775807'), hash{
      field x => validator(sub{
        my %params = @_;
        Math::BigInt->new('9223372036854775807')->beq($params{got});
      });
      end;
    }, 'positive bignum';

    is from_toml('x=-9223372036854775808'), hash{
      field x => validator(sub{
        my %params = @_;
        Math::BigInt->new('-9223372036854775808')->beq($params{got});
      });
      end;
    }, 'negative bignum';
  };

  subtest 'hexadecimal' => sub{
    is from_toml('x=0xDEADBEEF'), {x => 0xDEADBEEF}, 'all caps';
    is from_toml('x=0xdeadbeef'), {x => 0xDEADBEEF}, 'all lower';
    is from_toml('x=0xDeAdBeEf'), {x => 0xDEADBEEF}, 'mixed caps';
    is from_toml('x=0xDEAD_BEEF'), {x => 0xDEADBEEF}, 'underscores';
    is from_toml('x=0xDEADBEEF '), {x => 0xDEADBEEF}, 'trailing space';

    is from_toml('x=0x7fffffffffffffff'), hash{
      field x => validator(sub{
        my %params = @_;
        Math::BigInt->new('0x7fffffffffffffff')->beq($params{got});
      });
      end;
    }, 'bignum';
  };

  subtest 'binary' => sub{
    is from_toml('x=0b1010'), {x => 0b1010}, 'binary';
    is from_toml('x=0b10_10'), {x => 0b1010}, 'underscores';

    is from_toml('x=0o777777777777777777777'), hash{
      field x => validator(sub{
        my %params = @_;
        Math::BigInt->from_oct('0777777777777777777777')->beq($params{got});
      });
      end;
    }, 'bignum';
  };

  subtest 'octal' => sub{
    is from_toml('x=0o755'), {x => 0755}, 'octal';
    is from_toml('x=0o7_55'), {x => 0755}, 'underscores';

    is from_toml('x=0b111111111111111111111111111111111111111111111111111111111111111'), hash{
      field x => validator(sub{
        my %params = @_;
        Math::BigInt->new('0b111111111111111111111111111111111111111111111111111111111111111')->beq($params{got});
      });
      end;
    }, 'bignum';
  };
};

subtest 'floats' => sub{
  is from_toml('x=4.2'), {x => 4.2}, '4.2';
  is from_toml('x=+4.2'), {x => 4.2}, '+4.2';
  is from_toml('x=-4.2'), {x => -4.2}, '-4.2';

  is from_toml('x=0.42'), {x => 0.42}, '0.42';
  is from_toml('x=+0.42'), {x => 0.42}, '+0.42';
  is from_toml('x=-0.42'), {x => -0.42}, '-0.42';

  subtest 'exponent w/ lowercase e' => sub{
    is from_toml('x=4.2e3'), {x => 4.2e3}, '4.2e3';
    is from_toml('x=-4.2e3'), {x => -4.2e3}, '-4.2e3';
    is from_toml('x=4.2e-3'), {x => 4.2e-3}, '4.2e-3';
    is from_toml('x=-4.2e-3'), {x => -4.2e-3}, '-4.2e-3';
  };

  subtest 'exponent w/ uppercase e' => sub{
    is from_toml('x=4.2E3'), {x => 4.2e3}, '4.2E3';
    is from_toml('x=-4.2E3'), {x => -4.2e3}, '-4.2E3';
    is from_toml('x=4.2E-3'), {x => 4.2e-3}, '4.2E-3';
    is from_toml('x=-4.2E-3'), {x => -4.2e-3}, '-4.2E-3';
  };

  is from_toml('x=inf'), {x => 'inf'}, 'inf';
  is from_toml('x=+inf'), {x => 'inf'}, '+inf';
  is from_toml('x=-inf'), {x => -'inf'}, '-inf';

  for (qw(nan +nan -nan)) {
    is from_toml("x=$_"), hash{
      field x => 'NaN';
      end;
    }, $_;
  }

  is from_toml('x=nan'), {x => 'NaN'}, 'nan';
  is from_toml('x=+nan'), {x => 'NaN'}, '+nan';
  is from_toml('x=-nan'), {x => 'NaN'}, '-nan';

  is from_toml('x=42_42.42_42'), {x => 4242.4242}, 'underscores';
};

#-------------------------------------------------------------------------------
# Ensure that numbers survive the trip through to_toml(from_toml(...)) and are
# not coerced into strings by perl.
#-------------------------------------------------------------------------------
subtest 'round trip preserves numerical values' => sub{
  is to_toml(scalar from_toml('port=1234')), 'port=1234', 'integers';
  is to_toml(scalar from_toml('pi=3.14')), 'pi=3.14', 'floats';
  is to_toml(scalar from_toml('nan=nan')), 'nan=nan', 'nan';
  is to_toml(scalar from_toml('pos=inf')), 'pos=inf', 'inf';
  is to_toml(scalar from_toml('neg=-inf')), 'neg=-inf', '-inf';
};

done_testing;
