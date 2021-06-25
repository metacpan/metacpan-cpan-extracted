package Syntax::Keyword::Combine::Keys;

use v5.14;
use strict;
use warnings;

use warnings;

use Carp;

our $VERSION = 0.09; 

require XSLoader;
XSLoader::load( __PACKAGE__, $VERSION );

our %HASH = ();

sub import {
	shift;
	my @syms = @_;

	@syms or @syms = ( "ckeys" );

	my %syms = map { $_ => 1 } @syms;

	$^H{"Syntax::Keyword::Combine::Keys/ckeys"}++ if delete $syms{ckeys};
	   
	croak "Unrecognised import symbols @{[ keys %syms ]}" if keys %syms;

	do {
		no strict 'refs';
		*{caller() . "::HASH"} = \%{Syntax::Keyword::Combine::Keys::HASH};
	};

	1;
}

1;

=head1 NAME

Syntax::Keyword::Combine::Keys - ckeys keyword

=head1 VERSION

Version 0.09

=cut

=head1 SYNOPSIS

	use Syntax::Keyword::Combine::Keys;

	my %hash = ckeys {
		$_ => $HASH{$_}->{value};
	} %{$hash1}, %hash2, e => { value => 500 };


=head1 DESCRIPTION

This ia an experimental module written for learning purposes. The module provides a single keyword - ckeys, most simply put it is a modification of map being passed the sorted keys of a hash. To demonstrate further the following is the "pure" perl equivalent of the synopsis.

	my %HASH = (%{$hash1}, %hash2, e => { value => 500 };
	my %hash = map {
		$_ => $HASH{$_}->{value};
	} sort keys %HASH;


=head1 KEYWORDS

=head2 ckeys

	my @keys = ckeys {
		uc $_;
	} %hash1, %hash2, %hash3

Repeatedly calls the block of code, with $_ locally set to each key from the given list. It Returns the processed values from the block. ckeys also exposes a variable called %HASH which contains the merged list that is passed to the block.

	%HASH = ( %hash1, %hash2, $hash3 );
	
=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-syntax-keyword-combine-keys at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Syntax-Keyword-Combine-Keys>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Syntax::Keyword::Combine::Keys


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Syntax-Keyword-Combine-Keys>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Syntax-Keyword-Combine-Keys>

=item * Search CPAN

L<https://metacpan.org/release/Syntax-Keyword-Combine-Keys>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Syntax::Keyword::Combine::Keys
