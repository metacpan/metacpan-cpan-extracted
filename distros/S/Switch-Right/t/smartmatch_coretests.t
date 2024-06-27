# THESE TESTS ADAPTED FROM THE match::smart DISTRIBUTION...
# WHICH ADAPTED THEM IN TURN FROM PERL'S OWN TEST SUITE...

use 5.036;
use strict;
use warnings;
no warnings 'uninitialized';
use Test2::V0;

use experimental 'builtin';
use builtin qw< true false >;

use Switch::Right;

use Tie::Array;
use Tie::Hash;
use List::Util 'all';

# Predeclare vars used in the tests:
my @empty;
my %empty;
my @sparse; $sparse[2] = 2;

my $deep1 = []; push @$deep1, $deep1;
my $deep2 = []; push @$deep2, $deep2;

my @nums = (1..10);
tie my @tied_nums, 'Tie::StdArray';
@tied_nums =  (1..10);

my %hash = (foo => 17, bar => 23);
tie my %tied_hash, 'Tie::StdHash';
%tied_hash = %hash;

{
        package Test::Object::NoOverload;
        sub new { bless { key => 1 } }
}

{
        package Test::Object::StringOverload;
        use overload '""' => sub { "object" }, fallback => 1;
        sub new { bless { key => 1 } }
}

our $obj      = Test::Object::NoOverload->new;
our $str_obj  = Test::Object::StringOverload->new;

require Tie::RefHash;
tie my %refh, 'Tie::RefHash';
$refh{$obj} = 1;

my @keyandmore = qw(key and more);
my @fooormore = qw(foo or more);
my %keyandmore = map { $_ => 0 } @keyandmore;
my %fooormore = map { $_ => 0 } @fooormore;

# Load and run the tests
plan tests => 319;

while (<DATA>) {
        SKIP: {
                next if /^#/ || !/\S/;
                chomp;
                my ($yn, $left, $right, $note) = split /[ ]{2,}/;
                $note //= q{};

                die "Bad test spec: ($yn, $left, $right)" if $yn =~ /[^!@=]/;

                my $tstr = "smartmatch($left, $right)";

                test_again:

                my $res;
                if ($note =~ /NOWARNINGS/) {
                        $res = eval "no warnings; $tstr";
                }
                else {
                        $res = eval $tstr;
                }

                chomp $@;

                if ( $yn =~ /@/ ) {
                        ok( $@ ne '', "$tstr dies" )
                                and print "# \$\@ was: $@\n";
                } else {
                        my $test_name = $tstr . ($yn =~ /!/ ? " does not match" : " matches");
                        if ( $@ ne '' ) {
                                fail($test_name);
                                print "# \$\@ was: $@\n";
                        } else {
                                ok( ($yn =~ /!/ xor $res), $test_name )
                                        or diag sprintf '%s ~~ %s', (eval($left), eval($right));
                        }
                }

                if ( $yn =~ s/=// ) {
                        $tstr = "smartmatch($right, $left)";
                        goto test_again;
                }
        }
}

sub foo {}
sub bar {42}
sub gorch {42}
sub fatal {die "fatal sub\n"}

# to test constant folding
sub FALSE() { 0 }
sub TRUE() { 1 }
sub NOT_DEF() { undef }

# Prefix character :
#   - expected to match
# ! - expected to not match
# @ - expected to be a compilation failure
# = - expected to match symmetrically (runs test twice)
# Data types to test :
#   undef
#   Object-overloaded
#   Object
#   Coderef
#   Hash
#   Hashref
#   Array
#   Arrayref
#   Tied arrays and hashes
#   Arrays that reference themselves
#   Regex (// and qr//)
#   Range
#   Num
#   Str
# Other syntactic items of interest:
#   Constants
#   Values returned by a sub call
__DATA__
# Any ~~ undef
!       $obj            undef
!       sub {}          undef
!       \%hash          undef
!       \%hash          undef
!       {}              undef
!       \@nums          undef
!       \@nums          undef
!       []              undef
!       \%tied_hash     undef
!       \@tied_nums     undef
!       $deep1          undef
!       qr/foo/         undef
!       qr/foo/         undef
!       [21..30]        undef
!       189             undef
!       "foo"           undef
!       ""              undef
!       !1              undef
        undef           undef
        (my $u)         undef
        NOT_DEF()       undef
        &NOT_DEF        undef

