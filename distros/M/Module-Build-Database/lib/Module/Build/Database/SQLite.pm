
=head1 NAME

Module::Build::Database::SQLite - SQLite implementation for MBD

=head1 SYNOPSIS

 my $builder = Module::Build::Database->new(
    database_type => "SQLite",
    database_options => {
        name   => "my_database_name",
    });

=head1 DESCRIPTION

SQLite driver for Module::Build::Database.

=head1 METHODS

=over

=cut

package Module::Build::Database::SQLite;
use base 'Module::Build::Database';
use Module::Build::Database::Helpers qw/do_system verify_bin debug info/;

use Path::Class qw( tempdir );
use File::Copy qw( copy );
use File::Temp;
use File::Basename qw/dirname/;
use Cwd qw/abs_path/;

use strict;
use warnings;
our $VERSION = '0.58';

__PACKAGE__->add_property(database_options => default => { name => "unknown" });
__PACKAGE__->add_property(_tmp_db_dir         => default => "" );

our $dbFile;
our %Bin = (
    Sqlite => 'sqlite3'
);
verify_bin(\%Bin);

=item have_db_cli

Is there a command line interface for sqlite available
in the current PATH?

=cut

sub have_db_cli {
    return $Bin{Sqlite} && $Bin{Sqlite} !~ qr[/bin/false] ? 1 : 0;
}

sub _show_live_db {
    my $self = shift;
    my $name = shift || $self->database_options('name');
    info "database : ". (eval { abs_path($name) } || $name);
}

sub _is_fresh_install {
    my $self = shift;
    my $database_name = $self->database_options('name');

    return -e $database_name && -s _ ? 0 : 1;
}

sub _create_database {
    my $self = shift;
    $dbFile = $self->database_options('name') or die "no database name";
    # nothing to do
    return 1;
}

sub _create_patch_table {
    my $self = shift;
    $dbFile ||= $self->database_options('name');
    debug "creating patch table";
    $self->_do_sqlite(<<EOT);
    CREATE TABLE patches_applied (
        patch_name   varchar(255) primary key,
        patch_md5    varchar(255),
        when_applied timestamp );
EOT
}

sub _insert_patch_record {
    my $self = shift;
    my $record = shift;
    my ($name,$md5) = @$record;
    debug "adding patch record $name, $md5";
    $self->_do_sqlite("insert into patches_applied (patch_name, patch_md5, when_applied) ".
             " values ('$name','$md5',current_timestamp); ");
}

sub _patch_table_exists {
    my $self = shift;
    $dbFile ||= $self->database_options('name');
    my $is_it = do_system("_silent", "echo",q[.table patches_applied],"|",$Bin{Sqlite},$dbFile,"|","grep -q patches_applied");
    return $is_it ? 1 : 0;
}

sub _dump_patch_table {
    my $self = shift;
    my %args = @_;
    my $filename = $args{outfile} or Carp::confess "need a filename";
    debug "dumping patches into $filename";
    $self->_do_sqlite_into_file($filename,"select patch_name,patch_md5 from patches_applied order by patch_name;");
}

sub _remove_patches_applied_table {
    my $self = shift;
    $self->_do_sqlite("drop table if exists patches_applied;");
}

sub _start_new_db {
    # Make a new empty database file, return the name of the file.
    my $self = shift;
    $dbFile = File::Temp->new(UNLINK => 0);
    $dbFile->close;
    return "$dbFile";
}

sub _do_sql_file {
    my $self = shift;
    my $filename = shift;
    my $outfile = shift;  # optional output file
    Carp::confess "dbFile is not defined" unless defined($dbFile);
    do_system( $Bin{Sqlite}, $dbFile, "<", $filename,
        ( $outfile ? ( ">", $outfile ) : () ) );
}

sub _do_sqlite {
    my $self = shift;
    my $sql = shift;
    my $tmp = File::Temp->new(TEMPLATE => "tmp_db_XXXX", SUFFIX => '.sql');
    print $tmp ".header off\n";
    print $tmp ".mode list\n";
    print $tmp ".separator ' '\n";
    print $tmp $sql;
    $tmp->close;
    my $ret = $self->_do_sql_file("$tmp", @_);  # pass @_ which may have an $outfile
    $tmp->unlink_on_destroy($ret);
    $ret;
}

sub _do_sqlite_into_file {
    my $self = shift;
    my $filename = shift;
    my $sql      = shift;
    debug "doing $sql";
    $self->_do_sqlite($sql,$filename);
}

sub _do_sqlite_getlines {
    my $self = shift;
    my $sql      = shift;
    my $filename = tempdir(CLEANUP=>1)->file("tmp.sql");
    debug "doing $sql";
    $self->_do_sqlite($sql,$filename);
    my @result = $filename->slurp;
    return @result;
}

sub _apply_base_sql {
    my $self = shift;
    my $filename = shift || $self->base_dir."/db/dist/base.sql";
    return unless -e $filename;
    info "applying base.sql";
    $self->_do_sql_file($filename);
}

sub _apply_base_data {
    my $self = shift;
    my $filename = shift || $self->base_dir."/db/dist/base_data.sql";
    return unless -e $filename;
    info "applying base_data.sql";
    $self->_do_sql_file($filename);
}

sub _apply_patch {
    my $self = shift;
    my $patch_file = shift;

    return $self->_do_sql_file($self->base_dir."/db/patches/$patch_file");
}

sub _dump_base_sql {
    my $self = shift;

    $dbFile ||= $self->database_options('name');

    # Optional parameter "outfile" gives the name of the file into which to dump the schema.
    # If the parameter is omitted, dump and atomically rename to db/dist/base.sql.
    my %args = @_;
    my $outfile = $args{outfile} || $self->base_dir. "/db/dist/base.sql";

    my $tmpfile = File::Temp->new(
        TEMPLATE => (dirname $outfile)."/dump_XXXXXX",
        UNLINK   => 0
    );
    $tmpfile->close;

    debug "dumping base sql";
    $self->_do_sqlite(qq[.output $tmpfile\n.schema\n.exit\n]);
    rename "$tmpfile", $outfile or die "rename failed: $!";
}

sub _dump_base_data {
    my $self = shift;
    my %args = @_;
    my $outfile = $args{outfile} || $self->base_dir. "/db/dist/base_data.sql";

    $dbFile ||= $self->database_options('name');

    my $tmpfile = File::Temp->new(
        TEMPLATE => (dirname $outfile)."/dump_XXXXXX",
        UNLINK   => 1,
    );
    debug "dumping base_data.sql";

    my ($tables) = $self->_do_sqlite_getlines(qq[.tables]);
    for my $table (split /\s+/, $tables) {
        my $more = tempdir(CLEANUP => 1)->file("more.sql");
        my $more_safe_fn = $more;
        $more_safe_fn =~ s{\\}{/}g;
        $self->_do_sqlite(qq[.output $more_safe_fn\n.mode insert $table\nselect * from $table;\n.exit\n]);
        $tmpfile->print($_) for $more->slurp;
    }
    copy $tmpfile, $outfile or die "copy failed: $!";
}

sub _stop_db {
   # there's no daemon, yay
}

sub _remove_db {
    return unless defined($dbFile) && -e "$dbFile";
    unlink "$dbFile" or die "Could not unlink $dbFile :$!";
}

=back

=head1 SEE ALSO

See L<Module::Build::Database>.

=cut

1;


