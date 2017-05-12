#
# This file is part of MooseX-Types-ElasticSearch
#
# This software is Copyright (c) 2014 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package MooseX::Types::ElasticSearch;
$MooseX::Types::ElasticSearch::VERSION = '0.0.4';
# ABSTRACT: Useful types for ElasticSearch

use DateTime::Format::Epoch::Unix;
use DateTime::Format::ISO8601;
use Search::Elasticsearch;

use MooseX::Types -declare => [
    qw(
      Location
      QueryType
      SearchType
      ES
      ESDateTime
      ) ];

use MooseX::Types::Moose qw/Int Str ArrayRef HashRef Object/;

coerce ArrayRef, from Str, via { [$_] };

subtype ES, as Object;
coerce ES, from Str, via {
    my $server = $_;
    $server = "127.0.0.1$server" if ( $server =~ /^:/ );
    return
      Search::Elasticsearch->new( nodes   => $server,
                          cxn     => "HTTPTiny",
                        );
};

coerce ES, from HashRef, via {
    return Search::Elasticsearch->new(%$_);
};

coerce ES, from ArrayRef, via {
    my @servers = @$_;
    @servers = map { /^:/ ? "127.0.0.1$_" : $_ } @servers;
    return
      Search::Elasticsearch->new( nodes   => \@servers,
                          cxn     => "HTTPTiny",
                        );
};

enum QueryType, [qw(query_and_fetch query_then_fetch dfs_query_and_fetch dfs_query_then_fetch scan count)];

subtype SearchType, as QueryType;

class_type ESDateTime;
coerce ESDateTime, from Str, via {
    if ( $_ =~ /^\d+$/ ) {
        DateTime::Format::Epoch::Unix->parse_datetime($_);
    } else {
        DateTime::Format::ISO8601->parse_datetime($_);
    }
};

subtype Location,
  as ArrayRef,
  where { @$_ == 2 },
  message { "Location is an arrayref of longitude and latitude" };

coerce Location, from HashRef,
  via { [ $_->{lon} || $_->{longitude}, $_->{lat} || $_->{latitude} ] };
coerce Location, from Str, via { [ reverse split(/,/) ] };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Types::ElasticSearch - Useful types for ElasticSearch

=head1 VERSION

version 0.0.4

=head1 SYNOPSIS

 use MooseX::Types::ElasticSearch qw(:all);

=head1 TYPES

=head2 ES

This type matches against an L<Elasticsearch> instance. It coerces from a C<Str>, C<ArrayRef> and C<HashRef>.

If the string contains only the port number (e.g. C<":9200">), then C<127.0.0.1:9200> is assumed.

=head2 Location

ElasticSearch expects values for geo coordinates (C<geo_point>) as an C<ArrayRef> of longitude and latitude.
This type coerces from C<Str> (C<"lat,lon">) and C<HashRef> (C<< { lat => 41.12, lon => -71.34 } >>).

=head2 SearchType

C<Enum> type. Valid values are: C<query_and_fetch query_then_fetch dfs_query_and_fetch dfs_query_then_fetch scan count>.
The now deprecated C<QueryType> is also still available.

=head2 ESDateTime

ElasticSearch returns dates in the ISO8601 date format. This type coerces from C<Str> to L<DateTime>
objects using L<DateTime::Format::ISO8601>.

=head1 TODO

B<More types>

Please don't hesitate and send other useful types in.

=head1 AUTHOR

Moritz Onken

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
