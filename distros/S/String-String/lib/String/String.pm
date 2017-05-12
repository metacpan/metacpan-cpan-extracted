## ----------------------------------------------------------------------------
#  String::String
# -----------------------------------------------------------------------------
# Mastering programmed by YAMASHINA Hio
#
# Copyright 2006 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id: perl.txt,v 1.9 2004/12/27 07:11:50 hio Exp $
# -----------------------------------------------------------------------------
package String::String;
use strict;
use warnings;
require Exporter;
our @ISA = qw(Exporter);
our $VERSION = '0.01';
our @EXPORT_OK = qw(string);
1;

sub string
{
  wantarray ? map{ defined($_) ? "$_" : '' } @_ : join('', &string);
}

__END__

=head1 NAME

String::String - make values string

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

 use String::String qw(string);

=head1 FUNCTIONS

=head2 string(LIST)

return stringy values of each LIST elements.

in scalar context, return is joined with ''.

=head1 AUTHOR

YAMASHINA Hio, C<< <hio at hio.jp> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-string-string at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=String-String>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc String::String

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/String-String>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/String-String>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=String-String>

=item * Search CPAN

L<http://search.cpan.org/dist/String-String>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 YAMASHINA Hio, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
