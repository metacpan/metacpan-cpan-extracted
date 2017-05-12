package Oracle::DML;

# Perl standard modules
use strict;
use warnings;
use Carp;
require Exporter;
our @ISA         = qw(Exporter);
# use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
# warningsToBrowser(1);
# use CGI;
# use Getopt::Std;
use DBI;
use Debug::EchoMessage;
use Oracle::DML::Common qw(:db_conn :table check_input_drf);
use Oracle::Schema qw(get_table_definition); 
# use Oracle::SQL::Builder qw(build_sql_stmt split_cns);

require 5.003;
$Oracle::DML::VERSION = 0.10;

our @EXPORT      = qw();
our @EXPORT_OK   = qw( 
    select_records insert_records delete_records update_records
    check_records insert_into
    check_input_arf
    );
our @IMPORT_OK   = qw( 
    get_dbh is_object_exist get_table_definition 
    debug echoMSG disp_param
    );
our %EXPORT_TAGS = (
    all  => [@EXPORT_OK],
    all_ok=>[@EXPORT_OK,@IMPORT_OK],
    );

=head1 NAME

Oracle::DML - Perl class for Oracle batch DML 

=head1 SYNOPSIS

  use Oracle::DML;

  my %cfg = ('conn_string'=>'usr/pwd@db', 'table_name'=>'my_ora_tab');
  my $ot = Oracle::DML->new;
  # or combine the two together
  my $ot = Oracle::DML->new(%cfg);
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

   my $obj = new Oracle::DML;      # or
   my $obj = Oracle::DML->new;     # or
   my $cs  = 'usr/pwd@db';
   my $tn  = 'my_table'; 
   my $obj = Oracle::DML->new(cs=>$cs,tn=>$tn); # or
   my $obj = Oracle::DML->new('cs',$cs, 'tn',$tn); 

Return: new empty or initialized Oracle::DML object.

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

  use Oracle::DML qw(:all);

=cut

=head3 insert_into ($dbh,$tab,$crf,$pr)

Input variables:

  $dbh - database handler 
  $tab - table name
  $crf - table definition array: $crf->[$i]{$itm} 
      $i - column number
      $k - items: col, typ, req, wid, dft, etc.
           PK, CK, MP_TABLE, MP are in the last element of the array
  $pr  - additional parameters

Variables used or routines called:

  None

How to use:

   my $obj = new Oracle::DML;      # or
   my $obj = Oracle::DML->new;     # or
   my $cs  = 'usr/pwd@db';
   my $tn  = 'my_table'; 
   my $def = 'tables.def';
   my $crf = $self->read_tab_def($def); 
   my $sql = $obj->insert_into($dbh,$tn,$def->{$tn});  

Return: SQL statement 

=cut

sub insert_into {
    my $s = (ref($_[0])) ? shift : Oracle::DML->new;
    my ($dbh,$tab,$crf,$pr) = @_;
    print "WARN: no table name is defined.\n"    if !$tab;
    print "WARN: no table def array.\n" if !$crf || $crf !~ /ARRAY/;
    return ""  if !$tab || !$crf || $crf !~ /ARRAY/;

    $pr = {} if !$pr || $pr !~ /HASH/;
    my $n = $#$crf;
    my $stn = (exists $crf->[$n]{MP_TABLE}[0])?$crf->[$n]{MP_TABLE}[0]:"";
    print "WARN: no mapping table for $tab.\n" if !$stn;
    return ""    if !$stn; 
    my @mp = (exists $crf->[$n]{MP}) ? @{$crf->[$n]{MP}} : ();
    my %mp = ();
    if (@mp) { 
        foreach (@mp) {
            my ($k, $v) = ($_ =~ /\s*(\w+)\s*=\s*(.+)/); 
            $mp{lc $k} = $v; 
        }
    }
    my $t = "INSERT INTO $tab\n  SELECT "; 
    for my $i (0..$#$crf) { 
        my $k = lc $crf->[$i]{col}; 
        my $v = (exists $mp{$k}) ? $mp{$k} : $k; 
        if ($i == 0) { 
            $t .= ($n==0) ? "$v\n" : "$v,\n";  
        } elsif ($i==$n && $n > 0) {
            $t .= "         $v\n";
        } else { $t .= "         $v,\n"; }
    }
    my $whr = (exists $pr->{where}) ? $pr->{where} : ""; 
    $t .= "    FROM $stn\n"; 
    $t .= "   WHERE $whr\n"    if $whr;
    return $t;
}

=head3 select_records($dbh,$tn,$cns,$whr,$rtp)

Input variables:

  $dbh - a database handler.
  $tn  - table name.
  $cns - column names separated by comma.
  $whr - conditions used in WHERE clause
  $rtp - returned array type:
         ARRAY     - default, array does not contain column names.
         SFR_ARRAY - first row contains column names, i.e.,
                     skip first row when processing data
         HASH      - hashed array
         lc_hash   - column name in lower case
  $dtp - database type: Oracle|CSV|ODBC

Variables used or routines called: 

  echoMSG - display messages

How to use:

  my $arf = $self->select_records($dbh,'emp',
        'firstname,lastname', 'sal > 10000','lc_hash');

Return: an array reference contain the records in sequence while 
columns can be in sequence or in hash. 

The returned array can be accessed through ${$arf}[$i][$j] or 
${$arf}[$i]{$col}.  When it is ${$arf}[$i][$j], no column name is
returned from it. When $atp = 'SFR_ARRAY', then the first row contains
column names. 

=cut

sub select_records {
    my $self = shift;
    my($dbh,$tn,$cns,$whr,$rtp,$dtp) = @_;
    croak "No database handler is specified.\n" if ! $dbh;
    croak "No table name is specified.\n" if ! $tn;
    if (!$dtp) {
        if ($dbh =~ /ODBC/) { $dtp = 'ODBC';  # Win32::ODBC=HASH()
        } else {
            $dtp = 'Oracle'; 
        }
    }
    $cns = "*" if ! $cns; 
    $self->echoMSG("    getting data from table $tn...",1);
    my $sel = $cns; 
    my ($dft,$cdf); 
    if ($dft && !$cdf) { 
        $self->echoMSG("WARN: no column definition array ref.");
        $self->echoMSG("WARN: date format - $dft will not be applied.");
        my ($cn1,$cd1,$cd2) =
            $self->get_table_definition($dbh,$tn,'','hash');
        $cdf = $cd1; 
    }
    my (%ha, $i, $k, $msg);
    if ($dft && $cdf && "$cdf" =~ /ARRAY/) {
        $self->echoMSG("    setting date format to $dft...",2);
        my $scn = ""; 
        for $i (0..$#{$cdf}) {
            $k = lc(${$cdf}[$i][0]);       # cname
            $scn .= "$k,"; 
            $ha{$k} = uc(${$cdf}[$i][1]);  # coltype
        }
        $scn =~ s/,$//;               # remove last comma
        $sel = "";
        $cns = $scn if $cns eq '*'; 
        # foreach $i (split /,/, $scn) {
        #     $k = lc($i); 
        #     if ($sel) { $sel .= ","; } else { $sel = ""; }
        #     if ($ha{$k} eq 'DATE') {
        #         $sel .= "to_char($k,'$dft') AS $k"; 
        #     } else {
        #         $sel .= "$k"; 
        #     }
        # }
        foreach $i (split /,/, $cns) {
            $k = lc($i); 
            if ($sel) { $sel .= ","; } else { $sel = ""; }
            if (!exists $ha{$k} && $k =~ /^(rowid|rownum)/i) {
                $sel .= "$k"; next; 
            }
            if (!exists $ha{$k}) {
                $msg = "Excluded: $k not in table def arf.";
                $self->echoMSG("    $msg",2);
                next;
            }
            if ($ha{$k} eq 'DATE') {
                $sel .= "to_char($k,'$dft') AS $k"; 
            } else {
                $sel .= "$k"; 
            }
        }
    }
    my $q  = "SELECT $sel \n      FROM $tn";
    my $m1 = $self->split_cns("SELECT $sel",65,',',4); 
       $msg = "$m1      FROM $tn";
    if ($whr) { 
        my $m2 = $self->split_cns(" $whr",65,',',4); 
        $q .= "\n    $whr"; $msg .= "\n$m2"; 
    } else    { $msg .= "<p>"; }
    $self->echoMSG("$msg",2);
    my ($s,$arf,$hrf); 
    $s=$dbh->prepare($q) || print  "ERR: Stmt - $dbh->errstr";
    $s->execute()        || print  "ERR: Stmt - $s->errstr"; 
    $i = -1;
    if ($rtp && $rtp =~ /^(hash|lc_hash)/i) {
        while ($hrf = $s->fetchrow_hashref) {
            ++$i; 
            if ($rtp =~ /^lc_hash/i) {
                my $ar = bless {}, ref($self)||$self;
                foreach my $k (keys %{$hrf}) { 
                    ${$ar}{lc $k} = ${$hrf}{$k}; 
                }
                ${$arf}[$i] = $ar;
            } else { 
                ${$arf}[$i] = $hrf;
            }
        }
    } else {
        $arf = $s->fetchall_arrayref;
        if ($rtp && $rtp =~ /^(sfr_array)/i) {
            my ($cn1,$cd1,$cmt) = 
                $self->get_table_definition($dbh,$tn); 
            # insert the column names in the very begining of the array
            splice(@$arf, 0,0,[split /,/, $cn1]); 
        }
    }
    return $arf;
}

