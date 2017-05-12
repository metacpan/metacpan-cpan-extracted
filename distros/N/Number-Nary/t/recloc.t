use strict;
use warnings;

# I think that Jesse's Number::RecordLocator is his own answer to the question
# that originally created this module.  Here, you can see how Number::Nary can
# easily be configured to do what Number::RecordLocator does. -- rjbs,
# 2007-01-03

use Test::More tests => 9;

BEGIN {
  use_ok('Number::Nary', -codec_pair => {
    digits    => [  2 .. 9, 'A', 'C' .. 'R', 'T' .. 'Z' ],
    predecode => sub { my $s = $_[0]; $s =~ tr/01SBsb/OIFPFP/; return $s },
  });
}

is(
  encode('1'),
  '3',
  "We skip one and zero so should end up with 3 when encoding 1"
);

is(encode('12354'),  'F44');
is(encode('123456'), '5RL2');
is(decode('5RL2'),   '123456');

is(decode(encode('123456')), '123456');

is(decode('1234'), decode('I234'));
is(decode('10SB'), decode('IOFP'));

is(eval { encode('A') }, undef);

