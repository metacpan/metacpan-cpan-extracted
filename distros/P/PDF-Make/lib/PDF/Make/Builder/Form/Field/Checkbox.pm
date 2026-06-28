package PDF::Make::Builder::Form::Field::Checkbox;
use strict;
use warnings;
use Object::Proto;

BEGIN {
    Object::Proto::define('PDF::Make::Builder::Form::Field::Checkbox',
        extends => 'PDF::Make::Builder::Form::Field',
        'on_value:Str:default(Yes)',
    );
    Object::Proto::import_accessors('PDF::Make::Builder::Form::Field::Checkbox');
}

sub BUILD {
    my ($self) = @_;
    # Checkboxes: square, inline label, no background fill
    $self->w(14);
    $self->h(14);
    $self->inline_label(1);
    $self->border_colour('#666');
    $self->bg_colour('#fff');
}

sub _draws_own_chrome { 1 }

sub _create_field {
    my ($self, $doc, $name, $fx, $fy, $fw, $fh) = @_;
    return PDF::Make::FieldPtr::checkbox($doc, $name, $fx, $fy, $fw, $fh, $self->on_value);
}

1;

__END__

=encoding UTF-8

=head1 NAME

PDF::Make::Builder::Form::Field::Checkbox - Checkbox form field

=head1 SYNOPSIS

    $b->add_field(
        type       => 'checkbox',
        name       => 'agree_terms',
        label      => 'I agree to the terms and conditions',
    );

=head1 DESCRIPTION

Renders a checkbox with an inline label to the right. Default size is
14x14 points.

=head1 PROPERTIES

Inherits all properties from L<PDF::Make::Builder::Form::Field>, plus:

=over 4

=item C<on_value> (Str, default 'Yes') - The value when checked

=back

=head1 SEE ALSO

L<PDF::Make::Builder::Form::Field>, L<PDF::Make::Builder>

=cut
