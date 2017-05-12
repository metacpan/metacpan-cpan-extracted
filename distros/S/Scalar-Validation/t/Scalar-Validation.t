# Perl
#
# Tests of Scalar::Validation
#
# Sat Sep 27 12:26:36 2014

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Scalar::Validation qw (:all);

use FileHandle;

# ------------------------------------------------------------------------------
# start testing

sub die_bla {
    validate (die_bla_param => PositiveInt => '+');
    warn "Not reached ...\n";
}

# ------------------------------------------------------------------------------
# test of declare_rule() => ok

is (declare_rule (
        Positive => -where   => sub { $_ >= 0 },
                    -message => sub { "value $_ is not a positive integer" },
) => Positive => "declare_rule (Positive)");

is (declare_rule (
        Bool01 => -where    => sub { defined $_ && ($_ eq '0' || $_ eq '1') },
                  -message => sub { "value $_ is not a bool value ( 0 or 1 )" },
) => Bool01 => "declare_rule (Bool01)");

is (declare_rule (
    enum align => qw (Left l Center c right R)
) => align => "declare_rule (align)");

is (declare_rule (
    Enum Align => qw (left l Center C right r)
) => Align => "declare_rule (Align)");

eval {
        is (declare_rule (
                Enum_explained (Align1 =>  
                        # value => alias? => description => 1 # using alias requires description
                        # value => description? => 1 
        left   => l => "Align left in cell"   => 1,
        center => C => "Align center in cell" => 1,
        Right  => R => "Align right in cell"  => 1,
    )) => Align1 => "declare_rule (Align1)");
};

is (declare_rule (
    enum_explained ( align1 => 
        # value => alias? => description => 1 # using alias requires description
        # value => description? => 1 
        left   => l => "Align left in cell"   => 1,
        center => c => "Align center in cell" => 1,
        Right  => R => "Align right in cell"  => 1,
    )) => align1 => "declare_rule (align1)");

is (declare_rule (
    Blubber => -as      => 'Bla',
               -where   => sub { $_ < 0 },
               -message => sub { "value $_ is not a negative integer" })
                => Blubber => "declare_rule (Blubber)");

is (declare_rule (
    Any => -where   => sub { 1; },
           -message => sub { "No problem!!"})
           => Any => "declare_rule (Any)");
    
is (declare_rule (
    Wrong => -where   => sub { 0; },
             -message => sub { "Every time a problem!!"})
             => Wrong => "declare_rule (Wrong)");

is (rule_known(align  => 1) => align => "rule_known(align)  = 'align'");
is (rule_known(blabla => 1) => ''    => "rule_known(blabla) = ''");
is (rule_known(0)           => ''    => "rule_known(0)      = ''");

declare_rule (
    Blub1 => -as      => 'Int',
             -where   => sub { $_ < 0 },
             -message => sub { "value $_ is not a negative integer" });

is (is_valid (blub1 => Blub1 => -1) => 1 => "Test rule Blub1");

is (replace_rule (
    Blub1 => -as      => 'Int',
             -where   => sub { $_ > 0 },
             -message => sub { "value $_ is not a positive integer" })
             => Blub1 => "replace_rule (Blub1 => ...)");

is (is_valid (blub1 => Blub1 => 1) => 1 => "Test replaced rule Blub1");

is (delete_rule('Blub1') => Blub1 => "delete_rule('Blub1')");

# ------------------------------------------------------------------------------
# test of rule_known()

throws_ok {
    rule_known ();
} qr/rule to search not set/o,
    "rule_known (): detect that rule is missing";

throws_ok {
    rule_known ('');
} qr/rule to search not set/o,
    "rule_known (''): detect that rule is missing";

# ------------------------------------------------------------------------------
# test of declare_rule() => dies

throws_ok {
    declare_rule ();
} qr/rule to declare not set/o,
    "declare_rule (): detect that rule is missing";

throws_ok {
    declare_rule ('');
} qr/rule to declare not set/o,
    "declare_rule (''): detect that rule is missing";

throws_ok {
    declare_rule ('Int');
} qr/rule 'Int': already defined/o,
    "detect that rule 'Int' is already defined";

throws_ok {
    declare_rule (blubber => 1, 2);
} qr/rule 'blubber': where condition is missing/o,
    "detect that where condition is missing";

throws_ok {
    declare_rule (blubber => -where => 2);
} qr/rule 'blubber': where condition is not a code reference: '2'/o,
    "detect that '2' as where condition is not a code reference";

throws_ok {
    declare_rule (blubber => -where => new FileHandle);
} qr/rule 'blubber': where condition is not a code reference:/o,
    "detect that FileHandle as where condition is not a code reference";

declare_rule (blubber =>
              -where => sub { lc($_) eq 'blubb!' },
              # no message!
          );

# ------------------------------------------------------------------------------
# test of validate() => ok

is (validate (parameter => Defined => ''),         '',  "(Defined => '')");
is (validate (parameter => Defined => 0),           0,  "(Defined => 0)");
is (validate (parameter => Defined => 1),           1,  "(Defined => 1)");
is (validate (parameter => Defined => 'text'), 'text',  "(Defined => text)");

is (validate (parameter => Filled   => 0),           0, "(Filled => 0)");
is (validate (parameter => Filled   => 1),           1, "(Filled => 1)");
is (validate (parameter => Filled   => 'text'), 'text', "(Filled => text)");

