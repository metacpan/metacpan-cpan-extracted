#!/usr/bin/perl

# Main testing for Perl::MinimumVersion

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More 0.47 tests => 116;
use version 0.76;
use File::Spec::Functions ':ALL';
use PPI 1.215;
use Perl::MinimumVersion 'PMV';

sub version_is {
	my $Document = PPI::Document->new( \$_[0] );
	isa_ok( $Document, 'PPI::Document' );
	my $v = Perl::MinimumVersion->new( $Document );
	isa_ok( $v, 'Perl::MinimumVersion' );
	is( $v->minimum_version, $_[1], $_[2] || 'Version matches expected' );
	$v;
}





#####################################################################
# Basic Testing

# Test support function _max
is( PMV, 'Perl::MinimumVersion', 'PMV constant exports correctly' );

# Check the _max support function (bad)
is( Perl::MinimumVersion::_max(),      '', '_max() returns false'      );
is( Perl::MinimumVersion::_max(undef), '', '_max(undef) returns false' );
is( Perl::MinimumVersion::_max(''),    '', '_max(undef) returns false' );

# Check the _max support function (good)
is_deeply( Perl::MinimumVersion::_max(version->new(5.004)),
	version->new(5.004),
	'_max(one) returns the same valud' );

is_deeply( Perl::MinimumVersion::_max(version->new(5.004), undef),
	version->new(5.004),
	'_max(one, bad) returns the good version' );

is_deeply( Perl::MinimumVersion::_max(version->new(5.004), version->new(5.006)),
	version->new(5.006),
	'_max(two) returns the higher version' );

is_deeply( Perl::MinimumVersion::_max(version->new(5.006), version->new(5.004)),
	version->new(5.006),
	'_max(two) returns the higher version' );

is_deeply( Perl::MinimumVersion::_max(version->new(5.006), version->new(5.004), version->new('5.5.3')),
	version->new(5.006),
	'_max(three) returns the higher version' );

is_deeply( Perl::MinimumVersion::_max(version->new(5.006), version->new('5.8.4'), undef, version->new(5.004), '', version->new('5.5.3')),
	version->new('5.8.4'),
	'_max(three) returns the higher version' );

# Check the _max support function (bad)
is( PMV->_max(),      '', '_max() returns false (as method)'      );
is( PMV->_max(undef), '', '_max(undef) returns false (as method)' );
is( PMV->_max(''),    '', '_max(undef) returns false (as method)' );

# Check the _max support function (good)
is_deeply( PMV->_max(version->new(5.004)),
	version->new(5.004),
	'_max(one) returns the same value (as method)' );

is_deeply( PMV->_max(version->new(5.004), undef),
	version->new(5.004),
	'_max(one, bad) returns the good version (as method)' );

is_deeply( PMV->_max(version->new(5.004), version->new(5.006)),
	version->new(5.006),
	'_max(two) returns the higher version (as method)' );

is_deeply( PMV->_max(version->new(5.006), version->new(5.004)),
	version->new(5.006),
	'_max(two) returns the higher version (as method)' );

is_deeply( PMV->_max(version->new(5.006), version->new(5.004), version->new('5.5.3')),
	version->new(5.006),
	'_max(three) returns the higher version (as method)' );

is_deeply( PMV->_max(version->new(5.006), version->new('5.8.4'), undef, version->new(5.004), '', version->new('5.5.3')),
	version->new('5.8.4'),
	'_max(three) returns the higher version (as method)' );

# Constructor testing
SCOPE: {
	my $v = Perl::MinimumVersion->new( \'print "Hello World!\n";' );
	isa_ok( $v, 'Perl::MinimumVersion' );
	$v = Perl::MinimumVersion->new( catfile( 't', '02_main.t' ) );
	# version_is tests the final method

	# Bad things
	foreach ( {}, sub { 1 }, undef ) {
		is( Perl::MinimumVersion->new( $_ ), undef, '->new(evil) returns undef' );
	}
}

SCOPE: {
my $v = version_is( <<'END_PERL', '5.004', 'Hello World matches expected version' );
print "Hello World!\n";
END_PERL
is( $v->_any_our_variables, '', '->_any_our_variables returns false' );

# This first time, lets double check some assumptions
isa_ok( $v->Document, 'PPI::Document'  );
isa_ok( $v->minimum_version, 'version' );
}

# Try one with an 'our' in it
SCOPE: {
my $v = version_is( <<'END_PERL', '5.006', '"our" matches expected version' );
our $foo = 'bar';
END_PERL
ok( $v->_any_our_variables, '->_any_our_variables returns true' );
}

# Try with attributes
SCOPE: {
my $v = version_is( <<'END_PERL', '5.006', '"attributes" matches expected version' );
sub foo : attribute { 1 };
END_PERL
ok( $v->_any_attributes, '->_any_attributes returns true' );
}

# Check with a complex explicit
SCOPE: {
my $v = version_is( <<'END_PERL', '5.008', 'explicit versions are detected' );
sub foo : attribute { 1 };
require 5.006;
use 5.008;
END_PERL
}

# Check with syntax higher than explicit
SCOPE: {
my $v = version_is( <<'END_PERL', '5.006', 'Used syntax higher than low explicit' );
sub foo : attribute { 1 };
require 5.005;
END_PERL
}

# Regression bug: utf8 mispelled
SCOPE: {
my $v = version_is( <<'END_PERL', '5.008', 'utf8 module makes the version 5.008' );
use utf8;
1;
END_PERL
}

# Regression: binary
SCOPE: {
my $v = version_is( <<'END_PERL', '5.006', 'binary' );
$c=0b10000001;
1;
END_PERL
}

# Check the use of constant hashes
SCOPE: {
my $v = version_is( <<'END_PERL', '5.008', 'constant hash adds a 5.008 dep' );
use constant {
	FOO => 1,
};
1;
END_PERL
}

