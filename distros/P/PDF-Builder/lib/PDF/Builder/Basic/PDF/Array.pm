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
package PDF::Builder::Basic::PDF::Array;

use base 'PDF::Builder::Basic::PDF::Objind';

use strict;
use warnings;

our $VERSION = '3.027'; # VERSION
our $LAST_UPDATE = '3.027'; # manually update whenever code is changed

=head1 NAME

PDF::Builder::Basic::PDF::Array - Corresponds to a PDF array

Inherits from L<PDF::Builder::Basic::PDF::Objind>

=head1 METHODS

=head2 new

    PDF::Array->new($parent, @values)

=over

Creates an array with the given storage parent and an optional list of values to
initialise the array with.

=back

=cut

sub new {
    my ($class, @values) = @_;
    my $self = {};

    $self->{' val'} = [@values];
    $self->{' realised'} = 1;
    bless $self, $class;
    return $self;
}

=head2 outobjdeep

    $a->outobjdeep($fh, $pdf)

=over

Outputs an array as a PDF array to the given filehandle. It's unusual to
need to call this method from user code.

=back

=cut

sub outobjdeep {
    my ($self, $fh, $pdf) = @_;

    $fh->print('[ ');
    foreach my $obj (@{$self->{' val'}}) {
	# if no graphics object (page->gfx), creates an invalid Contents object
	# (unblessed HASH containing no keys) for this page's graphics, and
	# this function blows up
        if ($obj !~ /^PDF::Builder/) { next; }

        $obj->outobj($fh, $pdf);
        $fh->print(' ');
    }
    $fh->print(']');
    return;
}

=head2 elements

    $a->elements()

=over

Returns the contents of the array.

=back

=cut

sub elements {
    my $self = shift();
    return @{$self->{' val'}};
}

=head2 add_elements

    $a->add_elements(@elements)

=over

Appends the given elements to the array. An element is only added if it
is defined.

=back

=cut

sub add_elements {
    my $self = shift();

    foreach my $element (@_) {
	    next unless defined $element;
        push @{$self->{' val'}}, $element;
    }
    return $self;
}

=head2 remove_element

    $a->remove_element($element)

=over

Removes all occurrences of an element from an array.

=back

=cut

sub remove_element {
    my ($self, $element) = @_;

    $self->{' val'} = [ grep { $_ ne $element } @{$self->{' val'}} ];
    return $self;
}

=head2 val

    $a->val()

=over

Returns a reference to the contents of the array.

=back

=cut

sub val {
    return $_[0]->{' val'};
}

=head2 copy

    $a->copy($pdf)

=over

Copies the array with deep-copy on elements which are not full PDF objects
with respect to a particular $pdf output context.

=back

=cut

sub copy {
    my ($self, $pdf) = @_;

    my $res = $self->SUPER::copy($pdf);

    $res->{' val'} = [];
    foreach my $e (@{$self->{' val'}}) {
        if (ref($e) and $e->can('is_obj') and not $e->is_obj($pdf)) {
            push @{$res->{' val'}}, $e->copy($pdf);
        } else {
            push @{$res->{' val'}}, $e;
        }
    }
    return $res;
}

1;
