package PICA::Parser::PPXML;
use v5.14.1;

our $VERSION = '1.08';

use parent 'PICA::Parser::XML';

sub _next_record {
    my ($self) = @_;

    my $reader = $self->{xml_reader};
    return
        unless $reader->nextElement('record',
        'http://www.oclcpica.org/xmlns/ppxml-1.0');

    my @record;

    # get all field from PICA record;
    foreach
        my $field ($reader->copyCurrentNode(1)->getElementsByLocalName('tag'))
    {
        my @field;

        # get field tag number
        my $tag        = $field->getAttribute('id');
        my $occurrence = $field->getAttribute('occ') // '';
        push(@field, ($tag, $occurrence));

        # get all subfields
        foreach my $subfield ($field->getElementsByLocalName('subf')) {
            my $subfield_code = $subfield->getAttribute('id');
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

PICA::Parser::PPXML - PicaPlus-XML Parser (format variant of the Deutsche Nationalbiliothek)

=head1 DESCRIPTION

See L<PICA::Parser::Base> for synopsis and configuration.

=head1 SEE ALSO

Use L<PICA::Parser::XML> for the standard variant of the PICA+ XML format.

=cut
