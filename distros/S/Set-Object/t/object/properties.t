#!/usr/bin/perl -w

use strict;
use Test::More tests => 79;
use Set::Object qw(ish_int is_int is_double is_string is_object
		   blessed reftype refaddr is_key);

is(is_int(0),         1, "is_int(0)");
is(is_int(7),         1, "is_int(7)");
is(is_key(7),         1, "is_key(7)");
is(is_int(7.0),   undef, "!is_int(7.0)");
is(is_key(7.0),       1, "is_key(7.0)");
is(is_int('7'),   undef, "!is_int('7')");
is(is_key('7'),       1, "is_key('7')");

is(is_string(7),     undef, "!is_string()");
is(is_string(7.0),   undef, "!is_string(7.0)");
is(is_string("7"),       1, "is_string('7')");

is(is_double(7),     undef, "!is_double(7)");
is(is_double(7.0),       1, "is_double(7.0)");
is(is_double("7"),   undef, "!is_double('7')");

# behvaiour for numeric strings
my $foo;
is(is_int($foo="7"), undef, "!is_int(\$foo = '7')");
is(is_double($foo),  undef, "!is_double($foo)");
is(ish_int($foo),    undef, "!ish_int($foo)");

# behaviour changes between Perls
#is(is_int($foo+0),       1, "is_int(\$foo + 0)");
is(is_int(int($foo)),    1, "is_int(int(\$foo))");
# behaviour changes between Perls
#is(is_double($foo),  undef, "is_double($foo)");
is(ish_int($foo),        7, "ish_int($foo)");

is(is_double($foo+0.01-0.01), 1, "is_double(\$foo + 0)");
is(is_double($foo),      1, "is_double($foo)");
is(is_int(int($foo)),    1, "is_int(int(\$foo))");
is(ish_int($foo),        7, "ish_int($foo)");

{
# no warnings for brevity
local($^W) = 0;

is(ish_int($foo = "7am"), undef,
   "!defined(ish_int($foo = '7am'))");
is(ish_int($foo + 0),   7, "ish_int(\$foo + 0) == 7");
# behaviour changes between Perls
#is(is_int($foo),    undef, "!is_int($foo)");
is(is_double($foo),     1, "is_double($foo)");
#diag("foo is $foo");
is(ish_int($foo),   undef, "!defined(ish_int($foo))");

is(ish_int($foo = "7.0"), undef,
   "!defined(ish_int($foo = '7.0'))");
is(ish_int($foo + 0),   7, "ish_int($foo + 0) == 7");
# behaviour changes between Perls
# is(is_int($foo),    undef, "!is_int($foo)");
is(is_double($foo),     1, "is_double($foo)");
is(ish_int($foo),   undef, "!defined(ish_int($foo))");

is(ish_int($foo = "7e6"), undef,
   "!defined(ish_int($foo = '7e6'))");
is(ish_int($foo + 0), 7e6, "ish_int($foo + 0) == 7e6");
# behaviour changes between Perls
# is(is_int($foo),    undef, "!is_int($foo)");
is(is_double($foo),     1, "is_double($foo)");
is(ish_int($foo),   undef, "!defined(ish_int($foo))");

is(ish_int($foo = "7"), undef,
   "!defined(ish_int($foo = '7'))");
is(ish_int($foo + 0.001 - 0.001),   7, "ish_int($foo + 0) == 7");
is(is_double($foo),     1, "is_double($foo)");
# behaviour changes between Perls
# is(is_int($foo),    undef, "is_int($foo)");
is(ish_int($foo),       7, "ish_int($foo) == 7");

is(ish_int($foo = "0"), undef,
   "!defined(ish_int($foo = '0'))");
is(ish_int($foo + 0.001 - 0.001),   0, "ish_int($foo + 0) == 0");
is(is_double($foo),     1, "is_double($foo)");
# behaviour changes between Perls
# is(is_int($foo),    undef, "is_int($foo)");
is(ish_int($foo),       0, "ish_int($foo) == 7");

# value must be within 1e-9 of an int
is(ish_int(7.000000001234), undef,
   "!ish_int(7.000000001234)");
is(ish_int(7.0000000001234), 7,
   "ish_int(7.0000000001234) == 7");

}

is(blessed($foo = []), undef, "!blessed(\$foo = [])");
is(is_key($foo), undef, "is_key([])");
is(reftype($foo), "ARRAY",
   "reftype(\$foo) eq 'ARRAY'");

bless $foo, "This";
is(blessed($foo), "This", "blessed(\$foo) eq 'This'");
is(reftype($foo), "ARRAY", "reftype(\$foo) eq 'ARRAY'");
is(is_key($foo), undef, "is_key(blessed array)");

$foo = {};
bless $foo, "This";
is(reftype({}),    "HASH", "reftype({})");
is(reftype($foo),  "HASH", "reftype(\$foo)");
is(is_key($foo), undef, "is_key(blessed hash)");

my %foo;
my $tiehandle = tie %foo, "This";

is(reftype(\%foo), "HASH", "reftype(\%foo) - tied");
is(reftype($tiehandle),
   "ARRAY", "reftype(\$tiehandle)");
