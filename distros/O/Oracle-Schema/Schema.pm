package Oracle::Schema;

# Perl standard modules
use strict;
use warnings;
use Carp;
use DBI;
use Debug::EchoMessage;
use Oracle::DML::Common qw(:db_conn);

require 5.003;
$Oracle::Schema::VERSION = 0.02;

require Exporter;
our @ISA         = qw(Exporter);
our @EXPORT      = qw();
our @EXPORT_OK   = qw( get_table_definition
    );
our %EXPORT_TAGS = (
    all   => [@EXPORT_OK],
    table => [qw(get_table_definition)],
    );
our @IMPORT_OK   = qw(
    get_dbh is_object_exist 
    debug echoMSG disp_param
    );

=head1 NAME

Oracle::Schema - Perl class for Oracle Schema Information and 
Management

=head1 SYNOPSIS

  use Oracle::Schema;

  my %cfg = ('conn_string'=>'usr/pwd@db');
  my $os = Oracle::Schema->new;
  # or combine the two together
  my $os = Oracle::Schema->new('cs'=>'usr/pwd@db');
  $os->display_objects; 


=head1 DESCRIPTION

This class includes methods to query (find, retrieve, and
compare) objects in an Oracle schema and to manage (create, drop,
update, merge, and move) Oracle objects.

=cut

=head2 new (cs=>'usr/pwd@db',tn=>'my_table')

Input variables:

  $cs  - Oracle connection string in usr/pwd@db
  $tn  - Oracle table name without schema

Variables used or routines called:

  None

How to use:

   my $obj = new Oracle::Schema;      # or
   my $obj = Oracle::Schema->new;     # or
   my $cs  = 'usr/pwd@db';
   my $tn  = 'my_table'; 
   my $obj = Oracle::Schema->new(cs=>$cs,tn=>$tn); # or
   my $obj = Oracle::Schema->new('cs',$cs, 'tn',$tn); 

Return: new empty or initialized Oracle::Schema object.

This method constructs a Perl object and capture any parameters if
specified. It creates and defaults the following variables:
 
  $self->{conn_string} = "";       # or $self->{cs}
  $self->{table_name}  = "";       # or $self->{tn}  

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
    my $vs = 'conn_string,table_name,cs,tn';
    foreach my $k (split /,/, $vs) {
        $self->{$k} = ""        if ! exists $arg{$k};
        $self->{$k} = $arg{$k}  if   exists $arg{$k};
    }
    my $cs1 = $self->{conn_string};
    my $tn1 = $self->{table_name};
    $self->{cs} = ($cs1)?$cs1:$self->{cs};
    $self->{tn} = ($tn1)?$tn1:$self->{tn};
    $self->{conn_string} = ($self->{cs})?$self->{cs}:$cs1;
    $self->{table_name}  = ($self->{tn})?$self->{tn}:$tn1;
    return $self;
}

=head1 METHODS

The following are the common methods, routines, and functions 
defined in this class.

=head2 Exported Tag: All 

The I<:all> tag includes all the methods or sub-rountines 
defined in this class. 

  use Oracle::Schema qw(:all);

It includes the following sub-routines:

=head2 Table Methods

The I<:table> tag includes sub-rountines for creating, checking and
manipulating tables.

  use Oracle::DML::Common qw(:table);

It includes the following sub-routines:

=head3 get_table_definition($dbh,$tn,$cns,$otp)

Input variables:

  $dbh - database handler, required.
  $tn  - table/object name, required.
         schema.table_name is allowed.
  $cns - column names separated by comma.
         Default is null, i.e., to get all the columns.
         If specified, only get definition for those specified.
  $otp - output array type:
         AR|ARRAY        - returns ($cns,$df1,$cmt)
         AH1|ARRAY_HASH1 - returns ($cns,$df2,$cmt)
         HH|HASH         - returns ($cns,$df3,$cmt)
         AH2|ARRAY_HASH2 - returns ($cns,$df4,$cmt)

Variables used or routines called:

  echoMSG - display messages.

How to use:

  ($cns,$df1,$cmt) = $self->getTableDef($dbh,$table_name,'','array');
  ($cns,$df2,$cmt) = $self->getTableDef($dbh,$table_name,'','ah1');
  ($cns,$df3,$cmt) = $self->getTableDef($dbh,$table_name,'','hash');
  ($cns,$df4,$cmt) = $self->getTableDef($dbh,$table_name,'','ah2');

