# THESE TESTS ARE ADAPTED FROM THE PERL v5.40 CORE TESTS FOR THE ~~ OPERATOR
# THE AIM IS TO ILLUSTRATE THAT THE NEW smartmatch() BEHAVIOURS
# CAN REPLICATE (ALMOST) ALL THE OLD OPERATOR'S BEHAVIOURS, AND TO HIGHLIGHT
# THE SYNTACTIC CHANGES REQUIRED IN THE TWO ARGUMENTS TO ACCOMPLISH THAT...

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

{
    package Test::Object::WithOverload;
    sub new { bless { key => ($_[1] // 'magic') } }
    use overload '""' => sub { "stringified" };
    use overload 'eq' => sub {"$_[0]" eq "$_[1]"};
}

use Multi::Dispatch;
multi smartmatch($left, Test::Object::WithOverload $right) {
    return defined $left && $left eq reverse $right->{key};
}

our $obj     = Test::Object::NoOverload->new;
our $str_obj = Test::Object::StringOverload->new;
our $ov_obj  = Test::Object::WithOverload->new;

require Tie::RefHash;
tie my %refh, 'Tie::RefHash';
$refh{$obj} = 1;

my @keyandmore = qw(key and more);
my @fooormore = qw(foo or more);
my %keyandmore = map { $_ => 0 } @keyandmore;
my %fooormore = map { $_ => 0 } @fooormore;

# Load and run the tests
plan tests => 346;

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

BEGIN {
    open *DATA, '<', \q{
# Any ~~ undef
!       $ov_obj         undef
!       $obj            undef
!       sub {}          undef
!      \%hash           undef               # CHANGED: smartmatch() DOESN'T AUTO_ENREFERENCE
!       \%hash          undef
!       {}              undef
!      \@nums           undef               # CHANGED: smartmatch() DOESN'T AUTO_ENREFERENCE
!       \@nums          undef
!       []              undef
!      \%tied_hash      undef               # CHANGED: smartmatch() DOESN'T AUTO_ENREFERENCE
!      \@tied_nums      undef               # CHANGED: smartmatch() DOESN'T AUTO_ENREFERENCE
!       $deep1          undef
!       /foo/           undef
!       qr/foo/         undef
!      [21..30]         undef               # CHANGED: smartmatch() DOESN'T AUTO_ENREFERENCE
!       189             undef
!       "foo"           undef
!       ""              undef
!       !1              undef
        undef           undef
        (my $u)         undef
        NOT_DEF         undef
        &NOT_DEF        undef

# Any ~~ object overloaded
!       \&fatal                 $ov_obj
        'cigam'                 $ov_obj
!       'cigam on'              $ov_obj
!       ['cigam']               $ov_obj
!       ['stringified']         $ov_obj
!       { cigam => 1 }          $ov_obj
!       { stringified => 1 }    $ov_obj
!       $obj                    $ov_obj
!       undef                   $ov_obj

# regular object
@       $obj            $obj
@       $ov_obj         $obj
=@      \&fatal         $obj
@       \&FALSE         $obj
@       \&foo           $obj
@       sub { 1 }       $obj
@       sub { 0 }       $obj
@      \%keyandmore     $obj          # CHANGED: NO AUTO_ENREFERENCING
@       {"key" => 1}    $obj
@      \@fooormore      $obj          # CHANGED: NO AUTO_ENREFERENCING
@       ["key" => 1]    $obj
@       /key/           $obj
@       qr/key/         $obj
@       "key"           $obj
@       FALSE           $obj

# regular object with "" overload
@       $obj                $str_obj
=@      \&fatal             $str_obj
@       \&FALSE             $str_obj
@       \&foo               $str_obj
@       sub { 1 }           $str_obj
@       sub { 0 }           $str_obj
@      \%keyandmore         $str_obj      # CHANGED: NO AUTO_ENREFERENCING
@       {"object" => 1}     $str_obj
@      \@fooormore          $str_obj      # CHANGED: NO AUTO_ENREFERENCING
@       ["object" => 1]     $str_obj
@       /object/            $str_obj
@       qr/object/          $str_obj
@       "object"            $str_obj
@       FALSE               $str_obj
# Those will treat the $str_obj as a string because of fallback:

# object (overloaded or not) ~~ Any
       "$obj"           qr/NoOverload/      # CHANGED: smartmatch() DOESN'T PATTERN-MATCH REFS/OBJS
       "$ov_obj"        qr/^stringified$/   # CHANGED: smartmatch() DOESN'T PATTERN-MATCH REFS/OBJS
=       "$ov_obj"       "stringified"
=       "$str_obj"      "object"
=      "$ov_obj"        "stringified"       # CHANGED: smartmatch() OVERLOADING TAKES PRECEDENCE
       "$str_obj"       "object"            # CHANGED: smartmatch() DOESN'T PATTERN-MATCH REFS/OBJS
        $ov_obj         'stringified'       # CHANGED: smartmatch() DOESN'T USE OVERLOADED eq
!       $ov_obj         'not magic'         # CHANGED: smartmatch() DOESN'T USE OVERLOADED eq

# ~~ Coderef
       [sub{0}]                     sub { ref $_[0][0] eq "CODE" }       # CHANGED: RHS CODE SEMANTICS
    all=>[keys %fooormore]          sub { $_[0] =~ /^(foo|or|more)$/ }   # CHANGED: RHS CODE SEMANTICS
!   all=>[keys %fooormore]          sub { $_[0] =~ /^(foo|or|less)$/ }   # CHANGED: RHS CODE SEMANTICS
    all=>[keys %fooormore]          sub { $_[0] =~ /^(foo|or|more)$/ }   # CHANGED: RHS CODE SEMANTICS
!   all=>[keys %fooormore]          sub { $_[0] =~ /^(foo|or|less)$/ }   # CHANGED: RHS CODE SEMANTICS
    all=>[keys %{+{%fooormore}}]    sub { $_[0] =~ /^(foo|or|more)$/ }   # CHANGED: RHS CODE SEMANTICS
!   all=>[keys %{+{%fooormore}}]    sub { $_[0] =~ /^(foo|or|less)$/ }   # CHANGED: RHS CODE SEMANTICS
    all=>\@fooormore                sub { $_[0] =~ /^(foo|or|more)$/ }   # CHANGED: NO AUTO-ENREFERENCE
!   all=>\@fooormore                sub { $_[0] =~ /^(foo|or|less)$/ }   # CHANGED: NO AUTO-ENREFERENCE
    all=>\@fooormore                sub { $_[0] =~ /^(foo|or|more)$/ }   # CHANGED: RHS CODE SEMANTICS
!   all=>\@fooormore                sub { $_[0] =~ /^(foo|or|less)$/ }   # CHANGED: RHS CODE SEMANTICS
    all=>[@fooormore]               sub { $_[0] =~ /^(foo|or|more)$/ }   # CHANGED: RHS CODE SEMANTICS
!   all=>[@fooormore]               sub { $_[0] =~ /^(foo|or|less)$/ }   # CHANGED: RHS CODE SEMANTICS

       \%fooormore      sub{@_==1}                            # CHANGED: DOESN'T AUTO-ENREFERENCE
       \@fooormore      sub{@_==1}                            # CHANGED: DOESN'T AUTO-ENREFERENCE
        "foo"           sub { $_[0] =~ /^(foo|or|more)$/ }
!       "more"          sub { $_[0] =~ /^(foo|or|less)$/ }
      qr/fooormore/     sub{ref $_[0] eq 'Regexp'}            # CHANGED: DOESN'T AUTO-ENREFERENCE
        qr/fooormore/   sub{ref $_[0] eq 'Regexp'}
        1               sub{shift}
!       0               sub{shift}
!       undef           sub{shift}
        undef           sub{not shift}
        NOT_DEF         sub{not shift}
        &NOT_DEF        sub{not shift}
        FALSE           sub{not shift}
        [1]             \&bar
        {a=>1}          \&bar
        qr//            \&bar
!       [1]             \&foo
!       {a=>1}          \&foo
        $obj            sub { ref($_[0]) =~ /NoOverload/ }
        $ov_obj         sub { ref($_[0]) =~ /WithOverload/ }
# empty stuff no longer matches, because RHS CODE SEMANTICS CHANGED...
!       []              \&foo          # CHANGED
!       {}              \&foo          # CHANGED
!      \@empty          \&foo          # CHANGED
!      \%empty          \&foo          # CHANGED
!       qr//            \&foo          # CHANGED
!       undef           \&foo          # CHANGED
        undef           \&bar          # CHANGED
@       undef           \&fatal        # CHANGED
@       1               \&fatal        # CHANGED
@       [1]             \&fatal        # CHANGED
@       {a=>1}          \&fatal        # CHANGED
@       "foo"           \&fatal        # CHANGED
@       qr//            \&fatal        # CHANGED
# sub is now called on empty hashes / arrays because RHS CODE SEMANTICS CHANGED
@       []              \&fatal        # CHANGED
@       +{}             \&fatal        # CHANGED
@      \@empty          \&fatal        # CHANGED
@      \%empty          \&fatal        # CHANGED
# sub is not special on the left BUT RHS CODE SEMANTICS STILL CHANGED
     "".sub {0}         qr/^CODE/                          # CHANGED: RHS REGEXP ONLY MATCHES NON-REFS
       [sub {0}]        sub { ref shift->[0] eq "CODE" }   # CHANGED: NEW RHS CODE SEMANTICS

# HASH ref against:
#   - another hash ref
        {}              {}
=!      {}              {1 => 2}
        {1 => 2}        {1 => 2}
=!      {1 => 2}        {1 => 3}         # CHANGED: HASH vs HASH NOW REQUIRES MATCHING VALUES AS WELL
        {1 => 2}        {1 => true}      # WORKAROUND FOR PREVIOUS LINE'S CHANGE
=!      {1 => 2}        {2 => 3}
        \%main::        {map {$_ => true} keys %main::}    # CHANGED: HASH/HASH REQUIRES VALUES MATCH

#  - tied hash ref
=       \%hash          \%tied_hash
        \%tied_hash     \%tied_hash
!=      {"a"=>"b"}      \%tied_hash
=      \%hash           \%tied_hash           # CHANGED: NO AUTO-ENREFERENCING
       \%tied_hash      \%tied_hash           # CHANGED: NO AUTO-ENREFERENCING
!=      {"a"=>"b"}      \%tied_hash           # CHANGED: NO AUTO-ENREFERENCING
@       $ov_obj         any=>[keys %refh]     # CHANGED: RHS HASH SEMANTICS CHANGED
@       "$ov_obj"       any=>[keys %refh]     # CHANGED: NO AUTO-ENREFERENCING
@       $ov_obj         any=>[keys %refh]     # CHANGED: NO AUTO-ENREFERENCING
@       "$ov_obj"       any=>[keys %refh]     # CHANGED: NO AUTO-ENREFERENCING
       \%refh           \%refh                # CHANGED: NO AUTO-ENREFERENCING

#  - an array ref  ALL THESE ARE CHANGED, BECAUSE smartmatch() HASH/ARRAY SEMANTICS CHANGED
#  (since this is symmetrical, tests as well the former hash~~array)
     all=>[keys %main::]       any=>[keys %::]          # CHANGED: ARRAY/HASH NEVER MATCH
     all=>[qw[STDIN STDOUT]]   any=>[keys %::]          # CHANGED: ARRAY/HASH NEVER MATCH
     all=>[keys %::]           any=>[keys %main::]      # CHANGED: ARRAY/HASH NEVER MATCH
     any=>[keys %::]           any=>[qw[STDIN STDOUT]]  # CHANGED: ARRAY/HASH NEVER MATCH
=!      []                        \%::
=!      [""]                      {}
=!      []                        {}
=!     \@empty                    {}
=!     any=>[undef]              any=>[keys %{{"" => 1}}]      # CHANGED: undef NO LONGER PROMOTED
=      any=>[""]                 any=>[keys %{{"" => 1}}]      # CHANGED: ARRAY/HASH SEMANTICS
=      any=>["foo"]              any=>[keys %{{ foo => 1 }}]   # CHANGED: ARRAY/HASH SEMANTICS
=      any=>["foo", "bar"]       any=>[keys %{{ foo => 1 }}]   # CHANGED: ARRAY/HASH SEMANTICS
=      any=>["foo", "bar"]       any=>[keys %hash]             # CHANGED: ARRAY/HASH SEMANTICS
=      any=>["foo"]              any=>[keys %hash]             # CHANGED: ARRAY/HASH SEMANTICS
=!     any=>["quux"]             any=>[keys %hash]             # CHANGED: ARRAY/HASH SEMANTICS
=      any=>[qw(foo quux)]       any=>[keys %hash]             # CHANGED: ARRAY/HASH SEMANTICS
       all=>\@fooormore          any=>[keys %{{ foo => 1, or => 2, more => 3 }}]   # CHANGED
       all=>\@fooormore          any=>[keys %fooormore]        # CHANGED: ARRAY/HASH SEMANTICS
       all=>\@fooormore          any=>[keys %fooormore]        # CHANGED: ARRAY/HASH SEMANTICS
       all=>\@fooormore          any=>[keys %fooormore]        # CHANGED: ARRAY/HASH SEMANTICS

#  - a regex   ALL CHANGED (REGEXP ON THE LHS NEVER MATCHES, EXCEPT THE SAME REGEX ON THE LHS)
=!      qr/^(fo[ox])$/          {foo => 1}      # CHANGED: REGEXP/ANY SEMANTICS CHANGED
=!      qr/^(fo[ox])$/         \%fooormore      # CHANGED: REGEXP/ANY SEMANTICS CHANGED
=!      qr/[13579]$/            +{0..99}        # CHANGED: REGEXP/ANY SEMANTICS CHANGED
=!      qr/a*/                  {}              # CHANGED: REGEXP/ANY SEMANTICS CHANGED
=!      qr/a*/                  {b=>2}          # CHANGED: REGEXP/ANY SEMANTICS CHANGED
=!      qr/B/i                  {b=>2}          # CHANGED: REGEXP/ANY SEMANTICS CHANGED
=!      qr/B/i                  {b=>2}          # CHANGED: REGEXP/ANY SEMANTICS CHANGED
=!      qr/a+/                  {b=>2}          # CHANGED: REGEXP/ANY SEMANTICS CHANGED
=!      qr/^à/                  {"à"=>2}        # CHANGED: REGEXP/ANY SEMANTICS CHANGED

#  - a scalar
        "foo"           any=>[keys %{+{foo => 1, bar => 2}}]
        "foo"           any=>[keys %fooormore]
!       "baz"           any=>[keys %{+{foo => 1, bar => 2}}]
!       "boz"           any=>[keys %fooormore]
!       1               any=>[keys %{+{foo => 1, bar => 2}}]
!       1               any=>[keys %fooormore]
        1               any=>[keys %{{ 1 => 3 }}]
        1.0             any=>[keys %{{ 1 => 3 }}]
!       "1.0"           any=>[keys %{{ 1 => 3 }}]
!       "1.0"           any=>[keys %{{ 1.0 => 3 }}]
        "1.0"           any=>[keys %{{ "1.0" => 3 }}]
        "à"             any=>[keys %{{ "à" => "À" }}]

#  - undef
!       undef           { hop => 'zouu' }
!       undef          \%hash                    # CHANGED: NO AUTO_ENREFERENCING
!       undef           +{"" => "empty key"}
!       undef           {}

# ARRAY ref against:
#  - another array ref
        []                      []
=!      []                      [1]
!       [["foo"], ["bar"]]      [qr/o/, qr/a/]            # CHANGED: NO AUTO-FLATTENING NESTED REFS
!       [["foo"], ["bar"]]      [qr/ARRAY/, qr/ARRAY/]
        ["foo", "bar"]          [qr/o/, qr/a/]
!       [qr/o/, qr/a/]          ["foo", "bar"]
!       ["foo", "bar"]          [["foo"], ["bar"]]        # CHANGED: NO AUTO-FLATTENING NESTED REFS
!       ["foo", "bar"]          [qr/o/, "foo"]
        ["foo", undef, "bar"]   [qr/o/, undef, "bar"]
!       ["foo", undef, "bar"]   [qr/o/, "", "bar"]
!       ["foo", "", "bar"]      [qr/o/, undef, "bar"]
        $deep1                  $deep1
       \@$deep1                \@$deep1                   # CHANGED: NO AUTO-ENREFERENCING
!       $deep1                  $deep2

=       \@nums                  \@tied_nums
=      \@nums                   \@tied_nums           # CHANGED: NO AUTO_ENREFERENCING
=       \@nums                 \@tied_nums
=      \@nums                  \@tied_nums            # CHANGED: NO AUTO_ENREFERENCING

#  - an object
!       $obj           \@fooormore
        $obj            any=>[sub{ref shift}]          # CHANGED: RHS ARRAY MATCHING SEMANTICS CHANGED

#  - a regex ... ON THE LEFT IS NOW NO LONGER REVERSIBLE
!       qr/x/           any=>[qw(foo bar baz quux)]    # CHANGED: RHS ARRAY MATCHING SEMANTICS CHANGED
        any=>[qw(foo bar baz quux)]    qr/x/           # CHANGED: RHS ARRAY MATCHING SEMANTICS CHANGED
=!      qr/y/           any=>[qw(foo bar baz quux)]    # CHANGED: RHS ARRAY MATCHING SEMANTICS CHANGED
!     qr/x/             any=>[qw(foo bar baz quux)]    # CHANGED: RHS ARRAY MATCHING SEMANTICS CHANGED
      any=>[qw(foo bar baz quux)]      qr/x/           # CHANGED: RHS ARRAY MATCHING SEMANTICS CHANGED
=!    qr/y/             any=>[qw(foo bar baz quux)]    # CHANGED: RHS ARRAY MATCHING SEMANTICS CHANGED
!     qr/FOO/i          any=>\@fooormore               # CHANGED: RHS ARRAY MATCHING SEMANTICS CHANGED
      any=>\@fooormore                 qr/FOO/i        # CHANGED: RHS ARRAY MATCHING SEMANTICS CHANGED
=!    qr/bar/           any=>\@fooormore               # CHANGED: RHS ARRAY MATCHING SEMANTICS CHANGED

# - a number
!       2               any=>[qw(1.00 2.00)]           # CHANGED: ONLY ACTUAL RHS NUMS MATCH WITH ==
        2               any=>[qw(foo 2)]               # CHANGED: RHS ARRAY MATCHING SEMANTICS
        2.0_0e+0        any=>[qw(foo 2)]               # CHANGED: RHS ARRAY MATCHING SEMANTICS
!       2               any=>[qw(1foo bar2)]           # CHANGED: RHS ARRAY MATCHING SEMANTICS

# - a string
!       "2"             any=>[qw(1foo 2bar)]           # CHANGED: RHS ARRAY MATCHING SEMANTICS
        "2bar"          any=>[qw(1foo 2bar)]           # CHANGED: RHS ARRAY MATCHING SEMANTICS

# - undef
        undef           any=>[1, 2, undef, 4]          # CHANGED: RHS ARRAY MATCHING SEMANTICS
!       undef           any=>[1, 2, [undef], 4]        # CHANGED: RHS ARRAY MATCHING SEMANTICS
!       undef           any=>\@fooormore               # CHANGED: RHS ARRAY MATCHING SEMANTICS
        undef           any=>\@sparse                  # CHANGED: RHS ARRAY MATCHING SEMANTICS
        undef           any=>[undef]                   # CHANGED: RHS ARRAY MATCHING SEMANTICS
!       0               any=>[undef]                   # CHANGED: RHS ARRAY MATCHING SEMANTICS
!       ""              any=>[undef]                   # CHANGED: RHS ARRAY MATCHING SEMANTICS
!       undef           any=>[0]                       # CHANGED: RHS ARRAY MATCHING SEMANTICS
!       undef           any=>[""]                      # CHANGED: RHS ARRAY MATCHING SEMANTICS

# - nested arrays and ~~ distributivity  (NOPE: THEY NO LONGER WORK THAT WAY)
!       11              [[11]]                 # CHANGED
!       11              [[12]]                 # CHANGED
!       "foo"           [{foo => "bar"}]       # CHANGED
!       "bar"           [{foo => "bar"}]       # CHANGED

# Number against number
        2               2
        20              2_0
!       2               3
        0               FALSE
        3-2             !!TRUE                 # CHANGED: MUST NOW BE CANONICALLY true
!       undef           0
!       (my $u)         0

# Number against string
=       2               "2"
!       2               "2.0"                  # CHANGED: ONLY CANONICAL NUMBERS MATCH VIA ==
        "2.0"           2
!       2               "2bananas"
!=      2_3             "2_3"           NOWARNINGS
        FALSE           "0"
!       undef           "0"
!       undef           ""

# Regex against string
        "x"             qr/x/
!       "x"             qr/y/

# Regex against number
        12345           qr/3/
!       12345           qr/7/

# array/hash against string   (NO LONGER MATCHES BECAUSE RHS STRINGS NEVER MATCH REFS)
!      \@fooormore      "".\@fooormore           # CHANGED
!      \@keyandmore     "".\@fooormore           # CHANGED
!      \%fooormore      "".\%fooormore           # CHANGED
!      \%keyandmore     "".\%fooormore           # CHANGED

# Test the implicit referencing (THERE ISN'T ANY, SO THESE ALL NOW HAVE EXPLICIT REFERENCING)
        7               any=>\@nums            # CHANGED: RHS ARRAY NO LONGER DISJUNCTIVE
       \@nums           \@nums
!      \@nums           \ \@nums
       \@nums           [1..10]
!      \@nums           [0..9]

        "foo"              any=>[keys %hash]
!       /bar/             \%hash               # CHANGED: LHS REGEX NO LONGER MATCHES
        any=>[qw(bar)]     any=>[keys %hash]
!       [qw(a b c)]        any=>[keys %hash]
       \%hash             \%hash
       \%hash              +{%hash}
       \%hash              \%hash
       \%hash             \%tied_hash
       \%tied_hash        \%tied_hash
       \%hash              { foo => true, bar => true }                  # CHANGED: MUST MATCH VALUES
!      \%hash              { foo => true, bar => true, quux => true }    # CHANGED: MUST MATCH VALUES

        any=>\@nums        any=>[keys %{{ 1, '', 2, '' }}]      # CHANGED: NO ARRAY/HASH MATCHINg
        any=>\@nums        any=>[keys %{{ 1, '', 12, '' }}]     # CHANGED: NO ARRAY/HASH MATCHINg
!       any=>\@nums        any=>[keys %{{ 11, '', 12, '' }}]    # CHANGED: NO ARRAY/HASH MATCHINg

# array slices
        [@nums[0..-1]]   []                  # CHANGED: NO LONGER AUTO_ENREFERENCE
        [@nums[0..0] ]   [1]                 # CHANGED: NO LONGER AUTO_ENREFERENCE
!       [@nums[0..1] ]   [0..2]              # CHANGED: NO LONGER AUTO_ENREFERENCE
        [@nums[0..4] ]   [1..5]              # CHANGED: NO LONGER AUTO_ENREFERENCE

!       undef           any=>[@nums[0..-1]]      # CHANGED: SEMANTICS AND AUTO_ENREFERENCING
        1               any=>[@nums[0..0]]       # CHANGED: SEMANTICS AND AUTO_ENREFERENCING
        2               any=>[@nums[0..1]]       # CHANGED: SEMANTICS AND AUTO_ENREFERENCING
!       [@nums[0..1]]   2                        # CHANGED: SEMANTICS AND AUTO_ENREFERENCING

        [@nums[0..1]]     [@nums[0..1]]          # CHANGED: NO AUTO_ENREFERENCING

# hash slices  CHANGED: NO LONGER AUTO-ENREFERENCE OR DISTRIBUTE ACROSS RHS ARRAY
        [@keyandmore{qw(not)}]           [undef]                                  # CHANGED
        [@keyandmore{qw(key)}]           [0]                                      # CHANGED

        undef                            any=>[@keyandmore{qw(not)}]              # CHANGED
        0                                any=>[@keyandmore{qw(key and more)}]     # CHANGED
!       2                                any=>[@keyandmore{qw(key and)}]          # CHANGED

        [@fooormore{qw(foo)}]            [@keyandmore{qw(key)}]                   # CHANGED
        [@fooormore{qw(foo or more)}]    [@keyandmore{qw(key and more)}]          # CHANGED

# UNDEF
!       3               undef
!       1               undef
!       []              undef
!       {}              undef
!       \%::main        undef
!       [1,2]           undef
!      \%hash           undef          # CHANGED: NO AUTO_ENREFERENCING
!      \@nums           undef          # CHANGED: NO AUTO_ENREFERENCING
!       "foo"           undef
!       ""              undef
!       !1              undef
!       \&foo           undef
!       sub { }         undef

}}
