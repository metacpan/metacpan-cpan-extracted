package Oracle::SQL::Builder;

use strict;

# require Exporter;
# require DynaLoader;
# require AutoLoader;
use POSIX qw(strftime);
use Carp;
use warnings;
use DBI;
use Oracle::DML::Common qw(check_input_drf);


our @ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
our @EXPORT = qw(

);
our @EXPORT_OK = qw( 
    form_sql genWhere split_cns  run_sql 
    build_sql_stmt build_sql_value build_sql_operator build_sql_where
);
our %EXPORT_TAGS = ( 
    sql    => [qw(form_sql genWhere split_cns run_sql quote_keywords
              )],
    all    => [@EXPORT_OK],
);
our @IMPORT_OK   = qw(
    check_input_drf
    );

our $VERSION = '0.01';

# bootstrap Oracle::SQL::Builder $VERSION;

=head1 NAME

Oracle::SQL::Builder - Perl extension for building SQL statements.

=head1 SYNOPSIS

  use Oracle::SQL::Builder;

No automatically exported routines. You have to specifically to import
the methods into your package.

  use Oracle::SQL::Builder qw(:sql);
  use Oracle::SQL::Builder /:sql/;
  use Oracle::SQL::Builder ':sql';

=head1 DESCRIPTION

This is a package containing common sub routines that can be used in 
other programs. 

=cut

=head3 new (%arg)

Input variables:

  any input variable and value pairs 

Variables used or routines called:

  None

How to use:

   my $obj = new Oracle::SQL;      # or
   my $obj = Oracle::SQL->new;     # or

Return: new empty or initialized Oracle::SQL object.

=cut

sub new {
    my $caller        = shift;
    my $caller_is_obj = ref($caller);
    my $class         = $caller_is_obj || $caller;
    my $self          = bless {}, $class;
    my %arg           = @_;   # convert rest of inputs into hash array
    foreach my $k ( keys %arg ) { $self->{$k} = $arg{$k}; }
    return $self;
}

# -------------------------------------------------------------------

=head2 Export Tag: sql    

The I<:table> tag includes sub-rountines for accessing Orable tables.

  use Oracle::SQL::Builder qw(:sql);

It includes the following sub-routines:

=cut

=head3 build_sql_stmt($idn,$idv,$hrf,$dft,$acm)

Input variables:

  $idn - id/key name
  $idv - id/key value
  $hrf - hash ref with column definition. It is from
         getTableDef method
  $dft - date format. Default to 'YYYYMMDD.HH24MISS'
  $acm - add comma. If $acm = 1, then add a comma in 
         the end.

Variables used or routines called:

  fmtTime      - get current time

How to use:

  my $cs  = 'usr/pwd@db';
  my $dbh = $self->getDBHandler($cs, "Oracle");
  my $tab = "test_table";
  my ($cns,$cd1,$hrf) = $self->getTableDef($dbh,$tab,'*','hash');
  my $dft = 'YYYYMMDD.HH24MISS'; 
  my $v   = $self->build_sql_stmt('dept',10,$hrf,$dft); 

Return: value string to be used in SQL statement.

Any undef or 'null' value of $idv will be translated to '' for 
insert_records method and 'null' for update_records so that the
DBI can handle correctly.

=cut

