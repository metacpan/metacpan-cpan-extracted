#=======================================================================
#
#   THIS IS A REUSED PERL MODULE, FOR PROPER LICENCING TERMS SEE BELOW:
#
#   Copyright Martin Hosken <Martin_Hosken@sil.org>
#
#   No warranty or expression of effectiveness, least of all regarding
#   anyone's safety, is implied in this software or documentation.
#
#   This specific module is licensed under the Perl Artistic License.
#   Effective 28 January 2021, the original author and copyright holder, 
#   Martin Hosken, has given permission to use and redistribute this module 
#   under the MIT license.
#
#=======================================================================
package PDF::Builder::Basic::PDF::Number;

use base 'PDF::Builder::Basic::PDF::String';

use strict;
use warnings;

our $VERSION = '3.028'; # VERSION
our $LAST_UPDATE = '3.027'; # manually update whenever code is changed

=head1 NAME

PDF::Builder::Basic::PDF::Number - Numbers in PDF

Inherits from L<PDF::Builder::Basic::PDF::String>

=head1 METHODS

=head2 convert

    $n->convert($str)

=over

Converts a string from PDF to internal, by doing nothing

=back

=cut

sub convert {
    return $_[1];
}

=head2 as_pdf

    $n->as_pdf()

=over

Converts a number to PDF format

=back

=cut

sub as_pdf {
    return $_[0]->{'val'};
}

1;
