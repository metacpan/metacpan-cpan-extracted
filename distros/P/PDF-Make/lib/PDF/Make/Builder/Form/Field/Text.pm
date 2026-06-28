package PDF::Make::Builder::Form::Field::Text;
use strict;
use warnings;
use Object::Proto;

BEGIN {
    Object::Proto::define('PDF::Make::Builder::Form::Field::Text',
        extends => 'PDF::Make::Builder::Form::Field',
        'multiline:Bool:default(0)',
        'password:Bool:default(0)',
        'max_length:Int',
    );
    Object::Proto::import_accessors('PDF::Make::Builder::Form::Field::Text');
}

sub _create_field {
    my ($self, $doc, $name, $fx, $fy, $fw, $fh) = @_;
    my $field = PDF::Make::FieldPtr::text($doc, $name, $fx, $fy, $fw, $fh);
    $field->multiline if $self->multiline;
    $field->password  if $self->password;
    my $ml = $self->max_length;
    $field->set_max_len($ml) if defined $ml;
    return $field;
}

1;

__END__

=encoding UTF-8

=head1 NAME

PDF::Make::Builder::Form::Field::Text - Text input form field

=head1 SYNOPSIS

    $b->add_field(
        type          => 'text',
        name          => 'email',
        label         => 'Email Address',
        w             => 300,
        default_value => 'user@example.com',
    );

    # Multiline
    $b->add_field(
        type       => 'text',
        name       => 'comments',
        label      => 'Comments',
        w          => 400,
        h          => 80,
        multiline  => 1,
    );

    # Password
    $b->add_field(
        type       => 'text',
        name       => 'password',
        label      => 'Password',
        password   => 1,
    );

=head1 PROPERTIES

Inherits all properties from L<PDF::Make::Builder::Form::Field>, plus:

=over 4

=item C<multiline> (Bool, default 0) - Allow multiple lines of text

=item C<password> (Bool, default 0) - Mask input characters

=item C<max_length> (Int) - Maximum number of characters

=back

=head1 SEE ALSO

L<PDF::Make::Builder::Form::Field>, L<PDF::Make::Builder>

=cut
