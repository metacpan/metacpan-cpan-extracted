package Pg::DatabaseManager::TestMigrations;
$Pg::DatabaseManager::TestMigrations::VERSION = '0.06';
use strict;
use warnings;

use Exporter qw( import );
use File::Slurp qw( read_file );
use File::Temp qw( tempdir );
use MooseX::Params::Validate 0.15 qw( validated_hash );
use Path::Class qw( dir file );
use Pg::CLI::pg_dump;
use Pg::DatabaseManager;
use Test::Differences;
use Test::More;

our @EXPORT_OK = 'test_migrations';

sub test_migrations {
    my %p = validated_hash(
        \@_,
        class => {
            isa     => 'Str',
            default => 'Pg::DatabaseManager',
        },
        min_version                    => { isa => 'Int' },
        max_version                    => { isa => 'Int' },
        sql_file_pattern               => { isa => 'Str' },
        MX_PARAMS_VALIDATE_ALLOW_EXTRA => 1,
    );

    my $class            = delete $p{class};
    my $min_version      = delete $p{min_version};
    my $max_version      = delete $p{max_version};
    my $sql_file_pattern = delete $p{sql_file_pattern};

    my $tempdir = dir( tempdir( CLEANUP => 1 ) );

    my %fresh;

    for my $version ( $min_version .. $max_version ) {
        ( my $sql_file = $sql_file_pattern ) =~ s/%{version}/$version/g;

        my $man = $class->new(
            db_name => 'MigrationTest',
            %p,
            sql_file => $sql_file,
            drop     => 1,
            quiet    => 1,
        );

        $man->update_or_install_db();

        my $dump = $tempdir->file( 'fresh.v' . $version );

        _pg_dump( $man, $dump );

        $fresh{$version} = $dump;
    }

    for my $version ( $min_version .. $max_version - 1 ) {
        ( my $sql_file = $sql_file_pattern ) =~ s/%\{version\}/$version/g;

        my $man = $class->new(
            db_name => 'MigrationTest',
            %p,
            sql_file => $sql_file,
            drop     => 1,
            quiet    => 1,
        );

        $man->update_or_install_db();

        for my $next_version ( $version + 1 .. $max_version ) {
            my $from_version = $next_version - 1;

            $man->_migrate_db( $from_version, $next_version, 'no dump' );

            my $dump
                = $tempdir->file(
                sprintf( 'migrate.v%d-to-v%d', $from_version, $next_version )
                );

            _pg_dump( $man, $dump );

            _compare_files(
                $dump,
                $fresh{$next_version},
                $version,
                $next_version
            );
        }
    }
}

sub _pg_dump {
    my $man  = shift;
    my $dump = shift;

    $man->_pg_dump->run(
        database => $man->db_name(),
        options  => [
            '-C',
            '-f', $dump->stringify(),
            '-s',
        ],
    );
}

sub _compare_files {
    my $migrated      = shift;
    my $fresh         = shift;
    my $start_version = shift;
    my $final_version = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 2;

    eq_or_diff(
        scalar read_file( $migrated->stringify() ),
        scalar read_file( $fresh->stringify() ),
        "comparing migration from $start_version to $final_version"
    );
}

# ABSTRACT: Test your database migrations

__END__

=pod

=encoding UTF-8

=head1 NAME

Pg::DatabaseManager::TestMigrations - Test your database migrations

=head1 VERSION

version 0.06

=head1 SYNOPSIS

  use Pg::DatabaseManager::TestMigrations qw( test_migrations );
  use Test::More;

  test_migrations(
      min_version      => 3,
      max_version      => 6,
      sql_file_pattern => 't/schemas/MyApp.sql.v%{version}',
  );

  done_testing();

=head1 DESCRIPTION

This module provides a single exportable subroutine for testing migrations.

=head1 SUBROUTINES

This module provides one exportable subroutine, C<test_migrations>:

=head2 test_migrations( ... )

This subroutine will test your migrations. It requires a number of parameters:

=over 4

=item * min_version

The minimum database version to test. Required.

=item * max_version

The maximum database version to test. Required.

=item * sql_file_pattern

This should be a string that contains the pattern "%{version}, for example
something like "path/to/schemas/MyApp.sql.v%{version}".

Internally, the code will replace "%{version}" with each version number to
find the appropriate sql file.

Required.

=item * class

This is the database manager class to use. This defaults to
L<Pg::DatabaseManager>, but you can use your own subclass if needed.

=item * db_name

The database name to use when testing migrations. This defaults to
"MigrationTest" but you can use any version you like.

=back

You can also pass any parameter that the database manager class accepts, such
as C<username>, C<password>, C<db_encoding>, etc.

=head1 HOW IT WORKS

The tests are done by creating each version of the database from scratch,
using the appropriate SQL file, then dumping the resulting database with
F<pg_dump>. Then the code recreates each version and runs the migrations from
that version to the max version, comparing the output of F<pg_dump> after each
migration.

It uses L<Test::Differences> to compare the dumped databases.

=head1 BUGS

See L<Pg::DatabaseManager> for details on reporting bugs.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