# regular object
@       $obj            $obj
@       \&fatal         $obj
@       \&FALSE         $obj
@       \&foo           $obj
@       sub { 1 }       $obj
@       sub { 0 }       $obj
@       \%keyandmore    $obj
@       {"key" => 1}    $obj
@       \@fooormore     $obj
@       ["key" => 1]    $obj
@       qr/key/         $obj
@       qr/key/         $obj
@       "key"           $obj
@       FALSE()         $obj

# regular object with "" overload
@       $obj             $str_obj
@       \&fatal          $str_obj
@       \&FALSE          $str_obj
@       \&foo            $str_obj
@       sub { 1 }        $str_obj
@       sub { 0 }        $str_obj
@       \%keyandmore     $str_obj
@       {"object" => 1}  $str_obj
@       \@fooormore      $str_obj
@       ["object" => 1]  $str_obj
@       qr/object/       $str_obj
@       qr/object/       $str_obj
@       "object"         $str_obj
@       FALSE()          $str_obj
# Those will treat the $str_obj as a string because of fallback:

# object (overloaded or not) ~~ Any
!       $obj            qr/NoOverload/
        "$str_obj"      "object"
        $str_obj        "object"

# ~~ Coderef
!       sub{0}          sub { ref $_[0] eq "CODE" }
        \%fooormore     sub { all { /^(foo|or|more)$/ } keys %{$_[0]} }
!       \%fooormore     sub { all { /^(foo|or|less)$/ } keys %{$_[0]} }
        \%fooormore     sub { all { /^(foo|or|more)$/ } keys %{$_[0]} }
!       \%fooormore     sub { all { /^(foo|or|less)$/ } keys %{$_[0]} }
        +{%fooormore}   sub { all { /^(foo|or|more)$/ } keys %{$_[0]} }
!       +{%fooormore}   sub { all { /^(foo|or|less)$/ } keys %{$_[0]} }
        \@fooormore     sub { all { /^(foo|or|more)$/ } @{$_[0]} }
!       \@fooormore     sub { all { /^(foo|or|less)$/ } @{$_[0]} }
        \@fooormore     sub { all { /^(foo|or|more)$/ } @{$_[0]} }
!       \@fooormore     sub { all { /^(foo|or|less)$/ } @{$_[0]} }
        [@fooormore]    sub { all { /^(foo|or|more)$/ } @{$_[0]} }
!       [@fooormore]    sub { all { /^(foo|or|less)$/ } @{$_[0]} }
        \%fooormore     sub{@_==1}
        \@fooormore     sub{@_==1}
        "foo"           sub { $_[0] =~ /^(foo|or|more)$/ }
!       "more"          sub { $_[0] =~ /^(foo|or|less)$/ }
        qr/fooormore/   sub{ref $_[0] eq 'Regexp'}
        1               sub{shift}
!       0               sub{shift}
!       undef           sub{shift}
        undef           sub{not shift}
        NOT_DEF()       sub{not shift}
        &NOT_DEF        sub{not shift}
        FALSE()         sub{not shift}
        [1]             \&bar
        {a=>1}          \&bar
        qr//            \&bar
!       [1]             \&foo
!       {a=>1}          \&foo
        $obj            sub { ref($_[0]) =~ /NoOverload/ }
!       []              \&foo
!       {}              \&foo
!       \@empty         \&foo
!       \%empty         \&foo
!       qr//            \&foo
!       undef           \&foo
        undef           \&bar
