package PICA::Writer::Patch;
use v5.14.1;

our $VERSION = '2.12';

use Carp qw(croak);

use parent 'PICA::Writer::Plain';

sub write_field {
    my ($self, $field) = @_;

    if (@$field % 2) {
        my $char = $field->[$#$field];
        croak "Invalid annotation: '$char'" if $char !~ /^[ +-]$/;
    }
    else {
        $field = [@$field, " "];
    }
    PICA::Writer::Base::write_field($self, $field);
}

1;
__END__

=head1 NAME

PICA::Writer::Plain - Plain PICA+ format serializer

=head2 DESCRIPTION

This is basically L<PICA::Writer::Plain> with option C<annotate> enabled. In
addition writing an annotated field with result in an error if the field is
annotated with another character but C<+>, C<-> or space.

The counterpart of this module is L<PICA::Parser::Patch>.

=cut
