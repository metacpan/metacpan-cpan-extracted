package PICA::Writer::Import;
use v5.14.1;

our $VERSION = '2.12';

use charnames qw(:full);

use parent 'PICA::Writer::Base';
use PICA::Schema qw(clean_pica);

sub SUBFIELD_INDICATOR {"\N{INFORMATION SEPARATOR ONE}"}

sub write_record {
    my ($self, $record) = @_;
    $record = clean_pica(
        $record,
        allow_empty_subfields => 1,
        ignore_empty_records  => 1
    ) or return;
    return unless @$record;

    $self->{fh}->print("\N{INFORMATION SEPARATOR THREE}\N{LINE FEED}");
    $self->write_field($_) for @$record;
}

sub write_field {
    my ($self, $field) = @_;

    my $fh = $self->{fh};

    $fh->print("\N{INFORMATION SEPARATOR TWO}");
    $self->{color} = {};
    $self->write_identifier($field);
    $fh->print(' ');
    for (my $i = 3; $i < scalar @$field; $i += 2) {
        $self->write_subfield($field->[$i - 1], $field->[$i]);
    }

    $fh->print("\N{LINE FEED}");
}

1;
__END__

=head1 NAME

PICA::Writer::Import - PICA Import format serializer

=head2 DESCRIPTION

Serializes PICA+ records in PICA Import format (also known as "normalized title
format", see L<https://format.gbv.de/pica/import>).

See L<PICA::Parser::Import> for corresponding parser.

=cut
