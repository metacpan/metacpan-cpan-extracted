package OpenSearch::MooseTypes;
use strict;
use warnings;
use Moose::Util::TypeConstraints;
use Data::Dumper;
use OpenSearch::Filter::Source;
use OpenSearch::Filter::Nodes;

enum 'enum_cluster_expand_wildcards' => [qw/all open closed hidden none/];
enum 'enum_cluster_level'            => [qw/cluster indices shards awareness_attributes/];
subtype 'cluster_wait_for_active_shards', as 'Str',    where { $_ =~ /^[0-9]+|all$/                    };
subtype 'cluster_wait_for_nodes',         as 'Str',    where { $_ =~ /^[<>]?[0-9]+$/                   };
subtype 'time_string',                    as 'Str',    where { $_ =~ /^[0-9]+[sShHmMdD]/               }; # Maybe check valid strings. probably strftime?

1;