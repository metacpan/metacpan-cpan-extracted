package SRU::Response::Diagnostic;
{
  $SRU::Response::Diagnostic::VERSION = '1.01';
}
#ABSTRACT: An SRU diagnostic message

use strict;
use warnings;
use SRU::Utils::XML qw( element elementNoEscape );
use base qw( Class::Accessor );

## these are standard diagnostics for use in 
## newFromCode()

our %DIAG = (

    ## general diagnostics
    1   => 'General System Error',
    2   => 'System temporarily unavailable',
    3   => 'Authentication error',
    4   => 'Unsupported operation',
    5   => 'Unsupported version',
    6   => 'Unsupported parameter value',
    7   => 'Mandatory parameter not supplied',
    8   => 'Unsupported parameter',
    10  => 'Query syntax error',

    ## diagnostics relating to CQL
    13  => 'Invalid or unsupported use of parentheses',
    15  => 'Unsupported context set',
    16  => 'Unsupported index',
    18  => 'Unsupported combination of indexes',
    19  => 'Unsupported relation',
    20  => 'Unsupported relation modifier',
    21  => 'Unsupported combination of relation modifiers',
    22  => 'Unsupported combination of relation and index',
    23  => 'Too many characters in term',
    24  => 'Unsupported combination of relation and term',
    26  => 'Non special character escaped in term',
    27  => 'Empty term unsupported',
    28  => 'Masking character not supported',
    29  => 'Masked words too short',
    30  => 'Too many masked characters in term',
    31  => 'Anchoring character not supported',
    32  => 'Anchoring character in unsupported position',
    33  => 'Combination of proximity/adjacency and masking characters not supported',
    34  => 'Combination of proximity/adjacency and anchoring characters not supported',
    35  => 'Term contains only stopwords',
    36  => 'Term ininvalid format for index or relation',
    37  => 'Unsupported boolean operator',
    38  => 'Too many boolean operators in query',
    39  => 'Proximity not supported',
    40  => 'Unsupported proximity relation',
    41  => 'Unsupported proximity distance',
    42  => 'Unsupported proximity unit',
    43  => 'Unsupported proximity ordering',
    44  => 'Unsupported combination of proximity modifiers',
    46  => 'Unsupported boolean modifier',
   
    ## Diagnostics relating to result sets
    50  => 'Result sets not supported',
    51  => 'Result set does not exist',
    52  => 'Result set temporarily unavailable',
    53  => 'Result sets only supported for retrieval',
    55  => 'Combination of result sets with search terms not supported',
    58  => 'Result set created with unpredictable partial results available',
    59  => 'Result set created with valid partial results available',
    60  => 'Result set not created: too man matching records',

    ## Diagnostics relating to records
    61  => 'First record position out of range',
    64  => 'Record temporarily unavailable',
    65  => 'Record does not exist',
    66  => 'Unknown schema for retrieval',
    67  => 'Record not available in this schema',
    68  => 'Not authorized to send record',
    69  => 'Not authorized to send record in this schema',
    70  => 'Record too large to send',
    71  => 'Unsupported record packing',
    72  => 'XPath retrieval unsupported',
    73  => 'XPath expression contains unsupported feature',
    74  => 'Unable to evaluate XPath expression',

    ## Diagnostics related to sorting
    80  => 'Sort not supported',
    82  => 'Unsupported sort sequence',
    83  => 'Too many records to sort',
    86  => 'Cannot sort: incompatible record formats',
    87  => 'Unsupported schema for sort',
    88  => 'Unsupported path for sort',
    89  => 'Path unsupported for schema',
    90  => 'Unsupported direction',
    91  => 'Unsupported case',
    92  => 'Unsupported missing value action',

    ## Diagnostics relating to stylesheets
    110 => 'Stylesheet not supported',
    111 => 'Unsupported stylesheet',

    ## Diagnostics related to Scan
    120 => 'Response portion out of range',

);



sub new {
    my ($class,%args) = @_;
    my $self = $class->SUPER::new( \%args );
    return $self;
}


sub newFromCode {
    my ($class,$code,$details) = @_;
    return error( "no such diagnostic code ($code)" )
        if ! exists $DIAG{$code};
    my $desc = $DIAG{$code};
    return $class->new( 
        uri     => 'info:srw/diagnostic/1/' . $code,
        message => $desc,
        details => $details );
}

SRU::Response::Diagnostic->mk_accessors( qw(
    uri
    details
    message
) );


sub asXML {
    my $self = shift;
    my $xml = element( 'uri', $self->uri() );
    $xml .= element( 'details', $self->details() );
    $xml .= element( 'message', $self->message() );
    return elementNoEscape( 'diagnostics', $xml );
}

1;

__END__

=pod

=head1 NAME

SRU::Response::Diagnostic - An SRU diagnostic message

=head1 SYNOPSIS

    my $d = SRU::Response::Diagnostic->new(
        uri     => '',
        details => ''
        message => '' 
    );
    print $d->asXML();

=head1 DESCRIPTION

You probably won't need to use this class since it used interally
to store diagnostic messages.

=head1 METHOD

=cut

=head2 new()

Pass in uri, details and message attributes as needed. You'll probably
find using newFromCode() easier to work with.

=cut

=head2 newFromCode()

Create a SRU::Response::Diagnostic object from a code. For a
complete list of the codes see the SRW/SRU documentation.

=cut

=head2 uri()

=head2 details()

=head2 message()

=cut

=head2 asXML()

=cut
=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ed Summers.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
