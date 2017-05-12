package SRU::Request::SearchRetrieve;
{
  $SRU::Request::SearchRetrieve::VERSION = '1.01';
}
#ABSTRACT: A class for representing SRU searchRetrieve requests

use strict;
use warnings;
use base qw( Class::Accessor SRU::Request );
use SRU::Utils qw( error );
use CQL::Parser;


sub new {
    my ($class,%args) = @_;
    return SRU::Request::SearchRetrieve->SUPER::new( \%args );
}


my @validParams = qw(
    version
    query
    startRecord
    maximumRecords
    recordPacking
    recordSchema
    recordXPath
    resultSetTTL
    sortKeys
    stylesheet
    extraRequestData
);


sub validParams { return @validParams };

SRU::Request::SearchRetrieve->mk_accessors( @validParams );


sub cql {
    my $self = shift;
    my $query = $self->query();
    return '' unless $query;
    my $node;
    my $parser = CQL::Parser->new();
    eval { $node = $parser->parse( $query ) };
    return $node;
}

1;

__END__

=pod

=head1 NAME

SRU::Request::SearchRetrieve - A class for representing SRU searchRetrieve requests

=head1 SYNOPSIS

    ## creating a new request
    my $request = SRU::Request::SearchRetrieve->new(
        version => '1.1',
        query   => 'kirk and spock' );

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

The constructor which you can pass the following parameters:
version, query, startRecord, maximumRecords, recordPacking, recordSchema,
recordXPath, resultSetTTL, sortKeys, stylesheet, extraRequestData.
The version and query parameters are mandatory.

=cut

=head2 version()

=head2 query()

=head2 startRecord()

=head2 maximumRecords()

=head2 recordPacking()

=head2 recordSchema()

=head2 recordXPath()

=head2 resultSetTTL()

=head2 sortKeys()

=head2 stylesheet()

=head2 extraRequestData()

=cut

=head2 validParams()

=cut

=head2 cql()

Fetch the root node of the CQL parse tree for the query.

=cut
=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ed Summers.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
