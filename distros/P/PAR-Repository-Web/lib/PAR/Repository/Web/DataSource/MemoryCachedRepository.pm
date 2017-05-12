package PAR::Repository::Web::DataSource::MemoryCachedRepository;

use strict;
use warnings;
use base 'PAR::Repository::Web::DataSource::Repository';
require PAR::Repository::Query;
require PAR::Repository::Web::DataSource::MockupClient;

=head1 NAME

PAR::Repository::Web::DataSource::MemoryCachedRepository - Extract information from a PAR::Repository with caching

=head1 SYNOPSIS

See L<PAR::Repository::Web>

=head1 DESCRIPTION

=head1 METHODS

Those of the superclass (PAR::Repository::Web::DataSource::Repository) plus:

=cut

sub new {
  my $class = shift;
  my %args = @_;
  my $super = $class->SUPER::new(
    repositories => $args{repositories}
  );
  my $self = bless $super => $class;
  $self->{auto_update_cache} = $args{auto_update_cache} ? 1 : 0;

  $self->_init_cache();
  $self->update_cache();
  $self->_init_mockup_client();

  return $self;
}

sub _init_cache {
  my $self = shift;
  $self->{original_repository_objects} = $self->{repository_obj};
  delete $self->{repository_obj};
  $self->update_cache();
}

sub _init_mockup_client {
  my $self = shift;
  my $cache = $self->{cache};
  my $repos = $self->{repository_obj} || {};
  my $realrepos = $self->{original_repository_objects};

  foreach my $alias (keys %$realrepos) {
    $repos->{$alias} = PAR::Repository::Web::DataSource::MockupClient->new(
      $cache->{$alias}{modules},
      $cache->{$alias}{scripts},
    );
  }
  $self->{repository_obj} = $repos;
}

=head2 update_cache

Updates the repository indexes cached in memory if necessary.

=cut

sub update_cache {
  my $self = shift;
  my $cache = $self->{cache} || {};
  my $repos = $self->{original_repository_objects};

  foreach my $alias (keys %$repos) {
    my $repo = $repos->{$alias};
    my $repocache = $cache->{$alias} || {};

    my $updated = 0;
    if (not exists $cache->{$alias} or $repo->need_dbm_update(PAR::Repository::Client::MODULES_DBM_FILE.".zip")) {
      $updated = 1;
      my ($mdbm) = $repo->modules_dbm();
      my $modules_hash = tied(%$mdbm)->export();
      $repocache->{modules} = $modules_hash;
    }

    if (not exists $cache->{$alias} or $repo->need_dbm_update(PAR::Repository::Client::SCRIPTS_DBM_FILE.".zip")) {
      $updated = 1;
      my ($sdbm) = $repo->scripts_dbm();
      my $scripts_hash = tied(%$sdbm)->export();
      $repocache->{scripts} = $scripts_hash;
    }

    $cache->{$alias} = $repocache;
    $self->_init_mockup_client() if $updated;
  }

  $self->{cache} = $cache;
  return 1;
}


sub query_dist {
  my $self = shift;
  my $alias = shift;
  $self->update_cache()
    if $self->{auto_update_cache} and exists $self->{original_repository_objects}{$alias};
  return $self->SUPER::query_dist($alias, @_);
}

sub query_script {
  my $self = shift;
  my $alias = shift;
  $self->update_cache()
    if $self->{auto_update_cache} and exists $self->{original_repository_objects}{$alias};
  return $self->SUPER::query_script($alias, @_);
}

sub query_script_hash {
  my $self = shift;
  my $alias = shift;
  $self->update_cache()
    if $self->{auto_update_cache} and exists $self->{original_repository_objects}{$alias};
  return $self->SUPER::query_script_hash($alias, @_);
}

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2010 by Steffen Mueller E<lt>smueller@cpan.orgE<gt>

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