is (validate (parameter => Empty    => undef), undef,   "(Empty    => undef)");
is (validate (parameter => Empty    => ''),       '',   "(Empty    => '')");

is (validate (parameter => Optional => undef), undef,   "(Optional  => undef)");
is (validate (parameter => Optional => 123),     123,   "(Optional  => 123)");

is (validate (parameter => String   => ''),       '',   "(String   => '')");
is (validate (parameter => String   => 0),         0,   "(String   => 0)");
is (validate (parameter => String   => 1),         1,   "(String   => 1)");

is (validate (parameter => Int   => '0'),  0, "(Int   =>  '0')");
is (validate (parameter => Int   =>  1),   1, "(Int   =>   1)");
is (validate (parameter => Int   =>  17), 17, "(Int   =>  17)");

is (validate (parameter => Even  =>  16), 16, "(Even  =>  16)");

is (validate (parameter => Scalar   => undef), undef,  "(Scalar   => undef)");
is (validate (parameter => Scalar   => ''),       '',  "(Scalar   => '')");
is (validate (parameter => Scalar   => 0),         0,  "(Scalar   => 0)");
is (validate (parameter => Scalar   => 1),         1,  "(Scalar   => 1)");

my $fh = new FileHandle;

ok (validate (parameter => Ref      => [1 ,  2]),      "(Ref      => [1, 2])");
ok (validate (parameter => Ref      => $fh),           "(Ref      => FileHandle");
ok (validate (parameter => ArrayRef => [1 ,  2]),      "(ArrayRef => [1, 2])");
ok (validate (parameter => HashRef  => {1 => 2}),      "(HashRef  => {1 => 2})");
ok (validate (parameter => CodeRef  => sub {1}),       "(CodeRef  => sub {1})");

is (validate (parameter => Bool     => undef), undef,  "(Bool     => undef)");
is (validate (parameter => Bool     => ''),       '',  "(Bool     => '')");
is (validate (parameter => Bool     => 'a'),     'a',  "(Bool     => 'a')");
is (validate (parameter => Bool     => 0),         0,  "(Bool     => 0)");
is (validate (parameter => Bool     => 1),         1,  "(Bool     => 1)");
is (validate (parameter => Bool     => 2),         2,  "(Bool     => 2)");
is (validate (parameter => Bool01   => 0),         0,  "(Bool01   => 0)");
is (validate (parameter => Bool01   => 1),         1,  "(Bool01   => 1)");

is (validate (parameter => Any      => 1),         1,  "(Any      => 1)");
is (validate (parameter => Positive => 1),         1,  "(Positive => 1)");

is (validate (my_float   => Float       => "123.789"), 123.789, "(Float       => 123.789)");

is (validate (parameter => PositiveInt => 123),                     123, "(PositiveInt => 123)");
is (validate (parameter => PositiveInt => +0),                        0, "(PositiveInt => +0)");
is (validate (parameter => Float => '0'),                             0, "(Float => '0')");
is (validate (parameter => Float => '123.1'),                     123.1, "(Float => '123.1')");
is (validate (parameter => Float => '1E4')+0,                       1E4, "(Float => '1E4')");
is (validate (parameter => Float => '-123'),                       -123, "(Float => '-123')");
is (validate (parameter => Float => '+123E-3')+0,               +123E-3, "(Float => '+123E-3')");
is (validate (parameter => Float => 123.1e+3),                   123100, "(Float => 123.1e+3)");
                                                 
is (validate (parameter => Align => 'left'),                     'left', "(Align => 'left')");
is (validate (parameter => Align => 'C'),                           'C', "(Align => 'C')");
is (validate (parameter => align => 'Left'),                     'Left', "(align => 'Left')");
is (validate (parameter => align => 'R'),                           'R', "(align => 'R')");
                                                 
is (validate (parameter => Align1 => 'left'),                    'left', "(Align1 => 'left')");
is (validate (parameter => Align1 => 'C'),                          'C', "(Align1 => 'C')");
is (validate (parameter => align1 => 'Left'),                    'Left', "(align1 => 'Left')");
is (validate (parameter => align1 => 'R'),                          'R', "(align1 => 'R')");
                                                 
is (validate (parameter => PositiveFloat => 1),                       1, "(PositiveFloat => 1)");
is (validate (parameter => PositiveFloat => 123.1)            ,   123.1, "(PositiveFloat => 123.1)");
is (validate (parameter => PositiveFloat => '123.1E-200')+0, 123.1E-200, "(PositiveFloat => '123.1E-200')");

is (validate (parameter => blubber => 'blubb!'),               'blubb!', "(blubber => 'blubb!')");

is (validate (parameter => NegativeInt => '-121'),                 -121, "(NegativeInt => '-121')");
is (validate (parameter => PositiveFloat => 123.1E-70),       123.1E-70, "(PositiveFloat => 123.1E-70)");

is (validate (parameter => Float => '123'),                         123, "(Float => '123')");
is (validate (parameter => PositiveFloat => 1),                       1, "(PositiveFloat => 1)");

is (validate (parameter => -And => [Int => 'Float'], '123'),                123, "([Int => 'Float'] => '123')");
is (validate (parameter => -And => [Int => Float => 0], '123'),             123, "([Int => 'Float' => 0] => '123')");

