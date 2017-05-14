#!/usr/bin/perl
# $Id: sqldef.pl,v 1.10 1997/08/27 21:36:28 paul Exp bjepson $

=pod

=head1 NAME

sqldef.pl - Convert RDBMS schema to mSQL DDL

=head1 SYNOPSIS

B<sqldef.pl> [ --catalog-only ] [ --no-sequences ] [ --help ]

=head1 DESCRIPTION

B<sqldef.pl> will read a text-based schema for a relational database on
standard input and generate the corresponding Data Definition Language
(DDL) on standard output to create an mSQL 2.x database.

Most commonly you would pipe the output of sqldef.pl to the msql monitor
program (this will wipe out all of the data in the specified database):

     sqldef.pl db.schema | msql db 

=head2 SCHEMA FILE FORMAT

Table and column definitions consist of lists of colon seperated
fields.

Where an optional parameters is omitted the corresponding field should
be left blank.

All lines beginning with I<#> are comments.  

=head2 TABLE DEFINITION

=over 4

=item I<table_name>

name of the table

=item I<table_description>

table description (used in various HTML pages)

=item I<view_file> (optional)

HTML file to use when viewing the file as a result of a query

=back

=head2 COLUMN DEFINITION

=over 4

=item I<column_name>

name of the column

=item I<type>

