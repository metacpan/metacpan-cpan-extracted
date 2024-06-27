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
plan tests => 320;

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
        any=>[1,2,undef]          undef
!       any=>[]                   undef
!       any=>[1,2,3]              undef
!       all=>[1,2,undef]          undef
!       all=>\@fooormore          undef
        all=>[]                   undef
        all=>[undef,undef]        undef
!       all=>\@fooormore          undef
        none=>[1,2,3]             undef
        none=>\@fooormore         undef
!       none=>[1,2,3,undef]       undef
        undef                     any=>[1,2,3,undef]
!       undef                     any=>[1,2,3,4,5,6]
        undef                     all=>[]
        undef                     all=>[undef,undef]
!       undef                     all=>[1,2,3,undef]
!       undef                     none=>[1,2,3,undef]
        undef                     none=>[1,2,3,4,5,6]

# regular object
@       $obj            any=>[$obj]
@       \&fatal         any=>[$obj]
@       \&FALSE         any=>[$obj]
@       \&foo           any=>[$obj]
@       sub { 1 }       any=>[$obj]
@       sub { 0 }       any=>[$obj]
@       \%keyandmore    any=>[$obj]
@       {"key" => 1}    any=>[$obj]
@       \@fooormore     any=>[$obj]
@       ["key" => 1]    any=>[$obj]
@       qr/key/         any=>[$obj]
@       qr/key/         any=>[$obj]
@       "key"           any=>[$obj]
@       FALSE()         any=>[$obj]

# regular object with "" overload
@       $obj             all=>[$str_obj]
@       \&fatal          all=>[$str_obj]
@       \&FALSE          all=>[$str_obj]
@       \&foo            all=>[$str_obj]
@       sub { 1 }        all=>[$str_obj]
@       sub { 0 }        all=>[$str_obj]
@       \%keyandmore     all=>[$str_obj]
@       {"object" => 1}  all=>[$str_obj]
@       \@fooormore      all=>[$str_obj]
@       ["object" => 1]  all=>[$str_obj]
@       qr/object/       all=>[$str_obj]
@       qr/object/       all=>[$str_obj]
@       "object"         all=>[$str_obj]
@       FALSE()          all=>[$str_obj]
# Those will treat the $str_obj as a string because of fallback:

# object (overloaded or not) ~~ Any
        $obj            none=>[qr/NoOverload/]
!       $obj            any=>[qr/NoOverload/]
        "$str_obj"      any=>[1,2,3,"object"]
@       $str_obj        all=>["object",$str_obj]

# ~~ Coderef
!       sub{0}          any=>[sub { ref $_[0] eq "CODE" }]
        \%fooormore     any=>[sub { all { /^(foo|or|more)$/ } keys %{$_[0]} }]
!       \%fooormore     any=>[sub { all { /^(foo|or|less)$/ } keys %{$_[0]} }]
        \%fooormore     any=>[sub { all { /^(foo|or|more)$/ } keys %{$_[0]} }]
!       \%fooormore     any=>[sub { all { /^(foo|or|less)$/ } keys %{$_[0]} }]
        +{%fooormore}   any=>[sub { all { /^(foo|or|more)$/ } keys %{$_[0]} }]
!       +{%fooormore}   any=>[sub { all { /^(foo|or|less)$/ } keys %{$_[0]} }]
        \@fooormore     any=>[sub { all { /^(foo|or|more)$/ } @{$_[0]} }]
!       \@fooormore     any=>[sub { all { /^(foo|or|less)$/ } @{$_[0]} }]
        \@fooormore     any=>[sub { all { /^(foo|or|more)$/ } @{$_[0]} }]
!       \@fooormore     any=>[sub { all { /^(foo|or|less)$/ } @{$_[0]} }]
        [@fooormore]    any=>[sub { all { /^(foo|or|more)$/ } @{$_[0]} }]
!       [@fooormore]    any=>[sub { all { /^(foo|or|less)$/ } @{$_[0]} }]
        \%fooormore     any=>[sub{@_==1}]
        \@fooormore     any=>[sub{@_==1}]
        "foo"           any=>[sub { $_[0] =~ /^(foo|or|more)$/ }]
!       "more"          any=>[sub { $_[0] =~ /^(foo|or|less)$/ }]
        qr/fooormore/   any=>[sub{ref $_[0] eq 'Regexp'}]
        1               any=>[sub{shift}]
!       0               any=>[sub{shift}]
!       undef           any=>[sub{shift}]
        undef           any=>[sub{not shift}]
        NOT_DEF()       any=>[sub{not shift}]
        &NOT_DEF        any=>[sub{not shift}]
        FALSE()         any=>[sub{not shift}]
        [1]             any=>[\&bar]
        {a=>1}          any=>[\&bar]
        qr//            any=>[\&bar]
!       [1]             any=>[\&foo]
!       {a=>1}          any=>[\&foo]
        $obj            any=>[sub { ref($_[0]) =~ /NoOverload/ }]
!       []              any=>[\&foo]
!       {}              any=>[\&foo]
!       \@empty         any=>[\&foo]
!       \%empty         any=>[\&foo]
!       qr//            any=>[\&foo]
!       undef           any=>[\&foo]
        undef           any=>[\&bar]
@       undef           any=>[\&fatal]
@       1               any=>[\&fatal]
@       [1]             any=>[\&fatal]
@       {a=>1}          any=>[\&fatal]
@       "foo"           any=>[\&fatal]
@       qr//            any=>[\&fatal]
@       []              any=>[\&fatal]
@       +{}             any=>[\&fatal]
@       \@empty         any=>[\&fatal]
@       \%empty         any=>[\&fatal]
!       sub {0}         any=>[qr/^CODE/]
!       sub {0}         any=>[sub { ref shift eq "CODE" }]
        \&foo           any=>[\&foo]
        \&fatal         any=>[\&fatal]

!       sub{0}          all=>[true, sub { ref $_[0] eq "CODE" }]
        \%fooormore     all=>[true, sub { all { /^(foo|or|more)$/ } keys %{$_[0]} }]
!       \%fooormore     all=>[true, sub { all { /^(foo|or|less)$/ } keys %{$_[0]} }]
        \%fooormore     all=>[true, sub { all { /^(foo|or|more)$/ } keys %{$_[0]} }]
!       \%fooormore     all=>[true, sub { all { /^(foo|or|less)$/ } keys %{$_[0]} }]
        +{%fooormore}   all=>[true, sub { all { /^(foo|or|more)$/ } keys %{$_[0]} }]
!       +{%fooormore}   all=>[true, sub { all { /^(foo|or|less)$/ } keys %{$_[0]} }]
        \@fooormore     all=>[true, sub { all { /^(foo|or|more)$/ } @{$_[0]} }]
!       \@fooormore     all=>[true, sub { all { /^(foo|or|less)$/ } @{$_[0]} }]
        \@fooormore     all=>[true, sub { all { /^(foo|or|more)$/ } @{$_[0]} }]
!       \@fooormore     all=>[true, sub { all { /^(foo|or|less)$/ } @{$_[0]} }]
        [@fooormore]    all=>[true, sub { all { /^(foo|or|more)$/ } @{$_[0]} }]
!       [@fooormore]    all=>[true, sub { all { /^(foo|or|less)$/ } @{$_[0]} }]
        \%fooormore     all=>[true, sub{@_==1}]
        \@fooormore     all=>[true, sub{@_==1}]
        "foo"           all=>[true, sub { $_[0] =~ /^(foo|or|more)$/ }]
!       "more"          all=>[true, sub { $_[0] =~ /^(foo|or|less)$/ }]
        qr/fooormore/   all=>[true, sub{ref $_[0] eq 'Regexp'}]
        1               all=>[true, sub{shift}]
!       0               all=>[true, sub{shift}]
!       undef           all=>[true, sub{shift}]
        undef           all=>[true, sub{not shift}]
        NOT_DEF()       all=>[true, sub{not shift}]
        &NOT_DEF        all=>[true, sub{not shift}]
        FALSE()         all=>[true, sub{not shift}]
        [1]             all=>[true, \&bar]
        {a=>1}          all=>[true, \&bar]
        qr//            all=>[true, \&bar]
!       [1]             all=>[true, \&foo]
!       {a=>1}          all=>[true, \&foo]
        $obj            all=>[true, sub { ref($_[0]) =~ /NoOverload/ }]
!       []              all=>[true, \&foo]
!       {}              all=>[true, \&foo]
!       \@empty         all=>[true, \&foo]
!       \%empty         all=>[true, \&foo]
!       qr//            all=>[true, \&foo]
!       undef           all=>[true, \&foo]
        undef           all=>[true, \&bar]
