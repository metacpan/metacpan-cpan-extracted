#!/usr/bin/perl

use strict;
my %test_arg;
my %TESTS;
BEGIN {
%TESTS = (
  '001 basic test' => {
    prompt => 'Fruit: ',
    choices => [ qw(Apple Banana Cherry Duriam) ],
    'IN' => "A\t\r",
    'OUT' => "Fruit: Apple\r\n",
    'RESULT' => 'Apple'
  },
  '002 help text and backspace' => {
    prompt => 'Fruit: ',
    choices => [ qw(Apple Banana Cherry Duriam) ],
    helptext => "Do you like nice fruit?\n",
    'IN' => "\chR\chB\t\r",
    'OUT' => "Do you like nice fruit?\r\nFruit: R\ch \chBanana\r\n",
    'RESULT' => 'Banana'
  },
  '003 unknown escape' => {
    prompt => 'Fruit: ',
    choices => [ qw(Apple Banana Cherry Duriam) ],
    'IN' => "\c[C\t\r",
    'OUT' => "Fruit: Cherry\r\n",
    'RESULT' => 'Cherry'
  },
  '004 double tab with bell' => {
    prompt => 'Fruit: ',
    choices => [ qw(Apple Banana Cherry Coconut Duriam) ],
    'IN' => "C\t\to\t\r",
    'OUT' => "Fruit: C\a\r\nCherry  Coconut \r\nFruit: Coconut\r\n",
    'RESULT' => 'Coconut'
  },
  '005 kill line and list choices' => {
    prompt => 'Fruit: ',
    choices => [ qw(Apple Banana Cherry Duriam) ],
    'IN' => "\cuX\t\cu\cdD\t\r",
    'OUT' => "Fruit: X\a\r\nFruit: \r\nApple  Banana Cherry Duriam \r\nFruit: Duriam\r\n",
    'RESULT' => 'Duriam'
  },
  '006 cycle choices' => {
    prompt => 'Fruit: ',
    choices => [ qw(Apple Banana Cherry Duriam) ],
    'IN' => "\cn\cp\cp\cu\cp\cn\cn\r",
    'OUT' => "Fruit: Apple\ch \ch\ch \ch\ch \ch\ch \ch\ch \chDuriam\ch \ch\ch \ch\ch \ch\ch \ch\ch \ch\ch \chCherry\r\nFruit: Duriam\ch \ch\ch \ch\ch \ch\ch \ch\ch \ch\ch \chApple\ch \ch\ch \ch\ch \ch\ch \ch\ch \chBanana\r\n",
    'RESULT' => 'Banana'
  },
  '007 custom validate' => {
    prompt => 'Fruit: ',
    choices => [ qw(Apple Banana Cherry Duriam) ],
    validate => [ 'Must contain an "a"' => sub { $_[0] =~ /a/i ? $_[0] : undef } ],
    'IN' => "C\t\r\cuA\t\r",
    'OUT' => qq{Fruit: Cherry\r\nMust contain an "a"\r\nFruit: Cherry\r\nFruit: Apple\r\n},
    'RESULT' => 'Apple'
  },
  '008 validate lowercase' => {
    prompt => 'Fruit: ',
    choices => [ qw(Apple Banana Cherry Duriam) ],
    validate => 'lowercase',
    'IN' => "Ba\t\r",
    'OUT' => qq{Fruit: Banana\r\n},
    'RESULT' => 'banana'
  },
  '009 validate uppercase' => {
    prompt => 'Fruit: ',
    choices => [ qw(Apple Banana Cherry Duriam) ],
    validate => 'uppercase',
    'IN' => "Ba\t\r",
    'OUT' => qq{Fruit: Banana\r\n},
    'RESULT' => 'BANANA'
  },
  '010 validate match_one at start' => {
    prompt => 'Fruit: ',
    choices => [ qw(Apple Banana Cherry Coconut Duriam) ],
    validate => 'match_one',
    'IN' => "Rp\r\cuC\r\chAp\r",
    'OUT' => qq{Fruit: Rp\r\nERROR: Answer 'Rp' does not match a unique item!\r\nFruit: Rp\r\nFruit: C\r\nERROR: Answer 'C' does not match a unique item!\r\nFruit: C\ch \chAp\r\n},
    'RESULT' => 'Apple'
  },
  '011 validate match_one anywhere' => {
    prompt => 'Fruit: ',
    choices => [ qw(Apple Banana Cherry Duriam) ],
    validate => 'match_one',
    'IN' => "r\rr\r",
    'OUT' => qq{Fruit: r\r\nERROR: Answer 'r' does not match a unique item!\r\nFruit: rr\r\n},
    'RESULT' => 'Cherry'
  },
  '012 validate nonempty' => {
    prompt => 'Fruit: ',
    choices => [ qw(Apple Banana Cherry Duriam) ],
    validate => 'nonempty',
    'IN' => "\rPear\r",
    'OUT' => qq{Fruit: \r\nERROR: Empty input not allowed!\r\nFruit: Pear\r\n},
    'RESULT' => 'Pear'
  },
  '013 validate nonblank' => {
    prompt => 'Fruit: ',
    choices => [ qw(Apple Banana Cherry Duriam) ],
    validate => 'nonblank',
    'IN' => "\r \rPear  \r",
    'OUT' => qq{Fruit: \r\nERROR: Blank input not allowed!\r\nFruit:  \r\nERROR: Blank input not allowed!\r\nFruit: Pear  \r\n},
    'RESULT' => 'Pear'
  },
  '014 validate fromchoices' => {
    prompt => 'Number: ',
    choices => [ qw(123 231 312), undef ],
    validate => 'fromchoices,integer',
    'IN' => "\r222\r\cu\t\t3\r\t\r",
    'OUT' => qq{Number: \r\nERROR: Value must be an integer number!\r\nNumber: 222\r\nERROR: You must choose one item from the list!\r\nNumber: 222\r\nNumber: \a\r\n123 231 312 \r\nNumber: 3\r\nERROR: You must choose one item from the list!\r\nNumber: 312\r\n},
    'RESULT' => '312'
  },
  '015 validate numeric' => {
    prompt => 'Voltage: ',
    choices => [ qw(1.5 3.3 5.0) ],
    validate => 'numeric',
    'IN' => "Apple\r\cu3\t\r",
    'OUT' => qq{Voltage: Apple\r\nERROR: Value must be numeric!\r\nVoltage: Apple\r\nVoltage: 3.3\r\n},
    'RESULT' => '3.3'
  },
  '016 validate integer' => {
    prompt => 'Prime: ',
    choices => [ qw(2 3 5 7 11 13 17 19 23 31) ],
    validate => 'integer',
    'IN' => "prime\r\cu1.5\r\cu-7\r",
    'OUT' => qq{Prime: prime\r\nERROR: Value must be an integer number!\r\nPrime: prime\r\nPrime: 1.5\r\nERROR: Value must be an integer number!\r\nPrime: 1.5\r\nPrime: -7\r\n},
    'RESULT' => '-7'
  },
  '017 validate nonzero' => {
    prompt => 'Voltage: ',
    choices => [ qw(1.5 3.3 5.0) ],
    validate => 'nonzero',
    'IN' => "0\r\ch-0\r\cu0.000\r\cu1\r",
    'OUT' => qq{Voltage: 0\r\nERROR: Value must be a non-zero value!\r\nVoltage: 0\ch \ch-0\r\nERROR: Value must be a non-zero value!\r\nVoltage: -0\r\nVoltage: 0.000\r\nERROR: Value must be a non-zero value!\r\nVoltage: 0.000\r\nVoltage: 1\r\n},
    'RESULT' => '1'
  },
  '018 validate positive' => {
    prompt => 'Voltage: ',
    choices => [ qw(1.5 3.3 5.0) ],
    validate => 'positive',
    'IN' => "-1\r\cu-0.06\r\cu0.5\r",
    'OUT' => qq{Voltage: -1\r\nERROR: Value must be a positive value!\r\nVoltage: -1\r\nVoltage: -0.06\r\nERROR: Value must be a positive value!\r\nVoltage: -0.06\r\nVoltage: 0.5\r\n},
    'RESULT' => '0.5'
  },
  "019 poor man's choice list" => {
    prompt => 'Fruit: ',
    choices => [ qw(Apple Banana Cherry Duriam) ],
    columns => 0,
    'IN' => "\cdD\t\r",
    'OUT' => "Fruit: \r\nApple\r\nBanana\r\nCherry\r\nDuriam\r\nFruit: Duriam\r\n",
    'RESULT' => 'Duriam'
  },
  '020 many completion items' => {
    prompt => 'Word: ',
    columns => 30, rows => 5,
    'IN' => "\t\t \r\rqyo\tr\r",
    'OUT' => <<"EOT",
Word: \a\r
a              ahead          \r
air            alibis         \r
all            and            \r
any            are            \r
--more--\ch \ch\ch \ch\ch \ch\ch \ch\ch \ch\ch \ch\ch \ch\ch \chat             away           \r
back           be             \r
beast          before         \r
bell           boys           \r
bring          but            \r
--more--\ch \ch\ch \ch\ch \ch\ch \ch\ch \ch\ch \ch\ch \ch\ch \chcalifornia     called         \r
--more--\ch \ch\ch \ch\ch \ch\ch \ch\ch \ch\ch \ch\ch \ch\ch \chcalling        calls          \r
--more--\ch \ch\ch \ch\ch \ch\ch \ch\ch \ch\ch \ch\ch \ch\ch \chWord: yo\aur\r
EOT
    'RESULT' => 'your'
  },
  '021 no choices' => {
    prompt => 'Fruit: ',
    choices => [],
    'IN' => "\cdOrange\r",
    'OUT' => "Fruit: \r\nFruit: Orange\r\n",
    'RESULT' => 'Orange'
  },
  '022 unknown escape character' => {
    prompt => 'Fruit: ',
    choices => [ qw(Apple Banana Cherry Duriam) ],
    'IN' => "A\ce\t\r",
    'OUT' => "Fruit: A\apple\r\n",
    'RESULT' => 'Apple'
  },
  '023 wipe as no-op' => {
    prompt => 'Fruit: ',
    choices => [ qw(Apple Banana Cherry Duriam) ],
    'IN' => "A\t\cw\r",
    'OUT' => "Fruit: Apple\r\n",
    'RESULT' => 'Apple'
  },
);


  %test_arg = ( tests => 1 + 3 * keys(%TESTS) );
  eval { require IO::String; };
  if($@) {
    %test_arg = (skip_all => 'IO::String is required for testing Term::Completion');
  }
}
use Test::More %test_arg;

