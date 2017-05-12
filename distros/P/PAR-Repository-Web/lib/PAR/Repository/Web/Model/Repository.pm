package PAR::Repository::Web::Model::Repository;

use strict;
use warnings;
use base 'Catalyst::Model';

=head1 NAME

PAR::Repository::Web::Model::Repository - Catalyst Model for a PAR::Repository

=head1 SYNOPSIS

See L<PAR::Repository::Web>

=head1 DESCRIPTION

Catalyst Model.

=head1 METHODS

=cut

sub new {
  my ($class, $app, $args) = @_;
  
  if (not defined $args->{data_source}) {
    # default to slow, simple implementation
    $args->{data_source} = 'Repository';
  }

  $class->config($args);


  eval "require PAR::Repository::Web::DataSource::" . $args->{data_source};
  die "Could not load data source: $@" if $@;

  my $datasource = "PAR::Repository::Web::DataSource::" . $args->{data_source};

  my $options = $args->{data_source_options} || {};

  my $source = $datasource->new(
    %$options,
    repositories => $args->{repositories}
  );

  my $self = bless {
    data_source => $source,
  } => $class;

  return $self;
}

=head2 get_repository_configuration

Returns the repository configuration from the YAML
configuration file. 

=cut

sub get_repository_configuration {
  my $self = shift;
  return $self->{data_source}->get_repository_configuration();
}

=head1 REPOSITORY QUERY METHODS

=cut

=head2 query_dist

Corresponds to C<PAR::Repository::Query>'s C<query_dist> method,
but adds a layer of indirection to be able to add caching.

First argument should be the Model object, second should be the alias
of the repository to be queried. These should be followed by
any parameters to the repositories query method.

=cut

sub query_dist {
  my $self = shift;
  return $self->{data_source}->query_dist(@_);
}

=head2 query_module

Corresponds to C<PAR::Repository::Query>'s C<query_module> method,
but adds a layer of indirection to be able to add caching.

First argument should be the Model object, second should be the alias
of the repository to be queried. These should be followed by
any parameters to the repositories query method.

=cut


sub query_module {
  my $self = shift;
  return $self->{data_source}->query_module(@_);
}

=head2 query_script

Corresponds to C<PAR::Repository::Query>'s C<query_script> method,
but adds a layer of indirection to be able to add caching.

First argument should be the Model object, second should be the alias
of the repository to be queried. These should be followed by
any parameters to the repositories query method.

=cut

sub query_script {
  my $self = shift;
  return $self->{data_source}->query_script(@_);
}

=head2 query_script_hash

Corresponds to C<PAR::Repository::Query>'s C<query_script_hash> method,
but adds a layer of indirection to be able to add caching.

First argument should be the Model object, second should be the alias
of the repository to be queried. These should be followed by
any parameters to the repositories query method.

=cut

sub query_script_hash {
  my $self = shift;
  return $self->{data_source}->query_script_hash(@_);
}

=head1 PRIVATE METHODS

=cut

=head2 get_repositories 

Returns a hash ref containing repository aliases and
C<PAR::Repository::Client> objects.

You shouldn't usually use this method directly for querying
the repository. Use the C<query_*> methods documented below.
That enables you to use a cache-enabled data source.

=cut

sub get_repositories {
  my $self = shift;
  return $self->{data_source}->get_repositories(@_);
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
  return $self->{data_source}->get_repository(@_);
}


=head1 COPYRIGHT AND LICENSE

Copyright 2006-2008 by Steffen Mueller E<lt>smueller@cpan.orgE<gt>

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