=head3 delete_records($dbh,$tab,$col,$op,$val,$dft)

Input variables:

  $dbh - database handler
  $tab - table name
  $col - column name
  $op  - operator such as '=','<','in','like','btw', etc.
  $val - value or values separated by space
  $dft - date format, default to 'YYYYMMDD.HH24MISS'

Variables used or routines called:

  echoMSG    - echo message

How to use:

  my $cs  = "usr/pwd@db";
  my $dbh = $self->getDBHandler($cs, 'Oracle');
  $self->insert($dbh, 'myTab', 'ID', 'in', 'A B C');

Return: None.

If operator is 'like', then you can use wildcard such as '%' or '?'
in the $val. You can only use one string, and the others after the 
first blank space will be ignored.

=cut

sub delete_records {
    my $self = shift;
    my ($dbh,$tab,$col,$op,$val,$dft) = @_;
    $dft = 'YYYYMMDD.HH24MISS' if !$dft; 
    my ($msg, $q, $v, $r);
    my $mtd = 'Fax::DataFax::OraSub::delete_records'; 
    if (!defined($dbh) || !defined($tab) || !defined($col) ||
        !defined($op)  || !defined($val)) {
        $msg = "Missing inputs for $mtd.";
        $self->echoMSG($msg); return; 
    }
    $self->echoMSG("  - deleting records from $tab...");
    $col = lc($col);
    $op  = uc($op) ;
    if (!$self->is_object_exist($dbh, $tab, 'column', $col)) {
        $self->echoMSG("  Column $col does not exist in $tab");
        return;
    }
    my $dbg = $self->debug;
       $self->debug(-1);     # turn off all the message 
    my ($c1,$df3,$cmt)=$self->get_table_definition($dbh,$tab,$col,'HASH');
       $self->debug($dbg);   # restore message level
    $q  = "DELETE FROM $tab\n     WHERE $col "; 
    my $typ = ${$df3}{$col}{typ};    # column data type
    my @a = split / /, $val; 
    if ($typ =~ /^(V|C)/) { 
        for my $i (0..$#a) {  $a[$i] = "'$a[$i]'"; }
    } elsif ($typ =~ /^D/i) { 
        for my $i (0..$#a) { $a[$i] = "TO_DATE('$a[$i]','$dft')"; }
    }
    if ($op =~ /^IN$/i) {
        $q .= "$op (" . (join ',', @a) . ")"; 
    } elsif ($op =~ /^(BETWEEN|BTW|BTN)/i) {
        $q .= "BETWEEN $a[0] AND $a[1]"; 
    } elsif ($op =~ /^(LK|LIKE)/i) { 
        $q .= "LIKE '$a[0]'"; 
    } else {
        $q .= "$op @a"; 
    }
    $msg = "    $q"; 
    $self->echoMSG($msg, 2); 
    my $sth=$dbh->prepare($q) || die  "Stmt error: $dbh->errstr";
       $sth->execute() || die "Stmt error: $dbh->errstr";
    my $nr = $sth->rows;
    $self->echoMSG("    $nr rows deleted.",1); 
    # $dbh->commit || die "ERR: $dbh->errstr";
    return 1;
}

=head3 insert_records($dbh,$tab,$drf,$pk,$dft)

Input variables:

  $dbh - database handler
  $tab - target table name
  $drf - data array reference: ${$arf}[$i]{$col} or 
         a source table.
  $pk  - primary key. 
  $dft - date format. Defaults to 'YYYYMMDD.HH24MISS'

Variables used or routines called:

  echoMSG      - echo message
  check_input_drf - check input array ref
  is_object_exist   - check object existence
  get_table_definition  - get table definitions
  select_records - get table data 

How to use:

  my $cs  = 'usr/pwd@db';
  my $dbh = $self->getDBHandler($cs, "Oracle");
  my $drf = $self->select_records($dbh,$srctab,'*','','hash');
  my $tab = "test_table";
  $self->insert_records($dbh,$tab,$drf); 

Return: None.

This method inserts records in a data array ($drf) into a table.
If the primary key is specified, it checks to see if the
primary key does not exist in the table. If the primary key exists,
it will skip inserting the record. Here are the steps involved
in this method: 
  1) Checks whether the table exists;
  2) Gets the table definition; 
  3) Compares the column names with the column names in the array;
  4) Gets a list of primary keys in the table;
  5) Loops through each records in the array;
  6) Inserts records only if the primary key does not exist in the
     table.

=cut

sub insert_records {
    my $self = shift;
    my ($dbh, $tab, $drf,$pk,$dft) = @_;
    $self->echoMSG("\n  - inserting records for $tab ...");
    croak "ERR: no DB handler is specified.\n" if !$dbh;
    croak "ERR: no table name is specified.\n" if !$tab;
    croak "ERR: no data array is specified.\n" if !$drf;
    $drf = $self->check_input_drf($drf,$dbh); 
    $dft = 'YYYYMMDD.HH24MISS' if !$dft;
    my ($cns,$df3, $cmt) = 
        $self->get_table_definition($dbh,$tab,'','hash');
    # ${$df1}[$i][$j], ${$df3}{$cn}{$itm} 
    $cns = lc $cns;
    my $cnt = 0;  my $cn1 = ""; 
    for my $k (split /,/, $cns) {
        if (! exists ${$drf}[0]{$k}) {  ++$cnt; 
            if ($cn1) { $cn1 .= ",$k"; } else { $cn1 = $k; }
        }
    }
    if ($cnt) {
        $self->echoMSG("WARN: missing $cnt columns - $cn1"); 
        $self->echoMSG("      insert process abandoned."); 
        return 0; 
    }
    my ($id,$kr)  = ($pk,"");     # get id column
    my %key = ();
    if ($id) { 
        # get a list of keys
        # select_records($dbh,$tn,$cns,$whr,$atp,$dft,$cdf)
        $kr = $self->select_records($dbh,$tab,$id,'','array');
        for my $i (0..$#$kr) { $key{lc ${$kr}[$i][0]} = 1; }
    }
    #
    # insert new records
    my $vnp = ""; 
    # $vnp =~ s/(\w+)/\?/g; 
    my $v = ""; my $p = "";  
    for my $k (split /,/, $cns) {
        if (${$df3}{$k}{typ} =~ /^DATE/i) {
            $p = "to_date(?,'$dft')"; 
        } else { $p = '?'; }
        if ($vnp) { $vnp .= ",$p"; } else { $vnp = "$p"; };
    }
    my $m3 = $cns; $m3 =~ s/,/,\n/g; 
    my $q = "INSERT INTO $tab\n   ($m3)\n    VALUES ($vnp)\n";
    my $m1 = $self->split_cns("($cns)",65,',',6); 
    my $m2 = $self->split_cns("($vnp)",65,',',6); 
    my $msg = "    INSERT INTO $tab\n$m1    VALUES \n$m2"; 
    $self->echoMSG($msg, 2);
    my $s = $dbh->prepare($q);
    my @a = (); $cnt = 0; 
    my ($err,$scc,$idv) = (0,0,0); 
    my @k_inserted = ();
    my @k_exist    = ();
    for my $i (0..$#{$drf}) {
        if ($id) { 
            $idv = lc ${$drf}[$i]{$id};     # premier key value
            if (exists $key{$idv}) {
                $msg = "    Key ($id = $idv) is alread in table $tab"; 
                $self->echoMSG($msg, 2); 
                ++$scc;  push @k_exist, $idv; 
                next;                # skip insert
            }
        } 
        @a = (); 
        for my $k (split /,/, $cns) { 
            $v = ${$drf}[$i]{$k}; 
            push @a, $self->build_sql_stmt($k,$v,$df3,$dft); 
        } 
        $self->echoMSG((join ',', @a),2);
        if (!$s->execute(@a)) {
            ++$err; $self->echoMSG("ERR: Stmt - $s->errstr"); 
        } else { ++$cnt; push @k_inserted, $idv; }
    }
    my $tot = $#{$drf}+1; 
    $msg  = "    $cnt out of $tot rows inserted with $err errors.\n";
    $msg .= "    $scc records were skipped due to key already exists.";
    $self->echoMSG($msg, 2);
    return (\@k_inserted, \@k_exist);
}

=head3 check_records($dbh,$tab,$drf,$ckc,$dft)

Input variables:

  $dbh - database handler
  $tab - target table name
  $drf - data array reference: ${$arf}[$i]{$col} or 
         a source table.
  $chc - a list of column names separated by comma and 
         to be checked against the column definition.
  $dft - date format. Defaults to 'YYYYMMDD.HH24MISS'
  $pk  - primary key. Defaults to the first column

Variables used or routines called:

  echoMSG      - echo message
  check_input_drf - check input array ref
  is_object_exist   - check object existence
  get_table_definition  - get table definitions
  select_records - get table data 

How to use:

  my $cs  = 'usr/pwd@db';
  my $dbh = $self->getDBHandler($cs, "Oracle");
  my $drf = $self->select_records($dbh,$srctab,'*','','hash');
  my $tab = "test_table";
  my $rrf = $self->check_records($dbh,$tab,$drf); 

Return: $rrf - report hash array reference. The $rrf contains
${$rrf}{$cat}{$itm}{...}, where

  cn - column name
    {cn}{no_missing_in_array} - number of colunm name missing
          in the array comparing to the column names in the
          table.
    {cn}{nm_missing_in_array} - a list of column names separated
          by comma, which are missing in the array comparing to
          the column names in the table.
  rec - record related statistics
    {rec}{total} - total number of records in the array
  col - column statistics
    {col}{$cn}{wid} - statistics related to width and range
        {ok_cnt} - number of records within max and min width and
                   not null requirement if there is any
        {ok_pct} - percentage of the ok records
        {emp_rec} - number of empty records, which is excluded 
                   from ok_cnt if it is 'not null' column. 
        {bad_typ} - number of bad datatype records.
        {out_rng} - number of record which is out of range.
                   The range is determined by max and min width
                   for char columns and max and dec width for 
                   number fields.
        {rownum} - a list of row numbers for the records that
                   exceed the max width for char columns or
                   is out of range for numeric fields. 

This method checks data fields against column definition and report
any records that do not confirm with the column definition.
Here are the steps involved in this method: 

  1) Checks inputs and data array;
  2) Gets the table definition; 
  3) Compares the column names with the column names in the array;
  4) Check data fields 
  5) Report results 

