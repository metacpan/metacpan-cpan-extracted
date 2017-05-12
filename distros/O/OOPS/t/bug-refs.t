#!/usr/bin/perl 

use warnings;
use strict;
use Scalar::Util qw(refaddr reftype blessed);
use Test::More tests => 6;

#
# References to tied hash values are all unique.  They each have
# their own address.  References remain even when the hash key
# is deleted.
#
# Sometimes the references can become disconnected from the underlying
# hash.  They'll reconnect on assignement.
#
# When a reference reconnects after assignement, any other references
# disconnect.  (not shown)
#

print "# block at ".__LINE__."\n";

TODO: {
	local $TODO = "bug 27555";

	my %x;
	tie %x, 'Hash1', {};

	$x{y} = 7;
	my $a = \$x{y};
	delete $x{y};
	$x{y} = 9;
	my $b = \$x{y};
	my $c = \$x{y};

	ok($$a == 7, 
		"The \$a reference should be disconnected"); 
	ok(refaddr($b) eq refaddr($c),
		"References to the same thing should be the same");

	delete $x{y};
	$$c = 17;
	ok($$b != 17,
		"Post-delete, references should be disconnected");
	ok($x{y} != 17,
		"Post-delete, references should be disconnected");

	my $d = \$x{y};
	$$a = 12;
	ok($x{y} != 12,
		"Post-disconnect, reconnect shouldn't happen");

	my $q = \$x{q};
	ok(exists($x{q}),
		"creating a reference creates a key");
}

exit(0);

package Hash1;

sub TIEHASH
{
	my $pkg = shift;
	return bless [ @_ ], $pkg;
}

sub FETCH
{
	my $self = shift;
	my $key = shift;
	my ($underlying) = @$self;
	return $underlying->{$key};
}

sub STORE
{
	my $self = shift;
	my $key = shift;
	my $value = shift;
	my ($underlying) = @$self;
	return ($underlying->{$key} = $value);
}

sub DELETE
{
	my ($self, $key) = @_;
	my ($underlying) = @$self;
	return delete($underlying->{$key});
}

sub CLEAR
{
	my $self = shift;
	my ($underlying) = @$self;
	%$underlying = ();
}

sub EXISTS
{
	my $self = shift;
	my $key = shift;
	my ($underlying) = @$self;
	return exists $underlying->{$key};
}

sub FIRSTKEY
{
	my $self = shift;
	my ($underlying) = @$self;
	keys %$underlying;
	return each %$underlying;
}

sub NEXTKEY
{
	my $self = shift;
	my ($underlying) = @$self;
	return each %$underlying;
}

1;
