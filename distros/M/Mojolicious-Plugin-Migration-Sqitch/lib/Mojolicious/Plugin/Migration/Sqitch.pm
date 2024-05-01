package Mojolicious::Plugin::Migration::Sqitch 0.01;
use v5.26;
use warnings;

# ABSTRACT: Run Sqitch database migrations from a Mojo app

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Migration::Sqitch - Run Sqitch database migrations from a Mojo app

=head1 SYNOPSIS

  # Register plugin
  $self->plugin('Migration::Sqitch' => {
    dsn       => 'dbi:mysql:host=localhost;port=3306;database=myapp',
    registry  => 'sqitch_myapp',
    username  => 'sqitch',
    password  => 'world-banana-tuesday',
    directory => '/schema',
  });

  # use from command-line (normally done by startup script to ensure db up to date before app starts)
  tyrrminal@prodserver:/app$ script/myapp schema-initdb
  [2024-04-30 11:26:47.91166] [8982] [info] Database initialized

  tyrrminal@prodserver:/app$ script/myapp schema-migrate
  Deploying changes to db:MariaDB://sqitch@db/myapp_dev
    + initial_schema .. ok
  [2024-04-30 11:29:13.80192] [8985] [info] Database migration complete

  # Revert a migration in dev
  tyrrminal@devserver:/app$ script/myapp schema-migrate schema-migrate revert
  Revert all changes from db:MariaDB://sqitch@db/myapp_dev? [Yes] 
    - initial_schema .. ok
  [2024-04-30 11:26:47.91166] [8982] [info] Database migration complete

  # Start over from scratch
  tyrrminal@devserver:/app$ script/myapp schema-initdb --reset
  This will result in all data being deleted from the database. Are you sure you want to continue? [yN] y
  [2024-04-30 11:28:10.73379] [8983] [info] Database reset
  [2024-04-30 11:28:10.73501] [8983] [info] Database initialized

=head1 DESCRIPTION

Mojolicious::Plugin::Migration::Sqitch enables the use of sqitch via Mojolicious
commands. The primary advantage of this is single-point configuration: just pass
the appropriate parameters in at plugin registration and then you don't have to
worry about passwords, DSNs, and filesystem locations for running sqitch commands
thereafter.

This plugin also provides some additional functionality for initializing the 
database, which can't easily be done strictly through sqitch migrations without
hardcoding database names, which can be troublesome depending on the deployment.

=head1 METHODS

L<Mojolicious::Plugin::Migration::Sqitch> inherits all methods from 
L<Mojolicious::Plugin> and implements the following new ones

=head2 register( $args )

Register plugin in L<Mojolicious> application. The following keys are required
in C<$args>

=head4 dsn

The L<data source name|https://en.wikipedia.org/wiki/Data_source_name> for 
connecting to the I<application> database.

E.g., C<dbi:mysql:host=db;port=3306;database=myapp_prod>

=head4 registry

The name of the database used by sqitch for tracking migrations

E.g., C<myapp_prod_sqitch>

=head4 username

Database username for sqitch migrations. As this account needs to run arbitrary
SQL code (both DDL and DML), it must have sufficiently high privileges. This
can be the same account used by the application, if this consideration is taken
into account.

=head4 password

The password corresponding to the sqitch migration database account

=head4 directory

The on-disk location of the sqitch migrations directory. Sqitch expects to find
C<deploy>, C<revert>, and C<verify> subdirectories there, as well as the 
C<sqitch.plan> file. It must also contain a C<sqitch.conf> file, but the only
contents of this file needed are:

    [core]
      engine = $ENGINE

With C<$ENGINE> replaced by the actual engine name, e.g., C<mysql> or C<pgsql>.
This plugin handles the rest of the configuration that would normally be found
in that file.

E.g., C</schema> (in a containerized environment), or C</home/mojo/myapp/schema>

=head2 run_schema_initialization( \%args )

Create the configured application and migration databases, if either or both
do not already exist. One key is regarded in the C<args> HashRef:

=head4 reset

If this key is given and is assigned a "truthy" value, the application and 
migration databases will be dropped (if either or both exists) before being 
re-created. I<This is a destructive operation!>

=head2 run_schema_migration( $sqitch_subcommand )

Run the specified C<$sqitch_subcommand> including any additional parameters 
(e.g., C<deploy> or C<revert -to @HEAD^1>). Returns the exit status of the 
sqitch command to indicate success (zero) or failure (non-zero).

=head1 COMMANDS

=head2 schema-initdb [--reset]

Mojolicious command to execute L</run_schema_initialization>

If the C<--reset> flag is given, corresponding to the methods's L</reset> arg 
key, a console warning is given alerting the user of the destructive nature of 
this operation and must be manually approved before continuing.

=head2 schema-migrate [args]

Mojolicious command to execute L</run_schema_migration>. Any additional args
given are whitespace-joined and passed on to that method. If no args are 
provided, C<deploy> is assumed.

