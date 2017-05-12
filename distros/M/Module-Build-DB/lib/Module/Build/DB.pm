package Module::Build::DB;

use strict;
use warnings;

use base 'Module::Build';
our $VERSION = '0.10';

=head1 Name

Module::Build::DB - Build, configure, and test database-backed applications

=head1 Synopsis

In F<Build.PL>:

  use strict;
  use Module::Build::DB;

  Module::Build::DB->new(
      module_name   => 'MyApp',
      db_config_key => 'dbi',
      context       => 'test',
  )->create_build_script;

On the command-line:

  perl Build.PL
  ./Build --db_super_user postgres
  ./Build db --context test
  ./Build test

=head1 Description

This module subclasses L<Module::Build> to provide added functionality for
configuring, building, and testing database-backed applications. It uses a
simple Rails-style numbered migration scheme, although migration scripts are
written in pure SQL, not Perl.

Frankly, this isn't a great module. Some reasons:

=over

=item *

The numbered method of tracking migration dependencies has very little
flexibility.

=item *

Subclassing Module::Build is a really bad way to extend the build system,
because you can't really mix in other build features.

=back

Someday, I hope to fix the first issue by looking more closely at L<database
change
management|http://www.justatheory.com/computers/databases/change-management.html>,
and perhaps by adopting a L<completely different
approach|http://www.depesz.com/index.php/2010/08/22/versioning/>. The latter
problem I would likely solve by completely separating the migration code from
the build system, and then integrating as appropriate (hopefully Module::Build
will get proper plugins someday).