=cut

sub check_records {
    my $self = shift;
    my ($dbh, $tab, $drf,$ckc,$dft) = @_;
    $self->echoMSG("\n  - checking records for $tab ...");
    croak "ERR: no DB handler is specified.\n" if !$dbh;
    croak "ERR: no table name is specified.\n" if !$tab;
    croak "ERR: no data array is specified.\n" if !$drf;
    # 1. check data array
    $drf = $self->check_input_drf($drf,$dbh); 
    $dft = 'YYYYMMDD.HH24MISS' if !$dft;
    # 2. get table definition
    my ($cns,$df3, $cmt) = 
        $self->get_table_definition($dbh,$tab,'','hash');
    # my ($x1, $x2,  $df3) = $self->getTableDef($dbh,$tab);
    # ${$df1}[$i][$j], ${$df3}{$cn}{$itm}, ${$df2}[$i]{$itm} 
    $cns = lc $cns;
    $ckc = $cns if (!defined($ckc) || $ckc eq "*" || $ckc eq ""); 
    # 3. compare column names
    my %rpt = ();
    my $cnt = 0;  my $cn1 = ""; 
    for my $k (split /,/, $cns) {
        if (! exists ${$drf}[0]{$k}) {  ++$cnt; 
            if ($cn1) { $cn1 .= ",$k"; } else { $cn1 = $k; }
        }
    }
    $rpt{cn}{no_missing_in_array} = $cnt;
    $rpt{cn}{nm_missing_in_array} = $cn1;
    $cnt = 0;  $cn1 = ""; 
    foreach my $k (keys %{${$drf}[0]}) {
        if (! exists ${$df3}{$k}) {  ++$cnt; 
            if ($cn1) { $cn1 .= ",$k"; } else { $cn1 = $k; }
        }
    }
    $rpt{cn}{no_missing_in_table} = $cnt;
    $rpt{cn}{nm_missing_in_table} = $cn1;
    # 4. check data fields
    $rpt{rec}{total} = $#{$drf}+1; 
    for my $k (split /,/, $ckc) { # for each check column name
        my $j   = ${$df3}{$k}{seq};
        my $typ = ${$df3}{$k}{typ};
        my $wid = ${$df3}{$k}{wid};
        my $max = ${$df3}{$k}{max};
        my $min = ${$df3}{$k}{min};
        my $dec = ${$df3}{$k}{dec};
        my $req = ${$df3}{$k}{req};
        my $fmt = ${$df3}{$k}{dft};
        my ($max_no,$min_no) = (0,0);
        if ($typ =~ /^N/i) {   # need to define max and min numbers
            $max_no = ('9' x $max)+0;
            if ($min > 0) { $min_no = ('1' . ('0' x ($min-1))) + 0; }
        }
        if (!exists $rpt{col}{$k}{wid}{max}) {
            $rpt{col}{$k}{wid}{max} = -1;
        }
        if (!exists $rpt{col}{$k}{wid}{min}) {
            $rpt{col}{$k}{wid}{min} = 9999.99;
        }
        if (!exists $rpt{col}{$k}{wid}{avg}) {
            $rpt{col}{$k}{wid}{avg} = 0;
        }
        if (!exists $rpt{col}{$k}{wid}{emp_rec}) {
            $rpt{col}{$k}{wid}{emp_rec} = 0;
        }
        if (!exists $rpt{col}{$k}{wid}{bad_typ}) {
            $rpt{col}{$k}{wid}{bad_typ} = 0;
        }
        if (!exists $rpt{col}{$k}{wid}{out_rng}) {
            $rpt{col}{$k}{wid}{out_rng} = 0;
        }
        if (!exists $rpt{col}{$k}{wid}{ok_cnt}) {
            $rpt{col}{$k}{wid}{ok_cnt} = 0;
        }
        for my $i (0..$#$drf) {
            my $v = ${$drf}[$i]{$k}; 
            my $len = undef; 
            if ($typ =~ /^(C|V|D)/i)  {   # check width
                if (!defined($v) || !$v) {
                    ++$rpt{col}{$k}{wid}{emp_rec};  
                    next if ($req =~ /^not null/i || $req =~ /^Y/i); 
                    $v = "";
                }
                $len = ($v)?length($v):0; 
                if ($len>$rpt{col}{$k}{wid}{max}) {
                    $rpt{col}{$k}{wid}{max} = $len;
                }
                if ($len<$rpt{col}{$k}{wid}{min}) {
                    $rpt{col}{$k}{wid}{min} = $len;
                }
                if (length($v) <= $wid) { 
                    ++$rpt{col}{$k}{wid}{ok_cnt}  
                } else {
                    $rpt{col}{$k}{wid}{rownum} .= "$i,"
                }
            } elsif ($typ =~ /^N/i) {   # check range
                if (!defined($v) || ($v !~ /^0$/ && !$v)) {
                    ++$rpt{col}{$k}{wid}{emp_rec};  
                    next if ($req =~ /^not null/i || $req =~ /^Y/i); 
                    ++$rpt{col}{$k}{wid}{ok_cnt};  
                    next;
                }
                if ($v =~ /^[\d\.]+$/) {
                    $len = $v+0; 
                } else {
                    ++$rpt{col}{$k}{wid}{bad_typ};  
                    next;
                }
                if ($min_no <= $v && $v <= $max_no ) { 
                    ++$rpt{col}{$k}{wid}{ok_cnt};  
                } else {
                    ++$rpt{col}{$k}{wid}{out_rng};  
                    $rpt{col}{$k}{wid}{rownum} .= "$i,"
                }
            } elsif ($typ =~ /^D/i) {   # check date format  
            } else {
            }
            if ($len>$rpt{col}{$k}{wid}{max}) {
                $rpt{col}{$k}{wid}{max} = $len;
            }
            if ($len<$rpt{col}{$k}{wid}{min}) {
                $rpt{col}{$k}{wid}{min} = $len;
            }
            $rpt{col}{$k}{wid}{avg} += $len;
        }
    }
    # 5. report results
    my $msg  = "    Compared the array against table $tab and here is";
    $msg .= "the result:\n    Total records comparied: ";
    $msg .= "$rpt{rec}{total}\n";
    $msg .= "    $rpt{cn}{no_missing_in_array} column(s) ";
    $msg .= "missing in the array.\n";
    if ($rpt{cn}{no_missing_in_array} > 0) { 
        $msg .= "    They are $rpt{cn}{nm_missing_in_array}.";
    }
    $msg .= "    $rpt{cn}{no_missing_in_table} column(s) ";
    $msg .= "missing in the table.\n";
    if ($rpt{cn}{no_missing_in_table} > 0) { 
        $msg .= "    They are $rpt{cn}{nm_missing_in_table}.";
    }
    $msg .= "    Column Statistics:\n"; 
    $msg .= sprintf "%3s %35s %7s %7s %7s %5s %7s %5s %5s\n",
            "Seq", "ColName[data_type(max,min)]", 
            "Max", "Min", "Avg", "#OK", "OK%", "Empty", "BadRC"; 
    $msg .= sprintf "%3s %35s %7s %7s %7s %5s %7s %5s %5s \n",
            "-"x3, "-"x35, "-"x7, "-"x7, "-"x7, "-"x5, "-"x7, 
            "-"x5, "-"x5; 
    my $ft1 = "%3d %35s %7.2f %7.2f %7.2f %5d %7.2f %5d %5d\n"; 
    for my $k (split /,/, $ckc) { # for each check column name
        my $j   = ${$df3}{$k}{seq};
        my $c   = "$k\[${$df3}{$k}{typ}";
        if (${$df3}{$k}{typ} =~ /^N/i) {
           $c  .= "(${$df3}{$k}{max},${$df3}{$k}{dec})";  
        } else {
           $c  .= "(${$df3}{$k}{max},${$df3}{$k}{min})";  
        }
        if (${$df3}{$k}{req} =~ /^(not null|y)/i) {
            $c .= ",${$df3}{$k}{req}]"; 
        } else {
            $c .= "]"; 
        }
        my $avg = $rpt{col}{$k}{wid}{avg} / $rpt{rec}{total}; 
        $rpt{col}{$k}{wid}{avg} = $avg; 
        $rpt{col}{$k}{wid}{ok_pct} = 100 * $rpt{col}{$k}{wid}{ok_cnt}
            / $rpt{rec}{total};
        $msg .= sprintf $ft1, $j, $c, $rpt{col}{$k}{wid}{max},
                $rpt{col}{$k}{wid}{min}, $rpt{col}{$k}{wid}{avg},
                $rpt{col}{$k}{wid}{ok_cnt}, $rpt{col}{$k}{wid}{ok_pct}, 
                $rpt{col}{$k}{wid}{emp_rec},
                $rpt{col}{$k}{wid}{bad_typ}; 
    }
    $self->echoMSG($msg, 1);
    return \%rpt;
}

