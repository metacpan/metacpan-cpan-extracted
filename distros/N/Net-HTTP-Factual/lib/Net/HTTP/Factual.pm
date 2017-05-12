package Net::HTTP::Factual;
{
  $Net::HTTP::Factual::VERSION = '0.122480';
}
use warnings;
use strict;
use Net::HTTP::Spore;

#ABSTRACT: RESTful interface to Factual.com, using Spore



use Moose;
has client => ( is => 'ro', lazy_build => 1 );
has spec   => ( is => 'ro', lazy_build => 1 );

sub _build_client
{
    my $self = shift;
    my $client = Net::HTTP::Spore->new_from_string($self->spec );
    $client->enable( 'Format::JSON' );
    $client;
}

sub _build_spec
{
    my $factual_spec =
    '{
       "base_url" : "http://api.factual.com",
       "api_base_url" : "http://api.factual.com",
       "version" : "v2",
       "expected" : "200",
       "methods" : {
          "input" : {
             "params" : {
                 "required" : [
                    "table_id",
                    "values",
                    "api_key"
                 ],
                "optional" : [
                    "subject_key"
                 ]
             },
             "api_format" : [
                "json"
             ],
             "documentation" : "This method either suggests corrections for single rows of data or  inserts new rows of data in tables.  It is important to note that corrections to tables may not immediately be reflected in Factual tables or, in some cases, may never appear.  This is because one of the features of Factual tables is to try to discern the most accurate value for a fact based on numerous inputs, of which the ones provided in your input call may only be one of many.\\nIn order to suggest a correction to a fact in an existing row, either provide the subject_key for the row you wish to correct, or the subject itself (along with your fact inputs). It is acceptable to provide both a subject_key AND the subject.  If the subject disagrees with the currently displayed subject for the row identified by that subject_key, you are suggesting that the subject\'s actual label should be corrected.  Of note: is important to discern the difference between subject_keys and UUIDs.  Many tables use UUIDs as their subject.  In these cases, the UUID is merely the subject itself. live example.\nIn order to add a row, omit the subject_key and specify the subject you are adding to the table, as well as any facts about the subject you wish to also include.  The Factual Server API will determine if this is an existing subject (and add your facts as inputs to that subject) or add a new row for the subject otherwise.  If you are using a table that auto-generates subject labels (such as UUIDs), pass in null as the subject label. ",
             "path" : "/v2/tables/:table_id/input",
             "method" : "GET",
             "description" : "inserts or updates a row in a table"
          },
          "read" : {
             "params" : {
                "required" : [
                   "table_id"
                ],
                "optional" : [
                   "sort_by",
                   "sort_dir",
                   "limit",
                   "offset",
                   "filters",
                   "subject_key",
                   "include_schema"
                ]
             },
             "api_format" : [
                "json"
             ],
             "documentation" : "The read method enables you to read either a single row or a number of rows from a table.  It has support for limits and offsets to support paging through data.  It also has support for filtering data.",
             "path" : "/v2/tables/:table_id/read",
             "method" : "GET",
             "description" : "read from a table"
          },
          "schema" : {
             "required" : [
                "table_id",
                "api_key"
             ],
             "api_format" : [
                "json"
             ],
             "documentation" : "The schema call returns meta-data about a Factual Table.",
             "path" : "/v2/tables/:table_id/schema",
             "method" : "GET",
             "description" : "get the schema for a table"
          }
       },
       "name" : "factual",
       "author" : [
          "andrew grangaard <spazm@cpan.org>"
       ],
       "meta" : {
          "documentation" : "http://wiki.developer.factual.com/"
       }
    }';
}

1;

__END__

=pod

=head1 NAME

Net::HTTP::Factual - RESTful interface to Factual.com, using Spore

=head1 VERSION

version 0.122480

=head1 SYNOPSIS

    my $api_key = "... get this from factual.com ...";
    my $fact    = Net::HTTP::Factual->new();

    my $response = $fact->client->read(
        api_key  => $api_key,
        table_id => 'EZ21ij',
    );
    die unless $response->status == 200;
    my @json_decoded_data = $response->body->{response}{data};

=head1 DESCRIPTION

Net::HTTP::Factual is currently a thin wrapper around Net::HTTP::Spore that provides the necessary json spec file.  This interface should expand with use to provide helper functions around the three available REST verbs, read, input and schema.

DEPRECATED:

This module only supports factual API version 2.  The v2 API has been deprecated by factual.

=head1 SEE ALSO

=over 4

=item Spore

http://search.cpan.org/perldoc?Spore

=item Net::HTTP::Spore

http://search.cpan.org/perldoc?Net::HTTP::Spore

=back

=head1 AUTHOR

Andrew Grangaard <spazm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Andrew Grangaard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
