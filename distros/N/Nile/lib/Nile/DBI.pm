#   Copyright Infomation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author : Dr. Ahmed Amin Elsheshtawy, Ph.D.
# Website: https://github.com/mewsoft/Nile, http://www.mewsoft.com
# Email  : mewsoft@cpan.org, support@mewsoft.com
# Copyrights (c) 2014-2015 Mewsoft Corp. All rights reserved.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Nile::DBI;

our $VERSION = '0.55';
our $AUTHORITY = 'cpan:MEWSOFT';

=pod

=encoding utf8

=head1 NAME

Nile::DBI - SQL database manager.

=head1 SYNOPSIS
    
    # set database connection params to connect
    # $arg{driver}, $arg{host}, $arg{dsn}, $arg{port}, $arg{attr}
    # $arg{name}, $arg{user}, $arg{pass}
    # if called without params, it will try to load from the default config vars.

    # get app context
    $app = $self->app;

    $dbh = $app->db->connect(%arg);
    
=head1 DESCRIPTION

Nile::DBI - SQL database manager.

=cut

use Nile::Base;
use DBI;
use DBI::Profile;
use DBI::ProfileDumper;
use Hash::AsObject;
#my $hash = Hash::AsObject->new(\%hash); $hash->foo(27); print $hash->foo; print $hash->baz->quux;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 dbh()
    
    $app->db->dbh;

Get or set the current database connection handle.

=cut

has 'dbh' => (
      is      => 'rw',
  );
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 connect()
    
    $dbh = $app->db->connect(%arg);

Connect to the database. If %arg empty, it will try to get arg from the config object.
Returns the database connection handle is success.

=cut

sub connect {

    my ($self, %arg) = @_;
    my ($dbh, $dsn, $app);
    
    $app = $self->app;
    
    my $default = $app->config->get("dbi");
    $default ||= +{};

    %arg = (%{$default}, %arg);
    
    $arg{driver} ||= "mysql";
    $arg{dsn} ||= "";
    $arg{host} ||= "localhost";
    $arg{port} ||= 3306;
    $arg{attr} ||= +{};
    #$arg{attr} = {RaiseError => 0, PrintError => 0, mysql_enable_utf8 => 1}

    if (!$arg{name}) {
        $app->abort("Database error: Empty database name.");
    }

    #$self->dbh->disconnect if ($self->dbh);

    if ($arg{driver} =~ m/ODBC/i) {
        $dbh = DBI->connect("DBI:ODBC:$arg{dsn}", $arg{user}, $arg{pass}, $arg{attr})
                or $self->db_error("$DBI::errstr, DSN: $arg{dsn}");
    }
    else {
        $arg{dsn} ||= "DBI:$arg{driver}:database=$arg{name};host=$arg{host};port=$arg{port}";
        $dbh = DBI->connect($arg{dsn}, $arg{user}, $arg{pass}, $arg{attr}) 
                or $self->db_error("$DBI::errstr, DSN: $arg{dsn}");
    }

    $self->dbh($dbh);
    return $dbh;

    #$dbh->{'mysql_enable_utf8'} = 1;
    #$dbh->do('SET NAMES utf8');
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 disconnect()
    
    $app->db->disconnect;

Disconnect from this connection handle.

=cut

sub disconnect {
    my ($self) = @_;
    $self->dbh->disconnect if ($self->dbh);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub table {
    my ($self, $name) = @_;
    $self->app->load_once("Nile::DBI::Table");
    $self->app->object("Nile::DBI::Table", (name => $name));
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 run()
    
    $app->db->run($qry);

Run query using the DBI do command or abort if error.

=cut

sub run {
    my ($self, $qry) = @_;
    $self->dbh->do($qry) or $self->db_error($qry);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 do()
    
    $app->db->do($qry);

Run query using the DBI do command and ignore errors.

=cut

sub do {
    my ($self, $qry) = @_;
    $self->dbh->do($qry);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 exec()
    
    $sth = $app->db->exec($qry);

Prepare and execute the query and return the statment handle.

=cut

sub exec {
    my ($self, $qry) = @_;
    my $sth = $self->dbh->prepare($qry) or $self->db_error($qry);
    $sth->execute() or $self->db_error($qry);
    return $sth;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 begin()
    
    $app->db->begin;

Enable transactions (by turning AutoCommit off) until the next call to commit or rollback. After the next commit or rollback, AutoCommit will automatically be turned on again.

=cut

sub begin {
    my ($self) = @_;
    return $self->dbh->begin_work or $self->db_error();
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 commit()
    
    $app->db->commit;

Commit (make permanent) the most recent series of database changes if the database supports transactions and AutoCommit is off.

=cut

sub commit {
    my ($self) = @_;
    $self->dbh->commit or $self->db_error();
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 rollback()
    
    $app->db->rollback;

Rollback (undo) the most recent series of uncommitted database changes if the database supports transactions and AutoCommit is off.

=cut

sub rollback {
    my ($self) = @_;
    $self->dbh->rollback or $self->db_error();
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 quote()
    
    $app->db->quote($value);
    $app->db->quote($value, $data_type);

Quote a string literal for use as a literal value in an SQL statement, by escaping any special characters (such as quotation marks)
contained within the string and adding the required type of outer quotation marks.
=cut

sub quote {
    my ($self, @arg) = @_;
    return $self->dbh->quote(@arg);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 col()
    
    # select id from users. return one column array from all rows
    @cols = $app->db->col($qry);
    $cols_ref = $app->db->col($qry);

Return one column array from all rows

=cut

sub col {
    my ($self, $qry) = @_;
    #   select id from users. return one column array from all rows
    my $ret = $self->dbh->selectcol_arrayref($qry);
    if (!defined($ret) && $self->dbh->err()) {$self->db_error($qry);}
    return wantarray? @{$ret} : $ret;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 row()
    
    # select id, email, fname, lname from users
    @row = $app->db->row($qry);

Returns one row as array.

=cut

sub row {
    my ($self, $qry) = @_;
    # select id, email, fname, lname from users
    my @ret = $self->dbh->selectrow_array($qry);
    if (!@ret && $self->dbh->err()) {$self->db_error($qry);}
    return @ret;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 rows()
    
    # select id, fname, lname, email from users
    @rows = $app->db->rows($qry);
    $rows_ref = $app->db->rows($qry);

Returns all matched rows as array or array ref.

=cut

sub rows {
    my ($self, $qry) = @_;
    # select id, fname, lname, email from users
    my $ret = $self->dbh->selectall_arrayref($qry);
    if (!defined($ret) && $self->dbh->err()) {$self->db_error($qry);}
    return wantarray? @$ret : $ret;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 hash()
    
    # select * from users where id=$id limit 1
    %user = $app->db->hash($qry);
    $user_ref = $app->db->hash($qry);

Returns one row as a hash or hash ref

=cut

sub hash {
    my ($self, $qry) = @_;
    # select * from users where id=$id limit 1
    my $ret = $self->dbh->selectrow_hashref($qry);
    if (!defined($ret) && $self->dbh->err()) {$self->db_error($qry);}
    return wantarray? %{$ret} : $ret;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 row_object()
    
    # select * from users where id=$id limit 1
    $row_obj = $app->db->row_object($qry);
    print $row_obj->email;
    print $row_obj->fname;
    print $row_obj->lname;

Returns one row as object with columns names as object properties.

=cut

sub row_object {
    my ($self, $qry) = @_;
    # select * from users where id=$id limit 1
    my $ret = $self->dbh->selectrow_hashref($qry);
    if (!defined($ret) && $self->dbh->err()) {$self->db_error($qry);}
    return Hash::AsObject->new($ret);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 hashes()
    
    %hashes = $app->db->hashes($qry, $col);
    $hashes_ref = $app->db->hashes($qry, $col);

Returns list or hashes of all rows. Each hash element is a hash of one row  
=cut

sub hashes {
    my ($self, $qry, $col) = @_;
    my $ret = $self->dbh->selectall_hashref($qry, $col);
    if (!defined($ret) && $self->dbh->err()) {$self->db_error($qry);}
    return wantarray? %{$ret} : $ret;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 colhash()
    
    # select id, user from users
    %hash = $app->db->colhash($qry);

Returns all rows as a hash of the first column as the keys and the second column as the values.

=cut

sub colhash {
    my ($self, $qry) = @_;
    # select id, user from users
    my %list = map {$_->[0], $_->[1]} @{$self->dbh->selectall_arrayref($qry)};
    return wantarray? %list : \%list;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 value()
    
    # select email from users where id=123. return one column value
    $value = $app->db->value($qry);

Returns one column value from one row.

=cut

sub value {
    my ($self, $qry) = @_;
    # select email from users where id=123. return one column value
    my $ret = $self->dbh->selectcol_arrayref($qry);
    if (!defined($ret) && $self->dbh->err()) {$self->db_error($qry);}
    ($ret) = @{$ret};
    return $ret;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 insertid()
    
    $id = $app->db->insertid;

Returns the last insert id from auto increment.

=cut

sub insertid {
    my ($self) = @_;
    return $self->dbh->{mysql_insertid};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 profile()
    
	# level:
	# 0x01=DBI, 0x02=!Statement ,0x04=!MethodName, 0x06=!Statement:!Method, 
	# 0x08=!MethodClass, 0x10=!Caller2, 0=disable

    $app->db->profile($level);

	# this will generate the reports file app/log/dbi.prof
	# then run the command dbiprof to view it:
	# dbiprof --number 15 --sort count


Enable DBI profiling. See L<DBI::Profile> and L<DBI::ProfileDumper>.

=cut

sub profile {
    
	my ($self, $level) = @_;

	if (!$level) {
		$self->dbh->{Profile} = 0;
		return;
	}
	# level: ,0x01=DBI, 0x02=!Statement ,0x04=!MethodName, 0x06=!Statement:!Method, 
	# 0x08=!MethodClass, 0x10=!Caller2, 0=disable

	my $file = $self->app->file->catfile($self->app->var->get("log_dir"), "dbi.prof");

    $self->dbh->{Profile} = "$level/DBI::ProfileDumper/File:$file";
	#then run % dbiprof --number 15 --sort count

	#shell: >set DBI_PROFILE=2/DBI::ProfileDumper then %perl program.pl

	#$sth->{Profile} = 4;
	#$sth->execute; while (@array = $sth->fetchrow_array()) {};
	#print $sth->{Profile}->format;
	#finally, disable the profile status, so it does nothing at DESTROY time
    #$sth->{Profile} = 0;
	#mysql: mysql>SET profiling=1;mysql>show profiles;mysql>show profile for query 1;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 db_error()
    
    $app->db->db_error;

Aborts the application and display the last database error message.

=cut

sub db_error {
    my $self = shift;
    $self->app->abort("Database Error: $DBI::errstr<br>@_");
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=pod

=head1 Bugs

This project is available on github at L<https://github.com/mewsoft/Nile>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Nile>.

=head1 SOURCE

Source repository is at L<https://github.com/mewsoft/Nile>.

=head1 SEE ALSO

See L<Nile> for details about the complete framework.

=head1 AUTHOR

Ahmed Amin Elsheshtawy,  احمد امين الششتاوى <mewsoft@cpan.org>
Website: http://www.mewsoft.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2015 by Dr. Ahmed Amin Elsheshtawy احمد امين الششتاوى mewsoft@cpan.org, support@mewsoft.com,
L<https://github.com/mewsoft/Nile>, L<http://www.mewsoft.com>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
