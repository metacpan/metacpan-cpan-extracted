package Plack::Middleware::DBIC::QueryLog;

use Moo;
use Plack::Util;
use 5.008008;

extends 'Plack::Middleware';

our $VERSION = '0.05';
sub PSGI_KEY { 'plack.middleware.dbic.querylog' }

sub get_querylog_from_env {
  my ($self_or_class, $env) = @_;
  $env->{+PSGI_KEY};
}

has 'querylog_class' => (
  is => 'ro',
  default => sub { 'DBIx::Class::QueryLog' },
);

has 'querylog_args' => (
  is => 'ro',
  default => sub { +{} },
);

sub _create_querylog {
  Plack::Util::load_class($_[0]->querylog_class)
    ->new($_[0]->querylog_args);
}

sub find_or_create_querylog_in {
  my ($self, $env) = @_;
  $env->{+PSGI_KEY} ||= $self->_create_querylog;
}

sub call {
  my ($self, $env) = @_;
  $self->find_or_create_querylog_in($env);
  $self->app->($env);
}

1;

=head1 NAME

Plack::Middleware::DBIC::QueryLog - Expose a DBIC QueryLog Instance in Middleware

=head1 SYNOPSIS

    use Plack::Builder;
    builder {
      enable 'DBIC::QueryLog',
        querylog_args => {passthrough => 1};
      $app;
    };

=head1 DESCRIPTION

L<Plack::Middleware::DBIC::QueryLog> does one thing, it places an object that
is either an instance of L<DBIx::Class::QueryLog> OR a compatible object into
the C<$env> under C<plack.middleware.dbic.querylog>.  A new instance is created
for each incoming request.

The querylog is intended to be used by L<DBIX::Class> to log and profile SQL
queries, particularly during the context of a web request handled by your
L<Plack> application.  See the documentation for L<DBIx::Class::QueryLog> and
in L<DBIx::Class::Storage/debugobj> for more information.

This middleware is intended to act as a bridge between L<DBIx::Class>, which
can consume and populate the querylog, with a reporting tool such as seen in
L<Plack::Middleware::Debug::DBIC::QueryLog>.  This functionality was refactored
out of L<Plack::Middleware::Debug::DBIC::QueryLog> to facilitate interoperation
with other types of reporting tools.  For example, you may want query logging
but you don't need the Plack debug panels (maybe you are building an RPC or
REST application server and want sql query logging, is a possible use case).

Unless you are building some custom logging tools, you probably just want to
use the existing debug panel (L<Plack::Middleware::Debug::DBIC::QueryLog>)
rather than building something custom around this middleware.

If you are using an existing web application development system such as L<Catalyst>,
you can use L<Catalyst::TraitFor::Model::DBIC::Schema::QueryLog::AdoptPlack> to
'hook' the query log into your L<DBIx::Class> schema model.  If you are using
a different framework, or building your own, please consider releasing your
code or sending me a document patch suitable for including in a workbook or FAQ.

=head1 ARGUMENTS

This middleware accepts the following arguments.

=head2 querylog_class

This is the class which is used to build the C<querylog> unless one is already
defined.  It defaults to L<DBIx::Class::QueryLog>.  You should probably leave
this alone unless you need to subclass or augment L<DBIx::Class::QueryLog>.

If the class name you pass has not already been included (via C<use> or
C<require>) we will automatically try to C<require> it.

=head2 querylog_args

Accepts a HashRef of data which will be passed to L</"querylog_class"> when
building the C<querylog>.

=head1 SUBROUTINES

This middleware defines the following public subroutines

=head2 PSGI_KEY

Returns the PSGI C<$env> key under which you'd expect to find an instance of
L<DBIx::Class::QueryLog>.

=head2 get_querylog_from_env

Given a L<Plack> C<$env>, returns a L<DBIx::Class::QueryLog>, if one exists.
You should use this in your code that is trying to access the querylog.  For
example:

    use Plack::Middleware::DBIC::QueryLog;

    sub get_querylog_from_env {
      my ($self, $env) = @_;
      Plack::Middleware::DBIC::QueryLog->get_querylog_from_env($env);
    }

This returns undef if it does not exist.  This is the officially supported
interface for extracting a L<DBIx::Class::QueryLog> from a L<Plack> request.

=head1 SEE ALSO

L<Plack>, L<Plack::Middleware>, L<Plack::Middleware::Debug::DBIC::QueryLog>,
L<Catalyst::TraitFor::Model::DBIC::Schema::QueryLog::AdoptPlack>

=head1 AUTHOR

John Napiorkowski, C<< <jjnapiork@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2011, John Napiorkowski

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