is (validate (parameter => -And => ['Optional'], undef),                  undef, "(-And => [Optional] => undef)");
is (validate (parameter => -And => ['Optional'], 123),                      123, "(-And => [Optional] => 123)");
is (validate (parameter => -And => [Optional => 0], undef),               undef, "(-And => [Optional  => 0] => undef)");
is (validate (parameter => -And => [Optional => 0], 123),                   123, "(-And => [Optional  => 0] => 123)");
is (validate (parameter => -Optional => -And => [Int => 'Float'], undef),  undef, "(-Optional => -And => [Int => 'Float'] => undef)");
is (validate (parameter => -Optional => -And => [Int => 'Float'], 123),      123, "(-Optional => -And => [Int => 'Float'] => 123)");
is (validate (parameter => -Default => 456 => -And => [Int => 'Float'], undef), 456, "(-Default => 456 => -And => [Int => 'Float'] => undef) => 456");
is (validate (parameter => -Default => 456 => -And => [Int => 'Float'],    ''), 456, "(-Default => 456 => -And => [Int => 'Float'] =>    '') => 456");
is (validate (parameter => -Default => 456 => -And => [Int => 'Float'],     0),   0, "(-Default => 456 => -And => [Int => 'Float'] =>     0) =>   0");
is (validate (parameter => -Default => 456 => -And => [Int => 'Float'],   123), 123, "(-Default => 456 => -And => [Int => 'Float'] =>   123) => 123");

is (validate (parameter => -Or => [Int => CodeRef => 0], 123),               123, "(-Or => [Int => CodeRef => 0], 123)");
ok (validate (parameter => -Or => [Int => CodeRef => 0], sub { 0; }),             "(-Or => [Int => CodeRef => 0], sub)");

is (validate (parameter => -Or => [Int => sub { $_ > 12 } => 0],  5  ),      5  , '-Or => [Int => sub { $_ > 12 } => 0],  5)');
is (validate (parameter => -Or => [Int => sub { $_ > 12 } => 0], 12.1),     12.1, '-Or => [Int => sub { $_ > 12 } => 0], 12.1)');

is (validate (parameter => -Or => [Int => {
        -where   => sub { $_ && $_ > 12 },
        -message => sub { "$_ is not > 12" }}],                   5  ),      5,   '-Or => [Int => { -where => sub { $_ > 12 } => 0] ...},  5)');

is (validate (parameter => -Or => [Int => {
        -where   => sub { $_ && $_ > 12 },
        -message => sub { "$_ is not > 12" }}],                  12.2),     12.2, '-Or => [Int => { -where => sub { $_ > 12 } => 0] ...}, 12.1)');

is (validate (parameter => -Enum => {a => 1, b => 1, c => 1}, 'a'),          'a', "(-Enum => {a => 1, b => 1, c => 1}, 'a')");
is (validate (parameter => -Enum => {a => 1, b => 1, c => 1}, 'b'),          'b', "(-Enum => {a => 1, b => 1, c => 1}, 'b')");
is (validate (parameter => -Enum => {a => 1, b => 1, c => 1}, 'c'),          'c', "(-Enum => {a => 1, b => 1, c => 1}, 'c')");

is (validate (parameter => -Range => [1,3] => Int => 1),                       1, "(-Range => [1,3] => Int => 1)"); 
is (validate (parameter => -Range => [1,3] => Int => 2),                       2, "(-Range => [1,3] => Int => 2)"); 
is (validate (parameter => -Range => [1,3] => Int => 3),                       3, "(-Range => [1,3] => Int => 3)"); 

is (validate (parameter => -Range => [1,3] => Float => 1),                     1,   "(-Range => [1,3] => Float => 1  )"); 
is (validate (parameter => -Range => [1,3] => Float => 1.1),                   1.1, "(-Range => [1,3] => Float => 1.1)"); 
is (validate (parameter => -Range => [1,3] => Float => 2),                     2,   "(-Range => [1,3] => Float => 2  )"); 
is (validate (parameter => -Range => [1,3] => Float => 2.9),                   2.9, "(-Range => [1,3] => Float => 2.9)"); 
is (validate (parameter => -Range => [1,3] => Float => 3),                     3,   "(-Range => [1,3] => Float => 3  )"); 

is (par      (parameter => -Range => [1,3] => Float => 3),                     3,   "par(-Range => [1,3] => Float => 3)");

my $opt_ref = {-parameter => 3};
is (npar      (-parameter => -Range => [1,3] => Float => $opt_ref),            3,   "npar( -parameter => \$opt_ref => -Range => [1,3] => Float )"); 

$opt_ref = {-parameter => 3};
is (npar    ([ -parameter => -Range => [1,3] => Float => $opt_ref ]),          3,   "npar([-parameter => \$opt_ref => -Range => [1,3] => Float])"); 

$opt_ref = {-parameter => 3};
is (npar    ([ -parameter => -Range => [1,3] => Float => $opt_ref ],{-bla => 1}), 3, "npar([-parameter => \$opt_ref => -Range => [1,3] => Float] => {-bla => 1})"); 