use_ok('Term::Completion');

# must do this here, when DATA is initialized
$TESTS{'020 many completion items'}{choices} = [map { /(\S+)/ } <DATA>];

foreach my $test (sort keys %TESTS) {
  my %arg = %{$TESTS{$test}};
  my $in = delete($arg{IN}) . "END\n";
  my $in_fh = IO::String->new($in);
  my $out = '';
  my $out_fh = IO::String->new($out);
  my $expected_out = delete($arg{OUT});
  my $expected_result = delete($arg{RESULT});

  my $result = Term::Completion->new(
        in => $in_fh,
        out => $out_fh,
        columns => 80, rows => 24, # to suppress Term::Size on IO::String
        %arg
  )->complete();

  is($result, $expected_result, "$test: complete() returned correct value");
  is($out, $expected_out, "$test: correct data sent to terminal");
  $out =~ s#\t#\\t#g;
  $out =~ s#\r#\\r#g;
  $out =~ s#\n#\\n#g;
  $out =~ s#\a#\\a#g;
  $out =~ s#\ch#\\ch#g;
  $out =~ s#([\x00-\x1f])#sprintf("%%%02x",ord($1))#ge;
  #diag("out = '$out'\n");
  my $in_rest = <$in_fh>;
  is($in_rest, "END\n", "$test: input stream correctly used up");
} # loop tests

exit 0;

__DATA__
a
ahead
air
alibis
all
and
any
are
at
away
back
be
beast
before
bell
boys
bring
but
california
called
calling
calls
can
cannot
candle
captain
ceiling
chambers
champagne
checkout
colitas
cool
corridor
could
courtyard
dance
dark
desert
device
dim
distance
door
doorway
down
face
far
feast
find
for
forget
friends
from
gathered
got
grew
had
hair
have
he
head
hear
heard
heaven
heavy
hell
her
here
highway
hotel
how
i
ice
in
is
it
just
kill
knives
last
leave
light
like
lit
living
lot
lovely
man
master
me
mercedes-benz
middle
mind
mirrors
mission
my
myself
never
nice
night
nineteen
not
of
on
or
our
own
passage
pink
place
please
plenty
pretty
prisoners
programmed
receive
relax
remember
rising
room
running
said
saw
say
she
shimmering
showed
sight
since
sixty-nine
smell
so
some
spirit
stab
steely
still
stood
stop
such
summer
surprise
sweat
sweet
that
the
their
them
then
there
they
thing
thinking
this
those
thought
through
tiffany
time
to
twisted
ungh
up
voices
wake
warm
was
way
we
welcome
were
what
wind
wine
with
year
you
your
