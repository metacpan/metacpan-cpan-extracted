package OpenSearch::Cluster;
use strict;
use warnings;
use Moose;
use feature qw(signatures);
use Data::Dumper;

use OpenSearch::Cluster::Allocation;
use OpenSearch::Cluster::Health;
use OpenSearch::Cluster::Stats;
use OpenSearch::Cluster::Settings;

sub allocation { shift; return ( OpenSearch::Cluster::Allocation->new(@_) ); }
sub health     { shift; return ( OpenSearch::Cluster::Health->new(@_) ); }
sub stats      { shift; return ( OpenSearch::Cluster::Stats->new(@_) ); }
sub settings   { shift; return ( OpenSearch::Cluster::Settings->new(@_) ); }

1;
__END__

=encoding utf-8

=head1 NAME

C<OpenSearch::Cluster> - OpenSearch Cluster API

=head1 SYNOPSIS

    use strict;
    use warnings;
    use OpenSearch;

    my $opensearch = OpenSearch->new(
      user => 'admin',
      pass => 'admin',
      hosts => ['http://localhost:9200'],
      secure => 0,
      allow_insecure => 1,
    );

    my $cluster = $opensearch->cluster;

    my $allocation = $cluster->allocation;
    my $health = $cluster->health;
    my $stats = $cluster->stats;
    my $settings = $cluster->settings;

=head1 DESCRIPTION

This is the Module for the OpenSearch Cluster API. The following Endpoints
are currently supported:

=over 4

=item * Cluster Allocation

=item * Cluster Health

=item * Cluster Settings

=item * Cluster Stats

=back

=head1 METHODS

=head2 allocation

returns a new OpenSearch::Cluster::Allocation object

  my $allocation = $opensearch->cluster->allocation;

=head2 health

returns a new OpenSearch::Cluster::Health object

  my $health = $opensearch->cluster->health;

=head2 stats

returns a new OpenSearch::Cluster::Stats object

  my $stats = $opensearch->cluster->stats;

=head2 settings

returns a new OpenSearch::Cluster::Settings object

  my $settings = $opensearch->cluster->settings;

=head1 LICENSE

Copyright (C) localh0rst.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

localh0rst E<lt>git@fail.ninjaE<gt>

=cut

