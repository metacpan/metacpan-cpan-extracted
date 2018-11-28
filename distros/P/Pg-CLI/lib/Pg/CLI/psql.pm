package Pg::CLI::psql;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.14';

use MooseX::Params::Validate qw( validated_hash );
use MooseX::Types qw( as coerce from subtype via where );
use MooseX::Types::Moose qw( ArrayRef Bool Defined Str );
use MooseX::Types::Path::Class qw( File );

use Moose;
use MooseX::SemiAffordanceAccessor;

with qw( Pg::CLI::Role::Connects Pg::CLI::Role::Executable );

has quiet => (
    is      => 'ro',
    isa     => Bool,
    default => 1,
);

{

    my $array_of_files = subtype(
        as ArrayRef [ Str | File ],
        where { @$_ > 0 },
    );
    coerce $array_of_files, from Str | File, via { [$_] };

    sub execute_file {
        my $self = shift;
        my %p    = validated_hash(
            \@_,
            database => { isa => Str,             optional => 1 },
            file     => { isa => $array_of_files, coerce   => 1 },
            options => { isa => ArrayRef [Str], optional => 1 },
            stdin   => { isa => Defined,        optional => 1 },
            stdout  => { isa => Defined,        optional => 1 },
            stderr  => { isa => Defined,        optional => 1 },
        );

        push @{ $p{options} }, map { ( '-f', "$_" ) } @{ delete $p{file} };

        $self->run(%p);
    }
}

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _run_options {
    my $self = shift;

    return ( $self->quiet() ? '-q' : () );
}
## use critic

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Wrapper for the F<psql> utility

__END__

=pod

=encoding UTF-8

=head1 NAME

Pg::CLI::psql - Wrapper for the F<psql> utility

=head1 VERSION

version 0.14

=head1 SYNOPSIS

  my $psql = Pg::CLI::psql->new(
      username => 'foo',
      password => 'bar',
      host     => 'pg.example.com',
      port     => 5433,
  );

  $psql->run(
      database => 'database',
      options  => [ '-c', 'DELETE FROM table' ],
  );

  $psql->execute_file(
      database => 'database',
      file     => 'thing.sql',
  );

  my $sql = '...';
  my $errors;
  $psql->run(
      database => 'foo',
      stdin    => \$sql,
      stderr   => \$errors,
  );

=head1 DESCRIPTION

This class provides a wrapper for the F<psql> utility.

=head1 METHODS

This class provides the following methods:

=head2 Pg::CLI::psql->new( ... )

The constructor accepts a number of parameters:

=over 4

=item * executable

The path to F<psql>. By default, this will look for F<psql> in your path and
throw an error if it cannot be found.

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

=item * quiet

This defaults to true. When true, the "-q" flag is passed to psql whenever it
is executed.

=back

=head2 $psql->run( database => ..., options => [ ... ] )

This method runs a command against the specified database. You must pass one
or more options that indicate what psql should do.

This method also accepts optional C<stdin>, C<stdout>, and C<stderr>
parameters. These parameters can be any defined value that could be passed as
the relevant parameter to L<IPC::Run3>'s C<run3> subroutine.

Most notably, you can pass scalar references to pipe data in via the C<stdin>
parameter or capture output sent to C<stdout> or C<stderr>

=head2 $psql->execute_file( database => ..., file => ... )

This method executes the specified file or files against the database. C<file>
should either be the path to a single file as a string or C<Path::Class::File>
or an arrayref of such paths. You can also pass additional options via the
C<options> parameter.

This method also accepts optional C<stdin>, C<stdout>, and C<stderr>
parameters, just like the C<< $psql->run() >> method.

=head2 $psql->version()

Returns a the three part version as a string.

=head2 $psql->two_part_version()

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
