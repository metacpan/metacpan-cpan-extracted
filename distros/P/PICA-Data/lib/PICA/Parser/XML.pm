package PICA::Parser::XML;
use v5.14.1;

our $VERSION = '2.03';

use Carp qw(croak);
use Scalar::Util qw(reftype);
use Encode qw(encode);
use XML::LibXML::Reader;

use parent 'PICA::Parser::Base';

sub new {
    my $self  = PICA::Parser::Base::_new(@_);
    my $input = $self->{fh};

    # check for file or filehandle
    my $ishandle = eval {fileno($input);};
    if (!$@ && defined $ishandle) {
        binmode $input;    # drop all PerlIO layers, as required by libxml2
        my $reader = XML::LibXML::Reader->new(IO => $input)
            or croak "cannot read from filehandle $input\n";
        $self->{xml_reader} = $reader;
    }
    elsif ($input !~ /\n/ && -e $input) {
        my $reader = XML::LibXML::Reader->new(location => $input)
            or croak "cannot read from file $input\n";
        $self->{xml_reader} = $reader;
    }
    elsif ((ref $input and reftype $input eq 'SCALAR')) {
        $input = encode('UTF-8', $$input);    # Unicode to raw bytes
        my $reader = XML::LibXML::Reader->new(string => $input)
            or croak "cannot read XML string reference\n";
        $self->{xml_reader} = $reader;
    }
    elsif (defined $input && length $input > 0) {
        my $reader = XML::LibXML::Reader->new(string => $input)
            or croak "cannot read XML string\n";
        $self->{xml_reader} = $reader;
    }
    else {
        croak "file, filehande or string $input does not exists";
    }

    $self;
}

my $namespaceURI = 'info:srw/schema/5/picaXML-v1.0';
my $recordPattern
    = XML::LibXML::Pattern->new('record|p:record', {p => $namespaceURI});

sub _next_record {
    my ($self) = @_;

    my $reader = $self->{xml_reader};
    return unless $reader->nextPatternMatch($recordPattern);

    my @record;

    # get all field nodes from PICA record;
    foreach my $field_node (
        $reader->copyCurrentNode(1)->getChildrenByLocalName('datafield'))
    {
        my @fields;

        # get field tag number
        my $tag = $field_node->getAttribute('tag')
            // $field_node->getAttributeNS($namespaceURI, 'tag');
        my $occurrence = $field_node->getAttribute('occurrence')
            // $field_node->getAttributeNS($namespaceURI, 'occurrence');
        push(@fields, ($tag, $occurrence > 0 ? $occurrence : ''));

        # get all subfield nodes
        foreach my $subfield_node (
            $field_node->getChildrenByLocalName('subfield'))
        {
            my $subfield_code = $subfield_node->getAttribute('code')
                // $subfield_node->getAttributeNS($namespaceURI, 'code');
            my $subfield_data = $subfield_node->textContent;
            push(@fields, ($subfield_code, $subfield_data));
        }
        push(@record, [@fields]);
    }
    return \@record;
}

1;
__END__

=head1 NAME

PICA::Parser::XML - PICA+ XML parser

=head2 DESCRIPTION

See L<PICA::Parser::Base> for synopsis and configuration.

The counterpart of this module is L<PICA::Writer::XML>.

=cut
