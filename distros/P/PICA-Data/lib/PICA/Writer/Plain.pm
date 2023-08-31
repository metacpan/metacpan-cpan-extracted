package PICA::Writer::Plain;
use v5.14.1;

our $VERSION = '2.12';

use charnames qw(:full);
use Term::ANSIColor;

use parent 'PICA::Writer::Base';

sub SUBFIELD_INDICATOR {'$'}
sub END_OF_FIELD       {"\n"}
sub END_OF_RECORD      {"\n"}

sub write_subfield {
    my ($self, $code, $value) = @_;
    $value =~ s/\$/\$\$/g;

    if (my $col = $self->{color}) {
        $value
            = ($col->{syntax} ? colored('$', $col->{syntax}) : '$')
            . ($col->{code}  ? colored($code,  $col->{code})  : $code)
            . ($col->{value} ? colored($value, $col->{value}) : $value);
    }
    else {
        $value = $self->SUBFIELD_INDICATOR . $code . $value;
    }

    $self->{fh}->print($value);
}

sub write_start_field {
    my ($self, $field) = @_;

    my $annotation = $self->annotation($field);
    $self->{fh}->print("$annotation ") if defined $annotation;
    $self->write_identifier($field);
    $self->{fh}->print(' ');
}

1;
__END__

=head1 NAME

PICA::Writer::Plain - Plain PICA+ format serializer

=head2 DESCRIPTION

See L<PICA::Writer::Base> for synopsis and details.

This writer can be used to write PICA Patch format but L<PICA::Writer::Patch> should be used to ensure all fields are strictly annotated.

The counterpart of this module is L<PICA::Parser::Plain>.

=cut