But in the meantime, I have working code that depends on this simple
implementation (which does support L<PostgreSQL|http://www.postgresql.org/>,
L<SQLite|http://www.sqlite.org/> and L<MySQL|http://www.mysql.com/>), and I
want it to be easy for people to get at this dependency. So here we are.

=cut

##############################################################################

=head1 Class Interface

=head2 Properties

Module::Build::DB defines these properties in addition to those specified by
L<Module::Build|Module::Build>. Note that these may be specified either in
F<Build.PL> or on the command-line.

=head3 context

  perl Build.PL --context test

Specifies the context in which the build will run. The context associates the
build with a configuration file, and therefore must be named for a
configuration file your project. For example, to build in the "dev" context,
there must be a F<dev.yml> file (or F<dev.json> or some other format supported
by L<Config::Any>) in the F<conf/> or F<etc/> directory of your project.
Defaults to "test", which is also the only required context.

=head3 db_client

  perl Build.PL --db_client /usr/local/pgsql/bin/pgsql

Specifies the location of the database command-line client. Defaults to
F<psql>, F<mysql>, or F<sqlite3>, depending on the value of the DSN in the
context configuration file.

=head3 drop_db

  ./Build db --drop_db 1

Tells the L</"db"> action to drop the database and build a new one. When this
property is set to a false value (the default), an existing database for the
current context will not be dropped, but it will be brought up-to-date by
C<./Build db>.

=head3 db_config_key

The config key under which DBI configuration is stored in the configuration
file. Defaults to "dbi". The keys that should be under this configuration key
are:

=over

=item * C<dsn>

=item * C<username>

=item * C<password>

=back

=head3 db_super_user

=head3 db_super_pass

  perl Build.PL --db_super_user root --db_super_pass s3cr1t

Specifies a super user and password to be used to connect to the database.
This is important if you need to use a different database user to create and
update the database than to run your app. Most likely you'll use this for
production deployments. If not specified the user name and password from the
the context configuration file will be used.

=head3 test_env

  ./Build db --test_env CATALYST_DEBUG=0 CATALYST_CONFIG=conf/test.json

Optional hash reference of environment variables to set for the lifetime of
C<./Build test>. This can be useful for making Catalyst less verbose, for
example. Another use is to tell PostgreSQL where to find pgTAP functions when
they're installed in a schema outside the normal search path in your database:

  ./Build db --test_env PGOPTIONS='--search_path=tap,public'

=head3 meta_table

  ./Build db --meta_table mymeta

The name of the metadata table that Module::Build::DB uses to track migrations
in the database. Defaults to "metadata". Change if that name conflicts with
other objects in your application's database, but use only characters that
don't require quoting in the database (e.g., "my_meta" but not "my meta").

=head3 replace_config

  Module::Build::DB->new(
      module_name    => 'MyApp',
      db_config_key  => 'dbi',
      replace_config => 'conf/dev.json',
  )->create_build_script;

Set to a string or regular expression (using C<qr//>) and, the C<module_name>
file will be opened during C<./Build> and matching strings replaced with name
of the context configuration file. This is useful when deploying Catalyst
applications, for example, where your C<module_name> file might have something
like this in it:

  __PACKAGE__->config(
      name                   => 'MyApp',
      'Plugin::ConfigLoader' => { file => 'conf/dev.json' },
  );

The C<conf/dev.json> string would be replaced in the copy of the file in
F<blib/lib> with the context configuration file name. Use a regular expression
if you want to cover a variety of values, as in:

      replace_config => qr{etc/[^.].json},

=head3 named

  ./Build migration --named create_users

A string to use when creating a new migration file. The above command would
create a file named F<sql/$time-create_users.sql>.

=cut

__PACKAGE__->add_property( context        => 'test'     );
__PACKAGE__->add_property( replace_config => undef      );
__PACKAGE__->add_property( db_config_key  => 'dbi'      );
__PACKAGE__->add_property( db_client      => undef      );
__PACKAGE__->add_property( drop_db        => 0          );
__PACKAGE__->add_property( db_super_user  => undef      );
__PACKAGE__->add_property( db_super_pass  => undef      );
__PACKAGE__->add_property( test_env       => {}         );
__PACKAGE__->add_property( meta_table     => 'metadata' );
__PACKAGE__->add_property( named          => undef      );

##############################################################################

=head2 Actions

=head3 test

=begin comment

=head3 ACTION_test

=end comment

Overrides the default implementation to ensure that tests are only run in the
"test" context, to make sure that the database is up-to-date, and to set up
the test environment with values stored in C<test_env>.

=cut

sub ACTION_test {
    my $self = shift;
    die qq{ERROR: Tests can only be run in the "test" context\n}
        . "Try `./Build test --context test`\n"
        unless $self->context eq 'test';

    # Make sure the database is up-to-date.
    $self->depends_on('db');

    # Tell the tests where to find stuff, like pgTAP.
    local %ENV = ( %ENV, %{ $self->test_env } );

    # Make it so.
    $self->SUPER::ACTION_test(@_);
}

##############################################################################

=head3 migration

=begin comment

=head3 ACTION_migration

=end comment

Creates a new migration script in the F<sql> directory. Best used in
combination with the C<--named> option.

=cut

sub ACTION_migration {
    my $self = shift;
    File::Path::mkpath('sql');
    die "Can't create directory sql: $!" unless -d 'sql';
    my $file = File::Spec->catfile(
        'sql',
        (time . '-' . $self->named || 'migration') . '.sql'
    );
    my $fh = IO::File->new("> $file") or die "Can't create $file: $!";
    print $fh "-- $file SQL Migration\n\n";
    close $fh;
    return $self;
}

##############################################################################

=head3 config_data

=begin comment

=head3 ACTION_config_data

=end comment

Overrides the default implementation to completely change its behavior. :-)
Rather than creating a whole new configuration file in Module::Build's weird
way, this action now simply opens the application file (that returned by
C<dist_version_from> and replaces all text matching C<replace_config> with the
configuration file for the current context. This means that an installed app
is effectively configured for the proper context at installation time.

=cut

sub ACTION_config_data {
    my $self = shift;
    my $replace = $self->replace_config or return $self;

    my $file = File::Spec->catfile( split qr{/}, $self->dist_version_from);
    my $blib = File::Spec->catfile( $self->blib, $file );

    # Die if there is no file
    die qq{ERROR: "$blib" seems to be missing!\n} unless -e $blib;

    # Make sure we have a config file.
    $self->cx_config;

    # Figure out where we're going to install this beast.
    $file       .= '.new';
    my $new     = File::Spec->catfile( $self->blib, $file );
    my $config  = $self->cx_config_file;
    $replace    = quotemeta $replace unless ref $replace eq 'Regexp';

    # Update the file.
    open my $orig, '<', $blib or die qq{Cannot open "$blib": $!\n};
    open my $temp, '>', $new or die qq{Cannot open "$new": $!\n};
    while (<$orig>) {
        s/$replace/$config/g;
        print $temp $_;
    }
    close $orig;
    close $temp;

    # Make the switch.
    rename $new, $blib or die "Cannot rename '$blib' to '$new': $!\n";
    my $mode = oct(444) | ( $self->is_executable($blib) ? oct(111) : 0 );
    chmod $mode, $blib;
    return $self;
}

##############################################################################

=head3 db

=begin comment

=head3 ACTION_db

=end comment

This action creates or updates the database for the current context. If
C<drop_db> is set to a true value, the database will be dropped and created
anew. Otherwise, if the database already exists, it will be brought up-to-date
from the files in the F<sql> directory.

Those files are expected to all be SQL scripts. They must all start with a
number followed by a dash. The number indicates the order in which the scripts
should be run. For example, you might have SQL files like so:

  sql/001-types.sql
  sql/002-tables.sql
  sql/003-triggers.sql
  sql/004-functions.sql
  sql/005-indexes.sql

The SQL files will be run in integer order to build or update the database.
Module::Build::DB will track the current schema update number corresponding to
the last run SQL script in the C<metadata> table in the database.

If any of the scripts has an error, Module::Build::DB will immediately exit with
the relevant error. To prevent half-way applied updates, the SQL scripts
should use transactions as appropriate.

=cut

sub ACTION_db {
    my $self = shift;

    # Get the database configuration information.
    my $config = $self->cx_config;

    my ( $db, $cmd ) = $self->db_cmd( $config->{$self->db_config_key} );

    # Does the database exist?
    my $db_exists = $self->drop_db ? 1 : $self->_probe(
        $self->{driver}->get_check_db_command($cmd, $db)
    );

    if ( $db_exists ) {
        # Drop the existing database?
        if ( $self->drop_db ) {
            $self->log_info(qq{Dropping the "$db" database\n});
            $self->do_system(
                $self->{driver}->get_drop_db_command($cmd, $db)
            ) or die;
        } else {
            # Just run the upgrades and be done with it.
            $self->upgrade_db( $db, $cmd );
            return;
        }
    }

    # Now create the database and run all of the SQL files.
    $self->log_info(qq{Creating the "$db" database\n});
    $self->do_system( $self->{driver}->get_create_db_command($cmd, $db) ) or die;

    # Add the metadata table and run all of the schema scripts.
    $self->create_meta_table( $db, $cmd );
    $self->upgrade_db( $db, $cmd );
}

##############################################################################

=head2 Instance Methods

=head3 cx_config

  my $config = $build->cx_config;

Uses L<Config::Any|Config::Any> to read and return the contents of the current
context's configuration file.

=cut

sub cx_config {
    my $self = shift;
    return $self->{cx_config} if $self->{cx_config};
    my @stems = map {
        File::Spec->catfile( $_ => $self->context )
    } qw(conf etc);
    require Config::Any;
    my $cfg = Config::Any->load_stems({ stems => \@stems, use_ext => 1 })->[0];
    my ($file, $config) = %{ $cfg };
    $self->cx_config_file($file);
    return $self->{cx_config} = $config;
}

=head3 cx_config_file

  my $config_file = $build->cx_config_file;

Returns the name of the context configuration file loaded by C<cx_config>. If
C<cx_config> has not yet been called and loaded a file, it will be.

=cut

sub cx_config_file {
    my $self = shift;
    return $self->{cx_config_file} = shift if @_;
    $self->cx_config; # Make sure we've found the file.
    return $self->{cx_config_file};
}

=head3 db_cmd

  my ($db_name, $db_cmd) = $build->db_cmd($db_config);

Uses the current context's configuration to determine all of the options to
run the C<db_client> for building the database. Returns the name of the
database and an array ref representing the C<db_client> command and all of its
options, suitable for passing to C<system>. The database name is not included
so as to enable connecting to another database (e.g., template1 on PostgreSQL)
to create the database.

=cut

sub db_cmd {
    my ($self, $dconf) = @_;
    return @{$self}{qw(db_name db_cmd)} if $self->{db_cmd} && $self->{db_name};

    require DBI;
    my (undef, $driver, undef, undef, $driver_dsn) = DBI->parse_dsn($dconf->{dsn});
    my %dsn = map { split /=/ } split /;/, $driver_dsn;

    $driver = __PACKAGE__ . "D::$driver";
    eval "require $driver"
        or die $@ || "Package $driver did not return a true value\n";

    # Make sure we have a client.
    $self->db_client( $driver->get_client ) unless $self->db_client;

    my ($db, $cmd) = $driver->get_db_and_command($self->db_client, {
        %{ $dconf },
        %dsn,
        db_super_user => $self->db_super_user,
        db_super_pass => $self->db_super_pass,
    });

    $self->{db_cmd}  = $cmd;
    $self->{db_name} = $db;
    $self->{driver}  = $driver;
    return ($db, $cmd);
}

##############################################################################

=head3 create_meta_table

  my ($db_name, $db_cmd ) = $build->db_cmd;
  $build->create_meta_table( $db_name, $db_cmd );

Creates the C<metadata> table, which Module::Build::DB uses to track the current
schema version (corresponding to update numbers on the SQL scripts in F<sql>
and other application metadata. If the table already exists, it will be
dropped and recreated. One row is initially inserted, setting the
"schema_version" to 0.

=cut

sub create_meta_table {
    my ($self, $db, $cmd) = @_;
    my $quiet = $self->quiet;
    $self->quiet(1) unless $quiet;
    my $driver = $self->{driver};
    $self->do_system($driver->get_execute_command(
        $cmd, $db,
        $driver->get_meta_table_sql($self->meta_table),
    )) or die;
    my $table = $self->meta_table;
    $self->do_system( $driver->get_execute_command($cmd, $db, qq{
        INSERT INTO $table VALUES ( 'schema_version', 0, '' );
    })) or die;
    $self->quiet(0) unless $quiet;
}

##############################################################################

=head3 upgrade_db

  my ($db_name, $db_cmd ) = $build->db_cmd;
  push $db_cmd, '--dbname', $db_name;
  $self->upgrade_db( $db_name, $db_cmd );

Upgrades the database using all of the schema files in the F<sql> directory,
applying each in numeric order, setting the schema version upon the success of
each, and exiting upon any error.

=cut

sub upgrade_db {
    my ($self, $db, $cmd) = @_;

    $self->log_info(qq{Updating the "$db" database\n});
    my $driver = $self->{driver};
    my $table  = $self->meta_table;

    # Get the current version number of the schema.
    my $curr_version = $self->_probe(
        $driver->get_execute_command(
            $cmd, $db,
            qq{SELECT value FROM $table WHERE label = 'schema_version'},
        )
    );

    my $quiet = $self->quiet;
    # Apply all relevant upgrade files.
    for my $sql (sort grep { -f } glob 'sql/[0-9]*-*.sql' ) {
        # Compare upgrade version numbers.
        ( my $new_version = $sql ) =~ s{^sql[/\\](\d+)-.+}{$1};
        next unless $new_version > $curr_version;

        # Apply the version.
        $self->do_system( $driver->get_file_command($cmd, $db, $sql) ) or die;
        $self->quiet(1) unless $quiet;
        $self->do_system( $driver->get_execute_command($cmd, $db, qq{
            UPDATE $table
               SET value = $new_version
             WHERE label = 'schema_version'
        })) or die;
        $self->quiet(0) unless $quiet;
    }
}

sub _probe {
    my $self = shift;
    my $ret = $self->_backticks(@_);
    chomp $ret;
    return $ret;
}

1;

__END__

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Copyright

Copyright (c) 2008-2010 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