sub build_sql_stmt {
    my $self = (ref $_[0]) ? shift : Oracle::SQL->new(@_);
    my ($idn,$idv,$hrf,$dft,$acm) = @_;
    # Input variables:
    #   $idn - id/key name
    #   $idv - id/key value
    #   $hrf - hash ref with column definition. It is from
    #          getTableDef method
    #   $dft - date format. Default to 'YYYYMMDD.HH24MISS'
    #
    carp "WARN: no input for id/key name in build_sql_stmt.\n" 
        if !$idn; 
    $idn = lc $idn; 
    $acm = 0 if !$acm;
    my $s = "";                           # return string
    my $v = $idv;                         # id value 
    my $ddn1 = 'rec_crt_dt';              # small initial date
    my $ddn2 = 'rec_upd_dt|last_update_dt|start_dt'; # current date
    my ($pkg,$file,$line,$sub) = caller(1);
    $sub =~ s/.*:://g;                    # remove class names
    if (!defined($v) || $v =~ /^null$/i) {  
        $v = 'null';                      # assign empty (= null)  
        if (${$hrf}{$idn}{req} =~ /^not null/i) { 
            $self->echoMSG("    Null in required col $idn", 5); 
        } 
    } 
    my $typ = ${$hrf}{$idn}{typ}; 
    my $req = ${$hrf}{$idn}{req};
    if ($typ =~ /^DATE/i) {               # date datatype
        my $dtv = $v;                     # date value
           $dtv = '' if $v eq 'null'; 
        if ($v eq 'null' && $req =~ /^not null/i) { 
            # datetime in SQL server: 1/1/1753 ~ 12/31/9999
            if ($idn =~ /^($ddn1)/i) {
                $dtv = '19980101.000000'; 
            } elsif ($idn =~ /^($ddn2)/i) {
                $dtv =  $self->fmtTime; 
            } else {
                $dtv = '17530101.000000'; 
            }
        }
        if ($sub =~ /^(insert_)/i) {    # called by insert_records sub
            $s .= $dtv;                 # no to_date function 
        } else {                        # called by update_records sub
            $s .= "TO_DATE('$dtv','$dft')"; 
        }
    } elsif ($typ =~ /^(V|C)/i) {
        $v =~ s/'/''/gm if $v;          # escape the quote (') 
        if ($sub =~ /^(insert_)/i) {    # called by insert_records sub
            # if ($v eq 'null') { $s .= ''; } else { $s .= "'$v'"; } 
            if ($v eq 'null') { $s .= ''; } else { $s .= "$v"; } 
        } elsif ($sub =~ /^(update_)/i) { # called by update_records sub
            if ($v eq 'null') { $s .= $v; } else { $s .= "'$v'"; } 
        } else {
            # if ($v eq 'null') { $s .= $v; } else { $s .= "'$v'"; } 
            if ($v eq 'null') { $s .= $v; } else { $s .= "$v"; } 
        }
    } else {                            # numeric datatype 
        if ($sub =~ /^(insert_)/i) {    # called by insert_records sub
            if ($v eq 'null') { $s .= ''; } else { $s .= $v; } 
        } elsif ($idn =~ /^(rowid)/i) {
            $s .= "'$v'"; 
        } else {
            $s .= $v; 
        }
    }
    $s = "$s,"      if $acm;
    $self->echoMSG("$idn=$v; TYP=$typ; REQ=$req: $s<br>\n", 5); 
    return $s;
}

=head3 build_sql_value($k,$v,$ar,$dft,$act)

Input variables:

  $k   - column name
  $v   - column value 
  $ar  - hash ref for column definition: ${$ar}{$k}{$itm}. 
         It is from getTableDef with 'hash' type. 
  $dft - date format. 
         Default to 'YYYYMMDD.HH24MISS'? - not sure that we need
         to do that. 
         It checks the dft in $ar for $k first;
         If not, then call id_datetime_format to get a format
         If not, then return undef.
  $act - action: update|insert

Variables used or routines called:

  id_datetime_format - get date and time format based on
          the date and time value provided.

How to use:

  my $cs  = 'usr/pwd@db';
  my $dbh = $self->getDBHandler($cs, "Oracle");
  my $tab = "test_table";
  my ($cns,$cd1,$ar) = $self->getTableDef($dbh,$tab,'*','hash');
  my $dft = 'YYYYMMDD.HH24MISS'; 
  my $v   = $self->build_sql_value('dept',10,$ar,$dft); 

Return: undef or value string to be used in SQL statement.

  undef  - value string can not be determined if no $k. 
           Do not use the column in your SQL statement.
  'NULL' - null if $v is not defined and $v is not required.
  "''"   - empty string if $v is not defined and data type is CHAR
          or VARCHAR and NOT NULL. 
  str    - any value string: number or quoted string

This method returns the value with proper quotes and format string. 
For date datatype, it gets date and time format and use it in the 
TO_DATE function. If the $dft is provided or defined in the $ar for
the column, then it convert the $v to the same format as defined in 
$dft if the $v has different date and time format.

=cut

