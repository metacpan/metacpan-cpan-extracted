=head1 NAME

Rose::Planter::DB  -- base db class for Rose-Planter planted objects.

=head1 DESCRIPTION

This is derived from Rose::DB, but adds a few class methods as
described below.  Also, it allows database to be registered
based on configuration files.

=head1 METHODS

=cut

package Rose::Planter::DB;
use Log::Log4perl qw /:easy/;

eval { use Module::Build::Database; };
use DateTime::Format::Pg;
use DBIx::Connector;
use List::MoreUtils qw/mesh/;

use base 'Rose::DB';

use strict;
use warnings;

our %Registered; # hash from app names to db class names.

=over

=cut

=item DateTime::Duration::TO_JSON

This is defined here to serialize durations as postgres intervals.

=cut

sub DateTime::Duration::TO_JSON {
    my $d = shift;
    return DateTime::Format::Pg->format_duration($d);
}

=item dbi_connect

Connect and retain the db handle.  Also, set the time zone to UTC.

=cut

{
 my %connections;
 sub dbi_connect {
  my $self = shift;
  my $class = ref $self || $self;
  # This causes a "set time zone" command, so we only get utc times.
  # see http://www.postgresql.org/docs/9.0/static/datatype-datetime.html#DATATYPE-TIMEZONES
  $ENV{PGTZ} = "UTC";
  $connections{$class} ||= DBIx::Connector->new(@_);
  # See http://archives.postgresql.org/pgsql-performance/2011-02/msg00493.php
  $connections{$class}->dbh->{pg_server_prepare} = 0;
  return $connections{$class}->dbh;
}
}

=item release_dbh

Overridden to hold onto dbh's.

=cut

sub release_dbh {
    # probably there's a better way to do this, but I couldn't stop the handles
    # from being released :(
    return 0;
}

=item register_databases

Register all the rose databases for this class.

Arguments :

module_name: The name of the perl module for which we are registering
databases.  This will be used to check for an environment variable
named (uc $module_name)."_LIVE" to see if the live database configuration
should be used.  Also, if a unit test suite is running, the current
Module::Build object will indicate that this module is being tested
and hence a test database should be used.

register_params: A hash of parameters to be sent verbatim to Rose::DB::register_db.

conf: a configuration object which will be queried as follows :

 $conf->db : parameters for the database.

This should return a hash with keys such as "database", "schema", and "host"
which correspond to the parameters sent to Rose::DB::register_db.

If L<Module::Build::Database> is being used, the "test" database will be
determined using information stored in the _build directory.  This allows
the same database to be re-used during an entire './Build test'.

When HARNESS_ACTIVE is true, conf should not be passed.

=cut

sub register_databases {
    my $class           = shift;
    my %args            = @_;
    my $module_name     = $args{module_name} or die "no module name passed";
    my $conf            = $args{conf};
    my $register_params = $args{register_params} || {};
    my $mbd = $ENV{HARNESS_ACTIVE}
         && Module::Build::Database->can('current')
         && -d './_build'
         ? Module::Build::Database->current : undef;
    my $we_are_testing = ( $mbd && $mbd->module_name eq $module_name );
    my $live_env_var = ( uc $module_name ) . '_LIVE';
    my $we_are_live = $ENV{$live_env_var} ? 1 : 0;
    die "no conf argument passed" if !$conf && !$we_are_testing;

    $Registered{$module_name} = (ref $class || $class);
    my %default = (
            type     => "main",
            driver   => "Pg",
            connect_options => {
                PrintError => 1,
                RaiseError => 0,
            },
            %$register_params,
    );

    $class->default_type("main");

    if ($we_are_testing) {
        # If register_params was sent, this may be a configuration for the test.
        # (Once we have a Module::Build::Database::SQlite, this may not be necessary)
        die "ERROR: no test db instance found.  Please run ./Build dbtest --leave-running=1\n\n "
             unless $mbd->notes("dbtest_host") || $register_params;
        my %opts = %{ $mbd->can('database_options') ? $mbd->database_options : {} };
        if ($opts{name}) {
            $opts{database} = delete $opts{name};
        };
        $opts{host} = $mbd->notes("dbtest_host") if $mbd->notes("dbtest_host");
        # sanitize these, since MBD sanitizes when it starts a database
        delete $ENV{PGPORT};
        delete $ENV{PGUSER};
        $class->register_db( %default, %opts, domain => "test" );
        $class->default_domain("test");
        return;
    }

    # Just use "db" for the settings.
    if ($conf->db(default => '')) {
        my $domain = $we_are_live ? "live" : "dev";
        eval {
            $class->register_db( %default, domain => $domain, $conf->db );
        };
        warn "Error registering database : $@" if $@;
        $class->default_domain($domain);
        return;
    }

    warn "'db' may now be used instead of 'databases->dev' in the configuration file.";
    # Old way, for backwards compatibility.
    unless ($conf->databases(is_defined => 1)) {
        warn "No databases defined in configuration file.";
        $conf->databases(default => {});
    }

    warn "No dev database was defined in the configuration file.\n" unless $conf->databases->dev(is_defined => 1);
    $conf->databases->dev(default => {});

    $class->register_db( %default, domain => "dev", $conf->databases->dev ) if $conf->databases->dev(is_defined => 1);
    $class->register_db( %default, domain => "live", $conf->databases->live ) if $conf->databases->live(is_defined => 1);

    $class->default_domain( $we_are_live ? "live" : "dev" );
}

=item registered_by

Given a module name, return the name of the Rose::DB-derived
class which called register_databases.

=cut

sub registered_by {
    my $class = shift;
    my $module_name = shift or die "missing required parameter module_name";
    return $Registered{$module_name};
}

=item load_golden

Load a golden dataset into the database.

=cut

sub load_golden {
    my $class = shift;

    LOGDIE "Will not load golden dataset unless the database domain is test or dev"
        unless $class->domain =~ /^(dev|test)$/;

    INFO "Loading golden dataset, domain : ".$class->domain;
    LOGDIE "not yet implemented";
}

=item has_primary_key [ TABLE | PARAMS ]

Just like the overridden method in Rose::DB.pm except that
it ignores database objects that begin with 'v_'.  This
provides a naming convention to avoid warnings for missing
keys when loading views.

=cut

sub has_primary_key {
    my $self = shift;
    my $table = shift;
    return 1 if $table =~ /^v_/;
    $self->SUPER::has_primary_key($table);
}

=item do_sql

Do some sql and return the result as an arrayref of hashrefs.

=cut

sub do_sql {
    my $class = shift;
    my $sql = shift;
    my @bind = @_;
    my $obj = (ref $class ? $class : $class->new_or_cached);
    my $sth = $obj->dbh->prepare($sql);
    $sth->execute(@bind) or die $sth->errstr;
    my $types = $sth->{'pg_type'};
    my $names = $sth->{'NAME'};
    my $res = $sth->fetchall_arrayref({});
    return $res unless ref $names && ref $types;

    # Force all bigints into numeric context for JSON.  (see JSON::XS)
    my %name2type = mesh @$names, @$types;
    return $res unless grep /int8/, @$types;
    my @nums;
    for (@$names) {
        push @nums, $_ if $name2type{$_} eq 'int8';
    }
    for my $row (@$res) {
        for my $col (@nums) {
            next unless defined($row->{$col});
            $row->{$col} += 0;
        }
    }
    return $res;
}

=back

=cut

1;


