=head1 NAME

Module::Build::Database::PostgreSQL - PostgreSQL implementation for MBD

=head1 SYNOPSIS

In Build.PL :

 my $builder = Module::Build::Database->new(
     database_type => "PostgreSQL",
     database_options => {
         name   => "my_database_name",
         schema => "my_schema_name",
         # Extra items for scratch databases :
         append_to_conf => "text to add to postgresql.conf",
         after_create => q[create schema audit;],
     },
     database_extensions => {
         postgis     => { schema => "public", },
         # directory with postgis.sql and spatial_ref_sys.sql
         postgis_base => '/usr/local/share/postgresql/contrib'
     },
 );

=head1 DESCRIPTION

Postgres driver for L<Module::Build::Database>.

=head1 OPTIONS

All of the options above may be changed via the Module::Build option
handling, e.g.

  perl Build.PL --database_options name=my_name
  perl Build.PL --postgis_base=/usr/local/share/postgresql/contrib

The options are as follows ;

=over 4

=item database_options

=over 4

=item name

the name of the database (i.e. 'create database $name')

=item schema

the name of the schema to be managed by MBD

=item append_to_conf

extra options to append to C<postgresql.conf> before starting test instances of postgres

=item after_create

extra SQL to run after running a 'create database' statement.  Note that this will be run in several
different situations :

=over 4

=item 1.

during a L<dbtest|Module::Build::Database#dbtest> (creating a test db)

=item 2.

during a L<dbfakeinstall|Module::Build::Database#dbfakeinstall> (also creating a test db)

=item 3.

during an initial L<dbinstall|Module::Build::Database#dbinstall>; when the target database does not yet exist.

=back

An example of using the after_create statement would be to create a second schema which
will not be managed by MBD, but on which the MBD-managed schema depends.

=back

=item database_extension 

To specify a server side procedural language you can use the C<database_extension> -E<gt> C<languages>
option, like so:

 my $builder = Module::Build::Database->new(
   database_extension => {
     languages => [ 'plperl', 'pltcl' ],
   },
 );

Trying to create languages to a patch will not work because they not stored in the main schema and will
not be included in C<base.sql> when you run C<Build dbdist>.

This is also similar to

 after_create => 'create extension ...',

except it is executed on B<every> L<dbinstall|Module::Build::Database#dbinstall> meaning you can use this to add extensions to
existing database deployments.

=item postgis_base

Specify the directory containing postgis.sql and spatial_ref_sys.sql.  If specified these SQL files will be loaded so that
you can use PostGIS in your database.

=item leave_running

If set to true, and if you are not using a persistent scratch database (see next option), then the scratch database will
not be stopped and torn down after running C<Build dbtest> or C<Build dbfakeinstall>.

=item scratch_database

You can use this option to specify the connection settings for a persistent scratch or temporary database instance, used by
the C<Build dbtest> and C<Build dbfakeinstall> to test schema.  B<IMPORTANT>: the C<Build dbtest> and C<Build dbfakeinstall>
will drop and re-create databases on the scratch instance with the same name as the database on your production instance so
it is I<very> important that if you use a persistent scratch database that it be dedicated to that task.

 my $builder = Module::Build::Database->new(
   scratch_database => {
     PGHOST => 'databasehost',
     PGPORT => '5555',
     PGUSER => 'dbuser',
   },
 );

If you specify any one of these keys for this option (C<PGHOST>, C<PGPORT>, C<PGUSER>) then MBD will use a persistent
scratch database.  Any missing values will use the default.

You can also specify these settings using environment variables:

 % export MBD_SCRATCH_PGHOST=databasehost
 % export MBD_SCRATCH_PGPORT=5555
 % export MBD_SCRATCH_PGUSER=dbuser

By default this module will create its own scratch PostgreSQL instance that uses unix domain sockets for communication 
each time it needs one when you use the C<Build dbtest> or C<Build dbfakeinstall> commands.  Situations where you might
need to use a persistent scratch database:

=over 4

=item 1.

The server and server binaries are hosted on a system different to the one that you are doing development

=item 2.

You are using MBD on Windows where unix domain sockets are not available

=back

=back

=head1 NOTES

The environment variables understood by C<psql>:
C<PGUSER>, C<PGHOST> and C<PGPORT> will be used when
connecting to a live database (for L<dbinstall|Module::Build::Database#dbinstall> and
L<fakeinstall||Module::Build::Database#dbfakeinstall>).  C<PGDATABASE> will be ignored;
the name of the database should be specified in 
Build.PL instead.

=cut

package Module::Build::Database::PostgreSQL;
use base 'Module::Build::Database';
use File::Temp qw/tempdir/;
use File::Path qw/rmtree/;
use File::Basename qw/dirname/;
use File::Copy::Recursive qw/fcopy dirmove/;
use Path::Class qw/file/;
use IO::File;
use File::Which qw( which );

use Module::Build::Database::PostgreSQL::Templates;
use Module::Build::Database::Helpers qw/do_system verify_bin info debug/;
use strict;
use warnings;
our $VERSION = '0.57';

__PACKAGE__->add_property(database_options    => default => { name => "foo", schema => "bar" });
__PACKAGE__->add_property(database_extensions => default => { postgis => 0 } );
__PACKAGE__->add_property(postgis_base        => default => "/usr/local/share/postgis" );
__PACKAGE__->add_property(_tmp_db_dir         => default => "" );
__PACKAGE__->add_property(leave_running       => default => 0 ); # leave running after dbtest?
__PACKAGE__->add_property(scratch_database    => default => { map {; "PG$_" => $ENV{"MBD_SCRATCH_PG$_"} } 
                                                              grep { defined $ENV{"MBD_SCRATCH_PG$_"} } 
                                                              qw( HOST PORT USER ) } );

# Binaries used by this module.  They should be in $ENV{PATH}.
our %Bin = (
    Psql       => 'psql',
    Pgctl      => 'pg_ctl',
    Postgres   => 'postgres',
    Initdb     => 'initdb',
    Createdb   => 'createdb',
    Dropdb     => 'dropdb',
    Pgdump     => 'pg_dump',
    Pgdoc      => [ qw/pg_autodoc postgresql_autodoc/ ],
);
my $server_bin_dir;
if(my $pg_config = which 'pg_config')
{
  $pg_config = Win32::GetShortPathName($pg_config) if $^O eq 'MSWin32' && $pg_config =~ /\s/;
  $server_bin_dir = `$pg_config --bindir`;
  chomp $server_bin_dir;
  $server_bin_dir = Win32::GetShortPathName($server_bin_dir) if $^O eq 'MSWin32' && $server_bin_dir =~ /\s/;
  undef $server_bin_dir unless -d $server_bin_dir;
}
verify_bin(\%Bin, $server_bin_dir);

sub _do_psql {
    my $self = shift;
    my $sql = shift;
    my $database_name  = $self->database_options('name');
    my $tmp = File::Temp->new(TEMPLATE => "tmp_db_XXXX", SUFFIX => '.sql');
    print $tmp $sql;
    $tmp->close;
    # -q: quiet, ON_ERROR_STOP: throw exceptions
    local $ENV{PERL5LIB};
    my $ret = do_system( $Bin{Psql}, "-q", "-vON_ERROR_STOP=1", "-f", "$tmp", $database_name );
    $tmp->unlink_on_destroy($ret);
    $ret;
}
sub _do_psql_out {
    my $self = shift;
    my $sql = shift;
    my $database_name  = $self->database_options('name');
    # -F field separator, -x extended output, -A: unaligned
    local $ENV{PERL5LIB};
    do_system( $Bin{Psql}, "-q", "-vON_ERROR_STOP=1", "-A", "-F ' : '", "-x", "-c", qq["$sql"], $database_name );
}
sub _do_psql_file {
    my $self = shift;
    my $filename = shift;
    unless (-e $filename) {
        warn "could not open file $filename";
        return 0;
    }
    unless (-s $filename) {
        warn "file $filename is empty";
        return 0;
    }
    my $database_name  = $self->database_options('name');
    # -q: quiet, ON_ERROR_STOP: throw exceptions
    local $ENV{PERL5LIB};
    do_system($Bin{Psql},"-q","-vON_ERROR_STOP=1","-f",$filename, $database_name);
}
sub _do_psql_into_file {
    my $self = shift;
    my $filename = shift;
    my $sql      = shift;
    my $database_name  = $self->database_options('name');
    # -A: unaligned, -F: field separator, -t: tuples only, ON_ERROR_STOP: throw exceptions
    local $ENV{PERL5LIB};
    my $q = $^O eq 'MSWin32' ? '"' : "'";
    do_system( $Bin{Psql}, "-q", "-vON_ERROR_STOP=1", "-A", "-F $q\t$q", "-t", "-c", qq["$sql"], $database_name, ">", "$filename" );
}
sub _do_psql_capture {
    my $self = shift;
    my $sql = shift;
    my $database_name  = $self->database_options('name');
    local $ENV{PERL5LIB};
    return qx[$Bin{Psql} -c "$sql" $database_name];
}

sub _cleanup_old_dbs {
    my $self = shift;
    my %args = @_; # pass all => 1 to clean up the current one too

    my $glob;
    {
        my $tmpdir = tempdir("mbdtest_XXXXXX", TMPDIR => 1);
        $glob = "$tmpdir";
        rmtree($tmpdir);
    }
    $glob =~ s/mbdtest_.*$/mbdtest_*/;
    for my $thisdir (glob $glob) {
        next unless -d $thisdir && -w $thisdir;
        debug "cleaning up old tmp instance : $thisdir";
        $self->_stop_db("$thisdir/db");
        rmtree($thisdir);
    }
}

sub _start_new_db {
    my $self = shift;
    # Start a new database and return the host on which it was started.

    my $database_name   = $self->database_options('name');
    $ENV{PGDATABASE} = $database_name;

    if(%{ $self->scratch_database }) {
        delete @ENV{qw( PGHOST PGUSER PGPORT )};
        %ENV = (%ENV, %{ $self->scratch_database });
        do_system("_silent", $Bin{Dropdb}, $database_name);

    } else {

        $self->_cleanup_old_dbs();

        my $tmpdir          = tempdir("mbdtest_XXXXXX", TMPDIR => 1);
        my $dbdir           = $tmpdir."/db";
        my $initlog         = "$tmpdir/postgres.log";
        $self->_tmp_db_dir($dbdir);

        $ENV{PGHOST}     = "$dbdir"; # makes psql use a socket, not a tcp port
        delete $ENV{PGUSER};
        delete $ENV{PGPORT};

        debug "initializing database (log: $initlog)";

        do_system($Bin{Initdb}, "-D", "$dbdir", ">>", "$initlog", "2>&1") or do {
            my $log = '';
            $log = file($initlog)->slurp if -e $initlog;
            die "could not initdb ($Bin{Initdb})\n$log\n";
        };

        if (my $conf_append = $self->database_options('append_to_conf')) {
            die "cannot find postgresql.conf" unless -e "$dbdir/postgresql.conf";
            open my $fp, ">> $dbdir/postgresql.conf" or die "could not open postgresql.conf : $!";
            print $fp $conf_append;
            close $fp;
        }

        my $pmopts = qq[-k $dbdir -h '' -p 5432];

        debug "# starting postgres in $dbdir";
        do_system($Bin{Pgctl}, qq[-o "$pmopts"], "-w", "-t", 120, "-D", "$dbdir", "-l", "postmaster.log", "start") or do {
            my $log;
            if (-e "$dbdir/postmaster.log") {
                $log = file("$dbdir/postmaster.log")->slurp;
            } else {
                $log = "no log file : $dbdir/postmaster.log";
            }
            die "could not start postgres\n$log\n ";
        };

        my $domain = $dbdir.'/.s.PGSQL.5432';
        -e $domain or die "could not find $domain";
    }

    $self->_create_database();

    return $self->_dbhost;
}

sub _remove_db {
    my $self = shift;
    return if $ENV{MBD_DONT_STOP_TEST_DB} || %{ $self->scratch_database };
    my $dbdir = shift || $self->_tmp_db_dir();
    $dbdir =~ s/\/db$//;
    rmtree $dbdir;
}

sub _stop_db {
    my $self = shift;
    return if $ENV{MBD_DONT_STOP_TEST_DB} || %{ $self->scratch_database };
    my $dbdir = shift || $self->_tmp_db_dir();
    my $pid_file = "$dbdir/postmaster.pid";
    unless (-e $pid_file) {
        debug "no pid file ($pid_file), not stopping db";
        return;
    }
    my ($pid) = IO::File->new("<$pid_file")->getlines;
    chomp $pid;
    kill "TERM", $pid;
    sleep 1;
    return unless kill 0, $pid;
    kill 9, $pid or info "could not send signal to $pid";
}

sub _apply_base_sql {
    my $self = shift;
    my $filename = shift || $self->base_dir."/db/dist/base.sql";
    return unless -e $filename;
    info "applying base.sql";
    $self->_do_psql_file($filename);
}

sub _apply_base_data {
    my $self = shift;
    my $filename = shift || $self->base_dir."/db/dist/base_data.sql";
    return 1 unless -e $filename;
    info "applying base_data.sql";
    $self->_do_psql_file($filename);
}

sub _dump_base_sql {
    # Optional parameter "outfile" gives the name of the file into which to dump the schema.
    # If the parameter is omitted, dump and atomically rename to db/dist/base.sql.
    my $self = shift;
    my %args = @_;
    my $outfile = $args{outfile} || $self->base_dir. "/db/dist/base.sql";

    my $tmpfile = file( tempdir( CLEANUP => 1 ), 'dump.sql');

    # -x : no privileges, -O : no owner, -s : schema only, -n : only this schema
    my $database_schema = $self->database_options('schema');
    my $database_name   = $self->database_options('name');
    local $ENV{PERL5LIB};
    do_system( $Bin{Pgdump}, "-xOs", "-E", "utf8", "-n", $database_schema, $database_name, ">", $tmpfile )
    or do {
      info "Error running pgdump";
      die "Error running pgdump : $! ${^CHILD_ERROR_NATIVE}";
      return 0;
    };

    my @lines = $tmpfile->slurp();
    unless (@lines) {
        die "# Could not run pgdump and write to $tmpfile";
    }
    @lines = grep {
        $_ !~ /^--/
        and $_ !~ /^CREATE SCHEMA $database_schema;$/
        and $_ !~ /^SET (search_path|lock_timeout)/
    } @lines;
    for (@lines) {
        /alter table/i and s/$database_schema\.//;
    }
    file($outfile)->spew(join '', @lines);
    if (@lines > 0 && !-s $outfile) {
        die "# Unable to write to $outfile";
    }
    return 1;
}

sub _dump_base_data {
    # Optional parameter "outfile, defaults to db/dist/base_data.sql
    my $self = shift;
    my %args = @_;
    my $outfile = $args{outfile} || $self->base_dir. "/db/dist/base_data.sql";

    my $tmpfile = File::Temp->new(
        TEMPLATE => (dirname $outfile)."/dump_XXXXXX",
        UNLINK   => 0
    );
    $tmpfile->close;

    # -x : no privileges, -O : no owner, -s : schema only, -n : only this schema
    my $database_schema = $self->database_options('schema');
    my $database_name   = $self->database_options('name');
    local $ENV{PERL5LIB};
    do_system( $Bin{Pgdump}, "--data-only", "-xO", "-E", "utf8", "-n", $database_schema, $database_name,
        "|", "egrep -v '^SET (lock_timeout|search_path)'",
        ">", "$tmpfile" )
      or return 0;
    rename "$tmpfile", $outfile or die "rename failed: $!";
}

sub _apply_patch {
    my $self = shift;
    my $patch_file = shift;

    return $self->_do_psql_file($self->base_dir."/db/patches/$patch_file");
}

sub _is_fresh_install {
    my $self = shift;

    my $database_name = $self->database_options('name');
    unless ($self->_database_exists) {
        info "database $database_name does not exist";
        return 1;
    }

    my $file = File::Temp->new(); $file->close;
    my $database_schema = $self->database_options('schema');
    $self->_do_psql_into_file("$file","\\dn $database_schema");
    return !do_system("_silent","grep -q $database_schema $file");
}

sub _show_live_db {
    # Display the connection information
    my $self = shift;

    info "PGUSER : " . ( $ENV{PGUSER}     || "<undef>" );
    info "PGHOST : " . ( $ENV{PGHOST}     || "<undef>" );
    info "PGPORT : " . ( $ENV{PGPORT}     || "<undef>" );

    my $database_name = shift || $self->database_options('name');
    info "database : $database_name";

    return unless $self->_database_exists;
    $self->_do_psql_out("select current_database(),session_user,version();");
}

sub _patch_table_exists {
    # returns true or false
    my $self = shift;
    my $file = File::Temp->new(); $file->close;
    my $database_schema = $self->database_options('schema');
    $self->_do_psql_into_file("$file","select tablename from pg_tables where tablename='patches_applied' and schemaname = '$database_schema'");
    return do_system("_silent","grep -q patches_applied $file");
}

sub _dump_patch_table {
    # Dump the patch table in an existing db into a flat file, that
    # will be in the same format as patches_applied.txt.
    my $self = shift;
    my %args = @_;
    my $filename = $args{outfile} or Carp::confess "need a filename";
    my $database_schema = $self->database_options('schema');
    $self->_do_psql_into_file($filename,"select patch_name,patch_md5 from $database_schema.patches_applied order by patch_name");
}

sub _create_patch_table {
    my $self = shift;
    # create a new patch table
    my $database_schema = $self->database_options('schema');
    my $sql = <<EOSQL;
    CREATE TABLE $database_schema.patches_applied (
        patch_name   varchar(255) primary key,
        patch_md5    varchar(255),
        when_applied timestamp );
EOSQL
    $self->_do_psql($sql);
}

sub _insert_patch_record {
    my $self = shift;
    my $record = shift;
    my ($name,$md5) = @$record;
    my $database_schema = $self->database_options('schema');
    $self->_do_psql("insert into $database_schema.patches_applied (patch_name, patch_md5, when_applied) ".
             " values ('$name','$md5',now()) ");
}

sub _database_exists {
    my $self  =  shift;
    my $database_name = shift || $self->database_options('name');
    local $ENV{PERL5LIB};
    scalar grep /^$database_name$/, map { [split /:/]->[0] } `psql -Alt -F:`;
}

sub _create_language_extensions {
    my $self = shift;
    my $list = $self->database_extensions('languages');
    return unless $list;
    foreach my $lang (@$list) {
        $self->_do_psql("create extension if not exists $lang") || die "error creating language: $lang"; 
    }
}

sub _create_database {
    my $self = shift;

    my $database_name   = $self->database_options('name');
    my $database_schema = $self->database_options('schema');

    # create the database if necessary
    unless ($self->_database_exists($database_name)) {
        local $ENV{PERL5LIB};
        do_system($Bin{Createdb}, $database_name) or die "could not createdb";
    }

    # Create a fresh schema in the database.
    $self->_do_psql("create schema $database_schema") unless $database_schema eq 'public';

    $self->_do_psql("alter database $database_name set client_min_messages to ERROR");

    $self->_do_psql("alter database $database_name set search_path to $database_schema;");

    # stolen from http://wiki.postgresql.org/wiki/CREATE_OR_REPLACE_LANGUAGE
    $self->_do_psql(<<'SAFE_MAKE_PLPGSQL');
CREATE OR REPLACE FUNCTION make_plpgsql()
RETURNS VOID
LANGUAGE SQL
AS $$
CREATE LANGUAGE plpgsql;
$$;

SELECT
    CASE
    WHEN EXISTS(
        SELECT 1
        FROM pg_catalog.pg_language
        WHERE lanname='plpgsql'
    )
    THEN NULL
    ELSE make_plpgsql() END;

DROP FUNCTION make_plpgsql();
SAFE_MAKE_PLPGSQL

    if (my $postgis = $self->database_extensions('postgis')) {
        info "applying postgis extension";
        my $postgis_schema = $postgis->{schema} or die "No schema given for postgis";
        $self->_do_psql("create schema $postgis_schema") unless $postgis_schema eq 'public';
        $self->_do_psql("alter database $database_name set search_path to $postgis_schema;");
        # We need to run "createlang plpgsql" first.
        $self->_do_psql_file($self->postgis_base. "/postgis.sql") or die "could not do postgis.sql";
        $self->_do_psql_file($self->postgis_base. "/spatial_ref_sys.sql") or die "could not do spatial_ref_sys.sql";
        $self->_do_psql("alter database $database_name set search_path to $database_schema, $postgis_schema");
    }

    if (my $sql = $self->database_options('post_initdb')) {
        info "applying post_initdb (nb: this option has been renamed to 'after_create')";
        $self->_do_psql($sql);
    }

    if (my $sql = $self->database_options('after_create')) {
        info "applying after_create";
        $self->_do_psql($sql);
    }

    1;
}

sub _remove_patches_applied_table {
    my $self = shift;
    my $database_schema = $self->database_options('schema');
    $self->_do_psql("drop table if exists $database_schema.patches_applied;");
}

sub _generate_docs {
    my $self            = shift;
    my %args            = @_;
    my $dir             = $args{dir} or die "missing dir";
    my $tmpdir          = tempdir;
    my $tc              = "Module::Build::Database::PostgreSQL::Templates";
    my $database_name   = $self->database_options('name');
    my $database_schema = $self->database_options('schema');

    $self->_start_new_db();
    $self->_apply_base_sql();

    chdir $tmpdir;
    for my $filename ($tc->filenames) {
        open my $fp, ">$filename" or die $!;
        print ${fp} $tc->file_contents($filename);
        close $fp;
    }

    # http://perlmonks.org/?node_id=821413
    do_system( $Bin{Pgdoc}, "-d", $database_name, "-s", $database_schema, "-l .", "-t pod" );
    do_system( $Bin{Pgdoc}, "-d", $database_name, "-s", $database_schema, "-l .", "-t html" );
    do_system( $Bin{Pgdoc}, "-d", $database_name, "-s", $database_schema, "-l .", "-t dot" );

    for my $type (qw(pod html)) {
        my $fp = IO::File->new("<$database_name.$type") or die $!;
        mkdir $type or die $!;
        my $outfp;
        while (<$fp>) {
            s/^_CUT: (.*)$// and do { $outfp = IO::File->new(">$type/$1") or die $!; };
            s/^_DB: (.*)$//  and do { $_ = $self->_do_psql_capture($1);   s/^/ /gm;  };
            print ${outfp} $_ if defined($outfp);
        }
    }
    dirmove "$tmpdir/pod", "$dir/pod";
    info "Generated $dir/pod";
    dirmove "$tmpdir/html", "$dir/html";
    info "Generated $dir/html";
    fcopy "$tmpdir/$database_name.dot", "$dir";
    info "Generated $dir/$database_name.dot";
}

sub ACTION_dbtest        { shift->SUPER::ACTION_dbtest(@_);        }
sub ACTION_dbclean       { shift->SUPER::ACTION_dbclean(@_);       }
sub ACTION_dbdist        { shift->SUPER::ACTION_dbdist(@_);        }
sub ACTION_dbdocs        { shift->SUPER::ACTION_dbdocs(@_);        }
sub ACTION_dbinstall     { shift->SUPER::ACTION_dbinstall(@_);     }
sub ACTION_dbfakeinstall { shift->SUPER::ACTION_dbfakeinstall(@_); }

sub _dbhost {
    return $ENV{PGHOST} || 'localhost';
}

1;

