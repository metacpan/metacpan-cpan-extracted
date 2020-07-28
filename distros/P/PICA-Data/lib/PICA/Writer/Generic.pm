package PICA::Writer::Generic;
use v5.14.1;

our $VERSION = '1.14';

use charnames qw(:full);

use parent 'PICA::Writer::Base';

sub SUBFIELD_INDICATOR {
    my $self = shift;
    return
        exists $self->{us} ? "$self->{us}" : "\N{INFORMATION SEPARATOR ONE}";
}

sub END_OF_FIELD {
    my $self = shift;
    return
        exists $self->{rs} ? "$self->{rs}" : "\N{INFORMATION SEPARATOR TWO}";
}

sub END_OF_RECORD {
    my $self = shift;
    return
        exists $self->{gs}
        ? "$self->{gs}"
        : "\N{INFORMATION SEPARATOR THREE}";
}

sub write_subfield {
    my ($self, $code, $value) = @_;
    $self->{fh}->print($self->SUBFIELD_INDICATOR . $code . $value);
}

1;
__END__

=head1 NAME

PICA::Writer::Generic - Serialize PICA data with self defined data separators

=head2 DESCRIPTION

See L<PICA::Writer::Base> for synopsis and details.

=head1 METHODS

=head2 new( [ $fh | fh => $fh ], us => "$", rs => "#", gs => "\n" )

Create a new PICA writer, writing to STDOUT by default. The optional C<fh>
argument can be a filename, a handle or any other blessed object with a
C<print> method, e.g. L<IO::Handle>. You can set your own data separators 
(unit, record, group) via the C<us>, C<rs> and C<gs> arguments (default like 
L<PICA::Writer::Binary>).

=cut
