#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

use Syntax::Feature::With qw(with_hash);

# Empty hash list
{
	my ($a);

	my $result = with_hash sub { $a };

	ok(!defined $result, 'empty hash list: lexical remains undef');
}

# Empty hashref
{
	my %h;
	my ($a);

	my $result = with_hash \%h, sub { $a };

	ok(!defined $result, 'empty hashref: lexical remains undef');
}

# Flags + empty hash list
{
	my $a;

	my $result = with_hash -debug => sub { $a };

	ok(!defined $result, 'flags + empty hash list works');
}

# Flags + empty hashref
{
	my %h;
	my ($a);

	my $result = with_hash -strict => \%h, sub { $a };

	ok(!defined $result, 'flags + empty hashref works');
}

# Hash list with odd number of elements (user error)
{
	my $err;
	eval {
		with_hash a => 1 => 2 => sub { };   # malformed
	};
	$err = $@;

	like($err, qr/odd number of elements in hash list/,
		 'odd number of elements triggers error');
}

# Hashref + extra junk (user error)
{
	my %h = ( a => 1 );
	my $err;

	eval {
		with_hash \%h, 'junk', sub { };
	};
	$err = $@;

	like($err, qr/hashref must be the only argument before coderef/, 'extra junk before coderef triggers error');
}

# No coderef at all
{
	my $err;

	eval { with_hash a => 1 };
	$err = $@;

	like($err, qr/coderef/, 'missing coderef triggers error');
}

# Flags + hashref + coderef
{
	my %h = ( a => 10 );
	my ($a);

	my $result = with_hash -debug => \%h, sub { $a };

	is($result, 10, 'flags + hashref + coderef works');
}

# Flags + hash list + coderef
{
	my ($a);

	my $result = with_hash -trace => a => 5 => sub { $a };

	is($result, 5, 'flags + hash list + coderef works');
}

# Multiple flags
{
	my %h = ( a => 7 );
	my ($a);

	my $result = with_hash -strict => -debug => \%h, sub { $a };

	is($result, 7, 'multiple flags work');
}

# Hash list with only one key/value pair
{
	my ($a);

	my $result = with_hash a => 123 => sub { $a };

	is($result, 123, 'single key/value pair works');
}

# Hash list with many pairs
{
	my ($a, $b, $c);

	my $result = with_hash a => 1, b => 2, c => 3 => sub {
		return $a + $b + $c;
	};

	is($result, 6, 'multiple key/value pairs work');
}

# Hashref with many keys
{
	my %h = ( a => 1, b => 2, c => 3 );
	my ($a, $b, $c);

	my $result = with_hash \%h, sub { $a + $b + $c };

	is($result, 6, 'hashref with many keys works');
}

# with_hash should not modify the original hashref
{
	my %h = ( a => 1 );
	my ($a);

	with_hash \%h, sub { $a = 99 };

	is($h{a}, 99, 'writeback still works through with_hash');
}

# with_hash should not leak flags into with()
{
	my %h = ( a => 1 );
	my $a;

	my $result = with_hash -debug => \%h, sub { $a };

	is($result, 1, 'flags do not leak between calls');
}

done_testing();