@       undef           \&fatal
@       1               \&fatal
@       [1]             \&fatal
@       {a=>1}          \&fatal
@       "foo"           \&fatal
@       qr//            \&fatal
@       []              \&fatal
@       +{}             \&fatal
@       \@empty         \&fatal
@       \%empty         \&fatal
!       sub {0}         qr/^CODE/
!       sub {0}         sub { ref shift eq "CODE" }
        \&foo           \&foo
        \&fatal         \&fatal

# HASH ref against:
#   - another hash ref
        {}              {}
=!      {}              {1 => 2}
        {1 => 2}        {1 => 2}
=!      {1 => 2}        {1 => 3}
=!      {1 => 2}        {2 => 3}
        \%main::        {map {$_ => true} keys %main::}

#  - tied hash ref
=       \%hash          \%tied_hash
        \%tied_hash     \%tied_hash
!=      {"a"=>"b"}      \%tied_hash
=       \%hash          \%tied_hash
        \%tied_hash     \%tied_hash
        \%refh          \%refh          MINISKIP

#  - an array ref
#  (since this is symmetrical, tests as well hash~~array)
=!      [qw[STDIN STDOUT]]      \%::
=!      []              \%::
=!      [""]            {}
=!      []              {}
=!      \@empty         {}
=!      [undef]         {"" => 1}
=!      [""]            {"" => 1}
=!      ["foo"]         { foo => 1 }
=!      ["foo", "bar"]  { foo => 1 }
=!      ["foo", "bar"]  \%hash
=!      ["foo"]         \%hash
=!      ["quux"]        \%hash
=!      [qw(foo quux)]  \%hash
=!      \@fooormore     { foo => 1, or => 2, more => 3 }
=!      \@fooormore     \%fooormore
=!      \@fooormore     \%fooormore
=!      \@fooormore     \%fooormore

#  - a regex
=!      qr/^(fo[ox])$/          {foo => 1}
=!      qr/^(fo[ox])$/          \%fooormore
=!      qr/[13579]$/            +{0..99}
=!      qr/a*/                  {}
=!      qr/a*/                  {b=>2}
=!      qr/B/i                  {b=>2}
=!      qr/B/i                  {b=>2}
=!      qr/a+/                  {b=>2}
=!      qr/^à/                  {"à"=>2}

#  - a scalar
!       "foo"           +{foo => 1, bar => 2}
!       "foo"           \%fooormore
!       "baz"           +{foo => 1, bar => 2}
!       "boz"           \%fooormore
!       1               +{foo => 1, bar => 2}
!       1               \%fooormore
!       1               { 1 => 3 }
!       1.0             { 1 => 3 }
!       "1.0"           { 1 => 3 }
!       "1.0"           { 1.0 => 3 }
!       "1.0"           { "1.0" => 3 }
!       "à"             { "à" => "À" }

#  - undef
!       undef           { hop => 'zouu' }
!       undef           \%hash
!       undef           +{"" => "empty key"}
!       undef           {}

# ARRAY ref against:
#  - another array ref
        []                            []
=!      []                            [1]
        ["foo", "bar"]                [qr/o/, qr/a/]
!       [["foo"], ["bar"]]            [qr/ARRAY/, qr/ARRAY/]
        ["".["foo"], "".["bar"]]      [qr/ARRAY/, qr/ARRAY/]
!       [qr/o/, qr/a/]                ["foo", "bar"]
!       ["foo", "bar"]                [["foo"], ["bar"]]
!       ["foo", "bar"]                [qr/o/, "foo"]
        ["foo", undef, "bar"]         [qr/o/, undef, "bar"]
!       ["foo", undef, "bar"]         [qr/o/, "", "bar"]
!       ["foo", "", "bar"]            [qr/o/, undef, "bar"]
        $deep1                        $deep1
        $deep1                        $deep1
!       $deep1                        $deep2
!       [1,2]   [1,3]