Return:

  $cns - a list of column names separated by comma.
  $df1 - column definiton array ref in [$seq][$cnn].
    where $seq is column sequence number, $cnn is array
    index number corresponding to column names:
          0 - cname,
          1 - coltype,
          2 - width,
          3 - scale,
          4 - precision,
          5 - nulls,
          6 - colno,
          7 - character_set_name.
  $df2 - column definiton array ref in [$seq]{$itm}.
    where $seq is column number (colno) and $itm are:
          col - column name
          seq - column sequence number
          typ - column data type
          wid - column width
          max - max width
          min - min width
          dec - number of decimals
          req - requirement: null or not null
          dft - date format
          dsp - description or comments
  $df3 - {$cn}{$itm} when $otp = 'HASH'
    where $cn is column name in lower case and
          $itm are the same as the above
  $df4 - [$seq]{$itm} when $otp = 'AH2'
    where $seq is the column number, and $itm are:
          cname     - column name (col)
          coltype   - column data type (typ)
          width     - column width (wid)
          scale     - column scale (dec)
          precision - column precision (wid for N)
          nulls     - null or not null (req)
          colno     - column sequence number (seq)
          character_set_name - character set name
  $cmt - {$cn}: contains comments for each column 

=cut

sub get_table_definition {
    my $self = shift;
    my($dbh, $tn, $cns, $otp) = @_;
    # Input variables:
    #   $dbh - database handler
    #   $tn  - table name
    #   $cns - column names
    #
    # 0. check inputs
    croak "ERR: could not find database handler.\n" if !$dbh;
    croak "ERR: no table or object name is specified.\n" if !$tn;
    $tn = uc($tn);
    $self->echoMSG("  - reading table $tn definition...", 1);
    $otp = 'ARRAY' if (! defined($otp));
    $otp = uc $otp;
    if ($cns) { $cns =~ s/,\s*/','/g; $cns = "'$cns'"; }
    #
    # 1. retrieve column definitions
    my($q,$msg);
    if (index($tn,'.')>0) {   # it is in schema.table format
        my ($sch,$tab) = ($tn =~ /([-\w]+)\.([-\w]+)/);
        $q  = "  SELECT column_name,data_type,data_length,";
        $q .= "data_scale,data_precision,\n             ";
        $q .= "nullable,column_id,character_set_name\n";
        $msg = "$q";
        $q   .= "        FROM dba_tab_columns\n";
        $msg .= "        FROM dba_tab_columns\n";
        $q   .= "       WHERE owner = '$sch' AND table_name = '$tab'\n";
        $msg .= "       WHERE owner = '$sch' AND table_name = '$tab'\n";
    } else {
        $q  = "  SELECT cname,coltype,width,scale,precision,nulls,";
        $q .= "colno,character_set_name\n";
        $msg = "$q";
        $q   .= "        FROM col\n     WHERE tname = '$tn'";
        $msg .= "        FROM col\n     WHERE tname = '$tn'\n";
    }
    if ($cns) {
        $q   .= "         AND cname in (" . uc($cns) . ")\n";
        $msg .= "         AND cname in (" . uc($cns) . ")\n";
    }
    if (index($tn,'.')>0) {   # it is in schema.table format
        $q   .= "\n    ORDER BY table_name,column_id";
        $msg .= "    ORDER BY table_name, column_id\n";
    } else {
        $q   .= "\n    ORDER BY tname, colno";
        $msg .= "    ORDER BY tname, colno\n";
    }
    $self->echoMSG("    $msg", 2);
    my $sth=$dbh->prepare($q) || croak "ERR: Stmt - $dbh->errstr";
       $sth->execute() || croak "ERR: Stmt - $dbh->errstr";
    my $arf = $sth->fetchall_arrayref;       # = output $df1
    #
    # 2. construct column name list
    my $r = ${$arf}[0][0];
    for my $i (1..$#{$arf}) { $r .= ",${$arf}[$i][0]"; }
    $msg = $r; $msg =~ s/,/, /g;
    $self->echoMSG("    $msg", 5);
    #
    # 3. get column comments
    $q  = "SELECT column_name, comments\n      FROM user_col_comments";
    $q .= "\n     WHERE table_name = '$tn'";
    $msg  = "SELECT column_name, comments\nFROM user_col_comments";
    $msg .= "\nWHERE table_name = '$tn'<p>";
    $self->echoMSG("    $msg", 5);
    my $s2=$dbh->prepare($q) || croak "ERR: Stmt - $dbh->errstr";
       $s2->execute() || croak "ERR: Stmt - $dbh->errstr";
    my $brf = $s2->fetchall_arrayref;
    my (%cmt, $j, $k, $cn);
    for my $i (0..$#{$brf}) {
        $j = lc(${$brf}[$i][0]);             # column name
        $cmt{$j} = ${$brf}[$i][1];           # comments
    }
    #
    # 4. construct output $df2($def) and $df3($df2)
    my $def = bless [], ref($self)||$self;   # = output $df2
    my $df2 = bless {}, ref($self)||$self;   # = output $df3
    for my $i (0..$#{$arf}) {
        $j  = ${$arf}[$i][6]-1;              # column seq number
        ${$def}[$j]{seq} = $j;               # column seq number
        $cn = lc(${$arf}[$i][0]);            # column name
        ${$def}[$j]{col} = uc($cn);          # column name
        ${$def}[$j]{typ} = ${$arf}[$i][1];   # column type
        if (${$arf}[$i][4]) {                # precision > 0
            # it is NUMBER data type
            ${$def}[$j]{wid} = ${$arf}[$i][4];  # column width
            ${$def}[$j]{dec} = ${$arf}[$i][3];  # number decimal
        } else {                             # CHAR or VARCHAR2
            ${$def}[$j]{wid} = ${$arf}[$i][2];  # column width
            ${$def}[$j]{dec} = ""               # number decimal
        }
        ${$def}[$j]{max} = ${$def}[$j]{wid};

        if (${$def}[$j]{typ} =~ /date/i) {   # typ is DATE
            ${$def}[$j]{max} = 17;           # set width to 17
            ${$def}[$j]{wid} = 17;           # set width to 17
            ${$def}[$j]{dft} = 'YYYYMMDD.HH24MISS';
        } else {
            ${$def}[$j]{dft} = '';           # set date format to null
        }
        if (${$arf}[$i][5] =~ /^(not null|N)/i) {
            ${$def}[$j]{req} = 'NOT NULL';
        } else {
            ${$def}[$j]{req} = '';
        }
        if (exists $cmt{$cn}) {
            ${$def}[$j]{dsp} =  $cmt{$cn};
        } else {
            ${$def}[$j]{dsp} = '';
        }
        ${$def}[$j]{min} = 0;
        ${$df2}{$cn}{seq}  = $j;
        ${$df2}{$cn}{col}  = ${$def}[$j]{col};
        ${$df2}{$cn}{typ}  = ${$def}[$j]{typ};
        ${$df2}{$cn}{dft}  = ${$def}[$j]{dft};
        ${$df2}{$cn}{wid}  = ${$def}[$j]{wid};
        ${$df2}{$cn}{dec}  = ${$def}[$j]{dec};
        ${$df2}{$cn}{max}  = ${$def}[$j]{max};
        ${$df2}{$cn}{min}  = ${$def}[$j]{min};
        ${$df2}{$cn}{req}  = ${$def}[$j]{req};
        ${$df2}{$cn}{dsp}  = ${$def}[$j]{dsp};
    }
    #
    # 5. construct output array $df4
    my $df4 = bless [],ref($self)||$self;   # = output $df4
    for my $i (0..$#{$arf}) {
        $j = lc(${$arf}[$i][0]);            # column name
        push @$df4, {cname=>$j,         coltype=>${$arf}[$i][1],
                width=>${$arf}[$i][2],    scale=>${$arf}[$i][3],
            precision=>${$arf}[$i][4],    nulls=>${$arf}[$i][5],
                colno=>${$arf}[$i][6],
            character_set_name=>${$arf}[$i][7]};
    }
    #
    # 6. output based on output type
    if ($otp =~ /^(AR|ARRAY)$/i) {
        return ($r, $arf, \%cmt);      # output ($cns,$df1,$cmt)
    } elsif ($otp =~ /^(AH1|ARRAY_HASH1)$/i) {
        return ($r, $def, \%cmt);      # output ($cns,$df2,$cmt)
    } elsif ($otp =~ /^(HH|HASH)$/i) {
        return ($r, $df2, \%cmt);      # output ($cns,$df3,$cmt)
    } else {
        return ($r, $df4, \%cmt);      # output ($cns,$df4,$cmt);
    }
}



1;

=head1 HISTORY

=over 4

=item * Version 0.01

This version is to set the framework and move the get_table_definition
from Oracle:;DML::Common.

=item * Version 0.02

Added table tag for export.

=cut

=head1 SEE ALSO (some of docs that I check often)

Data::Describe, Oracle::Loader, CGI::Getopt, File::Xcopy,
perltoot(1), perlobj(1), perlbot(1), perlsub(1), perldata(1),
perlsub(1), perlmod(1), perlmodlib(1), perlref(1), perlreftut(1).

=head1 AUTHOR

Copyright (c) 2005 Hanming Tu.  All rights reserved.

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut


