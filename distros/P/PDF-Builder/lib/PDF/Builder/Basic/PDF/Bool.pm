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
#
#=======================================================================
package PDF::Builder::Basic::PDF::Bool;

use base 'PDF::Builder::Basic::PDF::String';

use strict;
use warnings;

our $VERSION = '3.015'; # VERSION
my $LAST_UPDATE = '3.010'; # manually update whenever code is changed

=head1 NAME

PDF::Builder::Basic::PDF::Bool - A special form of 
L<PDF::Builder::Basic::PDF::String> which holds the strings
B<true> or B<false>

=head1 METHODS

=head2 $b->convert($str)

Converts a string into the string which will be stored.

=cut

sub convert {
    return $_[1] eq 'true';
}

=head2 $b->as_pdf()

Converts the value to a PDF output form.

=cut

sub as_pdf {
    return $_[0]->{'val'}? 'true': 'false';
}

1;
