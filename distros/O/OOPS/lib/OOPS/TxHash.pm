
package OOPS::TxHash;

use strict;

sub commit
{
	my $self = shift;
	my ($under, $overlay, $whiteout) = @$self;
	for my $key (keys %$whiteout) {
		delete $under->{$key};
	}
	@$under{keys %$overlay} = values %$overlay;
	%$overlay = ();
	%$whiteout = ();
}

sub abort
{
	my $self = shift;
	my ($under, $overlay, $whiteout, $count) = @$self;
	%$overlay = ();
	%$whiteout = ();
	$$count = keys %$under;
}

sub TIEHASH
{
	my $pkg = shift;
	my ($under) = @_;
	my $count = keys %$under;
	my $doneunder;
	my $self = bless [ $under, {}, {}, \$count, \$doneunder ], $pkg;
	return $self;
}

sub FETCH
{
	my $self = shift;
	my ($under, $overlay, $whiteout) = @$self;
	my $key = shift;
	return undef 		if exists $whiteout->{$key};
	return $overlay->{$key}	if exists $overlay->{$key};
	return $under->{$key};
}

sub STORE
{
	my $self = shift;
	my ($under, $overlay, $whiteout, $count) = @$self;
	my ($key, $value) = @_;
	$$count++ if exists $whiteout->{$key}
		or ! (exists $under->{$key} or exists $overlay->{$key});
	$overlay->{$key} = $value;
	delete $whiteout->{$key};
	return $value;
}

sub DELETE
{
	my $self = shift;
	my ($under, $overlay, $whiteout, $count) = @$self;
	my $key = shift;
	my $old = $self->FETCH($key);
	return $old if exists $whiteout->{$key};
	$$count-- if exists $under->{$key} or exists $overlay->{$key};
	$whiteout->{$key} = 1;
	delete $overlay->{$key};
	return $old;
}

sub CLEAR
{
	my $self = shift;
	my ($under, $overlay, $whiteout, $count) = @$self;
	for my $key (keys %$overlay) {
		$$count-- unless $whiteout->{$key};
	}
	%$overlay = ();
	for my $key (keys %$under) {
		$$count-- unless $whiteout->{$key};
	}
	@$whiteout{keys %$under} = (1) x scalar(keys %$under);
}

sub EXISTS
{
	my $self = shift;
	my ($under, $overlay, $whiteout) = @$self;
	my $key = shift;
	return 0 if exists $whiteout->{$key};
	return 1 if exists $overlay->{$key};
	return 1 if exists $under->{$key};
	return 0;
}

sub FIRSTKEY
{
	my $self = shift;
	my ($under, $overlay, $whiteout, $count, $doneunder) = @$self;
	keys %$under;
	keys %$overlay;
	$$doneunder = 0;
	return $self->NEXTKEY;
}

sub NEXTKEY
{
	my $self = shift;
	my ($under, $overlay, $whiteout, $count, $doneunder) = @$self;
	my ($key, $value);
	unless ($$doneunder) {
		while (($key, $value) = each(%$under)) {
			next if $whiteout->{$key};
			return $key;
		}
		$$doneunder = 1;
	}
	while (($key, $value) = each(%$overlay)) {
		next if $whiteout->{$key};
		return $key;
	}
	return ();
}

sub SCALAR
{
	my $self = shift;
	my ($under, $overlay, $whiteout, $count) = @$self;
	return $$count;
}

1;

__END__

=head1 NAME
 
 OOPS::TxHash - Transactions on a simple hash

=head1 SYNOPSIS

 use OOPS::TxHash;

 my %underlying_hash;
 my $th = tie my %hash, 'OOPS::TxHash', \%underlying_hash or die;

 $th->commit;
 $th->abort;

=head1 DESCRIPTION

OOPS::TxHash provides transactions on a hash.  Changes to
the tied hash will only be reflected on the underlying if
commit() is called.

This is not recursive: if a hash value is a reference and
the reference is followed to a value and the value is changed,
it will be changed for both the hash and the underlying
hash.  

The abort() method will reset the values of the hash to
the underlying hash.  

No commit() is called by DESTROY: you must call commit()
explicitly if you want the changes preserved.