is (is_valid (parameter => PositiveFloat => 1.1),           1, " is_valid(PositiveFloat =>  1.1)");
is (is_valid (parameter => PositiveFloat => -1.1),          0, "!is_valid(PositiveFloat => -1.1)");
is (is_valid (parameter => PositiveFloat => 'a'),           0, "!is_valid(PositiveFloat =>  'a')");

is (is_valid (parameter => -Range => [1,3] => Int => -1),   0, "!is_valid(-Range => [1,3] => Int => -1)"); 
is (is_valid (parameter => -Range => [1,3] => Int => 0),    0, "!is_valid(-Range => [1,3] => Int => 0)"); 
is (is_valid (parameter => -Range => [1,3] => Int => 1),    1, " is_valid(-Range => [1,3] => Int => 1)"); 
is (is_valid (parameter => -Range => [1,3] => Int => 1.1),  0, "!is_valid(-Range => [1,3] => Int => 1.1)"); 
is (is_valid (parameter => -Range => [1,3] => Int => 4),    0, "!is_valid(-Range => [1,3] => Int => 4)"); 
is (is_valid (parameter => -Range => [1,3] => Int => 'a'),  0, "!is_valid(-Range => [1,3] => Int => a)"); 

is (is_valid (parameter => -Range => [1,3] => Float => 0.99999999), 0, "!is_valid(-Range => [1,3] => Float => 0.99999999)"); 
is (is_valid (parameter => -Range => [1,3] => Float => 1.00000000), 1, " is_valid(-Range => [1,3] => Float => 1.00000000)"); 
is (is_valid (parameter => -Range => [1,3] => Float => 2),          1, " is_valid(-Range => [1,3] => Float => 2         )"); 
is (is_valid (parameter => -Range => [1,3] => Float => 3.00000000), 1, " is_valid(-Range => [1,3] => Float => 3.00000000)"); 
is (is_valid (parameter => -Range => [1,3] => Float => 4.00000001), 0, "!is_valid(-Range => [1,3] => Float => 4.00000001)"); 
is (is_valid (parameter => -Range => [1,3] => Float => 'a'),        0, "!is_valid(-Range => [1,3] => Float => a         )");

is (is_valid (parameter => equal_to   4   => Int    =>   4),        1, " is_valid(equal_to ( 4   => Int    => 4)");
is (is_valid (parameter => equal_to   5.1 => Float  => 5.1),        1, " is_valid(equal_to ( 5.1 => Float  => 5.1)");
is (is_valid (parameter => equal_to   'a' => String => 'a'),        1, " is_valid(equal_to ( 'a' => String => 'a')");

is (is_valid (parameter => greater_than  4 => Int   => 5),          1, " is_valid(greater_than 4 => Int => 5)");
is (is_valid (parameter => greater_than (4 => Float => 3.1)),       0, "!is_valid(greater_than (4 => Float => 3.1))");

is (is_valid (parameter => greater_equal  4 => Int   => 4),         1, " is_valid(greater_equal 4 => Int => 4)");
is (is_valid (parameter => greater_equal  4 => Int   => 5),         1, " is_valid(greater_equal 4 => Int => 5)");
is (is_valid (parameter => greater_equal (4 => Float => 3.1)),      0, "!is_valid(greater_equal (4 => Float => 3.1))");

is (is_valid (parameter => less_than  4 => Int   => 3),             1, " is_valid(less_than 4 => Int => 3)");
is (is_valid (parameter => less_than (4 => 'Float') => 4.1),        0, "!is_valid(less_than (4 => 'Float') => 4.1)");

is (is_valid (parameter => less_equal  4 => Int   => 4.0),          1, " is_valid(less_equal 4 => Int => 4.0)");
is (is_valid (parameter => less_equal  4 => Int   => 3),            1, " is_valid(less_equal 4 => Int => 3)");
is (is_valid (parameter => less_equal (4 => 'Float') => 4.1),       0, "!is_valid(less_equal (4 => 'Float') => 4.1)");

is (is_valid (parameter => g_t  4 => Int   => 5),          1, " is_valid(g_t  4 => Int => 5)");
is (is_valid (parameter => g_t (4 => Float => 3.1)),       0, "!is_valid(g_t (4 => Float => 3.1))");

is (is_valid (parameter => g_e  4 => Int   => 4),          1, " is_valid(g_e  4 => Int => 4)");
is (is_valid (parameter => g_e  4 => Int   => 5),          1, " is_valid(g_e  4 => Int => 5)");
is (is_valid (parameter => g_e (4 => Float => 3.1)),       0, "!is_valid(g_e (4 => Float => 3.1))");

is (is_valid (parameter => l_t  4 => Int   => 3),          1, " is_valid(l_t  4 => Int => 3)");
is (is_valid (parameter => l_t (4 => 'Float') => 4.1),     0, "!is_valid(l_t (4 => 'Float') => 4.1)");

is (is_valid (parameter => l_e  4 => Int   => 4),          1, " is_valid(l_e  4 => Int => 4)");
is (is_valid (parameter => l_e  4 => Int   => 3),          1, " is_valid(l_e  4 => Int => 3)");
is (is_valid (parameter => l_e (4 => 'Float') => 4.1),     0, "!is_valid(l_e (4 => 'Float') => 4.1)");

