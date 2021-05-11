package PICA::Writer::Plain;
use v5.14.1;

our $VERSION = '1.19';

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

sub write_annotation {
    my ($self, $field) = @_;

    if (@$field % 2) {
        $self->{fh}->print($field->[$#$field] . " ")
            unless defined $self->{annotated} && !$self->{annotated};
    }
    elsif ($self->{annotated}) {
        $self->{fh}->print("  ");
    }
}

1;
__END__

=head1 NAME

PICA::Writer::Plain - Plain PICA+ format serializer

=head2 DESCRIPTION

See L<PICA::Writer::Base> for synopsis and details.

The counterpart of this module is L<PICA::Parser::Plain>.

This writer also supports annotated PICA by default. Use option C<annotated> to
ensure or ignore field annotations.

=cut