# Check regular use of constants
SCOPE: {
my $v = version_is( <<'END_PERL', '5.004', 'normal constant use has no dep' );
use constant FOO => 1;
1;
END_PERL
}

# Check 'mro' pragma
SCOPE: {
my $v = version_is( <<'END_PERL', '5.010', '"use mro" matches expected version' );
use mro 'c3';
END_PERL
ok( $v->_perl_5010_pragmas, '->_perl_5010_pragmas returns true' );
}

# Check "version number"
SCOPE: {
my $v = version_is( <<'END_PERL', '5.006', '"version number" detected' );
my $a=v1.1.1;
END_PERL
ok( $v->_any_version_literals, '->_any_version_literals returns true' );
}

# Check the localized soft refernence pragma
SCOPE: {
my $v = version_is( <<'END_PERL', '5.008', 'Localized soft reference matched expected version' );
local ${ "${class}::DIE" } = 1;
END_PERL
ok( $v->_local_soft_reference, '->_local_soft_reference returns true' );
}

# Check variables added in 5.5
SCOPE: {
my $v = version_is( <<'END_PERL', '5.005', 'variables added in 5.5' );
$! + $^R;
END_PERL
ok( $v->_5005_variables, '->_5005_variables returns true' );
}


# Check $^E + $!
SCOPE: {
my $v = version_is( <<'END_PERL', '5.008.003', '$^E + $!' );
$! + $^E;
END_PERL
is( $v->_bugfix_magic_errno->symbol, '$^E','->_bugfix_magic_errno returns $^E' );
}



# Check that minimum_syntax_version's limit param is respected
SCOPE: {
my $doc = PPI::Document->new(\'our $x'); # requires 5.006 syntax
my $minver = Perl::MinimumVersion->new($doc);
is(
  $minver->minimum_syntax_version,
  5.006,
  "5.006 syntax found when no limit supplied",
);
is(
  $minver->minimum_syntax_version(5.005),
  5.006,
  "5.006 syntax found when 5.005 limit supplied",
);
is(
  $minver->minimum_syntax_version(version->new(5.008)),
  '',
  "no syntax constraints found when 5.008 limit supplied",
);
is(
  Perl::MinimumVersion->minimum_syntax_version($doc, version->new(5.008)),
  '',
  "also works as object method with limit: no constraints found",
);
}


# Check feature bundle
SCOPE: {
my $v = version_is( <<'END_PERL', '5.12.0', 'use feature :5.12 matches expected version' );
use feature ':5.12';
END_PERL
}
SCOPE: {
my $v = version_is( <<'END_PERL', '5.10.0', 'use feature :5.10 along with older feature' );
use feature ':5.10';open A,'<','test.txt';
END_PERL
}
SCOPE: {
my $v = version_is( <<'END_PERL', '5.012', 'use feature :5.10 along with newer feature' );
use feature ':5.10';
sub foo { ... };
END_PERL
}

# Check regexes
SCOPE: {
my $v = version_is( <<'END_PERL', '5.005', '\z in regex matches expected version' );
m/a\z/
END_PERL
}
SCOPE: {
my $v = version_is( <<'END_PERL', '5.006', '\z along with newer feature' );
m/a\z/;open A,'<','test.txt';
END_PERL
}
SCOPE: {
my $v = version_is( <<'END_PERL', '5.015008', '\F' );
s/\Fa//;
END_PERL
}
SCOPE: {
my $v = version_is( <<'END_PERL', '5.004', '/c regex modifier' );
s//c;
END_PERL
}
SCOPE: {
my $v = version_is( <<'END_PERL', '5.015008', '\F and use feature' );
use feature ':5.10';
s/\Fa//;
END_PERL
}
SCOPE: {
my $v = version_is( <<'END_PERL', '5.16.0', '\F and use feature' );
use feature ':5.16';
s/\Fa//;
END_PERL
}

#check binmode
SCOPE: {
my $v = version_is( <<'END_PERL', '5.008', '2-arg binmode with utf' );
binmode($fh, ':utf');
END_PERL
}

# test version_markers
SCOPE: {
my $perl = <<'END_PERL';
use 5.005;
use mro 'dfs';
our $VERSION;
sub example : Sufficies { }
END_PERL
my @result = PMV->version_markers(\$perl);
is(@result, 6, "we find three versioned marked in the result");

my @expect = (
	'5.010' => [ qw(_perl_5010_pragmas) ],
	'5.006' => [ qw(_any_our_variables _any_attributes) ],
	'5.005' => [ qw(explicit) ],
);

for my $i (map { $_ * 2 } 0 .. $#result / 2) {
	is_deeply(
		[ "$result[$i]", [ sort @{ $result[$i + 1] } ] ],
		[ $expect[$i],   [ sort @{ $expect[$i + 1] } ] ],
		"correct data in results pos $i",
	);
}

}

#check _checks2skip
SCOPE: {
my $doc = PPI::Document->new(\'our $x;s/a//u;$^R;');
my $minver = Perl::MinimumVersion->new($doc);
$minver->_set_checks2skip([qw/_any_our_variables _regex/]);
is(
  $minver->minimum_syntax_version,
  '5.005',
  "5.6 checks not run when _checks2skip was used",
);
}
#check _checks2skip
SCOPE: {
my $doc = PPI::Document->new(\'our $x;s/a//u;$^R;');
my $minver = Perl::MinimumVersion->new($doc);
$minver->_set_collect_all_reasons();
like(
  $minver->minimum_syntax_version,
  qr/^5\.013010?$/,
  "correct version",
);
is(
  scalar(@{ $minver->{_all_reasons} }),
  3,
  "3 checks met",
);
}


1;