$fh = new FileHandle();
is (is_valid (parameter => is_a FileHandle => $fh),        1, ' is_valid(is_a FileHandle => $fh)');
is (is_valid (parameter => is_a FileHandle => \$fh),       0, '!is_valid(is_a FileHandle => \$fh)');
is (is_valid (parameter => is_a FileHandle => undef),      0, "!is_valid(is_a FileHandle => undef)");
is (is_valid (parameter => is_a Bla        => 0),          0, "!is_valid(is_a Bla        => 0)");
is (is_valid (parameter => is_a Bla        => 1),          0, "!is_valid(is_a Bla        => 1)");
is (is_valid (parameter => is_a Bla        => []),         0, "!is_valid(is_a Bla        => [])");
is (is_valid (parameter => is_a Bla        => {}),         0, "!is_valid(is_a Bla        => {})");
is (is_valid (parameter => is_a Bla        => $fh),        0, '!is_valid(is_a Bla        => $fh)');

is (is_valid (parameter => Class => $fh), 1, ' is_valid(Class => $fh)');
is (is_valid (parameter => Class => 123), 0, '!is_valid(Class => 123)');

is (is_valid (free_where_greater_zero => sub { $_ && $_ > 0} => 2),  1, ' is_valid (free => sub { $_ && $_ > 0} => 2');
is (is_valid (free_where_greater_zero => sub { $_ && $_ > 0} => 0),  0, ' is_valid (free => sub { $_ && $_ > 0} => 0');

is (is_valid (free_rule_greater_zero => {
        -where   => sub { $_ && $_ > 0},
        -message => sub { "$_ is not > 0" }}                        => 2),  1, ' is_valid (%hash => { -where => sub { $_ && $_ > 0}} => 2');

is (is_valid (free_rule_greater_zero => {
        -where   => sub { $_ && $_ > 0},
        -message => sub { "$_ is not > 0" }}                            => 0),  0, ' is_valid (%hash => { -where => sub { $_ && $_ > 0}} => 0');

is (validate_and_correct ([parameter => Float => 78.9],
                                                  {-default => 3.14159}),
        78.9, "validate_and_correct ([parameter => ([Float => 78.9]     {-default => ...}");

is (validate_and_correct ([parameter => Float => undef],
                                                  {-default => 3.14159}),
        3.14159, "validate_and_correct ([parameter => ([Float => undef]    {-default => ...}");

is (validate_and_correct ([parameter => Float => '123.1a'],
                                                  {-correction => sub { return $1 if /([\.\d]+)/; }
                                           }), 123.1, "validate_and_correct ([parameter => ([Float => '123.1a'] {-correction => ...}");

is (validate_and_correct ([parameter => Float => undef],
                                                  {-default => 3.14159,
                                                   -correction => sub { return $1 if /([\.\d]+)/; }
                                           }), 3.14159, "validate_and_correct ([parameter => ([Float => undef]    {-default => ... -correction => ...}");

is (validate_and_correct ([parameter => Float => undef],
                                                  {-default => '123.1a',
                                                   -correction => sub { return $1 if /([\.\d]+)/; }
                                           }), 123.1, "validate_and_correct ([parameter => ([Float => undef]    {-default => '123.1a', -correction => ...}");

is (validate_and_correct ([parameter => -Or => [Int => Float => 0] => '7.1a' ],
                                                  {-default => 3.14159,
                                                   -correction => sub { return 2; }
                                           }), 2, "validate_and_correct ([-Or => [Int => Float => 0] => 7.1a]    {-default => ... -correction => ...}");

is (validate_and_correct ([parameter => -Range => [1, 5] => Int => 7.1 ],
                                                  {-default => 3.14159,
                                                   -correction => sub { return 2; }
                                           }), 2, "validate_and_correct ([-Range => [1, 5] => Int => 7.1]    {-default => ... -correction => ...}");

is (validate_and_correct ([parameter => -Enum => {1 => 1, 2 => 2, 3 => 3} => 7.1 ],
                                                  {-default => 3.14159,
                                                   -correction => sub { return 2; }
                                           }), 2, "validate_and_correct ([-Enum => {1 => 1, 2 => 2, 3 => 3} => 7.1]    {-default => ... -correction => ...}");


# ------------------------------------------------------------------------------
# test of validate() => dies

throws_ok {
    validate (parameter => Wrong => 1);
} qr/Every time a problem!!/o,
    "Every time not valid: (Wrong => 1)";

throws_ok {
        validate (parameter => Scalar => sub { ; });
} qr/is not a scalar/o,
    "detect not valid: (Scalar => sub)";

throws_ok {
        validate (parameter => String => undef);
} qr/value <undef> is not a string/o,
    "detect not valid: (String => undef)";

throws_ok {
    validate (parameter => Filled => undef);
} qr/value is not set/o,
    "detect not valid: (Filled => undef)";

throws_ok {
    validate (parameter => Filled => '');
} qr/value is not set/o,
    "detect not valid: (Filled => '')";

throws_ok {
    validate (parameter => Int => undef);
} qr/value <undef> is not an integer/o,
    "detect not valid: (Int => undef)";

throws_ok {
    validate (parameter => Empty => 0);
} qr/value '0' has to be empty/o,
    "detect not valid: (Empty => 0)";

throws_ok {
    validate (parameter => Empty => 1);
} qr/value '1' has to be empty/o,
    "detect not valid: (Empty => 1)";

