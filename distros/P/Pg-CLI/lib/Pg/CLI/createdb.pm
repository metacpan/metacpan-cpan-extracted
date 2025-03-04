package Pg::CLI::createdb;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.14';

use Moose;
use MooseX::SemiAffordanceAccessor;

with qw( Pg::CLI::Role::Connects Pg::CLI::Role::Executable );

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Wrapper for the F<createdb> utility

__END__

=pod

=encoding UTF-8

=head1 NAME

Pg::CLI::createdb - Wrapper for the F<createdb> utility

=head1 VERSION

version 0.14

=head1 SYNOPSIS

  my $createdb = Pg::CLI::createdb->new(
      username => 'foo',
      password => 'bar',
      host     => 'pg.example.com',
      port     => 5433,
  );

  $createdb->run(
      database => 'NewDB',
      options  => [
          '--encoding', 'UTF-8',
          '--owner',    'alice',
      ],
  );

=head1 DESCRIPTION

This class provides a wrapper for the F<createdb> utility.

=head1 METHODS

This class provides the following methods:

=head2 Pg::CLI::createdb->new( ... )

The constructor accepts a number of parameters:

=over 4

=item * executable

The path to F<createdb>. By default, this will look for F<createdb> in your
path and throw an error if it cannot be found.

=item * username

The username to use when connecting to the database. Optional.

=item * password

The password to use when connecting to the database. Optional.

=item * host

The host to use when connecting to the database. Optional.

=item * port

The port to use when connecting to the database. Optional.

=item * require_ssl

If this is true, then the C<PGSSLMODE> environment variable will be set to
"require" when connecting to the database.

=back

=head2 $createdb->run( database => $db, ... )

This method runs the createdb command with the given options.

This method also accepts optional C<stdin>, C<stdout>, and C<stderr>
parameters. These parameters can be any defined value that could be passed as
the relevant parameter to L<IPC::Run3>'s C<run3> subroutine.

Most notably, you can pass scalar references to pipe data in via the C<stdin>
parameter or capture output sent to C<stdout> or C<stderr>

This method accepts the following arguments:

=over 4

=item * database

The name of the database to create. Required.

=item * options

A list of additional options to pass to the command. Optional.

=back

=head1 SUPPORT

Bugs may be submitted at L<http://rt.cpan.org/Public/Dist/Display.html?Name=Pg-CLI> or via email to L<bug-pg-cli@rt.cpan.org|mailto:bug-pg-cli@rt.cpan.org>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Pg-CLI can be found at L<https://github.com/houseabsolute/Pg-CLI>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
