package OpenSearch;
use strict;
use warnings;
use Moose;
use feature qw(signatures);
use Data::Dumper;
use OpenSearch::MooseTypes;
use OpenSearch::Base;
use OpenSearch::Search;
use OpenSearch::Cluster;
use OpenSearch::Cluster::Health;
use OpenSearch::Cluster::Stats;
use OpenSearch::Cluster::Allocation;
use OpenSearch::Cluster::Settings;
use OpenSearch::Remote;
use OpenSearch::Remote::Info;

# Filter
use OpenSearch::Filter::Source;

our $VERSION = '0.01';

# Base singleton
has 'base' => (
  is      => 'rw',
  isa     => 'OpenSearch::Base',
  lazy    => 1,
  default => sub { OpenSearch::Base->initialize; }
);

sub BUILD( $self, $args ) {
  $self->base( OpenSearch::Base->new(
    user           => $args->{user},
    pass           => $args->{pass},
    hosts          => $args->{hosts},
    secure         => $args->{secure}         // 0,
    allow_insecure => $args->{allow_insecure} // 1,
    pool_count     => $args->{pool_count}     // 1,
  ) );
}

#Search
sub search { shift; return ( OpenSearch::Search->new(@_) ); }

# Cluster
sub cluster            { shift; return ( OpenSearch::Cluster->new(@_) ); }
sub cluster_health     { shift; return ( OpenSearch::Cluster::Health->new(@_) ); }
sub cluster_stats      { shift; return ( OpenSearch::Cluster::Stats->new(@_) ); }
sub cluster_allocation { shift; return ( OpenSearch::Cluster::Allocation->new(@_) ); }
sub cluster_settings   { shift; return ( OpenSearch::Cluster::Settings->new(@_) ); }

# Remote
sub remote      { shift; return ( OpenSearch::Remote->new(@_) ); }
sub remote_info { shift; return ( OpenSearch::Remote::Info->new(@_) ); }

1;

__END__

=encoding utf-8

=head1 NAME

OpenSearch - It's new $module

=head1 SYNOPSIS

    use OpenSearch;

=head1 DESCRIPTION

OpenSearch is ...

=head1 LICENSE

Copyright (C) localh0rst.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

localh0rst E<lt>git@fail.ninjaE<gt>

=cut