throws_ok {
    validate (parameter => Empty => sub {});
} qr/value 'CODE\(0x\w+\)' has to be empty/o,
    "detect not valid: (Empty => sub {})";

throws_ok {
    validate (parameter => blubber => 'bla');
} qr/Value 'bla' is not valid for rule 'blubber'/o,
    "detect not valid: (blubber => 'bla')";

throws_ok {
    validate (parameter => Align => 'Left');
} qr/value 'Left' unknown, allowed values are:/o,
        "detect not valid: (Align => 'Left')";

throws_ok {
    validate (parameter => align => 'Bla');
} qr/value 'Bla' unknown, allowed values \(transformed to lower case\) are:/o,
        "detect not valid: (align => 'Bla')";

throws_ok {
    validate (parameter => Align1 => 'Left');
} qr/value 'Left' unknown, allowed values are:/o,
        "detect not valid: (Align1 => 'Left')";

throws_ok {
    validate (parameter => align1 => 'Bla');
} qr/value 'Bla' unknown, allowed values \(transformed to lower case\) are/o,
        "detect not valid: (align1 => 'Bla')";

throws_ok {
    validate (parameter => PositiveFloat => '-123.1E7');
} qr/value '-123.1E7' is not a positive float/o,
        "detect not valid: (PositiveFloat => '-123.1E7')";

throws_ok {
    validate (parameter => Float => '');
} qr/value '' is not a float/o,
        "detect not valid: (Float => '')";

throws_ok {
    validate (parameter => Float => '123e');
} qr/value '123e' is not a float/o,
        "detect not valid: (Float => '123e')";

throws_ok {
    validate (parameter => Float => '123e+');
} qr/value '123e\+' is not a float/o,
        "detect not valid: (Float => '123e+')";

throws_ok {
    validate (parameter => Int => 'a123');
} qr/value 'a123' is not an integer/o,
        "detect not valid: (Int => 'a123')";

throws_ok {
    validate (parameter => PositiveInt => '-123');
} qr/value '-123' is not a positive integer/o,
        "detect not valid: (PositiveInt => '-123')";

throws_ok {
    validate (parameter => PositiveInt => '12a1');
} qr/\(parameter\): value '12a1' is not a positive integer/o,
        "detect not valid: (PositiveInt => '12a1')";

throws_ok {
    validate (0 => PositiveInt => '12a1');
} qr/\(\): value '12a1' is not a positive integer/o,
        "detect not valid: (PositiveInt => '12a1')";

throws_ok {
    validate (parameter => NegativeInt => '121');
} qr/value '121' is not a negative integer/o,
        "detect not valid: (PositiveInt => '12a1')";

throws_ok {
    validate (parameter => Blubber => '-121');
} qr/unknown rule 'Bla' for validation/o,
        "detect not valid: (Blubber => '-121')";

throws_ok {
    validate (parameter => PositiveInt => 'abc');
} qr/value 'abc' is not a positive integer/o,
        "detect not valid: (PositiveInt => 'abc')";

throws_ok {
    validate (parameter => Bla => '12a1');
} qr/unknown rule 'Bla' for validation/o,
        "detect not valid: (Bla => '12a1')";

throws_ok {
        validate (parameter => -Or => [Int => CodeRef => 0], undef);
} qr /No rule matched of \[Int, CodeRef, 0\]/o,
        "detect not valid: (-Or => [Int => CodeRef => 0], undef)";

throws_ok {
        validate (parameter => -Or => [Int => CodeRef => 0], 0.1);
} qr /No rule matched of \[Int, CodeRef, 0\]/o,
        "detect not valid: (-Or => [Int => CodeRef => 0], 0.1)";

throws_ok {
        validate (parameter => -Enum => {a => 1, b => 1, c => 1}, undef);
        } qr /value <undef> unknown, allowed values are: \[ a, b, c \]/o,
        "detect not valid: (-Enum => {a => 1, b => 1, c => 1}, undef)";

throws_ok {
        validate (parameter => -Enum => {a => 1, b => 1, c => 1}, '');
        } qr /value '' unknown, allowed values are: \[ a, b, c \]/o,
        "detect not valid: (-Enum => {a => 1, b => 1, c => 1}, '')";

throws_ok {
        validate (parameter => -Enum => {a => 1, b => 1, c => 1}, 'f');
        } qr /value 'f' unknown, allowed values are: \[ a, b, c \]/o,
        "detect not valid: (-Enum => {a => 1, b => 1, c => 1}, 'f')";

throws_ok {
    die_bla();
} qr/value '\+' is not a positive integer/o,
          "detect not valid in called sub: (PositiveInt => '+')";

throws_ok {
    validate (parameter => -And => [] => 1);
} qr/No rule found in list to be validated/o,
    "detect empty rule list: (parameter => [] => 1)";

throws_ok {
    validate (parameter => -And => [ 0 ] => 1);
} qr/No rule found in list to be validated/o,
    "detect empty rule list: (parameter => [ 0 ] => 1)";

throws_ok {
    validate (parameter => -And => [ Int => 0 => blabla => 0 ] => 1);
} qr/unknown rule 'blabla' for validation/o,
    "detect missing rule: (parameter => [ int => 0 => blabla => 0 ] => 1)";

throws_ok {
        validate (parameter => -Range => 1,3 => Float => 0.99999999);
} qr/-Range needs ARRAY_ref containing two values/o,
    "detect wrong rule: (-Range => 1,3 => Float => 0.99999999)";

