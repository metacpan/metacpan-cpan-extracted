package Net::WoRMS;
# ======================================================================
# (C) 2012 by A. Weidauer
# Contact: alex.weidauer@huckfinn.de
# ======================================================================
# ABSTRACT: Service object to query the "World Register of Marine Species" WoRMS.
# ======================================================================

=encoding utf8

=head1 NAME

Net::WoRMS - query the "World Register of Marine Species" WoRMS

=head1 SYNOPSIS

    #!/usr/bin/env perl
    use strict;
    use warnings;
    use Net::WoRMS;

    # Example settings
    my $GENUS    = 'Abra';
    my $SPECIES  = 'Abra alba';

    # Initialize the service
    my $WORMS    = Net::WoRMS->new();
    my $WORMS->init();
    die "Cannot open service!"
       if not $WORMS->checkSoap();

    # Single species info, output CSV
    $WORMS->changeFormat('CSV');
    my $id = $WORMS->searchSpeciesID($SPECIES, 0);
    my $rec = $WORMS->getRecordByID($id);
    $WORMS->printRecordDef($rec, ' ');

    # Species info for GENUS, output plain TEXT
    my $gid = $WORMS->searchSpeciesID($GENUS, 0);
    $WORMS->changeFormat('CSV');
    $WORMS->getChildrenByID($gid) or
       die "No species found for GENUS: '$GENUS'!";

=head1 DESCRIPTION

Net::WoRMS bundles WEB access, parsing and formatting capabilities for
the tool L<query-worms|https://metacpan.org>, to harvest information
form the "World Register of Marine Species" --
L<http://www.marinespecies.org>. The module was built around the module
L<SOAP::Lite> and is OO implemented using L<Moo>.

=cut

# ======================================================================
use v5.20;
use strict;
use warnings;
use utf8;
use open qw(:std :utf8);

our $VERSION = 1.901;

# ----------------------------------------------------------------------

=head1 DEPENDENCIES

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

=item L<Syntax::Keyword::Match>

to end the switch-case/while-given madness

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

# ---------------------------------------------------------------------

=head1 DEFAULT SETTINGS

=over

=item $END_POINT = 'https://www.marinespecies.org/aphia.php?p=soap'

The access point to retrieve data via the Simple Object Access Protocol.

=item $APHIA_NS = 'https://aphia/v1.0'

Namespace and corresponding URI. In the development context these
variables are considered as a constants. There are methods to change
these values but never tested.

=item $FORMAT = 'TEXT'

FORMAT defines the default output format.

=item @ORDER_SCORE = qw/APHIA_ID ... /

The array holds field names for SQL related output.

=item @ORDER_DOT = qw/APHIA.ID ... /

The array holds field names for TEXT and CSV related output.

=item %FORMATS = ( TEXT => 1, SQL  => 2,  CSV  => 3)

The format hash mostly for validation.

=item %ORDER HASH

Dictionary to sort, parse and translate the retrieved field names from the
WoRMS database and bring them into a consistent form.

=back

=cut

# GLOBALS ==============================================================

my $END_POINT = 'https://www.marinespecies.org/aphia.php?p=soap';
my $APHIA_NS  = 'https://aphia/v1.0';
my $APHIA_URI = $APHIA_NS;
my $FORMAT    = 'TEXT';

my $RI = qr/^\d+$/;
my $RS = qr/^(\(?[\w-]+\)?\.?(?:\s+\(?[\w-]+\)?\.?){0,4})$/;
# my $RA = qr/^\(?\[?([\w.&'-]+(?:\s+[\w.&'-]+){0,20})(?:,?\s*(\d+))?\)?\]?$/;
my $RA = qr/^(?=.*\p{L}).{1,250}$/s;
my $RW = qr/^[\w+\-\.\s+]+$/;

my %TYPES = ($RI => 'APHIA.ID', $RS => 'TAXON',
             $RA => 'AUTHOR',   $RW => 'WORDS');

# Field name dump output
my %ORDER = (
   # WoRMS.KEY       ORDER   TEXT|CSV         SQL               REX  SUBS
  'AphiaID'         => [ 0, 'APHIA.ID',       'APHIA_ID',       $RI,  0],
  'scientificname'  => [ 1, 'NAME',           'NAME',           $RS,  1],
  'authority'       => [ 2, 'AUTHOR',         'AUTHOR',         $RA,  2],
  'rank'            => [ 3, 'RANK',           'RANK',           $RW,  1],
  'status'          => [ 4, 'STATUS',         'STATUS',         $RW,  1],
  'valid_AphiaID'   => [ 5, 'VALID.APHIA.ID', 'VALID_APHIA_ID', $RI,  0],
  'valid_name'      => [ 6, 'VALID.NAME',     'VALID_NAME',     $RS,  1],
  'valid_authority' => [ 7, 'VALID.AUTHOR',   'VALID_AUTHOR',   $RA,  2],
  'kingdom'         => [ 8, 'KINGDOM',        'RNK_KINGDOM',    $RW,  1],
  'phylum'          => [ 9, 'PHYLUM',         'RNK_PHYLUM',     $RW,  1],
  'class'           => [10, 'CLASS' ,         'RNK_CLASS',      $RW,  1],
  'order'           => [11, 'ORDER',          'RNK_ORDER',      $RW,  1],
  'family'          => [12, 'FAMILY',         'RNK_FAMILY',     $RW,  1],
  'genus'           => [13, 'GENUS',          'RNK_GENUS',      $RW,  1],
  'citation'        => [14, 'CITATION',       'CITATION',     undef,  3],
);

my %FORMATS = ( TEXT => 1, SQL  => 2,  CSV  => 3);

my @CTRL = qw(
    NUL SOH STX ETX EOT ENQ ACK BEL BS  TAB LF  VT  FF  CR  SO  SI
    DLE DC1 DC2 DC3 DC4 NAK SYN ETB CAN EM  SUB ESC FS  GS  RS  US
);
# ----------------------------------------------------------------------

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

=item _checkInit($what)

Internal initialization test to assert the task C<$what> was not
recycled.

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

# ----------------------------------------------------------------------

=head2 CONFIGURATION

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
    # $self->_checkInit('FORMAT');
    $self->_set_Format($format);
}

sub getFormats($self) { return \%FORMATS; }

# ----------------------------------------------------------------------

=head2 ASSERTATIONS

=over

=item checkSoap()

Check if the soap client is running. The function stops the calling
program C<(die ...)> in case of an error.

=item checkError($soapResponse)

Checks the SOAP query result. The function stops the calling program in
case of an communication error.

=item checkDebug($queryResult)

Prints the query result (dictionary) via L<Data::Dumper> to C<STDERR> if
the debug flag is set.

=back

=cut

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

# ----------------------------------------------------------------

=head2 QUERIES

=over

=item searchSpeciesID($name, $print)

Function to find a species by a certain name. The if the flag C<$print>
is set. The result will be written to C<STDOUT> on the given format.

=item getRecordByID($aphiaID)

Retrieves a record for a given AphiaID and returns a dictionary or
'dies' with an error.

=item getBlockChildrenByID($AphiaID, $offs)

Retrieve a set of taxon records under an given AphiaID for a defined
offset in the query ensemble. The offset addresses a paging pattern.

=item getChildrenByID($aphiaID)

Retrieves all children under a given AphiaID using the method
C<getBlockChildrenID(...)> and prints the result to C<STDOUT> using the
method C<printRecord(...)>.

=item searchFuzzy($name, $offs, $fuzzy)  EXPERIMENTAL

The fuzzy search function is experimantal and does not give
proper results due to offset maping issues.

=back

=cut

# Query functions ------------------------------------------------------


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
    print "\nWORMS.CHILDREN ID $sid \n" if $self->Format eq "TEXT";
    while ($num > 0) {
        my $found = $self->getBlockChildrenByID($sid, $offs);
        last if not $found;
        my @recs = @$found;
        if (@recs) {
          $num  = @recs;
          for my $ix (0..$#recs) {
              $total++;
              my %rec = %{ $recs[$ix] };
              $self->printRecord(\%rec, ($ix==0), ($ix==$#recs) ,"  ");
          }
          $offs +=$num+1;
        } else { $num=0; }
        # print "---- $num $offs $total -----\n";
    }
    print "\nEOF\n# WORMS.CHILDREN ID $sid TOTAL: $total\n"
        if $self->Format eq "TEXT";
    $total;
}

# Output service routine record DUMP, CSV and SQL ----------------------

=head2 OUTPUT

=over

=item quoteAuthor($author)

The function will translate abbrevation in names like <D'Alambert>
to the UTF8 form <D’Alambert> to avoid qouting in SQL fields.

=item quoteString($str, $fmt)

The function will quote $str to prevent SQL injection problems with:

=over

=item undef

    $str = $fmt eq 'SQL' ? 'NULL' : 'NA';

=item backspaced control sequences

    $str = '\r'; # becomes '\\r'

=item control sequences

    $str = "\r"; # becomes '<CR>'

=item embedded single quotes

    $str = "'"; # becomes "''"

=back

=item printRecord($record, $first, $last, $spc)

Prints a record to C<STDOUT> and handles indentation by C<$spc> as well
as header and trailing aspects by using the flags C<$first> and C<$last>.

=item printRecordDef($record, $record, $spc)

Prints the default plain TEXT record to C<STDOUT> and handles
indentation by C<$spc>.

=back

=cut

sub quoteString($self, $str, $fmt) {
    unless  (defined $str) {
        $str = $fmt eq 'SQL' ? 'NULL' : 'NA';
        return $str;
    }

    # Remove control sequences
    # $str =~ s/\x00/<NUL>/g;
    # $str =~ s/\r/<CR>/g;
    # $str =~ s/\n/<NL>/g;

    # Mask backslashes
    $str =~ s/\\/\\\\/g;

    # Remove control sequences
    $str =~ s/([\x00-\x1f\x7f])/ '<'.($CTRL[ord($1)] \/\/ 'DEL').'>' /ge;

    # Single Quotes
    $str =~ s/'/''/g;
    return "'$str'";
}

sub quoteAuthor($self, $author) {
    return unless defined $author;
    $author =~ s/'/\x{2019}/g;
    $author;
}

sub printRecord($self, $record, $first, $last, $spc) {
    my @fields; my @data; my @type; my $fmt = $self->Format;
    my $id = $record->{AphiaID};
    my $nm = $record->{scientificname};
    for my $field (keys %ORDER) {

        # Get the pasing and substitution rules
        my ($order, $txtField, $sqlField, $rex, $subs) = @{ $ORDER{$field} };
        print("F: $field: O: $order FT: $txtField FS: $sqlField RX:  $rex SB: $subs \n")
            if $self->Debug;
        # check, escape and pack the data content
        # the worms field xsd is not very expressive here
        my $value = $record->{$field};
        if (defined $value and defined $rex) {
            if ($value !~ /$rex/) {
                print STDERR "ERROR ID: $id NAME: '$nm' parsing ".
                    "FIELD: '$field' VALUE: '$value' is not a valid ".
                    $TYPES{$rex}." descriptor!\n" ;
                return 0;
           }
        }
        # Replace ' by ’ in Author stuff like D'Alambert
        $value = $self->quoteAuthor($value)
            if (defined $value) and ($subs == 2);

        # Add, NULL/NA and sanitize and quote strings
        if ($subs != 0) {
            $value = $self->quoteString($value, $fmt);
        } else {
           # Nulling integers
           $value //= $fmt eq 'SQL' ? 'NULL' : 'NA';
        }
        # Pack it in the predefined order
        $data[$order] = $value;
        $fields[$order] = ($fmt eq 'SQL') ? $sqlField : $txtField;

        # The WoRMS xsd makes no deeper differentiation here
        $type[$order] = $subs ? 'STR' : 'INT';
    }
    return 0 if not @data;

    # return if $record{status} =~ "deleted";
    
    # header section ---------------------------------------------------
    if ($first) {
      print join(",",@fields), "\n"       if $fmt eq "CSV";
      print "INSERT INTO WORMS_TABLE\n(",join(",",@fields),") ",
            "VALUES\n" if $fmt eq "SQL";
    }
    # data section -----------------------------------------------------
    print     join(",", @data),"\n" if $fmt eq "CSV";
    print "(",join(",", @data),")"  if $fmt eq "SQL";
    if ($self->Format eq "TEXT") {
        print "\n", $spc, "WORMS ID $id \n" if $fmt eq 'TEXT';
        for my $ix (0..$#fields) {
            printf "%s\t%s\t%-16s\t%s\n",
                $spc, $type[$ix], $fields[$ix], $data[$ix];
        }
       print $spc,"EOF\n";
    }
    # footer section ---------------------------------------------------
    if ($last) {
        print "\n", if $self->Format eq "TEXT";
        print ";\n" if $self->Format eq "SQL";
     } else {
        print ",\n" if $self->Format eq "SQL";
    }
    1
}

# WORMS dump Data ------------------------------------------------------
sub printRecordDef($self, $record, $spc) {
    $self->printRecord($record, 1, 1, $spc);
    1
}

=head1 BUGS

Please report bugs via the issue tracker: L<https://rt.cpan.org>.

=cut

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
