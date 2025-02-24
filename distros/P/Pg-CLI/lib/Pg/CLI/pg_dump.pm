package Pg::CLI::pg_dump;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.14';

use Moose;
use MooseX::SemiAffordanceAccessor;

with qw( Pg::CLI::Role::Connects Pg::CLI::Role::Executable );

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Wrapper for the F<pg_dump> utility

__END__

=pod

=encoding UTF-8

=head1 NAME

Pg::CLI::pg_dump - Wrapper for the F<pg_dump> utility

=head1 VERSION

version 0.14

=head1 SYNOPSIS

  my $pg_dump = Pg::CLI::pg_dump->new(
      username => 'foo',
      password => 'bar',
      host     => 'pg.example.com',
      port     => 5433,
  );

  $pg_dump->run(
      database => 'database',
      options  => [ '-C' ],
  );

  my $sql;
  $pg_dump->run(
      database => 'database',
      options  => [ '-C' ],
      stdout   => \$sql,
  );

=head1 DESCRIPTION

This class provides a wrapper for the F<pg_dump> utility.

=head1 METHODS

This class provides the following methods:

=head2 Pg::CLI::pg_dump->new( ... )

The constructor accepts a number of parameters:

=over 4

=item * executable

The path to F<pg_dump>. By default, this will look for F<pg_dump> in your path
and throw an error if it cannot be found.

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

=head2 $pg_dump->run( database => ..., options => [ ... ] )

This method dumps the specified database. Any values passed in C<options> will
be passed on to pg_dump.

This method also accepts optional C<stdin>, C<stdout>, and C<stderr>
parameters. These parameters can be any defined value that could be passed as
the relevant parameter to L<IPC::Run3>'s C<run3> subroutine.

Notably, you can capture the dump output in a scalar reference for the
C<stdout> output.

=head2 $pg_dump->version()

Returns a the three part version as a string.

=head2 $pg_dump->two_part_version()

Returns the first two decimal numbers in the version.

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