=cut

use Mojo::Base 'Mojolicious::Plugin';

use DBI;
use Syntax::Keyword::Try;
use Readonly;

use experimental qw(signatures);

Readonly::Scalar my $INITDB_SQL  => q{CREATE DATABASE IF NOT EXISTS `%s` CHARACTER SET 'utf8mb4' COLLATE 'utf8mb4_general_ci'};
Readonly::Scalar my $RESETDB_SQL => q{DROP DATABASE IF EXISTS `%s`};

sub _parse_dsn($dsn) {
  my ($scheme, $driver, $attr_string, $attr_hash, $driver_param_str) = DBI->parse_dsn($dsn);
  my %driver_params = split(/[;=]/, $driver_param_str);
  {
    scheme    => $scheme,
    driver    => $driver,
    attr_str  => $attr_string,
    attrs     => $attr_hash // {},
    params    => {%driver_params},
    param_str => $driver_param_str
  };
}

sub register($self, $app, $conf) {
  push($app->commands->namespaces->@*, 'Mojolicious::Plugin::Migration::Sqitch::Command');

  my $dsn                  = _parse_dsn($conf->{dsn});
  my $migrations_registry  = $conf->{registry};
  my $migrations_username  = $conf->{username};
  my $migrations_password  = $conf->{password};
  my $migrations_directory = $conf->{directory};

  my $initdb_sql  = $conf->{initdb_sql}  // $INITDB_SQL;
  my $resetdb_sql = $conf->{resetdb_sql} // $RESETDB_SQL;

  my $connectdb = $conf->{connectdb} // sub($parsed_dsn, $u, $p) {
    DBI->connect(
      sprintf('DBI:%s:host=%s;port=%s', $parsed_dsn->{driver}, $parsed_dsn->{params}->{host}, $parsed_dsn->{params}->{port},),
      $u, $p,);
  };
  my $initdb  = $conf->{initdb}  // sub($dbh, $name) {$dbh->do(sprintf($initdb_sql,  $name))};
  my $resetdb = $conf->{resetdb} // sub($dbh, $name) {$dbh->do(sprintf($resetdb_sql, $name))};

  $app->helper(
    run_schema_initialization => sub ($self, $args = {}) {
      my $dbh = $connectdb->($dsn, $migrations_username, $migrations_password);

      if ($args->{reset}) {
        try {
          $resetdb->($dbh, $_) foreach ($migrations_registry, $dsn->{params}->{database});
          $app->log->info("Database reset");
        } catch ($e) {
          $app->log->error("Database reset failed: $e");
        }
      }

      try {
        $initdb->($dbh, $_) foreach ($dsn->{params}->{database}, $migrations_registry);
        $app->log->info("Database initialized");
      } catch ($e) {
        $app->log->error("Database creation failed: $e");
      }
    }
  );

  $app->helper(
    run_schema_migration => sub ($self, $subcommand) {
      die("Sqitch subcommand is required") unless ($subcommand);
      my $make_dsn = sub ($obscured = 0)
      {    # sqitch DSNs are a) different than DBI's, and b) complicated. This should cover all cases in sqitch's manual
        my $driver = $dsn->{driver};

        my $port = $dsn->{params}->{port} ? ':' . $dsn->{params}->{port}   : '';
        my $host = $dsn->{params}->{host} ? $dsn->{params}->{host} . $port : '';

        my $username    = $migrations_username ? $migrations_username                               : '';
        my $password    = $migrations_password ? ':' . ($obscured ? '*' x 8 : $migrations_password) : '';
        my $credentials = $username            ? "$username$password@"                              : '';

        my $connection = ($credentials || $host) ? "//$credentials$host/" : '';
        my ($name) = ((grep {defined} @{$dsn->{params}}{qw(database dbname)}), '');

        my $params = '';
        $params .= '?Driver=' . ucfirst($driver)     if (grep {lc($driver) eq $_} (qw(exasol snowflake vertica)));
        $params .= ";warehouse=$migrations_registry" if (grep {lc($driver) eq $_} (qw(snowflake)));

        return sprintf("db:$driver:$connection$name$params");
      };

      my ($cmd, $log_cmd) = map {
        sprintf(q{sqitch -C %s %s --registry %s --target %s},
          $migrations_directory, $subcommand, $migrations_registry, $make_dsn->($_),)
      } (0, 1);

      $app->log->debug($log_cmd);
      my $err = system($cmd);

      if ($err) {
        my $code = ($? & 0x7F) ? ($? & 0x7F) | 0x80 : $? >> 8;
        $app->log->error("Database migration failed: $code");
        return $code;
      }
      $app->log->info("Database migration complete");
      return 0;
    }
  );

}

=pod

=head1 AUTHOR

Mark Tyrrell C<< <mark@tyrrminal.dev> >>

=head1 LICENSE

Copyright (c) 2024 Mark Tyrrell

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut

1;

__END__