sub build_sql_value {
    my $s = (ref $_[0]) ? shift : Oracle::SQL->new(@_);
    my ($k, $v, $ar, $dft, $act) = @_;
    return undef if !$k;
    my $typ = ${$ar}{$k}{typ};
    my $req = ${$ar}{$k}{req};
       $dft = ${$ar}{$k}{dft} if !$dft;
       $act = "update" if ! $act; 
    $v =~ s/^["']+//; $v =~ s/["']+$//;  # remove quotes
    my $msg = "";
    return 'NULL' if (!defined($v) && $req =~ /^null/i); 
    return "''"   if (!defined($v) && $req =~ /^not/i && 
        $typ =~ /^(V|C)/i); 
    return undef if (!defined($v) || 
        ($v =~ /^null$/i && $req =~ /^null/i)); 
    if ($typ =~ /^(V|C)/i && $v && index($v,"'") > -1) { 
        # escape the quote (') 
        $v =~ s/'/''/gm; 
    }
    return "'$v'" if (index($v,'?') > -1 || index($v,'%') > -1); 
    # remove quotes and leading and trailing spaces
    $v =~ s/^['"\s]+//; $v =~ s/['"\s]+$//;
    my $rst = undef; 
    if ($typ =~ /^N/i)      {   # numeric
        # return 'NULL' if ($v eq "");
        if ($v eq "" || !defined($v)) {
            return undef;
        } elsif ($v && $v =~ /^(blank|null)/i) { 
            return "NULL"; 
        } else { 
            return $v+0;
        }
    } elsif ($typ =~ /^D/i) {   # date
        # return undef if the $v less than the shortest format
        return $rst if (length($v) < 6);  # YYMMDD
        my $df = $s->id_datetime_format($v); 
        # print "$k|$v|$dft|$df\n"; 
        # return undef if we could not determine a format for $v
        return $rst if (!$dft && !$df);   
        if ($act =~ /^insert/i) {
            $rst = "'$v'"; 
        } else {
            $rst = "TO_DATE('$v', '$df')"; 
        }
        # if no $dft but we have $df, then use $df
        return $rst if (!$dft && $df); 
        # if we have $dft which equals $df, we use $df
        return $rst if ($dft && $dft eq $df); 
        if ($dft && $df && $dft ne $df) {
            # we need to convert $v from $df to $dft
            # then use $dft
            my $itp = $s->TimeFormat("$df", 'ora');
            my $otp = $s->TimeFormat("$dft",'ora'); 
            $msg = "$df($itp):$dft($otp):$v:";  
            $v = $s->cvtTime($v, $itp, $otp); 
            $msg .= "$v\n";  
            $s->echoMSG("    $msg",9); 
            if ($act =~ /^insert/i) {
                return "'$v'"; 
            } else { 
                return "TO_DATE('$v','$dft')"; 
            }
        } 
        return undef;
    } else {
        return 'NULL'   if ($v =~ /^null$/i);
        return "''"     if ($v =~ /^blank$/i); 
        return "'$v'";
    }
}

=head3 build_sql_operator($k,$v,$ar)

Input variables:

  $k   - column name
  $v   - column value 
  $ar  - hash ref for column definition: ${$ar}{$k}{$itm}. 
         It is from getTableDef with 'hash' type. 

Variables used or routines called:

  None

How to use:

  my $cs  = 'usr/pwd@db';
  my $dbh = $self->getDBHandler($cs, "Oracle");
  my $tab = "test_table";
  my ($cns,$cd1,$ar) = $self->getTableDef($dbh,$tab,'*','hash');
  my $v   = $self->build_sql_operator('dept',10,$ar); 

Return: SQL operator to be used in SQL statement.

  undef  - could not determine operator based on the inputs
           Do not use the column in your SQL statement.
  'LIKE' - match string with wild characters in $v. 
  'IN'   - $v contains a list of values of string or number 
           separated by comma.
  '='    - any number or quote strings 

This method returns SQL operator based on column data type and 
the value in $v.

=cut

sub build_sql_operator {
    my $s = (ref $_[0]) ? shift : Oracle::SQL->new(@_);
    my ($k, $v, $ar, $dft) = @_;
    return undef if !$k || ! defined($v);
    my $typ = ${$ar}{$k}{typ};
    return 'LIKE' if (${$ar}{$k}{typ} =~ /^(C|V)/i &&
        $v =~ /(\%|\?)/); 
    return 'IN'      if ((${$ar}{$k}{typ} =~ /^(C|V)/i &&
        $v =~ /','/) ||  (${$ar}{$k}{typ} =~ /^(N)/i && 
        $v =~ /,/));
    return '='; 
}

=head3 build_sql_where($str,$ar,$dft)

Input variables:

  $str - a string with k1=v1,k2=v2,...
  $ar  - hash ref for column definition: ${$ar}{$k}{$itm}. 
         It is from get_table_definition with 'hash' type. 
  $dft - date format. 
         Default to 'YYYYMMDD.HH24MISS'? - not sure that we need
         to do that. 
         It checks the dft in $ar for $k first;
         If not, then call id_datetime_format to get a format
         If not, then return undef.

Variables used or routines called:

  None

How to use:

  my $cs  = 'usr/pwd@db';
  my $dbh = $self->getDBHandler($cs, "Oracle");
  my $tab = "test_table";
  my ($cns,$cd1,$ar) = $self->getTableDef($dbh,$tab,'*','hash');
  my $s = "id=1,ln=tu,fn=han"; 
  my $whr = $self->build_sql_where($s,$ar,$dft); 

Return: SQL WHERE clause

=cut

sub build_sql_where {
    my $s = (ref $_[0]) ? shift : Oracle::SQL->new(@_);
    my ($str,$ar, $dft) = @_;
    return undef if !$str || !defined($str);
    my @b = split /,/, $str; 
    my $whr = "";
    my $sub_name = "Build_SQL_Where"; 
    my ($k, $v, $op); 
    for my $x (0..$#b) {
        ($k,$v) = (split /=/, $b[$x]);
        $k = lc $k;
        # remove leading and trailing spaces
        $k =~ s/^\s+//; $k =~ s/\s+$//;
        if (! exists ${$ar}{$k}) {
            $s->echoMSG("    $sub_name: Column $k does not exist.");
            next;
        }
        $v  = $s->build_sql_value($k,$v,$ar,$dft);
        $op = $s->build_sql_operator($k,$v,$ar,$dft); 
        next if ! defined($v);
        if ($whr) {
            $whr .= "       AND $k $op $v\n";
        } else {
            $whr  = " WHERE $k $op $v\n"; 
        }
    }
    return $whr; 
}

=head3 form_sql($dbh,$arf,$rtp)

Input variables:

  $dbh - database handler
  $arf - input array ref. It has the following elements: 
    act - SQL action such as SELECT, UPDATE, DELETE, etc.
    tab - target table or view name
    cns - column names separated by comma
    where - condition array reference: ${$ar}[$i]{$itm}
         $i is condition index number
         $itm are: 
         cn - column name
         op - operator such as =, <, >, in, lk, etc
         cv - value, or values separated by comma
         so - set operator such as AND or OR
    group_by - a list of columns separated by comma
    order_by - a list of columns separated by comma
    data - data array reference ${$ar}{$cn} 
    dft - date format
    rwd - right column width for formating sql statement
  $rtp - return type: default - SQL statement string
    where    - just where clause
    hash     - hash array. It has
        table - table name
        cns  - column specification such as '*' or column names
        columns - column names. If '*', then all the column names.
        select/update/delete - actions
        from  - from a table
        where - where clause
        group_by - group by clause
        order_by - order by clause
        sql   - full SQL statement
    hash_ref - hash array reference pointing to the above hash
    sql      - the whole SQL statement  

Variables used or routines called:

  echoMSG      - echo message
  isObjExist   - check object existence
  getTableDef  - get table definitions
  getTableData - get table data 

How to use:

  my $cs  = 'usr/pwd@db';
  my $dbh = $self->getDBHandler($cs, "Oracle");
  my $drf = $self->getTableData($dbh,$srctab,'*','','hash');
  my $arf = bless {}, ref($self)||$self;
     ${$arf}{act} = 'SELECT';
     ${$arf}{tab} = 'test_tab';
     ${$arf}{cns} = 'id,name'; 
     ${$arf}{data} = $drf; 
  my $tab = "test_table";
  $self->form_sql($dbh,$arf); 

Return: string, hash, hash ref based on return type.

=cut

sub form_sql {
    my $self = (ref $_[0]) ? shift : Oracle::SQL->new(@_);
    my ($dbh,$arf,$rtp) = @_;
    croak "ERR: no DB handler is specified.\n" if !$dbh;
    croak "ERR: action or table is specified.\n" if !$arf;
    my ($act,$tab,$cns,$mrc,$dft,$rwd) = ("","","","","","");
    $act = ${$arf}{act}        if exists ${$arf}{act}; 
    $act = 'SELECT'            if !$act; 
    $act = uc $act;                                     # DML 
    $tab = ${$arf}{tab}        if exists ${$arf}{tab};  # table name
    $dft = ${$arf}{dft}        if exists ${$arf}{dft};  # date format
    $dft = 'YYYYMMDD.HH24MISS' if !$dft; 
    $rwd = ${$arf}{rwd}        if exists ${$arf}{rwd};  # right col wid
    $rwd = 65                  if !$rwd;
    croak "ERR: no table name is specified.\n" if !$tab;
    $self->echoMSG("  - generating $act statement for $tab...");
    if (!$self->isObjExist($dbh,$tab,'table') &&
        !$self->isObjExist($dbh,$tab,'view') ) { 
        $self->echoMSG("WARN: table or view - $tab does not exist!");
        return 0;
    }
    $cns = ${$arf}{cns} if exists ${$arf}{cns};      # column name
    $cns = '*' if !$cns; 
    $mrc = 500;                  # max # records to be retrieved
    my ($wrf,$gpb,$odb) = ("","",""); 
    $wrf = ${$arf}{where} if exists ${$arf}{where}; 
    $gpb = ${$arf}{group_by} if exists ${$arf}{group_by}; 
    $odb = ${$arf}{order_by} if exists ${$arf}{order_by}; 
    # get column definition:
    #   $cn1 - columns separated by comma
    #   $dfa - array ref: ${$df1}[$i][$j]
    #   $dfb - hash ref : ${$df2}{$cn}{$itm} 
    my ($cn1,$dfa, $dfb) = $self->getTableDef($dbh,$tab,'','hash');
    my $n1 = 10;       #  left column width
    my $n2 = $rwd;     # right column width
    my $fmt = "%${n1}s %-${n2}s\n"; 
       $cns = lc $cns; 
    my @cln = $self->split_cns($cns, $n2); 
    my ($sql,$t,$whr,$grp,$ord) = ("","","","",""); 
    my ($so,$cn,$op,$cv,@a,@b,$k);
    my %rst = (table=>$tab, columns=>$cn1, cns=>$cns);
    if ($act =~ /^SEL/i) {
        if ($#cln==0)  {
            $sql = sprintf $fmt, $act, $cln[0]; 
        } else {
            $sql = sprintf $fmt, $act, "$cln[0],"; 
            foreach my $i (1..$#cln) {
                if ($i==$#cln) { 
                    $sql .= sprintf $fmt, "", "$cln[$i]"; 
                } else {
                    $sql .= sprintf $fmt, "", "$cln[$i],"; 
                }
            }
        }
        $rst{select} = $sql; 
        $sql .= sprintf $fmt, 'FROM', $tab; 
        $rst{from} = sprintf $fmt, 'FROM', $tab; 
    } elsif ($act =~ /^(UPD|INS)/i) {
        my $drf = ${$arf}{data}; 
        $sql = sprintf $fmt, 'INSERT INTO', "$tab"; 
        my $ito = sprintf $fmt, 'INSERT INTO', "$tab"; 
        $cns = lc $cn1 if (!$cns || $cns =~ /^\*/); 
        @a = $self->split_cns($cns, $n2); 
        foreach my $i (0..$#a) {
            if ($i==0) { 
                if ($i==$#a) {
                    $sql .= sprintf $fmt, '', "($a[$i])"; 
                    $ito .= sprintf $fmt, '', "($a[$i])"; 
                    next;
                } else { 
                    $sql .= sprintf $fmt, '', "($a[$i],"; 
                    $ito .= sprintf $fmt, '', "($a[$i],"; 
                }
            } elsif ($i==$#a) {  
                $sql .= sprintf $fmt, "", "$a[$i])"; 
                $ito .= sprintf $fmt, "", "$a[$i])"; 
            } else {
                $sql .= sprintf $fmt, "", "$a[$i],"; 
                $ito .= sprintf $fmt, "", "$a[$i],"; 
            }
        }
        $rst{insert_into} = $ito; 
        my ($v, $p, $vnp) = ("","",""); 
        @a = split /,/, $cns; 
        @b = (); 
        for my $i (0..$#a) {
            $k = $a[$i]; 
            $v = ${$drf}{$k}; 
            if (!$v || $v =~ /^null/i) { 
                $p = "null"; 
            } elsif (${$dfb}{$k}{typ} =~ /^DATE/i) {
                $p = "to_date('$v','$dft')"; 
            } elsif (${$dfb}{$k}{typ} =~ /^(V|C)/i) {
                $v =~ s/'/''/gm;     # escape quotes
                $p = "'$v'"; 
            } else { $p = "$v"; }
            if ($vnp && length("$vnp,$p") > $n2) { 
                push @b, $vnp; $vnp = ""; 
            }
            if ($vnp) { $vnp .= ",$p"; } else { $vnp = "$p"; };
        }
        if ($vnp) { push @b, $vnp; $vnp = ""; }
        my $vls = "";
        if ($#b==0) { 
            $sql .= sprintf $fmt, 'VALUES', "($b[0])"; 
            $vls .= sprintf $fmt, 'VALUES', "($b[0])"; 
        } else { 
            $sql .= sprintf $fmt, 'VALUES', "($b[0],"; 
            $vls .= sprintf $fmt, 'VALUES', "($b[0],"; 
            foreach my $j (1..$#b) {
                if ($j==$#b) { 
                    $sql .= sprintf $fmt, "", "$b[$j])"; 
                    $vls .= sprintf $fmt, "", "$b[$j])"; 
                } else { 
                    $sql .= sprintf $fmt, "", "$b[$j],"; 
                    $vls .= sprintf $fmt, "", "$b[$j],"; 
                }
            }
        }
        $rst{values} = $vls; 
    } elsif ($act =~ /^DEL/i) {
    } else {                      # Insert
    }
    if ($wrf) {    # where clause
        for my $i (0..$#{$wrf}) {      # each condition
            $so = ${$wrf}[$i]{so};     # set operator
            $cn = ${$wrf}[$i]{cn};     # column name
            $op = ${$wrf}[$i]{op};     # operator   
            $cv = ${$wrf}[$i]{cv};     # column value 
            $t  = $self->genWhere($so,$cn,$op,$cv,$dfb,$dft);
            # print "SO:$so CN:$cn OP:$op CV:$cv\n";    # XXX
            # print "T: $t\n"; 
            @a  = $self->split_cns($t, $n2, ' ');
            $k = 0; 
            if ($i == 0) {
                $whr  = sprintf $fmt, "WHERE", $a[0]; 
                $sql .= $whr; 
                $k = 1; 
            }
            foreach my $j ($k..$#a) {
                $sql .= sprintf $fmt, "", $a[$j]; 
                $whr .= sprintf $fmt, "", $a[$j]; 
            }
        }
        $rst{where} = $whr; 
    }
    if ($gpb) {    # group by
        @a  = $self->split_cns($gpb, $n2);
        $grp  = sprintf $fmt, 'GROUP BY', $a[0]; 
        $sql .= $grp; 
        foreach my $i (1..$#a) {
           $grp .= sprintf $fmt, "", $a[$i]; 
           $sql .= sprintf $fmt, "", $a[$i]; 
        }
        $rst{group_by} = $grp; 
    }
    if ($odb) {    # order by
        @a  = $self->split_cns($odb, $n2);
        $ord  = sprintf $fmt, 'ORDER BY', $a[0]; 
        $sql .= $ord; 
        foreach my $i (1..$#a) {
           $ord .= sprintf $fmt, "", $a[$i]; 
           $sql .= sprintf $fmt, "", $a[$i]; 
        }
        $rst{order_by} = $ord; 
    }
    $sql =~ s/\s*$//gm; 
    return $whr  if (!$rtp || $rtp =~ /^where/i);
    return $sql  if (!$rtp || $rtp =~ /^sql/i);
    $rst{sql} = $sql;
    return \%rst if ($rtp  && $rtp =~ /^hash_ref/i);
    return %rst  if ($rtp  && $rtp =~ /^hash/i);
}

=head3 split_cns($str,$len,$chr,$nbk)

Input variables:

  $str - string with words or column names separated by comma
         or by spliting character
  $len - length allow in a line, default to 65 
  $chr - spliting character, default to comma
  $nbk - number of blank space in from of each line. 
         If this is set, it will return a string with line breaks.

Variables used or routines called:

  None 

How to use:

  my $cs  = 'col1, col2, col3, this, is, a multiple,line'; 
  my @a   = $self->split_cns($cs,10);

Return: array with lines within length limit or a string. 

=cut

sub split_cns {
    my $self = (ref $_[0]) ? shift : Oracle::SQL->new(@_);
    my ($str, $len, $sep, $nbk) = @_;
    $sep = ',' if !$sep; 
    $nbk = 0   if !$nbk;
    # $str =~ s/^["']+//; $str =~ s/["']+$//;
    my @r = (); 
    if (length($str) <= $len) { push @r, $str; 
        return @r if !$nbk; 
        return (' ' x $nbk) . "$str\n";
    } 
    # we have multiple lines
    my $line = "";
    foreach my $i (split /$sep/, $str) {    # split it into words 
        $i = uc "\"$i\""; 
        if (length("$line$sep$i") > $len) { 
            push @r, $line; $line = ""; 
        }
        if ($line) { $line .= "$sep$i"; } else { $line = $i; }  
    }
    push @r, $line if $line; 
    return @r if !$nbk; 
    my $s = ""; 
    for my $i (0..$#r) { 
        next if !$r[$i]; 
        if ($i==$#r) {
            $s .= (' ' x $nbk) . "$r[$i]\n";
        } else { 
            $s .= (' ' x $nbk) . "$r[$i],\n";
        }
    }
    return $s; 
}


=head3 genWhere($so,$cn,$op,$cv,$ar,$dft)

Input variables:

    $so  - set operator: AND, OR
    $cn  - column name
    $op  - operator: =, <=, >=, <>, lk, btw, in, nn, nl, etc.
    $cv  - column value
    $ar  - hash array ref: ${$ar}{$cn}{$itm}.
           $itm: col, typ, wid, max. dec, req, min, dft, and dsp
    $dft - date format
Variables used or routines called:

  None 

How to use:

  my $whr = $self->build_where('','id','=',1); 
     $whr .= $self->build_where('Or','name','lk','A'); 

Return: string - where clause. 

=cut

sub genWhere {
    my $self = (ref $_[0]) ? shift : Oracle::SQL->new(@_);
    my ($so,$cn,$op,$cv,$ar,$dft) = @_;
    # Input variables:
    #   $so  - set operator: AND, OR
    #   $cn  - column name
    #   $op  - operator: =, <=, >=, <>, lk, btw, in, nn, nl, etc.
    #   $cv  - column value
    #   $ar  - hash array ref: ${$ar}{$cn}{$itm}.
    #          $itm: col, typ, wid, max. dec, req, min, dft, and dsp
    #
    my $r = "";
    return $r if ($cn =~ /^_/);
    return $r if (!$cn && !$op);
    return $r if ($cv =~ /^\s*$/); 
    $cn = lc($cn);
    my (@a);
    my %opt=('eq'=>'=',        'le'=>'<=',     'ge'=>'>=',
             'ne'=>'<>',       'gt'=>'>',      'lt'=>'<',
             'in'=>'in',       'lk'=>'like',   'btw'=>'between',
             'nn'=>'not null', 'nl'=>'is null'
           );
    my $ct = "";                     # column type
       $ct = ${$ar}{$cn}{typ} if exists ${$ar}{$cn}{typ}; 
       $ct = 'Number' if $cn =~ /^(rownum)/i; 
    $dft = "YYYYMMDD.H24MISS" if !$dft; 
    $dft = "'$dft'";                 # add quotes
    if ($op && $op eq 'lk') {
        # if user uses '*' as wildcard
        $cv =~ s/\*/\%/;             # change '*' to '%'
        # if user did not provide any wildcard, we add one
        if (index($cv, '%') < 0) { $cv .= '%'; }
    }
    # $so = 'AND' if ! $so; 
    my $msg = "SO:$so CN:$cn OP:$op CV:$cv DF:$dft\n";
    $self->echoMSG($msg, 5); 
    my ($t); 
    if ($so) { $r .= uc($so) . " "; }
    $r .= "$cn " .  uc($opt{$op}) . " ";         # column op 
    if (uc($op) eq 'BTW') {
        @a = split /,\s*/, $cv;
        if ($ct =~ /^N/i) {                      # Number
            $r .= "$a[0] AND $a[1]";
        } elsif ($ct =~ /^D/i) {                 # Date
            $r .= "to_date('$a[0]',$dft) AND";
            $r .= "to_date('$a[1]',$dft) ";
        } else {                                 # CHAR or VARCHAR
            $r .= "'$a[0]' AND '$a[1]' ";
        }
    } elsif (uc($op) eq 'IN') {
        if ($ct =~ /^N/i) {                      # Number
            $r .= "($cv) ";
        } elsif ($ct =~ /^D/i) {                 # Date
            @a = split /,\s*/, $cv;
            $t = ""; 
            foreach my $i (@a) { 
                if ($t) { $t .= ",to_date('$i',$dft)"; 
                } else  { $t  =  "to_date('$i',$dft)"; }  
             }
            $r .= "($t) ";
        } else {                                 # CHAR or VARCHAR
            $cv =~ s/,\s*/','/g;
            $r .= "('$cv') ";
        }
    } else {
        if ($ct =~ /^N/i) {                      # Number
            $r .= "$cv ";
        } elsif ($ct =~ /^D/i) {                 # Date
            $r .= "to_date('$cv',$dft) ";
        } else {                                 # CHAR or VARCHAR
            $r .= "'$cv' ";
        }
    }
    # print "$r\n";
    return $r;
}

=head3 run_sql($dbh,$sfn)

Input variables:

    $dbh - datebase handler or connection string 
           usr/pwd@db: for Oracle 
    $sfn - sql file name with full path 
    $hmd - home directory 

Variables used or routines called:

  None 

How to use:

  my $dbh = $self-?getDBHandler('usr/pwd@db'); 
  my $sfn = '/my/dir/sqls/crt1.sql'; 
     $self->run_sql($dbh, $sfn); 

Return: the following status codes:

  0 - ok; 
  1 - no DB handler
  2 - inproper inputs
  3 - sql not found

=cut

sub run_sql {
    my $s = shift;
    my ($dbh,$sfn,$hmd) = @_;
    # check input variables
    return 1 if ! $dbh; 
    return 2 if ! $sfn; 
    return 3 if ! -f $sfn; 
    my ($q,$e,@a,$m,$cmd,$cns,$dbt); 
    my $ds = '/'; 
    if ($dbh =~ /([-\w_]+)\/(\w+)\@(\w+)/) {
        $dbt = 'Oracle'; 
        $cns = $dbh; 
    } elsif ($dbh =~ /^(DBI::db)/i) {    # DBI::db=HASH(0x649178)
        $cns = $1; 
        $dbt = $dbh->{Driver}->{Name}; 
    } elsif ($dbh =~ /^(Win32::ODBC)/i) { # Win32::ODBC=HASH(0x17cadc8)
        $cns = $1; 
        $dbt = 'ODBC'; 
    } else {
        $dbt = 'CSV';
        $cns = ''; 
    }
    if ($dbt =~ /^oracle/i) {
        $hmd = $ENV{ORACLE_HOME} if ! $hmd && exists $ENV{ORACLE_HOME}; 
        # $q = "BEGIN\n@a\nEND;\n"; 
        # $e = $dbh->prepare($q); 
        # $e->execute() or croak "ERR: could not execute: $e->errstr";
        # print $q; 
        $cmd = join $ds, $hmd, "bin", "sqlplus";
        # $cmd .= " -s $cns \@$sfn ";
        $cmd .= " $cns \@$sfn ";
        $m=$cmd;
        $m =~ s{(\w+)/(\w+)\@}{$1/\*\*\*\@};
        $m =~ s{( \@)}{\n        $1}g;
        $s->echoMSG("    CMD: $m\n",2);
        open CMD, "$cmd |" or croak "Could not run sqlplus: $!\n";
        @a = <CMD>;
        close CMD;
        $s->echoMSG("@a", 5); 
    } else {
        # open FH, "<$sfn" or croak "ERR: open - $sfn: $!\n"; 
        # my @a = <FH>;
        # close FH; 
    }
    return 0;
}

=head1 AUTHOR

Hanming Tu, hanming_tu@yahoo.com

=head1 SEE ALSO (some of docs that I check often)

Oracle::Trigger, Oracle:DDL, Oracle::DML, Oracle::DML::Common,
Oracle::Loader, etc.


=cut

