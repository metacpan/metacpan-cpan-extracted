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
package PDF::Builder::Basic::PDF::Null;

use base 'PDF::Builder::Basic::PDF::Objind';

use strict;
use warnings;

our $VERSION = '3.014'; # VERSION
my $LAST_UPDATE = '3.010'; # manually update whenever code is changed

=head1 NAME

PDF::Builder::Basic::PDF::Null - PDF Null type object.  This is a subclass of
PDF::Builder::Basic::PDF::Objind and cannot be subclassed.

=head1 METHODS

=cut

# There is only one null object  (section 3.2.8).
my $null_obj = bless {}, 'PDF::Builder::Basic::PDF::Null';

=head2 PDF::Builder::Basic::PDF::Null->new()

Returns the null object. There is only one null object.

=cut

sub new {
    return $null_obj;
}

=head2 $s->realise()

Pretends to finish reading the object.

=cut

sub realise {
    return $null_obj;
}

=head2 $s->outobjdeep()

Output the object in PDF format.

=cut

sub outobjdeep {
    my ($self, $fh, $pdf) = @_;

    $fh->print('null');
    return;
}

=head2 $s->is_obj()

Returns false because null is not a full object.

=cut

sub is_obj {
    return 0;
}

=head2 $s->copy()

Another no-op.

=cut

sub copy {
    return $null_obj;
}

=head2 $s->val()

Return undef.

=cut

sub val {
    return undef; ## no critic (undef is intentional)
}

1;