=head3 update_records($dbh,$tab,$drf,$pk,$dft,$skn)

Input variables:

  $dbh - database handler
  $tab - target table name
  $drf - data array reference: ${$arf}[$i]{$col} or
         a source table.
  $pk  - primary key. Defaults to the first column or specified as
         my_id
         my_id:upper
         my_id=u_id
         my_id:lpad('0',?)=u_id:lpad('0',?)
  $dft - date format. Defaults to 'YYYYMMDD.HH24MISS'
  $skn - skip null: 1|0.
         1 - default to skip updating the column if the new value
             is null but the target column is not null.
         0 - update the column any way.

Variables used or routines called:

  echoMSG      - echo message
  is_object_exist  - check object existence
  get_table_definition  - get table definitions
  select_records - get table data 

How to use:

  my $cs  = 'usr/pwd@db';
  my $dbh = $self->getDBHandler($cs, "Oracle");
  my $drf = $self->select_records($dbh,$srctab,'*','','hash');
  my $tab = "test_table";
  $self->update_records($dbh,$tab,$drf); 

Return: None.

This method updates records in a data array ($drf) into a table if the
primary key does not exist in the table. Here are the steps involved
in this method: 
  1) Checks whether the table exists;
  2) Gets the table definition; 
  3) Get common column names in table and in the array;
  4) Gets a list of primary keys in the table;
  5) Loops through each records in the array;
  6) Updates records only if the primary key does exist in the table.