data type of the column.  This can be set to any B<one> of the standard
mSQL types B<int|char|text|date> or the `pseudo types'
B<datetime|created|modified|boolean>.

=item I<width> (optional)

the width of a B<char> or B<text> column

=item I<constraints> (optional)

additional mSQL constraints on the column e.g. B<not null>.

=item I<description>

short description of the table (used in various HTML pages)

=item I<key_types>

list of key types seperated by B<+>.  Valid key types are

=over

=item I<PRIMARY>

for a primary key

=item I<FOREIGN>

for a foreign key

=item I<LABEL>

for a column to be used in a selection list to identify a row from a
related table

=back

=item I<fkey_table> (optional)

if one of the key types is I<FOREIGN>, the name of the related table

=item I<fkey_column> (optional)

if one of the key types is I<FOREIGN>, the name of the related column in
I<fkey_table>

=item I<link_type>

type of link: I<MAILTO>, I<URL> or I<IMG>

=item I<prompt>

non-zero to prompt for this column in queries

=item I<display>

non-zero to display this column in query results

=item I<link>

name of column to use as label of link

=back

=head1 EXAMPLE

 # company.schema

 # company table
 table:company:companies::
 cmpny_id:int::not null:Unique Id:PRIMARY::::0:0:
 cmpny_name:char:40::Company name:LABEL::::1:1:
 
 # product table
 table:product:goods/services::
 prod_id:int::not null:Unique Id:PRIMARY::::0:0:
 prod_name:char:40::Product/services:LABEL::::1:1:

 # supply table
 # M:N (company:product)
 table:supply:supply of goods/services::
 supply_cmpny:int:::Company:PRIMARY+FOREIGN+LABEL:company:cmpny_id::1:1:
 supply_prod:int:::Product:PRIMARY+FOREIGN+LABEL:product:prod_id::1:1:

=head1 OPTIONS

I<--catalog-only>
    only create DDL for system catalog

I<--no-sequences>
    don't create DDL for table sequences

    Useful if you plan to dump your data with a program like msqldump,
    change the schema and then reload the data, as it will preserve your
    table sequences.

I<--help>
    print a usage messages, then exit

=head1 AUTHOR

Brian Jepson <bjepson@conan.ids.net>

Paul Sharpe <paul@miraclefish.com>

You may distribute this under the same terms as Perl itself.

=head1 SEE ALSO
    Msql::RDBMS

=cut

use Getopt::Long;

GetOptions( "catalog-only" => \$catonly,
            "no-sequences" => \$noseq,
	    "help"         => \$help );

&usage if ( $help );

if ( @ARGV ) {
    foreach ( @ARGV ) {
	print STDERR "Invalid option: $_\n";
    }
    usage;
}

&mkcatalog();

exit if ( $catonly );

while (<>) {
  chop;
  next unless $_;
  next if /^#/;
    if (/^table:/) {

      if ($def) {
	if ( $index_name ) {
	  $index = "CREATE UNIQUE INDEX $index_name ON $table ($index_cols)\n\\g\n";
	}
	else {
	  $index = '';
        }
	if ($catonly) {
	  print $tables, $index, $sequence, $columns, $keys, $links;
	} else {
	  print $drop,$head,$def,")\n\\g\n",$tables,$index, $sequence,$columns,$keys,$links;
	}
	$index_cols = $index_name = '';
      }

      ($null, $table, $description, $seehtml) = split(":");
      
      $drop     = "DROP TABLE $table\n\\g\n";
      $head     = "CREATE TABLE $table (\n";
      $def      = "";
      $index    = "";
      $sequence = "";
      
      $tables = "INSERT INTO systables\n" . 
	        "   (tbl_name, tbl_description, tbl_seehtml)\n" .
	        "VALUES ('$table', '$description', '$seehtml')\n\\g\n";
      $columns = "";
      $keys    = "";
      next;
    } else {
      $def .= ", \n" if $def;
    }

  ($column, $type, $len, $args, $caption, 
   $keytype, $fkey_tbl, $fkey_col, 
   $link, $query, $disp, $lnklabel)  = split(":");
  
  # map pseudo types
  $msql_type = $type;
  $msql_type =~ s/money/real/ig;
  $msql_type =~ s/datetime/int/ig;
  $msql_type =~ s/created/int/ig;
  $msql_type =~ s/modified/int/ig;
  $msql_type =~ s/boolean/int/ig;

  $def .= "   $column $msql_type ";
  $def .= " ($len)" if $len;
  $def .= " $args";
  
  $len      = $len * 1;
  $columns .="INSERT INTO syscolumns\n" . 
    "(col_name,col_label,col_type,col_len, tbl_name, col_query, col_disp)\n" .
      "VALUES ('$column', '$caption', '$type', $len, '$table', $query, $disp)".
	"\n\\g\n";
  
  if ( $keytype ) {
    # column:keytype is 1:n e.g. column = PRIMARY+FOREIGN+LABEL
    foreach ( split(/\+/, $keytype) ) {
	$keys .= "INSERT INTO syskeys\n" . 
	  "   (col_name, tbl_name, key_type, fkey_tbl, fkey_col)\n" .
	  "   VALUES ('$column', '$table', '$_', '$fkey_tbl', '$fkey_col')\n\\g\n";     

      if ( $keytype =~ /PRIMARY/i ) {
	# add column to (possibly composite) index
	if ( $index_cols ) {
	  $index_cols .= ", $column";
	  $index_name .= "_$column";
	}
	else {
	  $index_cols = $column;
	  $index_name = "ix_$column";
	}
	$sequence = "CREATE SEQUENCE ON $table STEP 1 VALUE 1\n\\g\n"
	    unless ( $noseq );
      }
    }
  }

  if ($link) {
    $links .= "INSERT INTO syslinks\n" . 
      "   (col_name_label, col_name_target, lnk_type)\n" .
	"   VALUES ('$lnklabel', '$column', '$link')\n\\g\n";     
  }
  
}

if ($def) {
  if ($catonly) {
    print $tables, $index, $sequence, $columns, $keys, $links;
  } else {
    print $drop,$head,$def,")\n\\g\n",$tables,$index,$sequence,$columns,$keys,$links;
  }
}

sub mkcatalog {
  print <<EOF;
DROP TABLE systables
\\g
CREATE TABLE systables (
   tbl_name        char (32) not null,
   tbl_description char (128),
   tbl_seehtml     char (64)
   )
\\g

DROP TABLE syscolumns
\\g
CREATE TABLE syscolumns (
   col_name  char (32) not null,
   col_label char (128),
   col_type  char (8),
   col_len  int,
   tbl_name  char (32),
   col_query int,
   col_disp int
   )
\\g

DROP TABLE syskeys
\\g
CREATE TABLE syskeys (
   col_name char(32) not null,
   tbl_name char(32) not null,
   key_type char(15) not null,
   fkey_tbl char(32),
   fkey_col char(32)
   )
\\g
DROP TABLE syslinks
\\g
CREATE TABLE syslinks (
   col_name_label  char(32) not null,
   col_name_target char(32) not null,
   lnk_type char(10)
   )
\\g
DROP TABLE sysusers 
\\g
CREATE TABLE sysusers (
   password char(24) not null,
   userid   char(8) not null
)
\\g
EOF
;

}

sub usage {
    print STDERR "Usage: sqldef.pl [OPTIONS]\n";
    print STDERR "Convert RDBMS schema on standard input, to mSQL DDL on standard output.\n\n";
    print STDERR "\t--help\t\tprint this help, then exit\n";
    print STDERR "\t--catalog-only\tonly create DDL for system catalog\n";
    print STDERR "\t--no-sequences\tdon't create DDL for table sequences\n";
    exit;
}
