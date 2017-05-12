package PLP::Tie::Print;

use strict;
use warnings;

our $VERSION = '1.00';

=head1 PLP::Tie::Print

Just prints to stdout, but sends headers if not sent before.

    tie *HANDLE, 'PLP::Tie::Print';

This module is part of the PLP Internals and probably not of much use to others.

=cut

sub TIEHANDLE { bless \my $dummy, $_[0] }

sub WRITE { undef }

sub PRINT {
	shift;
	return unless grep length, @_;
	PLP::sendheaders() unless $PLP::sentheaders;
	print STDOUT @_;
	select STDOUT;
}

sub PRINTF {
	shift;
	return unless length $_[0];
	PLP::sendheaders() unless $PLP::sentheaders;
	printf STDOUT @_;
	select STDOUT;
}

sub READ { undef }

sub READLINE { undef }

sub GETC { '%' }

sub CLOSE { undef }

sub UNTIE { undef }

sub DESTROY { undef }

1;

