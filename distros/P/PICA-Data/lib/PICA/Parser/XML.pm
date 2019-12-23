package PICA::Parser::XML;
use strict;
use warnings;

our $VERSION = '1.01';

use Carp qw(croak);
use XML::LibXML::Reader;

use parent 'PICA::Parser::Base';

sub new {
    my $self = PICA::Parser::Base::_new(@_);
    my $input = $self->{fh};

    # check for file or filehandle
    my $ishandle = eval { fileno($input); };
    if ( !$@ && defined $ishandle ) {
        binmode $input; # drop all PerlIO layers, as required by libxml2
        my $reader = XML::LibXML::Reader->new(IO => $input)
            or croak "cannot read from filehandle $input\n";
        $self->{xml_reader} = $reader;
    } elsif ( defined $input && $input !~ /\n/ && -e $input ) {
        my $reader = XML::LibXML::Reader->new(location => $input)
            or croak "cannot read from file $input\n";
        $self->{xml_reader} = $reader;
    } elsif ( defined $input && length $input > 0 ) {
        $input = ${$input} if (ref($input) // '' eq 'SCALAR');
        my $reader = XML::LibXML::Reader->new( string => $input )
            or croak "cannot read XML string $input\n";
        $self->{xml_reader} = $reader;
    } else {
        croak "file, filehande or string $input does not exists";
    }

    $self;
}

sub _next_record {
    my ($self) = @_;

    my $reader = $self->{xml_reader};
    return unless $reader->nextElement('record');

    my @record;

    # get all field nodes from PICA record;
    foreach my $field_node ( $reader->copyCurrentNode(1)->getChildrenByTagName('*') ) {
        my @field;

        # get field tag number
        my $tag = $field_node->getAttribute('tag');
        my $occurrence = $field_node->getAttribute('occurrence') // '';
        push(@field, ($tag, $occurrence));

            # get all subfield nodes
            foreach my $subfield_node ( $field_node->getChildrenByTagName('*') ) {
                my $subfield_code = $subfield_node->getAttribute('code');
                my $subfield_data = $subfield_node->textContent;
                push(@field, ($subfield_code, $subfield_data));
            }
        push(@record, [@field]);
    };
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
