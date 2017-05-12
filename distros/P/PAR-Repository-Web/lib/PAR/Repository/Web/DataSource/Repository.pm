package PAR::Repository::Web::DataSource::Repository;

use strict;
use warnings;
use PAR::Repository::Client;

=head1 NAME

PAR::Repository::Web::DataSource::Repository - Extract information from a PAR::Repository

=head1 SYNOPSIS

See L<PAR::Repository::Web>

=head1 DESCRIPTION

=head1 METHODS

=cut

sub new {
  my $class = shift;
  my %args = @_;
  my $repositories = $args{repositories};

  my $self = bless {
      repositories => $repositories,
  } => $class;
  $self->_make_objects();

  return $self;
}


sub _make_objects {
  my $self = shift;
  my $reps = $self->get_repository_configuration() || {};
  return if $self->{_initialized};
  foreach my $alias (keys %$reps) {
    my $uri = $reps->{$alias}{uri};
    $self->{repository_obj}{$alias} = PAR::Repository::Client->new(
        uri => $uri,
    );
  }
  $self->{_initialized} = 1;
  return 1;
}

=head2 get_repository_configuration

Returns the repository configuration from the YAML
configuration file. 

=cut

sub get_repository_configuration {
  my $self = shift;
  return $self->{repositories};
}

=head1 REPOSITORY QUERY METHODS

=cut

=head2 query_dist

Corresponds to C<PAR::Repository::Query>'s C<query_dist> method,
but adds a layer of indirection to be able to add caching in a subclass.

First argument should be the Model object, second should be the alias
of the repository to be queried. These should be followed by
any parameters to the repositories query method.

=cut

sub query_dist {
  my $self = shift;
  my $alias = shift;
  my $repo = $self->get_repository($alias);
  return if not $repo;

  return $repo->query_dist(@_);
}

=head2 query_module

Corresponds to C<PAR::Repository::Query>'s C<query_module> method,
but adds a layer of indirection to be able to add caching in a subclass.

First argument should be the Model object, second should be the alias
of the repository to be queried. These should be followed by
any parameters to the repositories query method.

=cut


sub query_module {
  my $self = shift;
  my $alias = shift;
  my $repo = $self->get_repository($alias);
  return if not $repo;

  return $repo->query_module(@_);
}

=head2 query_script

Corresponds to C<PAR::Repository::Query>'s C<query_script> method,
but adds a layer of indirection to be able to add caching in a subclass.

First argument should be the Model object, second should be the alias
of the repository to be queried. These should be followed by
any parameters to the repositories query method.

=cut

sub query_script {
  my $self = shift;
  my $alias = shift;
  my $repo = $self->get_repository($alias);
  return if not $repo;

  return $repo->query_script(@_);
}


=head2 query_scripthash

Corresponds to C<PAR::Repository::Query>'s C<query_script_hash> method,
but adds a layer of indirection to be able to add caching in a subclass.

First argument should be the Model object, second should be the alias
of the repository to be queried. These should be followed by
any parameters to the repositories query method.

=cut

sub query_script_hash {
  my $self = shift;
  my $alias = shift;
  my $repo = $self->get_repository($alias);
  return if not $repo;

  return $repo->query_script_hash(@_);
}


=head1 PRIVATE METHODS

=cut

=head2 get_repositories 

Returns a hash ref containing repository aliases and
C<PAR::Repository::Client> objects.

You shouldn't usually use this method directly for querying
the repository. Use the C<query_*> methods documented below.
That enables you to swap in a subclass of this model which
can do caching.

=cut

sub get_repositories {
  my $self = shift;
  return {%{$self->{repository_obj}}};
}


=head2 get_repository

Returns a single repository object identified by the repository
alias which must be passed in as first argument.

You shouldn't usually use this method directly for querying
the repository. Use the C<query_*> methods documented below.
That enables you to swap in a subclass of this model which
can do caching.

=cut

sub get_repository {
  my $self = shift;
  my $alias = shift;
  return $self->{repository_obj}{$alias};
}


=head1 COPYRIGHT AND LICENSE

Copyright 2006-2010 by Steffen Mueller E<lt>smueller@cpan.orgE<gt>

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
