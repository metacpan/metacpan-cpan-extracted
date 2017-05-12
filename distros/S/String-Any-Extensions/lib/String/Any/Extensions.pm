package String::Any::Extensions;

=encoding UTF-8
 
=head1 NAME
 
String::Any::Extensions - Get extensions from string possible for files.
 
=head1 VERSION

version 0.02

=cut

our $VERSION = '0.02';    # VERSION

use utf8;
use strict;
use warnings;
use List::Util qw/any/;
use vars qw/$VERSION @EXPORT_OK/;
require Exporter;
*import    = \&Exporter::import;
@EXPORT_OK = qw( exclude extension include);

=head2 include

True or false if the file extension is in the including list.

=cut

sub include {
    return ( any { $_ eq extension( $_[0] ) } @{ $_[1] } ) ? 1 : 0;
}

=head2 exclude

True or false if the file extension is in the excluding list.

=cut

sub exclude {
    return ( !scalar any { $_ eq extension( $_[0] ) } @{ $_[1] } ) ? 1 : 0;
}

=head2 extension

Parse extension from file string.

=cut

sub extension {
    my ($extension) = $_[0] =~ /((\.[^.\s|(\/|\\|::]+)+)$/;
    return $extension;
}

1;

__END__

=pod
 
=head1 SYNOPSIS
 
    ...
    use String::Any::Extensions qw/include exclude/;

    #returns true
    include('some_string.ext.ext2', ['.ext','.ext.ext2']);

    #returns false
    exclude('some_string.ext.ext2', ['.ext','.ext.ext2']);

    #returns false '.ext.ext2'
    extension('some_string.ext.ext2');

    ...
 
=head1 AUTHOR

Mario Zieschang, C<< <mziescha at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-String-Any-Extensions at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=String-Any-Extensions>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc String::Any::Extensions


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=String-Any-Extensions>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/String-Any-Extensions>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/String-Any-Extensions>

=item * Search CPAN

L<http://search.cpan.org/dist/String-Any-Extensions/>

=back

=head1 SEE ALSO
 
=over 4
 
=item L<List::Filter::Library::FileExtensions>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Mario Zieschang.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