=       \@nums                  \@tied_nums
=       \@nums                  \@tied_nums
=       \@nums                  \@tied_nums
=       \@nums                  \@tied_nums

#  - an object
!       $obj            \@fooormore
       [$obj]           [sub{ref shift}]

#  - a regex
=!      qr/x/           [qw(foo bar baz quux)]
=!      qr/y/           [qw(foo bar baz quux)]
=!      qr/FOO/i        \@fooormore
=!      qr/bar/         \@fooormore

# - a number
=!      2               [qw(1.00 2.00)]
=!      2               [qw(foo 2)]
=!      2.0_0e+0        [qw(foo 2)]
=!      2               [qw(1foo bar2)]

# - a string
!       "2"             [qw(1foo 2bar)]
!       "2bar"          [qw(1foo 2bar)]

# - undef
!       undef           [1, 2, undef, 4]
!       undef           [1, 2, [undef], 4]
!       undef           \@fooormore
!       undef           \@sparse
!       undef           [undef]
!       0               [undef]
!       ""              [undef]
!       undef           [0]
!       undef           [""]

# - nested arrays and ~~ distributivity
!       11              [[11]]
!       11              [[12]]
!       "foo"           [{foo => "bar"}]
!       "bar"           [{foo => "bar"}]

# Number against number
        2               2
        20              2_0
!       2               3
        0               FALSE()
        3-2             TRUE
!       undef           0
!       (my $u)         0

# Number against string
=       2               "2"
!       2               "2.0"
!       2               "2bananas"
!=      2_3             "2_3"           NOWARNINGS
        FALSE()         "0"
!       undef           "0"
!       undef           ""

# Regex against string
        "x"             qr/x/
!       "x"             qr/y/

# Regex against number
        12345           qr/3/
!       12345           qr/7/

# array/hash against string
!       \@fooormore     "".\@fooormore
!       \@keyandmore    "".\@fooormore
!       \%fooormore     "".\%fooormore
!       \%keyandmore    "".\%fooormore

# Test the implicit referencing
!       7               \@nums
        \@nums          \@nums
!       \@nums          \\@nums
        \@nums          [1..10]
!       \@nums          [0..9]

!       "foo"           \%hash
!       qr/bar/         \%hash
!       [qw(bar)]       \%hash
!       [qw(a b c)]     \%hash
        \%hash          \%hash
        \%hash          +{%hash}
        \%hash          \%tied_hash
        \%tied_hash     \%tied_hash
        \%hash          { foo => true, bar => true }
!       \%hash          { foo => true, bar => true, quux => true }

!       \@nums          { 1, '', 2, '' }
!       \@nums          { 1, '', 12, '' }
!       \@nums          {11, '', 12, '' }

# array slices
        [@nums[0..-1]]  []
        [@nums[0..0]]   [1]
!       [@nums[0..1]]   [0..2]
        [@nums[0..4]]   [1..5]

!       undef           [@nums[0..-1]]
!       1               [@nums[0..0]]
!       2               [@nums[0..1]]
!       [@nums[0..1]]   2

        [@nums[0..1]]   [@nums[0..1]]

# hash slices
        [@keyandmore{qw(not)}]          [undef]
        [@keyandmore{qw(key)}]          [0]

!       undef                           [@keyandmore{qw(not)}]
!       0                               [@keyandmore{qw(key and more)}]
!       2                               [@keyandmore{qw(key and)}]

        [@fooormore{qw(foo)}]           [@keyandmore{qw(key)}]
        [@fooormore{qw(foo or more)}]   [@keyandmore{qw(key and more)}]

# UNDEF
!       3               undef
!       1               undef
!       []              undef
!       {}              undef
!       \%::main        undef
!       [1,2]           undef
!       \%hash          undef
!       \@nums          undef
!       "foo"           undef
!       ""              undef
!       !1              undef
!       \&foo           undef
!       sub { }         undef
