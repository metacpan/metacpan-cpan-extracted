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
package PDF::Builder::Basic::PDF::Bool;

use base 'PDF::Builder::Basic::PDF::String';

use strict;
use warnings;

our $VERSION = '3.026'; # VERSION
our $LAST_UPDATE = '3.026'; # manually update whenever code is changed

=head1 NAME

PDF::Builder::Basic::PDF::Bool - A special form of 
L<PDF::Builder::Basic::PDF::String> which holds the strings
B<true> or B<false>

=head1 METHODS

=head2 convert

    $b->convert($str)

=over

Converts a string into the string which will be stored.

=back

=cut

sub convert {
    return $_[1] eq 'true';
}

=head2 as_pdf

    $b->as_pdf()

=over

Converts the value to a PDF output form.

=back

=cut

sub as_pdf {
    return $_[0]->{'val'}? 'true': 'false';
}

1;