untie(%foo);

my $psuedonum = psuedonum->new(7);

ok($psuedonum == 7, "Pseudonum numifies OK");
ok($psuedonum == 7.0, "Pseudonum numifies OK");
ok($psuedonum eq "7", "Pseudonum stringifies OK");
is(blessed($psuedonum), "psuedonum", "Pseudonum is blessed");
is(ish_int($psuedonum), 7, "ish_int(Pseudonum)");
is(is_key($psuedonum), 1, "is_key(psuedonum)");
$psuedonum = [ ];
is(is_key($psuedonum), undef, "is_key(psuedonum/hash)");

my $nevernum = nevernum->new(7);

eval { if ($nevernum == 7) { } };
ok($@, "nevernum dies when numified");
eval { if ($nevernum == 7.0) { } };
ok($@, "nevernum dies when doublified");
ok($nevernum eq "7", "nevernum stringifies OK");
ok(blessed($nevernum) eq "nevernum", "nevernum is blessed");
is(ish_int($nevernum), undef, "ish_int(Nevernum)");
is(is_key($nevernum), 1, "is_key(nevernum)");

my $notreallynum = notreallynum->new(7);

ok($notreallynum == 7, "notreallynum numifies OK");
ok($notreallynum == 7.0, "notreallynum numifies OK");
ok($notreallynum eq "7", "notreallynum stringifies OK");
ok(blessed($notreallynum) eq "notreallynum", "nevernum is blessed");
is(ish_int($notreallynum), undef, "ish_int(notreallynum)");
is(is_key($nevernum), 1, "is_key(notreallynum)");

# now test tied scalars
$tiehandle = tie $foo, "This";
$foo = 7;

ok(tied $foo, "\$foo is tied");

# my @spells = detect_magic($foo);
# ok(@spells && $spells[0] =~ m/Magic type q/,
# "Foo is definitely tied");

#use Devel::Peek qw(Dump);
#print Dump $foo;

is(ish_int($foo), 7, "ish_int(tied var)");
eval { _ish_int($foo) };
like($@, qr/tie/, "ish_int(tied var)");
is(is_key($foo), 1, "is_key(tied var)");

ok(refaddr($notreallynum) > 0 && refaddr($notreallynum) != refaddr($nevernum),
   "refaddr()");

exit(0);

# unused debugging function
sub showit {
    my $var = shift;
    if (defined $var) {
	if (is_int($var)) {
	    return $var;
	} elsif (is_double($var)) {
	    return sprintf("%e",$var);
	} elsif (is_string($var)) {
	    return "`$var'";
	} elsif (my $b = blessed($var)) {
	    return "Object($b)(".reftype($var).")";
	} else {
	    return "onion";
	}
    } else {
	return "undef";
    }
}
package This;

# this class is an array pretending to be a hash

sub TIESCALAR {
    my $invocant = shift;
    my $test = [ ];
    return bless $test, $invocant;
}

sub TIEHASH {
    my $invocant = shift;
    my $test = [ { } ];
    return bless $test, $invocant;
}

sub FETCH {
    my $self = shift;

    if (@_) {
	my $key = shift;
	if (my $idx = ish_int($key)) {
	    return $self->[$idx+1];
	} else {
	    if (exists $self->[0]->{$key}) {
		return $self->[$self->[0]->{$key}];
	    } else {
		return undef;
	    }
	}
    } else {
	# scalar fetch
	return $self->[0];
    }
}

sub STORE {
    my $self = shift;
    if (@_ == 2) {
	# hash set
	my $key  = shift;

	if (!defined $key) {
	    $key = "";
	}
    } elsif (@_ == 1) {
	# scalar set
	$self->[0] = shift;
    }
}

sub UNTIE {
    my $self = shift;
    @$self=();
}

package psuedonum;

use overload
    '""' => \&stringify,
    '0+' => \&numify,
    fallback => 1;

sub new {
    my $self = shift;
    my $val = shift;
    return bless { val => $val }
}

sub set {
    my $self = shift;
    my $val = shift;
    $self->{val} = $val;
}

sub stringify {
    my $self = shift;
    return "$self->{val}";
}

sub numify {
    my $self = shift;
    return $self->{val} + 0;
}

package notreallynum;

use overload
    '""' => \&stringify,
    fallback => 1;

sub new {
    my $self = shift;
    my $val = shift;
    return bless { val => $val }
}

sub set {
    my $self = shift;
    my $val = shift;
    $self->{val} = $val;
}

sub stringify {
    my $self = shift;
    return "$self->{val}";
}

package nevernum;

use overload
    '""' => \&stringify,
    'eq' => \&equal,
    fallback => 0;

sub new {
    my $self = shift;
    my $val = shift;
    return bless { val => $val }
}

sub set {
    my $self = shift;
    my $val = shift;
    $self->{val} = $val;
}

sub stringify {
    my $self = shift;
    return "$self->{val}";
}

sub equal {
    my $self = shift;
    my $other = shift;
    return $self->{val} eq $other;
}

