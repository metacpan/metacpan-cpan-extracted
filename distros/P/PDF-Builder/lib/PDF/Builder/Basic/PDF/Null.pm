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
package PDF::Builder::Basic::PDF::Null;

use base 'PDF::Builder::Basic::PDF::Objind';

use strict;
use warnings;

our $VERSION = '3.026'; # VERSION
our $LAST_UPDATE = '3.026'; # manually update whenever code is changed

=head1 NAME

PDF::Builder::Basic::PDF::Null - PDF Null type object.  This is a subclass of
PDF::Builder::Basic::PDF::Objind and cannot be subclassed.

=head1 METHODS

=cut

# There is only one null object  (section 3.2.8).
my $null_obj = bless {}, 'PDF::Builder::Basic::PDF::Null';

=head2 new

    PDF::Builder::Basic::PDF::Null->new()

=over

Returns the null object. There is only one null object.

=back

=cut

sub new {
    return $null_obj;
}

=head2 realise

    $s->realise()

=over

Pretends to finish reading the object.

=back

=cut

sub realise {
    return $null_obj;
}

=head2 outobjdeep

    $s->outobjdeep()

=over

Output the object in PDF format.

=back

=cut

sub outobjdeep {
    my ($self, $fh, $pdf) = @_;

    $fh->print('null');
    return;
}

=head2 is_obj

    $s->is_obj()

=over

Returns false because null is not a full object.

=back

=cut

sub is_obj {
    return 0;
}

=head2 copy

    $s->copy()

=over

Another no-op.

=back

=cut

sub copy {
    return $null_obj;
}

=head2 val

    $s->val()

=over

Return undef.

=back

=cut

sub val {
    return undef; ## no critic (undef is intentional)
}

1;