throws_ok {
        validate (parameter => -Range => [1] => Float => 0.99999999);
} qr/-Range needs ARRAY_ref containing two values/o,
    "detect wrong rule: (-Range => [1] => Float => 0.99999999)";

throws_ok {
        validate (parameter => -Range => [3,1] => Float => 0.99999999);
} qr/\(min\) 3 > 1 \(max\) in range definitio/o,
    "detect wrong rule: (-Range => [3,1] => Float => 0.99999999)";

throws_ok {
        validate (parameter => -Range => [1,3] => Int => 1.00000001);
} qr/value '1.00000001' is not an integer/o,
    "detect not valid: (-Range => [1,3] => Int => 1.00000001)";

throws_ok {
        validate (parameter => -Range => [1,3] => Int => 3.00000001);
} qr/value '3.00000001' is not an integer/o,
    "detect not valid: (-Range => [1,3] => Int => 3.00000001)";

throws_ok {
        validate (parameter => -Range => [1,3] => Float => 0.99999999);
} qr/value '0.99999999' is out of range \[1,3\]/o,
    "detect not valid: (-Range => [1,3] => Float => 0.99999999)";

throws_ok {
        validate (parameter => -Range => [1,3] => Float => 3.00000001);
} qr/value '3.00000001' is out of range \[1,3\]/o,
    "detect not valid: (-Range => [1,3] => Float => 3.00000001)";

throws_ok {
        validate (parameter => -Range => [1,3] => Float => 'a');
} qr/ value 'a' is not a float/o,
    "detect not valid: (-Range => [1,3] => Float => a)";

throws_ok {
        validate (free_where_greater_zero => sub { $_ && $_ > 0} => 0);
} qr/'0' does not match free defined rule/o,
    "free_where message";

throws_ok {
        validate (free_rule_greater_zero => {
                -where   => sub { $_ && $_ > 0},
                -message => sub { "$_ is not > 0" }}                            => 0);
} qr/'0' is not > 0 /o,
    "free_rule message";

throws_ok { validate not_empty => -RefEmpty => undef; }
        qr /Not a reference: <undef>/,
        "detect not valid:  validate (... => -RefEmpty => undef";

throws_ok { validate not_empty => -RefEmpty => 'blubb'; }
        qr /Not a reference: 'blubb'/,
        "detect not valid:  validate (... => -RefEmpty => blubb";

throws_ok { validate not_empty => -RefEmpty => { qw (bla blubber) }; }
        qr /Should be empty, but contains 1 entries: \[ bla \]/,
        "detect not valid:  validate (... => -RefEmpty => HashRef";

throws_ok { validate not_empty => -RefEmpty => [ qw (bla blubber) ]; }
        qr /Should be empty, but contains 2 entries: \[ bla, blubber \]/,
        "detect not valid:  validate (... => -RefEmpty => ArrayRef";

throws_ok { validate not_empty => -RefEmpty => sub {}; }
        qr /could not check, if CODE is empty/,
        "detect not valid:  validate (... => -RefEmpty => SubRef";

throws_ok { validate (parameter => -Or => [Int => sub { $_ > 12 } => 0] => 2.1
                      =>  sub { "$_ is not (Int or greater than 12)" })
} qr/'2.1' is not \(Int or greater than 12\)/,
    '-Or => [Int => sub { $_ > 12 } => 0],  2.1)';

throws_ok { validate (parameter => -Or => [Int => {
    -where   => sub { $_ && $_ > 12 },
    -message => sub { "$_ is not > 12" }}],                  2.2      => sub { "$_ is not (Int or greater than 12)" });
} qr/'2.2' is not \(Int or greater than 12\)/,
    '-Or => [Int => { -where => sub { $_ > 12 } => 0] ...},  2.2)';

throws_ok { my %args = convert_to_named_params undef }
        qr/value <undef> is not a array reference/,
        "convert_to_named_params undef";

throws_ok { my %args = convert_to_named_params [ bla => 1 => 2 ] }
        qr/Even number of args needed to build a hash, but arg-count = '3'/,
        "convert_to_named_params [ bla => 1 => 2 ]";

# ------------------------------------------------------------------------------
# test of localized fail_action, message_store and $trouble_level

# --- trouble level tests ----------------------------------------------------

my $old_trouble = validation_trouble();

{
        local $Scalar::Validation::trouble_level = 0;

        eval { my $v = par v => Int => 'ab'; };
        is (validation_trouble(), 1, "validation_trouble() == 1");
        
        eval { my $v = par v => Int => 'ab'; };
        is (validation_trouble(), 2, "validation_trouble() == 2");

        eval { my $v = par v => Int => 'ab'; };
        is (validation_trouble(), 3, "validation_trouble() == 3");
}

is (validation_trouble(), $old_trouble, "validation_trouble() == $old_trouble (\$old_trouble)");