@       undef           all=>[true, \&fatal]
@       1               all=>[true, \&fatal]
@       [1]             all=>[true, \&fatal]
@       {a=>1}          all=>[true, \&fatal]
@       "foo"           all=>[true, \&fatal]
@       qr//            all=>[true, \&fatal]
@       []              all=>[true, \&fatal]
@       +{}             all=>[true, \&fatal]
@       \@empty         all=>[true, \&fatal]
@       \%empty         all=>[true, \&fatal]
!       sub {0}         all=>[true, qr/^CODE/]
!       sub {0}         all=>[true, sub { ref shift eq "CODE" }]
        \&foo           all=>[true, \&foo]
        \&fatal         all=>[true, \&fatal]


# HASH ref against:
#   - another hash ref
        all=>[{},{}]            {}
=       none=>[{}]              {1 => 2}
        any=>[0,{1 => 2}]       {1 => 2}
=       none=>[{1 => 2}]        {1 => 3}
=       {1 => 2}                none=>[{2 => 3}]
        any=>[0,\%main::]       {map {$_ => true} keys %main::}

#  - tied hash ref
=       \%hash                  \%tied_hash
        \%tied_hash             \%tied_hash
=       none=>[{"a"=>"b"}]      all=>[\%tied_hash]
=       \%hash                  \%tied_hash
        \%tied_hash             \%tied_hash
        any=>[0,\%refh]         all=>[\%refh]          MINISKIP

# ARRAY ref against:
#  - another array ref
        any=>[[1,2,3],[]]                    any=>[[],[1,2,3],[1..9]]
=       none=>[[]]                           [1]
        all=>[["foo", "bar"]]                any=>[[qr/o/, qr/a/]]
        [["foo"], ["bar"]]                   none=>[[qr/ARRAY/, qr/ARRAY/]]
        all=>[["".["foo"], "".["bar"]]]      all=>[[qr/ARRAY/, qr/ARRAY/]]
        none=>[[qr/o/, qr/a/]]               ["foo", "bar"]
        none=>[["foo", "bar"]]               [["foo"], ["bar"]]
        none=>[["foo", "bar"]]               [qr/o/, "foo"]
        ["foo", undef, "bar"]                any=>[[qr/o/, undef, "bar"]]
        ["foo", undef, "bar"]                none=>[[qr/o/, "", "bar"]]
        ["foo", "", "bar"]                   none=>[[qr/o/, undef, "bar"]]
        all=>[$deep1]                        $deep1
        $deep1                               all=>[$deep1]
        $deep1                               none=>[$deep2]
        any=>[[1,2]]                         none=>[[1,3]]

=       any=>[\@nums]           \@tied_nums
=       all=>[\@nums]           \@tied_nums
=       \@nums                  any=>[\@tied_nums]
=       \@nums                  all=>[\@tied_nums]
=       all=>[\@nums]           any=>[\@tied_nums]
=       any=>[\@nums]           all=>[\@tied_nums]
        any=>[\@nums]           any=>[\@tied_nums]
        all=>[\@nums]           all=>[\@tied_nums]

#  - an object
       none=>[$obj]           \@fooormore
       [$obj]                 all=>[true, [sub{ref shift}]]

#  - a regex
!       qr/x/           any=>[qw(foo bar baz quux)]
=       qr/y/           none=>[qw(foo bar baz quux)]
!       qr/FOO/i        any=>\@fooormore
        qr/bar/         none=>\@fooormore

# - a number
        2               none=>[qw(1.00 2.00)]
=       2               any=>[qw(2 2.00)]
=       2               any=>[qw(foo 2)]
=       2               none=>[qw(foo bar)]
=       2.0_0e+0        any=>[qw(foo 2)]
=!      2               any=>[qw(1foo bar2)]

# - a string
        "2"             none=>[qw(1foo 2bar)]
        "2bar"          any=>[qw(1foo 2bar)]

# - undef
        undef           any=>[1, 2, undef, 4]
        undef           none=>[1, 2, [undef], 4]
        undef           none=>\@fooormore
        undef           any=>\@sparse
        undef           all=>[undef]
        0               none=>[undef]
        ""              none=>[undef]
        undef           none=>[0]
        undef           none=>[""]

