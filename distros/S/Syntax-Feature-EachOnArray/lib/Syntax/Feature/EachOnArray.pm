package Syntax::Feature::EachOnArray; # don't confuse dzil?
our $VERSION = '0.04'; # VERSION
# BEGIN PORTION (c) Toby Inkster
{
	package Tie::ArrayAsHash;

	use strict;
	no warnings;
	use Carp;
	use Hash::FieldHash qw(fieldhash);
	use Scalar::Util qw(reftype);

	use base qw(Exporter);
	BEGIN {
		our @EXPORT_OK = 'aeach';
		$INC{'Tie/ArrayAsHash.pm'} = __FILE__;
	};

	use constant {
		IDX_DATA  => 0,
		IDX_EACH  => 1,
		NEXT_IDX  => 2,
	};

	fieldhash our %cache;

	sub aeach (\[@%])
	{
		my $thing = shift;
		return each %$thing
			if reftype $thing eq 'HASH';
		confess "should be passed a HASH or ARRAY"
			unless reftype $thing eq 'ARRAY';

		my $thing_h = $cache{$thing} ||= do {
			tie my %h, __PACKAGE__, $thing;
			\%h
		};

		each %$thing_h;
	}

	sub TIEHASH
	{
		my ($class, $arrayref) = @_;
		bless [$arrayref, 0] => $class;
	}

	sub STORE
	{
		my ($self, $k, $v) = @_;
		$self->[IDX_DATA][$k] = $v;
	}

	sub FETCH
	{
		my ($self, $k) = @_;
		$self->[IDX_DATA][$k];
	}

	sub FIRSTKEY
	{
		my ($self) = @_;
		$self->[IDX_EACH] = 0;
		$self->NEXTKEY;
	}

	sub NEXTKEY
	{
		my ($self) = @_;
		my $curr = $self->[IDX_EACH]++;
		return if $curr >= @{ $self->[IDX_DATA] };
		return $curr;
	}

	sub EXISTS
	{
		my ($self, $k) = @_;
		!!($k eq $k+0
			and $k < @{ $self->[IDX_DATA] }
		);
	}

	sub DELETE
	{
		my ($self, $k) = @_;
		return pop @{ $self->[IDX_DATA] }
			if @{ $self->[IDX_DATA] } == $k + 1;
		confess "DELETE not fully implemented";
	}

	sub CLEAR
	{
		my ($self) = @_;
		$self->[IDX_DATA] = [];
	}

	sub SCALAR
	{
		my ($self) = @_;
		my %tmp =
			map { $_ => $self->[IDX_DATA][$_] }
			0 .. $#{ $self->[IDX_DATA] };
		return scalar(%tmp);
	}
}
# END PORTION

package Syntax::Feature::EachOnArray;

use strict;
use warnings;
use Tie::ArrayAsHash qw(aeach);

sub install {
    my $class = shift;
    my %args = @_;

    return unless $^V lt 5.12.0;
    no strict 'refs';
    *{"$args{into}::each"} = \&aeach;
}

# XXX on uninstall, delete symbol

1;
# ABSTRACT: Emulate each(@array) on Perl < 5.12


__END__
=pod

=head1 NAME

Syntax::Feature::EachOnArray - Emulate each(@array) on Perl < 5.12

=head1 VERSION

version 0.04

=head1 SYNOPSIS

 # This can run on Perls older than 5.12 and have no effect on 5.12+

 use syntax 'each_on_array';

 my @a = (qw/a b c/);
 while (my ($idx, $item) = each @a) {
     ...
 }

=head1 DESCRIPTION

Beginning with 5.12, Perl supports each() on array. This syntax extension
emulates the support on older Perls.

=for Pod::Coverage ^(install)$

=head1 CAVEATS

No uninstall() yet.

=head1 CREDITS

Thanks to Toby Inkster for writing the tie handler.

=head1 SEE ALSO

This module originates from this discussion thread:
L<http://www.perlmonks.org/?node_id=983878>

L<syntax>

L<Syntax::Feature::KeysOnArray>

L<Syntax::Feature::ValuesOnArray>

L<Array::Each::Override> (written in 2007, before Perl 5.10). Didn't find out
about this module until after I uploaded Syntax::Feature::EachOnArray to CPAN.
This module, although not using the L<syntax> syntax, does everything
Syntax::Feature::{Each,Keys,Values}OnArray does and more. Take a look at it.

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