# --- next tests are important for testing -----------------------------------
lives_ok {
        my $fail_message = '';
    local ($Scalar::Validation::fail_action)   = sub { $fail_message = "Not valid message: value was $_";
                                                                                                           s/^'//o; s/'$//o; return $_; };
    local ($Scalar::Validation::message_store) = [];
    is (validate (my_param => PositiveInt => '-1'), '-1', "detect not valid: (PositiveInt => '-1')");
    my $messages = validation_messages();
    is (scalar @$messages, 1, "1 message in message store afterwards");
    is ($messages->[0], "Test::Exception::lives_ok(my_param): value '-1' is not a positive integer",
                "stored message: \"value '-1' is not a positive integer\"");
        is ($fail_message, "Not valid message: value was '-1'",
                '$fail_message set by $fail_action->(): '."Not valid message: value was '-1'");
} "does not die with own fail action";

throws_ok {
    die_bla();
} qr/value '\+' is not a positive integer/o,
    "dies again: detect not valid in called sub: (PositiveInt => '+')";

# --- next tests are important for testing -----------------------------------
lives_ok {
    local ($Scalar::Validation::fail_action, $Scalar::Validation::off)   = prepare_validation_mode(warn => 1);
    is (validate (parameter => PositiveInt => '-1'), '-1', "warn: detect not valid: (PositiveInt => '-1')");

    ($Scalar::Validation::fail_action, $Scalar::Validation::off)   = prepare_validation_mode(silent => 1);
    is (validate (parameter => PositiveInt => '-1'), '-1', "silent: detect not valid: (PositiveInt => '-1')");

    ($Scalar::Validation::fail_action, $Scalar::Validation::off)   = prepare_validation_mode(off => 1);
    local ($Scalar::Validation::fail_action)   = sub { diag "Not valid message: $_"; };
    is (validate (parameter => PositiveInt => '-1'), '-1', "off: detect not valid: (PositiveInt => '-1')");
} "does not die with own fail action";

# ---- warn and optional test ----------
lives_ok {
    local ($Scalar::Validation::fail_action, $Scalar::Validation::off)   = prepare_validation_mode(warn => 1);

        validate (int_4   => -Optional => Int    =>                             undef);
        validate (int_5   => -Optional => -And   => [Scalar => Int => 0] =>     undef);
        validate (int_6   => -Optional => -Or    => [Int => CodeRef => 0] =>    undef);
        validate (enum_2  => -Optional => -Enum  => {a => 1, b => 1, c => 1} => undef);
        validate (range_1 => -Optional => -Range => [1,5] => Int =>             undef);

        validate (range_1 => -Optional => -Range => [1,5] => Int =>             '');

} "does not die while validation warn and -Optional used and value = undef";

# ---- silent and optional test ----------
lives_ok {
    local ($Scalar::Validation::fail_action, $Scalar::Validation::off)   = prepare_validation_mode(silent => 1);

        validate (int_4   => -Optional => Int    =>                             undef);
        validate (int_5   => -Optional => -And   => [Scalar => Int => 0] =>     undef);
        validate (int_6   => -Optional => -Or    => [Int => CodeRef => 0] =>    undef);
        validate (enum_2  => -Optional => -Enum  => {a => 1, b => 1, c => 1} => undef);
        validate (range_1 => -Optional => -Range => [1,5] => Int =>             undef);

} "does not die while validation silent and -Optional used and value = undef";

# ---- silent and optional test of '' ----------
lives_ok {
    local ($Scalar::Validation::fail_action, $Scalar::Validation::off)   = prepare_validation_mode(silent => 1);
    local ($Scalar::Validation::message_store) = [];

        # --- creates validation error message ----
        validate (range_1 => -Optional => -Range => [1,5] => Int =>             '');

        like (validation_messages()->[0], qr/value '' is not an integer/o,
                "detects emtpy string is not int: validate(-Optional => -Range => [1,5] => Int => '')");

        like (validation_messages(-clear)->[0], qr/value '' is not an integer/o,
                "validation_messages(-clear) of validate(-Optional => -Range => [1,5] => Int => '')");

        is (scalar @{validation_messages(-clear)}, 0,
                "validation_messages(-clear) ==> empty list");
        
} "does not die while validation silent and optional test of ''";

# ---- is_valid and optional test of '' ----------
lives_ok {
    local ($Scalar::Validation::message_store) = [];

        # --- creates validation error message ----
        is_valid (range_1 => -Optional => -Range => [1,5] => Int =>             '');

        # diag (@{validation_messages()});
        like (validation_messages()->[0], qr/value '' is not an integer/o,
                "detects emtpy string is not int: is_valid(-Optional => -Range => [1,5] => Int => '')");

} "does not die while is_valid optional test of ''";

# ---- off and optional test ----------
lives_ok {
    local ($Scalar::Validation::fail_action, $Scalar::Validation::off)   = prepare_validation_mode(off => 1);

        validate (int_4   => -Optional => Int    =>                             undef);
        validate (int_5   => -Optional => -And   => [Scalar => Int => 0] =>     undef);
        validate (int_6   => -Optional => -Or    => [Int => CodeRef => 0] =>    undef);
        validate (enum_2  => -Optional => -Enum  => {a => 1, b => 1, c => 1} => undef);
        validate (range_1 => -Optional => -Range => [1,5] => Int =>             undef);

} "does not die while validation off  and -Optional used and value = undef";

# --- reset to previous behavior -------------------

throws_ok {
    die_bla();
} qr/value '\+' is not a positive integer/o,
    "dies again (2): detect not valid in called sub: (PositiveInt => '+')";

# ------------------------------------------------------------------------------
# all test done here

done_testing();

exit 0;
