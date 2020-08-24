package MooX::Private::Attribute;
use strict;
use warnings;
use MooX::ReturnModifiers;
our $VERSION = 0.01;

sub import {
	my $target    = caller;
	my %modifiers = return_modifiers( $target, [qw/before around/] );
	$modifiers{around}->(
		'has',
		sub {
			my ( $orig, $attr, %opts ) = @_;
			my $private = delete $opts{private};
			$orig->( $attr, %opts );
			$modifiers{before}->(
				$attr,
				sub {
					my $private_caller = caller(1);
					if ( $private_caller ne $target ) {
						die
						    "cannot call private attribute $attr from $private_caller";
					}
				}
			) if $private;
		}
	);
}

1;

__END__

=head1 NAME

MooX::Private::Attribute - private attributes

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

	package Lays;

	use Moo;
	use MooX::Private::Attribute;

	has size => (
		is => 'ro',
		private => 1
	);

	has flavour => (
		is => 'ro',
		private => 1
	);

	sub bag {
		return {
			size => $_[0]->size,
			flavour => $_[0]->flavour
		}
	}

	....

	my $salt = Lays->new( 
		size => q|οικογένεια|,
		flavour => q|τυρί & κρεμμύδι| 
	);

	$salt->bag # works
	$salt->size # errors
	$salt->flavour # errors

=head1 SUBROUTINES/METHODS

=head2 import

call import method.

	$obj->import()

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-moox::private::attribute at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooX-Private-Attribute>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooX::Private::Attribute

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=MooX-Private-Attribute>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooX-Private-Attribute>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/MooX-Private-Attribute>

=item * Search CPAN

L<https://metacpan.org/release/MooX-Private-Attribute>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

 