# - nested arrays and ~~ distributivity
!       11              any=>[[11]]
!       11              any=>[[12]]
!       "foo"           any=>[{foo => "bar"}]
!       "bar"           any=>[{foo => "bar"}]

# Number against number
        2               any=>[2]
        20              any=>[2_0]
!       2               any=>[3]
        0               any=>[FALSE()]
        3-2             any=>[TRUE]
        undef           none=>[0..9]
        (my $u)         none=>[0..9]
        (my $u)         any=>[0..9, undef]

# Number against string
=       2               all=>["2"]
        2               none=>["2.0"]
        2               none=>["2bananas"]
=       2_3             none=>["2_3"]           NOWARNINGS
        FALSE()         all=>["0"]
        undef           none=>["0"]
        undef           none=>[""]

# Regex against string
        "x"             any=>[false, qr/x/]
        "x"             none=>[qr/y/]

# Regex against number
        12345           all=>[qr/3/]
        12345           none=>[qr/7/]

# array/hash against string
        \@fooormore     none=>["".\@fooormore]
        \@keyandmore    none=>["".\@fooormore]
        \%fooormore     none=>["".\%fooormore]
        \%keyandmore    none=>["".\%fooormore]

# Test the (lack of) implicit referencing
        none=>[7]       \@nums
        all=>[\@nums]   \@nums
        none=>[\@nums]  \\@nums
        any=>[\@nums]   [1..10]
        none=>[\@nums]  [0..9]

        "foo"           none=>[\%hash]
        qr/bar/         none=>[\%hash]
        [qw(bar)]       none=>[\%hash]
        [qw(a b c)]     none=>[\%hash]
        \%hash          all=>[\%hash, \%hash,]
        \%hash          all=>[+{%hash}, +{%hash},]
        \%hash          all=>[\%tied_hash, \%tied_hash,]
        \%tied_hash     all=>[\%tied_hash, \%tied_hash,]
        \%hash          all=>[{ foo => true, bar => true }, { foo => true, bar => true },]
        \%hash          none=>[{},{ foo => true, bar => true, quux => true }]

        any=>[\@nums]         none=>[{ 1, '', 2, '' }]
        any=>[\@nums]         none=>[{ 1, '', 12, '' }]
        any=>[\@nums]         none=>[{11, '', 12, '' }]

# array slices
        any=>[[@nums[0..-1]]]    []
        any=>[[@nums[0..0]]]     [1]
        [@nums[0..1]]            none=>[[0..2]]
        all=>[[@nums[0..4]]]     any=>[[1..5]]

        undef           none=>[[@nums[0..-1]]]
        1               none=>[[@nums[0..0]]]
        2               none=>[[@nums[0..1]]]
        [@nums[0..1]]   none=>[2]

        all=>[[@nums[0..1]]]   all=>[[@nums[0..1]]]

# hash slices
        [@keyandmore{qw(not)}]          any=>[false, [undef]]
        [@keyandmore{qw(key)}]          any=>[false, [0]]

        undef                           none=>[false, [@keyandmore{qw(not)}]]
        0                               none=>[false, [@keyandmore{qw(key and more)}]]
        2                               none=>[false, [@keyandmore{qw(key and)}]]

        all=>[[@fooormore{qw(foo)}]]           [@keyandmore{qw(key)}]
        all=>[[@fooormore{qw(foo or more)}]]   [@keyandmore{qw(key and more)}]

# UNDEF
        none=>[3]              undef
        none=>[1]              undef
        none=>[[]]             undef
        none=>[{}]             undef
        none=>[\%::main]       undef
        none=>[[1,2]]          undef
        none=>[\%hash]         undef
        none=>[\@nums]         undef
        none=>["foo"]          undef
        none=>[""]             undef
        none=>[!1]             undef
        none=>[\&foo]          undef
        none=>[sub { }]        undef
        3                      none=>[false, undef]
        1                      none=>[false, undef]
        []                     none=>[false, undef]
        {}                     none=>[false, undef]
        \%::main               none=>[false, undef]
        [1,2]                  none=>[false, undef]
        \%hash                 none=>[false, undef]
        \@nums                 none=>[false, undef]
        "foo"                  none=>[false, undef]
        ""                     none=>[false, undef]
        !1                     none=>[false, undef]
        \&foo                  none=>[false, undef]
        sub { }                none=>[false, undef]

