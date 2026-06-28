package PDF::Make::Builder::Form::Field::Radio;
use strict;
use warnings;
use Object::Proto;

BEGIN {
    Object::Proto::define('PDF::Make::Builder::Form::Field::Radio',
        extends => 'PDF::Make::Builder::Form::Field',
        'options:ArrayRef:default([])',
        'spacing:Num:default(10)',
    );
    Object::Proto::import_accessors('PDF::Make::Builder::Form::Field::Radio');
}

sub _create_field {
    my ($self, $doc, $name, $fx, $fy, $fw, $fh) = @_;
    my $group = PDF::Make::FieldPtr::radio_group($doc, $name);
    my $opts = options $self;
    my $ox = $fx;
    my $sp = spacing $self;
    for my $opt (@$opts) {
        my $val = ref $opt ? $opt->[0] : $opt;
        PDF::Make::FieldPtr::add_radio_option($group, $ox, $fy, $fh, $fh, $val);
        $ox += $fh + $sp;
    }
    return $group;
}

1;

__END__

=encoding UTF-8

=head1 NAME

PDF::Make::Builder::Form::Field::Radio - Radio button group form field

=head1 SYNOPSIS

    $b->add_field(
        type       => 'radio',
        name       => 'gender',
        label      => 'Gender',
        options    => ['Male', 'Female', 'Other'],
    );

=head1 PROPERTIES

Inherits all properties from L<PDF::Make::Builder::Form::Field>, plus:

=over 4

=item C<options> (ArrayRef, required) - Radio button values

=item C<spacing> (Num, default 10) - Horizontal spacing between buttons in points

=back

=head1 SEE ALSO

L<PDF::Make::Builder::Form::Field>, L<PDF::Make::Builder>

=cut
