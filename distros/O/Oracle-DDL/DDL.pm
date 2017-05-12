package Oracle::DDL;

# Perl standard modules
use strict;
use warnings;
use Carp;
use DBI;
use Debug::EchoMessage;
use Oracle::DML::Common qw(:all);
use POSIX qw(strftime);

require 5.003;
$Oracle::DDL::VERSION = 0.10;

require Exporter;
our @ISA         = qw(Exporter);
our @EXPORT      = qw();
our @EXPORT_OK   = qw( add_primary_key
    create_table
    );
our @IMPORT_OK   = qw( 
    get_dbh is_object_exist 
    debug echoMSG disp_param 
    );
our %EXPORT_TAGS = (
    all  => [@EXPORT_OK],
    all_ok=>[@EXPORT_OK,@IMPORT_OK],
    );

=head1 NAME

Oracle::DDL - Perl class for Oracle batch DML 

=head1 SYNOPSIS

  use Oracle::DDL;

  my %cfg = ('conn_string'=>'usr/pwd@db', 'table_name'=>'my_ora_tab');
  my $ot = Oracle::DDL->new;
  # or combine the two together
  my $ot = Oracle::DDL->new(%cfg);
  my $sql= $ot->prepare(%cfg); 
  $ot->execute();    # actually create the audit table and trigger


=head1 DESCRIPTION

This class contains methods to create audit tables and triggers for
Oracle tables.

=cut

=head2 Object Constructor

=head3 new (%arg)

Input variables:

  $cs  - Oracle connection string in usr/pwd@db
  $tn  - Oracle table name without schema

Variables used or routines called:

  None

How to use:

   my $obj = new Oracle::DDL;      # or
   my $obj = Oracle::DDL->new;     # or
   my $cs  = 'usr/pwd@db';
   my $tn  = 'my_table'; 
   my $obj = Oracle::DDL->new(cs=>$cs,tn=>$tn); # or
   my $obj = Oracle::DDL->new('cs',$cs, 'tn',$tn); 

Return: new empty or initialized Oracle::DDL object.

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

The following are the common methods, routines, and functions
defined in this class.

=head2 Exported Tag: All

The I<:all> tag includes all the methods or sub-rountines
defined in this class.

  use Oracle::DDL qw(:all);

=cut

=head3 add_primary_key($dbh, $tab, $pk, $exe)

Input variables:

  $dbh - database handler
  $tab - table name
  $pk  - primary key column name
  $exe - whether to execute the SQL statement
         0 - No (default); 1- Yes.

Variables used or routines called:

  echoMSG - display message

How to use:

    $self->add_primary_key(4dbh, 'my_tab', 'id');

Return: 0|1 - whether it is successful 0 - OK; 1 - failed

=cut

sub add_primary_key {
    my $s = shift;
    my ($dbh, $tab, $pk, $exe) = @_;
    my $r = 0;
    my $f1  = "ALTER TABLE %s \n";
       $f1 .= "    ADD (CONSTRAINT pk_%s_%s PRIMARY KEY (%s) )";
    my $q1 = sprintf $f1, $tab, $tab, $pk, $pk;
    my $s1 = $dbh->prepare($q1);
    if (! $s1) {
        print  "ERR: Stmt - $dbh->errstr";
        $r = 1;
    }
    if ($exe) { 
        if (!$s1->execute()) {
            print "ERR: Stmt - $s1->errstr";
            $r = 1;
        }
    }
    return $r;
}


=head3 create_table($tab,$crf,$opt)

Input variables:

  $tab - table name
  $crf - array ref containing table definition as $crf->[$i]{$itm},
         where $i is column number and $itm is col,typ,req,wid,dft,etc.
  $opt - other table related options:
    dbh           - database handler
    fn_sql        - output file name for SQL codes
    fn_log        - log file name for spool off and default to 
                    fn_sql with the extension replaced with .log
    fh_sql        - output file handler for SQL codes 
    action        - whether to return SQL codes
         SQL (default) - return array ref containing SQL codes
               execute SQL codes if dbh is specified
         TXT - return SQL codes in text and write SQL codes to
               output file if fn_sql or fh_sql is specified. 
         ALL - return SQL codes and 
               write to output file if fn_sql or fh_sql is specified
               execute SQL statements if dbh is specified
    public_select - 1 or actual grant statement
    drop_table    - 1 - drop before creating it; 0 - not drop
    relax_constraint - 0 - no; 1 - yes

