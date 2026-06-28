package PDF::Make::Builder::Form::Field::Listbox;
use strict;
use warnings;
use Object::Proto;

BEGIN {
    Object::Proto::define('PDF::Make::Builder::Form::Field::Listbox',
        extends => 'PDF::Make::Builder::Form::Field',
        'options:ArrayRef:default([])',
    );
    Object::Proto::import_accessors('PDF::Make::Builder::Form::Field::Listbox');
}

sub BUILD {
    my ($self) = @_;
    # Listboxes default taller to show multiple items
    $self->h(80) unless defined $self->[3];  # h slot
}

sub _create_field {
    my ($self, $doc, $name, $fx, $fy, $fw, $fh) = @_;
    my $field = PDF::Make::FieldPtr::listbox($doc, $name, $fx, $fy, $fw, $fh);
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

PDF::Make::Builder::Form::Field::Listbox - Scrollable list form field

=head1 SYNOPSIS

    $b->add_field(
        type       => 'listbox',
        name       => 'languages',
        label      => 'Languages',
        w          => 200,
        h          => 100,
        options    => ['Perl', 'Python', 'Ruby', 'Go', 'Rust', 'C'],
    );

=head1 PROPERTIES

Inherits all properties from L<PDF::Make::Builder::Form::Field>, plus:

=over 4

=item C<options> (ArrayRef) - List items. Same format as
L<PDF::Make::Builder::Form::Field::Combo>.

=back

Default height is 80 points to show multiple items.

=head1 SEE ALSO

L<PDF::Make::Builder::Form::Field::Combo>,
L<PDF::Make::Builder::Form::Field>, L<PDF::Make::Builder>

=cut
