package PICA::Parser::PIXML;
use v5.14.1;

our $VERSION = '2.10';

use parent 'PICA::Parser::XML';

sub _next_record {
    my ($self) = @_;

    my $reader = $self->{xml_reader};
    return unless $reader->nextElement('metadata');

    my @record;

    # get all field from PICA record;
    for my $datafield (
        $reader->copyCurrentNode(1)->getElementsByLocalName('datafield'))
    {
        my @field;

        # get field tag number
        my $tag = $datafield->getAttribute('tag');
        my $occ = $datafield->getAttribute('occurrence');
        $occ = $occ > 0 ? sprintf('%02d', $occ) : '';
        push(@field, ($tag, $occ));

        # get all subfields
        foreach my $subfield ($datafield->getElementsByLocalName('subfield'))
        {
            my $subfield_code = $subfield->getAttribute('code');
            my $subfield_data = $subfield->textContent;
            push(@field, ($subfield_code, $subfield_data));
        }
        push(@record, [@field]);
    }

    return \@record;
}

1;
__END__

=head1 NAME

PICA::Parser::PIXML - PICA FOLIO Import XML Parser

=head1 DESCRIPTION

This parser reads the XML serialization form of PICA+ used for import of PICA+
data into FOLIO library system. The reader does not validate input but ignored
additional elements not required to extract PICA+ data.

The counterpart of this module is L<PICA::Writer::PIXML>.

=head1 METHODS

See L<PICA::Parser::Base> for description of configuration and methods.

=cut
