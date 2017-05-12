## ----------------------------------------------------------------------------
#  UNIVERSAL::to_s
# -----------------------------------------------------------------------------
# Mastering programmed by YAMASHINA Hio
#
# Copyright 2006 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id$
# -----------------------------------------------------------------------------
package UNIVERSAL::to_s;
use strict;
use warnings;

our $VERSION = '0.01';

sub UNIVERSAL::to_s
{
	# same as String::String 0.01.
  wantarray ? map{ defined($_) ? "$_" : '' } @_ : join('', &UNIVERSAL::to_s);
}

__END__

=head1 NAME

UNIVERSAL::to_s - to_s method with all objects.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

 use UNIVERSAL::to_s;
 
 print $o->to_s;

if you want to_s with non-objects (un-blessed reference or scalar),
you can use L<autobox>.
L<autobox> allows calling methods on these and UNIVERSAL
works as well as blessed objects.

=head1 EXPORT

no functions exported.

but all objects have to_s method now!

=head1 AUTHOR

YAMASHINA Hio, C<< <hio at hio.jp> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-universal-to_s at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=UNIVERSAL-to_s>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc UNIVERSAL::to_s

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/UNIVERSAL-to_s>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/UNIVERSAL-to_s>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=UNIVERSAL-to_s>

=item * Search CPAN

L<http://search.cpan.org/dist/UNIVERSAL-to_s>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 YAMASHINA Hio, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