Variables used or routines called:

  echoMSG - display message

How to use:

  my $cs = 'usr/pwd\@db';
  my $dbh = get_dbh($cs);
  my $fh  = new IO::File "> myfile.sql"; 
  my %opt = (dbh=>$dbh, fh_sql => $fh,action=>'txt');
  my $crf = $self->read_tab_def('table.def', 'myTab',',');
  my $sql = $self->create_table('myTab',${$crf}{mytab},\%opt);

Return: the result of table creation or the SQL code for creating the
table.

=cut

sub create_table {
    my $self = shift;
    my($tab,$crf,$p) = @_;
    croak "ERR: No table name is specified.\n"   if ! $tab;
    croak "ERR: No column def array.\n"          if ! $crf;
    croak "ERR: No column def is not a array.\n" if $crf !~ /ARRAY/;
    $self->echoMSG("+++ [Oracle::DDL] Creating Table $tab +++",1);
    my ($dbh,$drp,$act,$pbs,$fn,$fh,$flg,$rlx,$spo) = ();
    if ($p && $p =~ /HASH/) { 
        $dbh = (exists $p->{dbh})?$p->{dbh}:'';
        $drp = (exists $p->{drop_table})?$p->{drop_table}:1;
        $drp = ($drp && $drp =~ /^(y|1)$/)?1:0;
        $act = (exists $p->{action})?$p->{action}:'SQL';
        $pbs = (exists $p->{public_select})?$p->{public_select}:0;
        $fn  = (exists $p->{fn_sql})?$p->{fn_sql}:'';
        $flg = (exists $p->{fn_log})?$p->{fn_log}:'';
        $fh  = (exists $p->{fh_sql})?$p->{fh_sql}:'';
        $rlx = (exists $p->{relax_constraint})?
               $p->{relax_constraint}:0;
        $spo = (exists $p->{spool_off})?$p->{spool_off}:'';
    }
    $self->echoMSG("ACT=$act;DBH=$dbh;DRP=$drp;PBS=$pbs", 3);
    $self->echoMSG("FN=$fn;LOG=$flg;FH=$fh;RLX=$rlx", 3);
    my $st = strftime "%Y%m%d.%H%M%S", localtime time;

    my $txt = "";      # text to be written to a file
    my $sql = "";      # SQL codes
    my @stm = ();      # SQL statement
    $txt .= "REM table $tab generated at $st\n";
    if ($flg) { 
        $txt .= "set serveroutput on echo on\nspool $flg\n";
        $txt .= "select to_char(sysdate, 'YYYY/MM/DD HH24:MI:SS') ";
        $txt .= "\"Started at\" from dual;\n";
    }
    $txt .= "DROP TABLE $tab;\n"      if  $drp;
    if ($drp && $dbh && $self->is_object_exist($dbh,$tab,'table')) {
        push @stm, "DROP TABLE $tab"      if  $drp;
    }
    $txt .= "-- DROP TABLE $tab;\n"   if !$drp;

    $sql .= "CREATE TABLE $tab (\n";

    my $fmt = "    %-35s %-23s %12s\n";
    my ($typ,$col,$wid,$dft,$req,$otp,$orq,$dec,$dsp);
    for my $i (0..$#{$crf}) {          # loop thru each column
        $col = uc(${$crf}[$i]{'col'}); # column name
        $col = "\"$col\"";
        $typ = uc(${$crf}[$i]{'typ'}); # column type
        if ($typ =~ /^N$/) { $typ = 'NUMBER'; }
        if ($typ =~ /^D$/) { $typ = 'DATE'; }
        if ($typ =~ /^C$/) { $typ = 'VARCHAR2'; }
        $wid = "";
        if (${$crf}[$i]{'wid'}) {      # use 'wid' first
            $wid = uc(${$crf}[$i]{'wid'}); # column width
        }
        if (!$wid) {                   # use 'max'
            $wid = uc(${$crf}[$i]{'max'}); # column width
        }
        $dft = uc(${$crf}[$i]{'dft'}); # column type
        $req = uc(${$crf}[$i]{'req'}); # requirement/constraint
        $dec = uc(${$crf}[$i]{'dec'}); # decimal
        $otp = "";                     # Oracle type
        # print "$col:$typ:$wid:$dec:$req\n";
        if ($dec ne "" && $wid && $typ =~ /^N/i) {
            if ($wid > $dec) { $wid .= ",$dec"; }
            # print "--$col:$wid\n";
        }
        if ($wid && $typ !~ /^D/i) { $otp = "$typ($wid)";
        } else { $otp = $typ; }
        $orq="";
        $orq = $req if $req && $typ !~ /^D/i && 
            (! $rlx || $col =~ /(^ID|ID$)/); 
        if ($i == $#{$crf}) {
            $sql .=  sprintf $fmt, $col, $otp, $orq . ')';
            # $sql .= $opt if ($opt);
        } else {
            $sql .= sprintf $fmt, $col, $otp, $orq . ',';
        }
    }
    $txt .= "$sql;\n";
    push @stm, $sql;
    if ($pbs && $pbs == 1) { 
        $txt .= "GRANT SELECT ON $tab TO PUBLIC;\n";
        push @stm, "GRANT SELECT ON $tab TO PUBLIC";
    } elsif ($pbs) { 
        $txt .= $pbs; 
        push @stm, $pbs; 
    }
    if (exists ${$crf}[0]{table_desc}) {
        $dsp = ${$crf}[0]{table_desc};
        $dsp =~ s/\'/ /g;              # change single quote to blank
        $dsp =~ s/\&/and/g;            # change & sign to 'and'
        $txt .= "COMMENT ON TABLE ${tab} IS\n  '$dsp';\n";
        push @stm, "COMMENT ON TABLE ${tab} IS\n  '$dsp'";
    }
    # create comment for columns
    for my $i (0..$#{$crf}) {          # loop thru each column
        $col = uc(${$crf}[$i]{'col'}); # column name
        $dsp = ${$crf}[$i]{'dsp'};     # column description
        $dsp =~ s/\'/ /g;              # change single quote to blank
        $dsp =~ s/\&/and/g;            # change & sign to 'and'
        next if !$dsp;
        $txt .= "COMMENT ON COLUMN ${tab}.\"$col\" IS\n  '$dsp';\n";
        push @stm, "COMMENT ON COLUMN ${tab}.\"$col\" IS\n  '$dsp'";
    }
    $txt .= "spool off\nexit\n"     if $spo;
    # action time...
    return $txt  if $act =~ /^TXT/i && !$fn && !$fh;
    return \@stm if $act =~ /^SQL/i && !$dbh; 
    my $fh1 = "";
    if ($fn) {
        use IO::File;
        $fh1 = new IO::File ">> $fn";
    }
    if ($act =~ /^(ALL|TXT)/i) {
        print $fh  $txt     if $fh;
        print $fh1 $txt     if $fn;
        $fh->close          if $fh;
        $fh1->close         if $fn;
        return $txt         if $act =~ /^TXT/i; 
    }
    if ($act =~ /^(ALL|SQL)/i && $dbh) {
        for my $i (0..$#stm) {
            my $q = "$stm[$i]\n";
            my $s=$dbh->prepare($q)|| print "ERR: Stmt - $dbh->errstr";
               $s->execute()       || print "ERR: Stmt - $s->errstr";
        }
    }
    return \@stm;
}

1;

=head1 HISTORY

=over 4

=item * Version 0.10

This version is to test the concept.

=item * Version 0.2


=cut

=head1 SEE ALSO (some of docs that I check often)

Oracle::Loader, Oracle::Trigger, Oracle::DML, Oracle::DML::Common,
CGI::Getopt, File::Xcopy

=head1 AUTHOR

Copyright (c) 2005 Hanming Tu.  All rights reserved.

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut

