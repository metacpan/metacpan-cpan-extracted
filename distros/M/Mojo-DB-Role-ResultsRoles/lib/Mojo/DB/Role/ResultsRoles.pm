package Mojo::DB::Role::ResultsRoles;

use Mojo::Base -role;

our $VERSION = 'v0.1.0';

requires 'db';

has results_roles => sub { [] };

around db => sub {
  my $orig = shift;
  my $self = shift;
  my $db = $self->$orig(@_);
  my $class = $db->results_class;
  my $roles = $self->results_roles;
  $db->results_class($class->with_roles(@$roles)) if @$roles;
  return $db;
};

1;

=head1 NAME

Mojo::DB::Role::ResultsRoles - Apply roles to Mojo database results

=head1 SYNOPSIS

  use Mojo::Pg;
  my $pg = Mojo::Pg->new(...)->with_roles('Mojo::DB::Role::ResultsRoles');
  push @{$pg->results_roles}, 'Mojo::DB::Results::Role::Something';
  my $results = $pg->db->query(...);
  # $results does Mojo::DB::Results::Role::Something

=head1 DESCRIPTION

This role allows roles to be applied to the results objects returned by
L<Mojo::Pg> or similar database APIs. The manager object must create database
connections via a C<db> method, which must have a C<results_class> attribute
used to instantiate results objects.

=head1 ATTRIBUTES

L<Mojo::DB::Role::ResultsRoles> composes the following attributes.

=head2 results_roles

  my $roles = $manager->results_roles;
  $manager  = $manager->results_roles(\@roles);

Array reference of roles to compose into results objects. This only affects
database objects created by subsequent calls to the C<db> method.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Mojo::Pg>, L<Mojo::mysql>, L<Mojo::SQLite>