=cut

sub update_records {
    my $self = shift;
    my ($dbh,$tab,$drf,$pk,$dft,$skn) = @_;
    $self->echoMSG("\n  - updateing records for $tab ...");
    croak "ERR: no DB handler is specified.\n" if !$dbh;
    croak "ERR: no table name is specified.\n" if !$tab;
    croak "ERR: no data array is specified.\n" if !$drf;
    $dft = 'YYYYMMDD.HH24MISS' if !$dft;
    $skn = 1 if (!defined $skn || $skn !~ /^0$/); 
    if (!$self->is_object_exist($dbh,$tab,'table')) { 
        $self->echoMSG("WARN: table - $tab does not exist!");
        return 0;
    }
    $drf = $self->check_input_drf($drf,$dbh); 
    my ($cn1,$cn2,$dfa,$dfb,$df3,$cmt,$df4,$cns);
    ($cn2,$df3,$cmt)=$self->get_table_definition($dbh,$tab,'','hash');
    ($cn2,$df4,$cmt)=$self->get_table_definition($dbh,$tab,'','ah2');
        $cns = lc $cn2;
    my $cnt = 0;  
    my $ucn = "";       # columns will be updated
    my $cnx = "";       # columns will not be updated
    for my $k (split /,/, $cns) {
        if (! exists ${$drf}[0]{$k}) {  ++$cnt; 
            if ($cnx) { $cnx .= ",$k"; } else { $cnx = $k; }
        } else { 
            if ($ucn) { $ucn .= ",$k"; } else { $ucn = $k; }
        }
    }
    my $m1 = $self->split_cns("($ucn)",65,',',4); 
    my $msg  = "    columns \n  $m1     will be updated.\n"; 
       $msg .= "    $cnt columns will not be updated.";   
    $self->echoMSG("$msg",2)               if ($cnt); 
    my ($id1,$id2,$fn1,$fn2)= ("","","",""); 
    if ($pk && index($pk,'=')) {          # composite keys
        my ($s2,$s1) = ("",""); 
           ($s2,$s1) = split /=/, $pk;    # to_id=from_id
        ($id1,$fn1)  = split /:/, $s1 
            if $s1;                       # id:lpad('0',?)
        ($id2,$fn2)  = split /:/, $s2;    # id:function, ex: id:upper
    }
    $id2  = $pk if !$id2;                 # get id column
    ($id2) = ($cns =~ /^(\w+),/) if !$id2;# default to 1st column 
    $id1  = $id2 if !$id1; 
    if ($fn1) {      # user specified a function
        if (index($fn1, '?') < 0) { $fn1 = (uc $fn1) . "($id1)";
        } else { $fn1 =~ s/\?/$id1/g; }  
    }
    if ($fn2) {      # user specified a function
        if (index($fn2, '?') < 0) { $fn2 = (uc $fn2) . "($id2)";
        } else { $fn2 =~ s/\?/$id2/g; }  
    }
    # get a list of keys from target table
    my $kr = $self->select_records($dbh,$tab,$id2,'','array');
    my %key = ();
    for my $i (0..$#$kr) { $key{lc ${$kr}[$i][0]} = 1; }
    # get a list of keys from source data array
    my $idv = "";      # id value
    my $id1_lst = "";  # source id list
    my %ktm = ();
    for my $i (0..$#{$drf}) {
        $idv = ${$drf}[$i]{$id2};  
        next if exists $ktm{$idv};  
        $ktm{$idv} = 1; 
        $id1_lst .= $self->build_sql_stmt($id2,$idv,$df3,$dft,1); 
    }
    $id1_lst =~ s/,$//;    # remove the last comma 
    # get records matching with source keys from target table
    my $wh2 = "WHERE $id2 IN ($id1_lst)";  
print "WH2: $wh2<br>\n"; # XXX
    my $d2r = $self->select_records($dbh,$tab,'',$wh2,'lc_hash',
        $dft,$df4);
    # convert sequence based array into hash array with id as key
    my %d2 = ();       # target records
    for my $i (0..$#$d2r) {
        foreach my $k (keys %{${$d2r}[$i]}) { 
            my $ik = ${$d2r}[$i]{$id2};       # primary key
            my $cv = ${$d2r}[$i]{$k};         # column value 
            $d2{$ik}{$k} = $cv;   
        }
    }
    #
    # update records
    my $vnp = $ucn; $vnp =~ s/(\w+)/\?/g; 
    # my $q  = "UPDATE $tab SET\n   ($ucn) =\n";
    my $q  = "UPDATE $tab SET \n";
    my @a = (); $cnt = 0; 
    my ($err,$scc,$er2,$tcn) = (0,0,0,0);
    $msg  = "    looping through each record in array..."; 
    $self->echoMSG("$msg",2); 
    # $self->disp_param($drf); $self->disp_param(\%d2); 
    for my $i (0..$#{$drf}) {            # loop thru each record
        $idv = ${$drf}[$i]{$id2}; 
        if (! exists $key{$idv}) {  
            $msg = "    Key ($id2 = $idv) not in table $tab: skipped"; 
            $self->echoMSG($msg, 2); 
            next;
        }
        my $whr = " WHERE ";             # update condition
        if ($fn1) { $whr .= "$fn1 = "; } else { $whr .= "$id1 = "; } 
        if ($fn2) { $whr .= $fn2;      
        } else { 
            $whr .= $self->build_sql_stmt($id1,$idv,$df3,$dft); 
        } 
        # $self->echoMSG("FN1=$fn1;FN2=$fn2; WHR=$whr", 2);
        for my $k (split /,/, $ucn) {    # loop thru each updating col
            ++$tcn;
            my $v  = ${$drf}[$i]{$k};    # new value
               $v  = '' if (!defined $v || $v =~ /^null$/i); 
            my $v2 = $d2{$idv}{$k};      # value from target table 
            if ($skn && $v eq '' && defined($v2)) {  
                # When new value is null while target value is not, 
                # we are going to preserve the existing value.
                ++$er2;
                next; 
            }
            $v  = ""     if ! defined $v;
            $v2 = ""     if ! defined $v2;
            # print "V1=$v; V2=$v2\n"; 
            # compare the two value. If they are the same, there is 
            # no need to update the column 
            if (uc "$v" eq uc "$v2") {
                ++$scc;                  # skipped column count
                next;                    # no need to update
            } 
            $q  = "UPDATE $tab SET \n       $k = ";  
            $q .= $self->build_sql_stmt($k,$v,$df3,$dft,1); 
            $q =~ s/,$/\n/;                # remove last comma
            $q .= " $whr"; 
            $self->echoMSG("Q: $q", 2);
            my $s = $dbh->prepare($q) ||
                print  "ERR: Stmt - $dbh->errstr";
            if (!$s->execute()) { 
                ++$err; print "ERR: Stmt - $s->errstr"; 
            } 
        }
        ++$cnt; 
    }
    my $tot = $#{$drf}+1;
    $msg  = "    $cnt out of $tot rows updated with $err errors.\n";
    $msg .= "    $scc out of $tcn columns were skipped due to ";
    $msg .= "no change in values.\n";
    $msg .= "    $er2 columns have null value ";
    $msg .= "and updating was skipped.";
    $self->echoMSG($msg, 2);
    return 1;
}

=head2 Exported Tag: Misc

The I<:misc> tag includes all the miscellaneous methods or sub-rountines
defined in this class.

  use Oracle::DML qw(:misc);

=cut

1;

=head1 HISTORY

=over 4

=item * Version 0.10

This version is to test the concept.

=item * Version 0.2


=cut

=head1 SEE ALSO (some of docs that I check often)

Data::Describe, Oracle::Loader, Oracle::Trigger,
CGI::Getopt, File::Xcopy, Oracle::DDL, Oracle::DML, etc

=head1 AUTHOR

Copyright (c) 2005 Hanming Tu.  All rights reserved.

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut

