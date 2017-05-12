package Oracle::DML::Common;

# Perl standard modules
use strict;
use warnings;
use Carp;
# use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
# warningsToBrowser(1);
# use CGI;
# use Getopt::Std;
use Debug::EchoMessage;
use DBI;

our $VERSION = 0.21;

require Exporter;
our @ISA         = qw(Exporter);
our @EXPORT      = qw();
our @EXPORT_OK   = qw(get_dbh is_object_exist 
  );
our %EXPORT_TAGS = (
    all    =>[@EXPORT_OK],
    db_conn=>[qw(get_dbh is_object_exist
             )],
    table  =>[qw(
             )],
);

=head1 NAME

Oracle::DML::Common - Common routines for Oracle DML 

=head1 SYNOPSIS

  use Oracle::DML::Common;

  my %cfg = ('conn_string'=>'usr/pwd@db', 'table_name'=>'my_ora_tab');
  my $ot = Oracle::DML::Common->new;
  # or combine the two together
  my $ot = Oracle::DML::Common->new(%cfg);
  my $sql= $ot->prepare(%cfg); 
  $ot->execute();    # actually create the audit table and trigger


=head1 DESCRIPTION

This class contains methods to create audit tables and triggers for
Oracle tables.

=cut

=head3 new ()

Input variables:

  %ha  - any hash array containing initial parameters

Variables used or routines called:

  None

How to use:

   my $obj = new Oracle::DML::Common;      # or
   my $obj = Oracle::DML::Common->new;  

Return: new empty or initialized Oracle::DML::Common object.

This method constructs a Perl object and capture any parameters if
specified. 
 
=cut

sub new {
    my $caller        = shift;
    my $caller_is_obj = ref($caller);
    my $class         = $caller_is_obj || $caller;
    my $self          = bless {}, $class;
    my %arg           = @_;   # convert rest of inputs into hash array
    foreach my $k ( keys %arg ) {
        if ($caller_is_obj) {
            $self->{$k} = $caller->{$k};
        } else {
            $self->{$k} = $arg{$k};
        }
    }
    return $self;
}

=head1 METHODS

The following are the common methods, routines, and functions used
by other classes.

=head2 Connection Methods

The I<:db_conn> tag includes sub-rountines for creating and
managing database connections.

  use Oracle::DML::Common qw(:db_conn);

It includes the following sub-routines:

=head3 get_dbh($con, $dtp)

Input variables:

  $con - Connection string for
         Oralce: usr/pwd@db (default)
            CSV: /path/to/file
       ODBC|SQL: usr/pwd@DSN[:approle/rolepwd]
  $dtp - Database type: Oracle, CSV, etc

Variables used or routines called:

  DBI
  DBD::Oracle
  Win32::ODBC

How to use:

  $self->get_dbh('usr/pwd@dblk', 'Oracle');
  $self->get_dbh('usr/pwd@dblk:approle/rpwd', 'SQL');

Return: database handler

If application role is provided, it will activate the application role
as well.

=cut

sub get_dbh {
    my $self = shift;
    my ($con, $dtp) = @_;
    # Input variables:
    #   $con  - connection string: usr/pwd@db
    #   $dtp  - database type: Oracle, CSV
    #
    $dtp = 'Oracle' if !$dtp;
    my (@conn, $dsn, $dbh,$msg);
    my ($usr, $pwd, $sid) = ($con =~ /(\w+)\/(\w+)\@(\w+)/i);
    my ($apusr, $appwd) = ($con =~ /:(\w+)\/(\w+)/i);
    if ($dtp =~ /Oracle/i) {
        @conn = ("DBI:Oracle:$sid", $usr, $pwd);
        $dbh=DBI->connect(@conn) ||
            die "Connection error : $DBI::errstr\n";
        $dbh->{RaiseError} = 1;
    } elsif ($dtp =~ /CSV/i) {
        carp "WARN: CSV directory - $con does not exist.\n"
            if (!-d $con);
        @conn = ("DBI:CSV:f_dir=$con","","");
        $dbh=DBI->connect(@conn) ||
            die "Connection error : $DBI::errstr\n";

    } else {   # ODBC or SQL
        $dsn = "DSN=$sid;uid=$usr;pwd=$pwd;";
        $dbh = new Win32::ODBC($dsn);
        if (! $dbh) {
            Win32::ODBC::DumpError();
            $msg = "Could not open connection to DSN ($dsn) ";
            $msg .= "because of [$!]";
            die "$msg";
        }
        if ($apusr) {
            $dbh->Sql("exec sp_setapprole $apusr, $appwd");
        }
    }
    return $dbh;
}

=head3 is_object_exist($dbh,$tn,$tp)

Input variables:

  $dbh - database handler, required.
  $tn  - table/object name, required.
         schema.table_name is allowed.

Variables used or routines called:

  echoMSG    - display messages.

How to use:

  # whether table 'emp' exist
  $yesno = $self->is_object_exist($dbh,'emp');

Return: 0 - the object does not exist;
        1 - the object exist;

=cut

sub is_object_exist {
    my $self = shift;
    my($dbh,$tn, $tp) = @_;
    croak "ERR: could not find database handler.\n"      if !$dbh;
    croak "ERR: no table or object name is specified.\n" if !$tn;
    # get owner name and table name
    my ($sch, $tab, $stb) = ("","","");
    if (index($tn, '.')>0) {
        ($sch, $tab) = ($tn =~ /(\w+)\.([\w\$]+)/);
    }
    my($q,$r);
    $tp = 'TABLE' if ! $tp;
    $stb = 'user_objects';
    $stb = 'all_objects'   if $sch;
    $q  = "SELECT object_name from $stb ";
    $q .= " WHERE object_type = '" . uc($tp) . "'";
    if ($sch) {
        $q .= "   AND object_name = '" . uc($tab) . "'";
        $q .= "   AND owner = '" . uc($sch) . "'";
    } else {
        # $tn =~ s/\$/\\\$/g;
        $q .= "   AND object_name = '" . uc($tn) . "'";
    }
    $self->echoMSG($q, 5);
    my $sth=$dbh->prepare($q) || die  "Stmt error: $dbh->errstr";
       $sth->execute() || die "Stmt error: $dbh->errstr";
    my $n = $sth->rows;
    my $arf = $sth->fetchall_arrayref;
    $r = 0;
    $r = 1             if ($#{$arf}>=0);
    return $r;
}

=head2 Table Methods

The I<:table> tag includes sub-rountines for creating, checking and
manipulating tables.

  use Oracle::DML::Common qw(:table);

It includes the following sub-routines:

=cut

1;

=head1 HISTORY

=over 4

=item * Version 0.1

This versionwas contained in Oracle::Trigger class.

=item * Version 0.2

04/29/2005 (htu) - extracted common routines from Oracle::Trigger class
and formed Oracle::DML::Common.

=item * Version 0.21

Remove get_table_definition method to I<Oracle::Schema> class.

=cut

=head1 SEE ALSO (some of docs that I check often)

Data::Describe, Oracle::Loader, CGI::Getopt, File::Xcopy,
Oracle::Trigger,
perltoot(1), perlobj(1), perlbot(1), perlsub(1), perldata(1),
perlsub(1), perlmod(1), perlmodlib(1), perlref(1), perlreftut(1).

=head1 AUTHOR

Copyright (c) 2005 Hanming Tu.  All rights reserved.

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut


