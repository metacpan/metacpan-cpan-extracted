package Net::WoRMS;
# ======================================================================
# (C) 2012 by A. Weidauer
# Contact: alex.weidauer@huckfinn.de
# ======================================================================
# ABSTRACT: Bundles functionalities for the tool query-worms.

=head1 NAME

Net::WoRMS bundles functionalities for the tool query-worms.

=head1 VERSION

version 1.5

=head1 SYNOPSIS

Net::WoRMS bundles WEB access, parsing and formatting capabilities for
the tool L<query-worms|https://metacpan.org>, to harvest information
form the "World Register of Marine Species" --
L<http://www.marinespecies.org>. The module was built around the module
L<SOAP::Lite> and is implemented by a L<Moo> object.

=cut

# ======================================================================
use v5.20;
use strict;
use warnings;
use utf8;
use open qw(:std :utf8);

our $VERSION = 1.5;

=head1 MODULE DEPENDENCIES

The module uses the packages:

=over

=item L<Data::Dumper>

Debugging purposes

=item L<Moo>

Object oriented extension for the module

=item L<MooX::Types::MooseLike::Base>

Minimal type system for  L<Moo>

=item L<SOAP::Lite>

is used for the WEB access and parsing capabilities to retrieve data
from L<http://www.marinespecies.org>.

=item L<Syntax::Keyword::Match>, to end the switch-case/while-given madness

=back

=cut

# Modules  -------------------------------------------------------------
use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use SOAP::Lite;
use Data::Dumper;

# Modern Perl ----------------------------------------------------------
use Syntax::Keyword::Match;
use feature qw(signatures);
no warnings 'once';
no warnings 'experimental';
no warnings 'experimental::signatures';

=head1 GLOBAL VARIABLES and CONSTANTS

=over

=item $END_POINT = 'http://www.marinespecies.org/aphia.php?p=soap'

The access point to retrieve data via the Simple Object Access Protocol.

=item  $APHIA_NS = 'http://aphia/v1.0'

Namespace and corresponding URI. In the development context these
variables are considered as a constants. There are methods to change
these values but never tested.

=item C<$FORMAT ='TEXT'>

FORMAT defines the default output format.

=item C<@ORDER_SCORE = qw/APHIA_ID ... />

The array holds field names for SQL related output.

=item C<@ORDER_DOT = qw/APHIA.ID ... />

The array holds field names for TEXT and CSV related output.

=item C<%FORMATS = ( TEXT => 1, SQL  => 2,  CSV  => 3)>

The format hash mostly for validation.

=item C<%ORDER_HASH>

Dictionary to sort and translate the retrieved field names from the
WoRMS database and bring them into a consistent form.

=item C<@TYPE>

Type array corresponding to C<@ORDER_SCORE/@ORDER_DOT> and the
C<%ORDER_HASH> to handle quotes and C<NULL> values.

=back

=cut

# GLOBALS ==============================================================
my $END_POINT = 'http://www.marinespecies.org/aphia.php?p=soap';
my $APHIA_NS  = 'http://aphia/v1.0';
my $APHIA_URI = $APHIA_NS;
my $FORMAT    = 'TEXT';

# Field name dump output
my @ORDER_SCORE =
    qw/APHIA_ID NAME AUTHOR RANK STATUS VALID_APHIA_ID VALID_NAME
       VALID_AUTHOR RNK_KINGDOM RNK_PHYLUM RNK_CLASS RNK_ORDER
       RNK_FAMILY RNK_GENUS CITATION/;

# Field names SQL / CSV
my @ORDER_DOT =
    qw/APHIA.ID NAME AUTHOR RANK STATUS VALID.APHIA.ID VALID.NAME
       VALID.AUTHOR KINGDOM PHYLUM CLASS ORDER
       FAMILY GENUS CITATION/;

my %FORMATS = ( TEXT => 1, SQL  => 2,  CSV  => 3);

# SOAP entry mapping to field names - WoRMS keys are a mess
my %ORDER_HASH = (
  "AphiaID"       =>  0, "scientificname"  =>  1, "authority"  =>  2,
  "rank"          =>  3, "status"        =>  4,
  "valid_AphiaID" =>  5, "valid_name" =>  6, "valid_authority" =>  7,
  "kingdom"       =>  8, "phylum"     =>  9, "class"           => 10,
  "order"         => 11, "family"     => 12, "genus"           => 13,
  "citation"      => 14,);

# Data types of the fields
# Index         0   1   2   3   4   5   6   7   8   9
my @TYPE = qw (INT STR STR STR STR INT STR STR STR STR
               STR STR STR STR STR);

=head1 FIELDS

=over

=item Debug: BOOL

Flag to switch to the debugging mode.

=item Format: STR

Field holds the current output format. The tags "TEXT|SQL|CSV" are
allowed.

=item EndPoint: STR (URI)

The current SOAP endpoint defaults to C<$END_POINT>.

=item AphiaNS and AphiaURI: STR (URI)

The current namespace and corresponding URI, defaulting to $APHIA_NS.

=item Soap

The SOAP access client instance generate by L<SOAP::Lite>.

=back

=cut

# FIELDS ===============================================================
has Debug    => ( is => 'rwp', isa => Int, default => 0 );
has Format   => ( is => 'rwp', isa => Str, default => $FORMAT );
has EndPoint => ( is => 'rwp', isa => Str, default => $END_POINT );
has AphiaNS  => ( is => 'rwp', isa => Str, default => $APHIA_NS  );
has AphiaURI => ( is => 'rwp', isa => Str, default => $APHIA_URI );
has Soap => (
    is  => 'rwp',
);

# METHODS ==============================================================

=head1 METHODS

=over

=item init()

Initializes the SOAP client.

Note: All C<change*(...)> functions must be used before the
initialization phase.

=back

=cut

sub init($self) {
    $self->_set_Soap( SOAP::Lite->new(
        uri => $self->AphiaURI,
        proxy => $self->EndPoint));
}

sub _checkInit($self, $what) {
    die "You have to change the '$what' before the ".
        "initialization of the connection!" if $self->Soap;
}

=head2 CHANGE METHODS

=over

=item changeEndPoint($uri)

Change the end point for the soap client (don't change).

=item changeAphiaURI($uri)

Change the namespace URI for the soap client (don't change).

=item changeAphiaNS($uri)

Change the namespace soap soap client (don't change).

=item changeDebug($flag)

Demand debugging capabilities.

=item changeFormat($format)

Changes the output format. Valid formats are TEXT|CSV|SQL.

=item getFormats()

Get the format dictionary for validation.

=back

=cut

# Function to configure the net access --------------------------------

sub changeEndPoint($self, $endPoint) {
    $self->_checkInit('END.POINT');
    $self->_set_EndPoint($endPoint);
}

sub changeAphiaURI($self, $aphiaUri) {
    $self->_checkInit('APHIA.URI');
    $self->_set_AphiaURI($aphiaUri);
}

sub changeAphiaNS($self, $aphiaNS) {
    $self->_checkInit('APHIA.NS');
    $self->_set_AphiaNS($aphiaNS);
}

sub changeDebug($self, $debug) {
    $self->_checkInit('DEBUG');
    $self->_set_Debug($debug);
}

sub changeFormat($self, $format) {
    $self->_checkInit('FORMAT');
    $self->_set_Format($format);
}

sub getFormats($self) { return \%FORMATS; }


=head2 QUERY METHODS

=over

=item C<checkSoap()>

Check if the soap client is running. The function stops the calling
program C<(die ...)> in case of an error.

=item C<checkError($soapResponse)>

Checks the SOAP query result. The function stops the calling program in
case of an communication error.

=item C<checkDebug($queryResult)>

Prints the query result (dictionary) via L<Data::Dumper> to C<STDERR> if
the debug flag is set.

=item C<searchSpeciesID($name, $print)>

Function to find a species by a certain name. The if the flag C<$print>
is set. The result will be written to C<STDOUT> on the given format.

=item C<getRecordByID($aphiaID)>

Retrieves a record for a given AphiaID and returns a dictionary or
'dies' with an error.

=item C<getBlockChildrenByID($AphiaID, $offs)>

Retrieve a set of taxon records under an given AphiaID for a defined
offset in the query ensemble. The offset addresses a paging pattern.

=item C<getChildrenByID($aphiaID)>

Retrieves all children under a given AphiaID using the method
C<getBlockChildrenID(...)> and prints the result to C<STDOUT> using the
method C<printRecord(...)>.

=item C<printRecord($record, $first, $last, $spc)>

Prints a record to C<STDOUT> and handles indentation by C<$spc> as well
as header and trailing aspects by using the flags C<$first> and C<$last>.

=back

=cut

# Query functions ------------------------------------------------------

sub checkSoap($self) {
    my $res = $self->Soap;
    die "Missing connection!" if not $res;
    return $res;
}

sub checkError($self, $response) {
   die "ERROR: ".$response->faultstring."!\n" if $response->fault;
}

sub checkDebug($self, $result) {
    print STDERR "DGB BEGIN:\n",Dumper($result),"EOF\n" if $self->Debug;
}

# Request to WORMS for a specific taxon by name ------------------------
sub searchSpeciesID($self, $name, $print) {
   my $con = $self->checkSoap;
   my $response = $con->call(
          SOAP::Data->name("getAphiaID")->attr({ "xmlns" => $APHIA_NS})
          => SOAP::Data->name("ScientificName" => $name)) ;
   $self->checkError($response);
   my $aphia_id = $response->result;
   die "ERROR: Unknown species with the NAME: '$name'!" if not $aphia_id;
   if ($print) {
      match($self->Format: eq) {
          case('TEXT') {
              print "INT APHIA.ID ", $aphia_id, "\n";
          }
          case('SQL') {
              print "APHIA_ID = ", $aphia_id, "\n"
          }
          case ('CSV') {
              print $aphia_id, "\n"  if $aphia_id;
          }
      }
    }
    return $aphia_id;
}

# Request to WORMS for a specific taxon by AphiaID ---------------------
sub getRecordByID($self, $id) {
    my $con = $self->checkSoap;
    my $response = $con->call(
        SOAP::Data->name("getAphiaRecordByID")->attr({ "xmlns" => $APHIA_NS})
        => SOAP::Data->name("AphiaID") -> value($id)) ;
    $self->checkError($response);
    my $result = $response->result;
    $self->checkDebug($result);
    return $result;
}

# @TODO THIS REQUEST DONT WORK -----------------------------------------
sub getBlockChildrenByID($self, $id, $offs) {
    my $con = $self->checkSoap;
    my $response = $con->call(
        SOAP::Data->name("getAphiaChildrenByID")->attr({ 'xmlns' => $APHIA_NS})
        => SOAP::Data->name("AphiaID") -> value($id),
        => SOAP::Data->name("offset")  -> value($offs),
        => SOAP::Data->name("marine_only") -> value("false")
    ) ;
    $self->checkError($response);
    my $result = $response->result;
    $self->checkDebug($result);
    return $result;
}

# DONT WORK ------------------------------------------------------------
sub searchFuzzy($self, $name, $offs, $fuzzy) {
    my $con = $self->checkSoap;
    # print $name, $offs, $FUZZY, "\n";
    my $response = $con->call(
        SOAP::Data->name("getAphiaRecords")->attr({ 'xmlns' => $APHIA_NS})
        => SOAP::Data->name("scientificname") -> value($name),
        => SOAP::Data->name("offset") -> value($offs),
        => SOAP::Data->name("marine_only") -> value("false"),
        => SOAP::Data->name("like")  ->  value($fuzzy));
    $self->checkError($response);
    my $result = $response->result;
    $self->checkDebug($result);
    return $result;
}

# ======================================================================

sub getChildrenByID($self, $sid) {
    my $offs=0; my $total = 0; my $num=1;
    print "\nWORMS.CHILDREN ID $sid \n" if $FORMAT eq "DUMP";
    while ($num > 0) {
        my $found = $self->getBlockChildrenByID($sid, $offs);
        last if not $found;
        my @recs = @$found;
        if (@recs) {
          $num  = @recs;
          foreach my $rec (@recs) {
              $total++;
              $self->printRecord($rec, $total==1, 1,"  ");
          }
          $offs +=$num+1;
        } else { $num=0; }
        # print "---- $num $offs $total -----\n";
    }
    match($self->Format: eq) {
      case('TEXT') { print "EOF\n" }
      case('SQL' ) { print ";\n" if $total >0; }
    }
}

# Output service routine record DUMP, CSV and SQL ----------------------
# @TODO this is a mess rewrite
sub printRecord($self, $record, $first, $last, $spc) {
    # asign header section
    my @head = ($self->Format eq 'TEXT')
             ? @ORDER_DOT : @ORDER_SCORE;

    my $num_fields = $#head;
    my @data = (); my @quote = ();
    # NULL and quotation
    for my $i (0..$num_fields) {
      # Handle empty fields
      $data[$i]  = ( $self->Format eq 'SQL') ? 'NULL' : 'NA';
      $quote[$i] = ( $TYPE[$i] eq 'STR' ) ? "'" : '';
    }

    my %rechash = %$record;
    my $id = $rechash{AphiaID};

    # return if $record{status} =~ "deleted";
    # print %rechash, "\n";

    print "\n", $spc, "WORMS ID $id \n" if $self->Format eq 'TEXT';
    if ($first && $self->Format eq "SQL") {
      print "INSERT INTO WORMS_TABLE\n(";
      print join(",",@head), ") VALUES\n(";
    }
    if (!$first && $self->Format eq "SQL") {
       print ",\n(";
    }
    if ($first && $self->Format eq "CSV") {
      print join(",",@head), "\n";
    }

    foreach my $k (keys %rechash)  {
        my $value =  $rechash{$k};
        $value //= '';
        $value =~ s/'/\\'/g;
        my $i = $ORDER_HASH{$k};
        if (! defined($i)) {
            print "NO MATCH ",$k,"\n" if $self->Debug > 2;
            next;
        }
        if ($i>=0) {
          # $data[i] = sprintf("%16s %d %8s %16s %s%s%s",
          #    $k, $i, $TYPE[$i],$head[$i],$quote[$i], $value, $quote[$i])
           $data[$i] = sprintf("%s%8s %16s %s%s%s",
             $spc, $TYPE[$i],$head[$i],$quote[$i], $value, $quote[$i])
          if $self->Format eq "TEXT";

          $data[$i] = $quote[$i].$value.$quote[$i]
          if $self->Format eq "SQL";

          $data[$i] = $quote[$i].$value.$quote[$i]
          if $self->Format eq "CSV";
        }
    }
    print join(",", @data), "\n" if $self->Format eq "CSV";
    print join(",", @data), ")"  if !$last && $self->Format eq "SQL";
    print join(",", @data), ");\n" if  $last && $self->Format eq "SQL";
    print join("\n", @data)      if $self->Format eq "TEXT";
    print "\n", $spc,"EOF\n"     if  $last && $self->Format eq "TEXT";
}

# WORMS dump Data ------------------------------------------------------
sub printRecordDef($self, $record, $spc) {
    my %rechash = %$record;
    my $id = $rechash{AphiaID};
    # return if $record{status} =~ "deleted";
    # print %rechash, "\n";
    print "\n", $spc, "WORMS ID $id \n";
    foreach my $k (keys %rechash)  {
        my $value =  $rechash{$k};
        $value =~ s/'/\\'/g; # Franzoesische Authoren unerwuenscht
	print $spc, "  INT  APHIA.ID       ", $value, "\n"  if $k =~ m/^AphiaID/;
        print $spc, "  STR  AUTHOR         '",$value, "'\n" if $k =~ m/^authority/;
        print $spc, "  STR  NAME           '",$value, "'\n" if $k =~ m/^scientificname/;
        print $spc, "  STR  RANK           '",$value, "'\n" if $k =~ m/^rank/;
        print $spc, "  STR  STATUS         '",$value, "'\n" if $k =~ m/^status/;
        print $spc, "  STR  CITE           '",$value, "'\n" if $k =~ m/^citation/;
	print $spc, "  INT  VALID.APHIA.ID ", $value, "\n"  if $k =~ m/^valid_AphiaID/;
	print $spc, "  STR  VALID.NAME     '",$value, "'\n" if $k =~ m/^valid_name/;
	print $spc, "  STR  VALID.AUTHOR   '",$value, "'\n" if $k =~ m/^valid_authority/;
	print $spc, "  STR  KINGDOM        '",$value, "'\n" if $k =~ m/^kingdom/;
	print $spc, "  STR  PHYLUM         '",$value, "'\n" if $k =~ m/^phylum/;
	print $spc, "  STR  CLASS          '",$value, "'\n" if $k =~ m/^class/;
	print $spc, "  STR  ORDER          '",$value, "'\n" if $k =~ m/^order/;
	print $spc, "  STR  FAMILY         '",$value, "'\n" if $k =~ m/^family/;
        print $spc, "  STR  GENUS          '",$value, "'\n" if $k =~ m/^genus/;
    }
    print $spc, "EOF \n";
}

=head1 AUTHOR

Alexander Weidauer E<lt>alex.weidauer@huckfinn.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Alexander Weidauer

This program is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation, either version 3 of the License, or any later
version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

1;

# EOF ==================================================================
