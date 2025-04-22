package PDF::Builder::Resource::XObject::Form;

use base 'PDF::Builder::Resource::XObject';

use strict;
use warnings;

our $VERSION = '3.027'; # VERSION
our $LAST_UPDATE = '3.027'; # manually update whenever code is changed

use PDF::Builder::Basic::PDF::Utils;

=head1 NAME

PDF::Builder::Resource::XObject::Form - Base class for external form objects

Inherits from L<PDF::Builder::Resource::XObject>

=head1 METHODS

=head2 new

    $form = PDF::Builder::Resource::XObject::Form->new($pdf)

=over

Creates a form resource.

=back

=cut

sub new {
    my ($class, $pdf, $name) = @_;

    my $self = $class->SUPER::new($pdf, $name);

    $self->subtype('Form');
    $self->{'FormType'} = PDFNum(1);

    return $self;
}

=head2 bbox

    ($llx, $lly, $urx, $ury) = $form->bbox($llx, $lly, $urx, $ury)

=over

Get or set the coordinates of the form object's bounding box.

=back

=cut

sub bbox {
    my $self = shift();

    if (scalar @_) {
        $self->{'BBox'} = PDFArray(map { PDFNum($_) } @_);
    }

    return map { $_->val() } $self->{'BBox'}->elements();
}

=head2 resource

    $resource = $form->resource($type, $key)

    $form->resource($type, $key, $object, $force)

=over

Get or add a resource required by the form's contents, such as a Font, XObject, ColorSpace, etc.

By default, an existing C<$key> will not be overwritten. Set C<$force> to override this behavior.

=back

=cut

sub resource {
    my ($self, $type, $key, $object, $force) = @_;
    # we are a self-contained content stream.

    $self->{'Resources'} ||= PDFDict();

    my $dict = $self->{'Resources'};
    $dict->realise() if ref($dict) =~ /Objind$/;

    $dict->{$type} ||= PDFDict();
    $dict->{$type}->realise() if ref($dict->{$type}) =~ /Objind$/;

    unless (defined $object) {
        return $dict->{$type}->{$key} || undef;
    }

    if ($force) {
        $dict->{$type}->{$key} = $object;
    }
    else {
        $dict->{$type}->{$key} ||= $object;
    }

    return $dict;
}

1;
