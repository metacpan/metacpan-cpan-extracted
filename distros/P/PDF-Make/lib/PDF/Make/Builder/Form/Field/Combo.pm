package PDF::Make::Builder::Form::Field::Combo;
use strict;
use warnings;
use Object::Proto;

BEGIN {
    Object::Proto::define('PDF::Make::Builder::Form::Field::Combo',
        extends => 'PDF::Make::Builder::Form::Field',
        'options:ArrayRef:default([])',
    );
    Object::Proto::import_accessors('PDF::Make::Builder::Form::Field::Combo');
}

sub _create_field {
    my ($self, $doc, $name, $fx, $fy, $fw, $fh) = @_;
    my $field = PDF::Make::FieldPtr::combo($doc, $name, $fx, $fy, $fw, $fh);
    my $opts = options $self;
    for my $opt (@$opts) {
        my ($val, $display) = ref $opt ? @$opt : ($opt, $opt);
        $field->add_option($display, $val);
    }
    return $field;
}

1;

__END__

=encoding UTF-8

=head1 NAME

PDF::Make::Builder::Form::Field::Combo - Dropdown combo box form field

=head1 SYNOPSIS

    $b->add_field(
        type       => 'combo',
        name       => 'country',
        label      => 'Country',
        w          => 200,
        options    => ['US', 'UK', 'Canada', 'Australia'],
    );

    # With separate display/export values
    $b->add_field(
        type       => 'combo',
        name       => 'priority',
        label      => 'Priority',
        options    => [
            ['Low',    'low'],
            ['Medium', 'med'],
            ['High',   'high'],
        ],
    );

=head1 PROPERTIES

Inherits all properties from L<PDF::Make::Builder::Form::Field>, plus:

=over 4

=item C<options> (ArrayRef) - Dropdown options. Each element is either a
string (used as both display and export value) or an ArrayRef of
C<[display, export_value]>.

=back

=head1 SEE ALSO

L<PDF::Make::Builder::Form::Field::Listbox>,
L<PDF::Make::Builder::Form::Field>, L<PDF::Make::Builder>

=cut
