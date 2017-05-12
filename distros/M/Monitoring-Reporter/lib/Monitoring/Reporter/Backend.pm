package Monitoring::Reporter::Backend;
{
  $Monitoring::Reporter::Backend::VERSION = '0.01';
}
BEGIN {
  $Monitoring::Reporter::Backend::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: Monitoring dashboard backend

use Moose;
use namespace::autoclean;

use Cache::MemoryCache;

has 'cache' => (
    'is'      => 'rw',
    'isa'     => 'Cache::Cache',
    'lazy'    => 1,
    'builder' => '_init_cache',
);

has 'name' => (
    'is'      => 'ro',
    'isa'     => 'Str',
    'required'  => 1,
);

with qw(Config::Yak::RequiredConfig Log::Tree::RequiredLogger);

sub _init_cache {
    my $self = shift;

    my $Cache = Cache::MemoryCache::->new({
      'namespace'          => 'MonitoringReporter',
      'default_expires_in' => 600,
    });

    return $Cache;
}

sub fetch_n_store {
    my $self = shift;
    my $query = shift;
    my $timeout = shift;
    my @args = @_;

    my $key = $query.join(',',@args);

    my $result = $self->cache()->get($key);

    if( ! defined($result) ) {
        $result = $self->fetch($query,@args);
        $self->cache()->set($key,$result,$timeout);
    }

    return $result;
}

sub fetch {
  my $self = shift;
  my $query = shift;
  my @args = @_;

  die('Not implemented!');
}

sub triggers {
  my $self = shift;

  die('Not implemented');
}

sub disabled_actions {
  my $self = shift;

  die('Not implemented');
}

sub enable_actions {
  my $self = shift;
 
  die('Not implemented');
}

sub unsupported_items {
  my $self = shift;

  die('Not implemented');
}

sub unattended_alarms {
  my $self = shift;
  my $time = shift || 3600;
 
  die('Not implemented');
}

sub history {
  my $self = shift;
  my $max_age = shift // 30;
  my $max_num = shift // 100;

  die('Not implemented');
}

__PACKAGE__->meta->make_immutable;

1; # End of Monitoring::Reporter::Backend

__END__

=pod

=encoding utf-8

=head1 NAME

Monitoring::Reporter::Backend - Monitoring dashboard backend

=head1 METHODS

=head2 fetch_n_store

Fetch a result from cache or DB.

=head2 fetch

Fetch a result directly from DB.

=head2 triggers

Retrieve all matching triggers.

=head2 disabled_actions

Retrieve all disabled actions.

=head2 enable_actions

Enables all actions.

=head2 unsupported_items

Retrieve all unsupported items.

=head2 unattended_alarms

Retrieve all unsupported items.

=head2 history

Retrieve all triggers.

=head1 NAME

Monitoring::Reporter::Backend - Monitoring dashboard backend

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
