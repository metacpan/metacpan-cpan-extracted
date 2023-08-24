package PICA::Writer::PIXML;
use v5.14.1;

our $VERSION = '2.11';

use Scalar::Util qw(reftype);
use XML::LibXML;
use PICA::Path;
use PICA::Data;

use parent 'PICA::Writer::XML';

our $PPN = PICA::Path->new('003@$0');

sub namespace { }

sub write_field {
    my ($self, $field) = @_;

    my $writer = $self->{writer};

    my ($tag, $occurrence) = ($field->[0], $field->[1]);
    my %attr = (tag => $tag, fulltag => $tag);
    if ($occurrence > 1) {
        $attr{fulltag} .= $occurrence;
        $attr{occurrence} = $occurrence;
    }
    $writer->startTag('datafield', %attr);
    for (my $i = 3; $i < scalar @$field; $i += 2) {
        $writer->dataElement('subfield', $field->[$i],
            code => $field->[$i - 1]);
    }
    $writer->endTag('datafield');
}

sub write_record {
    my ($self, $record) = @_;
    $record = $record->{record} if reftype $record eq 'HASH';

    my $writer = $self->{writer};

    $writer->startTag('record');

    $writer->startTag('header', status => "upsert");

    $writer->dataElement('identifier',
        PICA::Data::pica_value($record, '003@$0'));
    $writer->endTag('header');

    $writer->startTag('metadata');

    $self->write_field($_) for grep {$_->[0] =~ /^0/} @$record;

    for my $holding (@{PICA::Data::pica_holdings($record)}) {
        my @local = grep {$_->[0] =~ /^1/} @{$holding->{record}};
        $self->write_field($_) for @local;

        for my $item (@{PICA::Data::pica_items($holding)}) {
            $writer->startTag('item', epn => $item->{_id} // "",);
            $self->write_field($_) for @{$item->{record}};
            $writer->endTag('item');
        }
    }

    $writer->endTag('metadata');
    $writer->endTag('record');
}

1;
__END__

=head1 NAME

PICA::Writer::PIXML - PICA FOLIO Import XML serializer

=head1 DESCRIPTION

This writer serializes the XML format used to import PICA+ records into FOLIO
library system. Records should have PPN (for level 0) and ELN (for each level 2
record) or the result will likely be incomplete.

The counterpart of this module is L<PICA::Parser::PIXML>.

=head1 METHODS

See L<PICA::Writer::Base> for description of configuration and methods.

=cut
