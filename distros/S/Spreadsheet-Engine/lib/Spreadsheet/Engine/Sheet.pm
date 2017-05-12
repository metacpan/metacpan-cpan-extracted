package Spreadsheet::Engine::Sheet;

=head1 NAME

Spreadsheet::Engine::Sheet - Spreadsheet basics

=head1 SYNOPSIS

  parse_sheet_save(\@lines, \my %sheetdata);
  my $outstr = create_sheet_save(\%sheetdata);
  
  add_to_editlog(\%headerdata, $str);

  parse_header_save(\@lines, my \%headerdata);
  my $outstr = create_header_save(\%headerdata);

  execute_sheet_command($sheetdata, $command);

  recalc_sheet(\%sheetdata);

=head1 DESCRIPTION

This is a motley bunch of functions for dealing with a spreadsheet file
and/or data structure. If you plan to use any of these directly, be
aware that they may move, vanish, or have significant interface changes
in future releases.

=cut

use strict;
use utf8;

require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(
  parse_sheet_save
  create_sheet_save
  execute_sheet_command
  recalc_sheet
  parse_header_save
  create_header_save
  add_to_editlog

  convert_date_gregorian_to_julian
  convert_date_julian_to_gregorian
  determine_value_type
  test_criteria
  lookup_result_type
  copy_function_args
  function_args_error
  function_specific_error
  top_of_stack_value_and_type
  operand_as_number
  operand_as_text
  operand_value_and_type
  decode_range_parts
  coord_to_cr
  cr_to_coord
  encode_for_save
  decode_from_save
  special_chars
  special_chars_nl

  %sheetfields
  %formathints
  $julian_offset
  $seconds_in_a_day
  $seconds_in_an_hour
);

# Were exporte, but no longer used from outside:
# format_number_for_display url_encode_plain

#
# Locals and Globals
#

our %sheetfields = (
  lastcol                   => "c",
  lastrow                   => "r",
  defaultcolwidth           => "w",
  defaultrowheight          => "h",
  defaulttextformat         => "tf",
  defaultnontextformat      => "ntf",
  defaulttextvalueformat    => "tvf",
  defaultnontextvalueformat => "ntvf",
  defaultlayout             => "layout",
  defaultfont               => "font",
  defaultcolor              => "color",
  defaultbgcolor            => "bgcolor",
  circularreferencecell     => "circularreferencecell",
  recalc                    => "recalc",
  needsrecalc               => "needsrecalc"
);

my @headerfieldnames = qw(
  version fullname templatetext templatefile lastmodified
  lastauthor basefiledt backupfiledt reverted editcomments
  publishhtml publishsource publishjs viewwithoutlogin
);

# Date/time constants

our $julian_offset      = 2415019;
our $seconds_in_a_day   = 24 * 60 * 60;
our $seconds_in_an_hour = 60 * 60;

# Input values that have special values, e.g., "TRUE", "FALSE", etc.
# Form is: uppercasevalue => "value,type"

my %input_constants = (
  'TRUE'    => '1,nl',
  'FALSE'   => '0,nl',
  '#N/A'    => '0,e#N/A',
  '#NULL!'  => '0,e#NULL!',
  '#NUM!'   => '0,e#NUM!',
  '#DIV/0!' => '0,e#DIV/0!',
  '#VALUE!' => '0,e#VALUE!',
  '#REF!'   => '0,e#REF!',
  '#NAME?'  => '0,e#NAME?',
);

# Formula constants for parsing:

my $token_num    = 1;
my $token_coord  = 2;
my $token_op     = 3;
my $token_name   = 4;
my $token_error  = 5;
my $token_string = 6;
my $token_space  = 7;

my $char_class_num      = 1;
my $char_class_numstart = 2;
my $char_class_op       = 3;
my $char_class_eof      = 4;
my $char_class_alpha    = 5;
my $char_class_incoord  = 6;
my $char_class_error    = 7;
my $char_class_quote    = 8;
my $char_class_space    = 9;

my @char_class = (

  # 0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
  # sp !  "  #  $  %  &  '  (  )  *  +  ,  -  .  /
  9, 3, 8, 4, 6, 3, 3, 0, 3, 3, 3, 3, 3, 3, 2, 3,

  # 0  1  2  3  4  5  6  7  8  9  :  ;  <  =  >  ?
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 0, 3, 3, 3, 0,

  # @  A  B  C  D  E  F  G  H  I  J  K  L  M  N  O
  0, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,

  # P  Q  R  S  T  U  V  W  X  Y  Z  [  \  ]  ^  _
  5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 0, 0, 0, 3, 0,

  # `  a  b  c  d  e  f  g  h  i  j  k  l  m  n  o
  0, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,

  # p  q  r  s  t  u  v  w  x  y  z  {  |  }  ~  DEL
  5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 0, 0, 0, 0, 0
);

# Convert one char token text to input text

my %token_op_expansion =
  ('G' => '>=', 'L' => '<=', 'M' => '-', 'N' => '<>', 'P' => '+');

# Operator Precedence:
# 1 !
# 2 : ,
# 3 M P
# 4 %
# 5 ^
# 6 * /
# 7 + -
# 8 &
# 9 < > = G(>=) L(<=) N(<>)
# Negative value means Right Associative

my @token_precedence = (

  # 0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
  # sp !  "  #  $  %  &  '  (  )  *  +  ,  -  .  /
  0, 1, 0, 0, 0, 4, 8, 0, 0, 0, 6, 7, 2, 7, 0, 6,

  # 0  1  2  3  4  5  6  7  8  9  :  ;  <  =  >  ?
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 9, 9, 9, 0,

  # @  A  B  C  D  E  F  G  H  I  J  K  L   M  N  O
  0, 0, 0, 0, 0, 0, 0, 9, 0, 0, 0, 0, 9, -3, 9, 0,

  #  P  Q  R  S  T  U  V  W  X  Y  Z  [  \  ]  ^   _
  -3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0
);

#
# Information about the resulting value types when doing operations on values
#
# Each hash entry is a hash with specific types with result type info as follows:
#
#    'type1a' => '|type2a:resulta|type2b:resultb|...
#    Type of t* or n* matches any of those types not listed
#    Results may be a type or the numbers 1 or 2 specifying to return type1 or type2
#

my %typelookup = (
  unaryminus => {
    'n*' => '|n*:1|',
    'e*' => '|e*:1|',
    't*' => '|t*:e#VALUE!|',
    'b'  => '|b:n|'
  },
  unaryplus => {
    'n*' => '|n*:1|',
    'e*' => '|e*:1|',
    't*' => '|t*:e#VALUE!|',
    'b'  => '|b:n|'
  },
  unarypercent => {
    'n*' => '|n:n%|n*:n|',
    'e*' => '|e*:1|',
    't*' => '|t*:e#VALUE!|',
    'b'  => '|b:n|'
  },
  plus => {
    'n%' => '|n%:n%|nd:n|nt:n|ndt:n|n$:n|n:n|n*:n|b:n|e*:2|t*:e#VALUE!|',
    'nd' => '|n%:n|nd:nd|nt:ndt|ndt:ndt|n$:n|n:nd|n*:n|b:n|e*:2|t*:e#VALUE!|',
    'nt' => '|n%:n|nd:ndt|nt:nt|ndt:ndt|n$:n|n:nt|n*:n|b:n|e*:2|t*:e#VALUE!|',
    'ndt' =>
      '|n%:n|nd:ndt|nt:ndt|ndt:ndt|n$:n|n:ndt|n*:n|b:n|e*:2|t*:e#VALUE!|',
    'n$' => '|n%:n|nd:n|nt:n|ndt:n|n$:n$|n:n$|n*:n|b:n|e*:2|t*:e#VALUE!|',
    'n'  => '|n%:n|nd:nd|nt:nt|ndt:ndt|n$:n$|n:n|n*:n|b:n|e*:2|t*:e#VALUE!|',
    'b'  => '|n%:n%|nd:nd|nt:nt|ndt:ndt|n$:n$|n:n|n*:n|b:n|e*:2|t*:e#VALUE!|',
    't*' => '|n*:e#VALUE!|t*:e#VALUE!|b:e#VALUE!|e*:2|',
    'e*' => '|e*:1|n*:1|t*:1|b:1|',
  },
  concat => {
    't'  => '|t:t|th:th|tw:tw|t*:2|e*:2|',
    'th' => '|t:th|th:th|tw:t|t*:t|e*:2|',
    'tw' => '|t:tw|th:t|tw:tw|t*:t|e*:2|',
    'e*' => '|e*:1|n*:1|t*:1|',
  },
  oneargnumeric => {
    'n*' => '|n*:n|',
    'e*' => '|e*:1|',
    't*' => '|t*:e#VALUE!|',
    'b'  => '|b:n|'
  },
  twoargnumeric => {
    'n*' => '|n*:n|t*:e#VALUE!|e*:2|',
    'e*' => '|e*:1|n*:1|t*:1|',
    't*' => '|t*:e#VALUE!|n*:e#VALUE!|e*:2|'
  },
  propagateerror => {
    'n*' => '|n*:2|e*:2|',
    'e*' => '|e*:2|',
    't*' => '|t*:2|e*:2|',
    'b'  => '|b:2|e*:2|'
  },
);

my %old_formats_map = (
  'default' => "default"
  ,    # obsolete: converts from early beta versions, used only one place
  'none'      => 'General',
  '%1.0f'     => "0",
  ','         => '[,]General',
  ',%1.0f'    => '#,##0',
  ',%1.1f'    => '#,##0.0',
  ',%1.2f'    => '#,##0.00',
  ',%1.3f'    => '#,##0.000',
  ',%1.4f'    => '#,##0.0000',
  '$,%1.0f'   => '$#,##0',
  '$,%1.1f'   => '$#,##0.0',
  '$,%1.2f'   => '$#,##0.00',
  '(,%1.0f'   => '#,##0_);(#,##0)',
  '(,%1.1f'   => '#,##0.0_);(#,##0.0)',
  '(,%1.2f'   => '#,##0.00_);(#,##0.00)',
  '($,%1.0f'  => '$#,##0_);($#,##0)',
  '($,%1.1f'  => '$#,##0.0_);($#,##0.0)',
  '($,%1.2f'  => '$#,##0.00_);($#,##0.00)',
  ',%1.0f%%'  => '0%',
  ',%1.1f%%'  => '0.0%',
  '(,%1.0f%%' => '0%_);(0%)',
  '(,%1.1f%%' => '0.0%_);(0.0%)',
  '%02.0f'    => '00',
  '%03.0f'    => '000',
  '%04.0f'    => '0000',
);

=head1 EXPORTS

=head2 parse_sheet_save

  parse_sheet_save(\@lines, \my %sheetdata);

Sheet input routine. Fills %sheetdata given lines of text @lines.

Currently always returns nothing.

Sheet save format:

  linetype:param1:param2:...

Linetypes are:

  version:versionname - version of this format. Currently 1.3.

  cell:coord:type:value...:type:value... - Types are as follows:

       v:value - straight numeric value
       t:value - straight text/wiki-text in cell, encoded to handle \, :, newlines
       vt:fulltype:value - value with value type/subtype
       vtf:fulltype:value:formulatext - formula resulting in value with value type/subtype, value and text encoded
       vtc:fulltype:value:valuetext - formatted text constant resulting in value with value type/subtype, value and text encoded
       vf:fvalue:formulatext - formula resulting in value, value and text encoded (obsolete: only pre format version 1.1)
          fvalue - first char is "N" for numeric value, "T" for text value, "H" for HTML value, rest is the value
       e:errortext - Error text. Non-blank means formula parsing/calculation results in error.
       b:topborder#:rightborder#:bottomborder#:leftborder# - border# in sheet border list or blank if none
       l:layout# - number in cell layout list
       f:font# - number in sheet fonts list
       c:color# - sheet color list index for text
       bg:color# - sheet color list index for background color
       cf:format# - sheet cell format number for explicit format (align:left, etc.)
       cvf:valueformat# - sheet cell value format number (obsolete: only pre format v1.2)
       tvf:valueformat# - sheet cell text value format number
       ntvf:valueformat# - sheet cell non-text value format number
       colspan:numcols - number of columns spanned in merged cell
       rowspan:numrows - number of rows spanned in merged cell
       cssc:classname - name of CSS class to be used for cell when published instead of one calculated here
       csss:styletext - explicit CSS style information, encoded to handle :, etc.
       mod:allow - if "y" allow modification of cell for live "view" recalc

    col:
       w:widthval - number, "auto" (no width in <col> tag), number%, or blank (use default)
       hide: - yes/no, no is assumed if missing
    row:
       hide - yes/no, no is assumed if missing

    sheet:
       c:lastcol - number
       r:lastrow - number
       w:defaultcolwidth - number, "auto", number%, or blank (default->80)
       h:defaultrowheight - not used
       tf:format# - cell format number for sheet default for text values
       ntf:format# - cell format number for sheet default for non-text values (i.e., numbers)
       layout:layout# - default cell layout number in cell layout list
       font:font# - default font number in sheet font list
       vf:valueformat# - default number value format number in sheet valueformat list (obsolete: only pre format version 1.2)
       ntvf:valueformat# - default non-text (number) value format number in sheet valueformat list
       tvf:valueformat# - default text value format number in sheet valueformat list
       color:color# - default number for text color in sheet color list
       bgcolor:color# - default number for background color in sheet color list
       circularreferencecell:coord - cell coord with a circular reference
       recalc:value - on/off (on is default). If "on", appropriate changes to the sheet cause a recalc
       needsrecalc:value - yes/no (no is default). If "yes", formula values are not up to date

    name:name:description:value - name definition, name in uppercase, with value being "B5", "A1:B7", or "=formula"
    font:fontnum:value - text of font definition (style weight size family) for font fontnum
                         "*" for "style weight", size, or family, means use default (first look to sheet, then builtin)
    color:colornum:rgbvalue - text of color definition (e.g., rgb(255,255,255)) for color colornum
    border:bordernum:value - text of border definition (thickness style color) for border bordernum
    layout:layoutnum:value - text of vertical alignment and padding style for cell layout layoutnum:
                             vertical-alignment:vavalue;padding topval rightval bottomval leftval;
    cellformat:cformatnum:value - text of cell alignment (left/center/right) for cellformat cformatnum
    valueformat:vformatnum:value - text of number format (see format_value_for_display) for valueformat vformatnum (changed in v1.2)
    clipboardrange:upperleftcoord:bottomrightcoord - origin of clipboard data. Not present if clipboard empty.
       There must be a clipboardrange before any clipboard lines
    clipboard:coord:type:value:... - clipboard data, in same format as cell data

The resulting $sheetdata data structure is as follows:

   $sheetdata{version} - version of save file read in
   $sheetdata{datatypes}->{$coord} - Origin of {datavalues} value:
                                        v - typed in numeric value of some sort, constant, no formula
                                        t - typed in text, constant, no formula
                                        f - result of formula calculation ({formulas} has formula to calculate)
                                        c - constant of some sort with typed in text in {formulas} and value in {datavalues}
   $sheetdata{formulas}->{$coord} - Text of formula if {datatypes} is "f", no leading "=", or text of constant if "c"
   $sheetdata{datavalues}->{$coord} - a text or numeric value ready to be formatted for display or used in calculation
   $sheetdata{valuetypes}->{$coord} - the value type of the datavalue as 1 or more characters
                                      First char is "n" for numeric or "t" for text
                                      Second chars, if present, are sub-type, like "l" for logical (0=false, 1=true)
   $sheetdata{cellerrors}->{$coord} - If non-blank, error text for error in formula calculation
   $sheetdata{cellattribs}->{$coord}->
      {coord} - coord of cell - existence means non-blank cell
      {bt}, {br}, {bb}, {bl} - border number or null if no border
      {layout} - cell layout number or blank for default
      {font} - font number or blank for default
      {color} - color number for text or blank for default
      {bgcolor} - color number for the cell background or blank for default
      {cellformat} - cell format number if not default - controls horizontal alignment
      {textvalueformat} - value format number if not default - controls how the cell's text values are formatted into text for display
      {nontextvalueformat} - value format number if not default - controls how the cell's non-text values are turned into text for display
      {colspan}, {rowspan} - column span and row span for merged cells or blank for 1
      {cssc}, {csss} - explicit CSS class and CSS style for cell
      {mod} - if "y" allow modification in live view
   $sheetdata{colattribs}->{$colcoord}->
      {width} - column width if not default
      {hide} - hide column if yes
   $sheetdata{rowattribs}->{$rowcoord}->
      {height} - ignored
      {hide} - hide row if yes
   $sheetdata{sheetattribs}->{$attrib}->
      {lastcol} - number of columns in sheet
      {lastrow} - number of rows in sheet (more may be displayed when editing)
      {defaultcolwidth} - number, "auto", number%, or blank (default->80)
      {defaultrowheight} - not used
      {defaulttextformat} - cell format number for sheet default for text values
      {defaultnontextformat} - cell format number for sheet default for non-text values (i.e., numbers)
      {defaultlayout} - default cell layout number in sheet cell layout list
      {defaultfont} - default font number in sheet font list
      {defaulttextvalueformat} - default text value format number in sheet valueformat list
      {defaultnontextvalueformat} - default number value format number in sheet valueformat list
      {defaultcolor} - default number for text color in sheet color list
      {defaultbgcolor} - default number for background color in sheet color list
      {circularreferencecell} - cell coord with a circular reference
      {recalc} - on/off (on is default). If "on", appropriate changes to the sheet cause a recalc
      {needsrecalc} - yes/no (no is default). If "yes", formula values are not up to date
   $sheetdata{names}->{$name}-> - name is uppercase
      {desc} - description (optional)
      {definiton} - in the form of B5, A1:B7, or =formula
   $sheetdata{fonts}->[$index] - font specifications addressable by array position
   $sheetdata{fonthash}->{$value} - hash with font specification as keys and {fonts}->[] index position as values
   $sheetdata{colors}->[$index] - color specifications addressable by array position
   $sheetdata{colorhash}->{$value} - hash with color specification as keys and {colors}->[] index position as values
   $sheetdata{borderstyles}->[$index] - border style specifications addressable by array position
   $sheetdata{borderstylehash}->{$value} - hash with border style specification as keys and {borderstyles}->[] index position as values
   $sheetdata{layoutstyles}->[$index] - cell layout specifications addressable by array position
   $sheetdata{layoutstylehash}->{$value} - hash with cell layout specification as keys and {layoutstyle}->[] index position as values
   $sheetdata{cellformats}->[$index] - cell format specifications addressable by array position
   $sheetdata{cellformathash}->{$value} - hash with cell format specification as keys and {cellformats}->[] index position as values
   $sheetdata{valueformats}->[$index] - value format specifications addressable by array position
   $sheetdata{valueformathash}->{$value} - hash with value format specification as keys and {valueformats}->[] index position as values
   $sheetdata{clipboard}-> - the sheet's clipboard
      {range} - coord:coord range of where the clipboard contents came from or null if empty
      {datavalues} - like $sheetdata{datavalues} but for clipboard copy of cells
      {datatypes} - like $sheetdata{datatypes} but for clipboard copy of cells
      {valuetypes} - like $sheetdata{valuetypes} but for clipboard copy of cells
      {formulas} - like $sheetdata{formulas} but for clipboard copy of cells
      {cellerrors} - like $sheetdata{cellerrors} but for clipboard copy of cells
      {cellattribs} - like $sheetdata{cellattribs} but for clipboard copy of cells
   $sheetdata{loaderror} - if non-blank, there was an error loading this sheet and this is the text of that error

=cut

sub parse_sheet_save {

  my ($lines, $sheetdata) = @_;

  # Initialize sheetdata structure
  $sheetdata->{datavalues}      = {};
  $sheetdata->{datatypes}       = {};
  $sheetdata->{valuetypes}      = {};
  $sheetdata->{formulas}        = {};
  $sheetdata->{cellerrors}      = {};
  $sheetdata->{cellattribs}     = {};
  $sheetdata->{colattribs}      = {};
  $sheetdata->{rowattribs}      = {};
  $sheetdata->{sheetattribs}    = {};
  $sheetdata->{layoutstyles}    = [];
  $sheetdata->{layoutstylehash} = {};
  $sheetdata->{names}           = {};
  $sheetdata->{fonts}           = [];
  $sheetdata->{fonthash}        = {};
  $sheetdata->{colors}          = [];
  $sheetdata->{colorhash}       = {};
  $sheetdata->{borderstyles}    = [];
  $sheetdata->{borderstylehash} = {};
  $sheetdata->{cellformats}     = [];
  $sheetdata->{cellformathash}  = {};
  $sheetdata->{valueformats}    = [];
  $sheetdata->{valueformathash} = {};

  # Get references to the parts

  my $datavalues      = $sheetdata->{datavalues};
  my $datatypes       = $sheetdata->{datatypes};
  my $valuetypes      = $sheetdata->{valuetypes};
  my $dataformulas    = $sheetdata->{formulas};
  my $cellerrors      = $sheetdata->{cellerrors};
  my $cellattribs     = $sheetdata->{cellattribs};
  my $colattribs      = $sheetdata->{colattribs};
  my $rowattribs      = $sheetdata->{rowattribs};
  my $sheetattribs    = $sheetdata->{sheetattribs};
  my $layoutstyles    = $sheetdata->{layoutstyles};
  my $layoutstylehash = $sheetdata->{layoutstylehash};
  my $names           = $sheetdata->{names};
  my $fonts           = $sheetdata->{fonts};
  my $fonthash        = $sheetdata->{fonthash};
  my $colors          = $sheetdata->{colors};
  my $colorhash       = $sheetdata->{colorhash};
  my $borderstyles    = $sheetdata->{borderstyles};
  my $borderstylehash = $sheetdata->{borderstylehash};
  my $cellformats     = $sheetdata->{cellformats};
  my $cellformathash  = $sheetdata->{cellformathash};
  my $valueformats    = $sheetdata->{valueformats};
  my $valueformathash = $sheetdata->{valueformathash};

  my ($coord, $type, $rest);
  my ($linetype, $value, $valuetype, $formula, $style, $namename, $namedesc);
  my ($fontnum, $layoutnum, $colornum, $check, $row, $col);
  my $errortext;
  my (
    $clipdatavalues,   $clipdatatypes,  $clipvaluetypes,
    $clipdataformulas, $clipcellerrors, $clipcellattribs
  );
  my ($maxcol, $maxrow) = (0, 0);

  foreach my $line (@$lines) {
    chomp $line;
    $line =~ s/\r//g;

    # assumed already done in read. #      $line =~ s/^\x{EF}\x{BB}\x{BF}//; # remove UTF-8 Byte Order Mark if present
    my ($linetype, $rest) = split (/:/, $line, 2);
    next unless $linetype;

    if ($linetype eq "cell") {
      ($coord, $type, $rest) = split (/:/, $rest, 3);
      $coord = uc($coord);
      $cellattribs->{$coord} = { 'coord' => $coord }
        if $type;    # Must have this if cell has anything
      ($col, $row) = coord_to_cr($coord);
      $maxcol = $col if $col > $maxcol;
      $maxrow = $row if $row > $maxrow;
      while ($type) {
        if ($type eq "v") {
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $datavalues->{$coord} = decode_from_save($value);
          $datatypes->{$coord}  = "v";
          $valuetypes->{$coord} = "n";
        } elsif ($type eq "t") {
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $datavalues->{$coord} = decode_from_save($value);
          $datatypes->{$coord}  = "t";
          $valuetypes->{$coord} =
            "tw";    # Typed in text is treated as wiki text by default
        } elsif ($type eq "vt") {
          ($valuetype, $value, $type, $rest) = split (/:/, $rest, 4);
          $datavalues->{$coord} = decode_from_save($value);
          if (substr($valuetype, 0, 1) eq "n") {
            $datatypes->{$coord} = "v";
          } else {
            $datatypes->{$coord} = "t";
          }
          $valuetypes->{$coord} = $valuetype;
        } elsif ($type eq "vtf") {
          ($valuetype, $value, $formula, $type, $rest) =
            split (/:/, $rest, 5);
          $datavalues->{$coord}   = decode_from_save($value);
          $dataformulas->{$coord} = decode_from_save($formula);
          $datatypes->{$coord}    = "f";
          $valuetypes->{$coord}   = $valuetype;
        } elsif ($type eq "vtc") {
          ($valuetype, $value, $formula, $type, $rest) =
            split (/:/, $rest, 5);
          $datavalues->{$coord}   = decode_from_save($value);
          $dataformulas->{$coord} = decode_from_save($formula);
          $datatypes->{$coord}    = "c";
          $valuetypes->{$coord}   = $valuetype;
        } elsif ($type eq "vf") {    # old format
          ($value, $formula, $type, $rest) = split (/:/, $rest, 4);
          $datavalues->{$coord}   = decode_from_save($value);
          $dataformulas->{$coord} = decode_from_save($formula);
          $datatypes->{$coord}    = "f";
          if (substr($value, 0, 1) eq "N") {
            $valuetypes->{$coord} = "n";
            $datavalues->{$coord} =
              substr($datavalues->{$coord}, 1);    # remove initial type code
          } elsif (substr($value, 0, 1) eq "T") {
            $valuetypes->{$coord} = "t";
            $datavalues->{$coord} =
              substr($datavalues->{$coord}, 1);    # remove initial type code
          } elsif (substr($value, 0, 1) eq "H") {
            $valuetypes->{$coord} = "th";
            $datavalues->{$coord} =
              substr($datavalues->{$coord}, 1);    # remove initial type code
          } else {
            $valuetypes->{$coord} =
              $valuetypes->{$coord} =~ m/[^0-9+\-\.]/ ? "t" : "n";
          }
        } elsif ($type eq "e") {
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $cellerrors->{$coord} = decode_from_save($value);
        } elsif ($type eq "b") {
          my ($t, $r, $b, $l);
          ($t, $r, $b, $l, $type, $rest) = split (/:/, $rest, 6);
          $cellattribs->{$coord}->{bt} = $t;
          $cellattribs->{$coord}->{br} = $r;
          $cellattribs->{$coord}->{bb} = $b;
          $cellattribs->{$coord}->{bl} = $l;
        } elsif ($type eq "l") {
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $cellattribs->{$coord}->{layout} = $value;
        } elsif ($type eq "f") {
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $cellattribs->{$coord}->{font} = $value;
        } elsif ($type eq "c") {
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $cellattribs->{$coord}->{color} = $value;
        } elsif ($type eq "bg") {
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $cellattribs->{$coord}->{bgcolor} = $value;
        } elsif ($type eq "cf") {
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $cellattribs->{$coord}->{cellformat} = $value;
        } elsif ($type eq "cvf") {    # obsolete - only pre 1.2 format
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $cellattribs->{$coord}->{nontextvalueformat} = $value;
        } elsif ($type eq "ntvf") {
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $cellattribs->{$coord}->{nontextvalueformat} = $value;
        } elsif ($type eq "tvf") {
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $cellattribs->{$coord}->{textvalueformat} = $value;
        } elsif ($type eq "colspan") {
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $cellattribs->{$coord}->{colspan} = $value;
        } elsif ($type eq "rowspan") {
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $cellattribs->{$coord}->{rowspan} = $value;
        } elsif ($type eq "cssc") {
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $cellattribs->{$coord}->{cssc} = $value;
        } elsif ($type eq "csss") {
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $cellattribs->{$coord}->{csss} = decode_from_save($value);
        } elsif ($type eq "mod") {
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $cellattribs->{$coord}->{mod} = $value;
        } else {
          $errortext = "Unknown type '$type' in line:\n$_\n";
          last;
        }
      }
    } elsif ($linetype eq "col") {
      ($coord, $type, $rest) = split (/:/, $rest, 3);
      $coord = uc($coord);    # normalize to upper case
      $colattribs->{$coord} = { 'coord' => $coord };
      while ($type) {
        if ($type eq "w") {
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $colattribs->{$coord}->{width} = $value;
        }
        if ($type eq "hide") {
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $colattribs->{$coord}->{hide} = $value;
        } else {
          $errortext = "Unknown type '$type' in line:\n$_\n";
          last;
        }
      }
    } elsif ($linetype eq "row") {
      ($coord, $type, $rest) = split (/:/, $rest, 3);
      $rowattribs->{$coord} = { 'coord' => $coord };
      while ($type) {
        if ($type eq "h") {
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $rowattribs->{$coord}->{height} = $value;
        }
        if ($type eq "hide") {
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $rowattribs->{$coord}->{hide} = $value;
        } else {
          $errortext = "Unknown type '$type' in line:\n$_\n";
          last;
        }
      }
    } elsif ($linetype eq "sheet") {
      ($type, $rest) = split (/:/, $rest, 2);
      while ($type) {
        if ($type eq "c") {    # number of columns
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $sheetattribs->{lastcol} = $value;
        } elsif ($type eq "r") {    # number of rows
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $sheetattribs->{lastrow} = $value;
        } elsif ($type eq "w") {    # default col width
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $sheetattribs->{defaultcolwidth} = $value;
        } elsif ($type eq "h") {    #default row height
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $sheetattribs->{defaultrowheight} = $value;
        } elsif ($type eq "tf") {    #default text format
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $sheetattribs->{defaulttextformat} = $value;
        } elsif ($type eq "ntf") {    #default not text format
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $sheetattribs->{defaultnontextformat} = $value;
        } elsif ($type eq "layout") {    #default layout number
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $sheetattribs->{defaultlayout} = $value;
        } elsif ($type eq "font") {      #default font number
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $sheetattribs->{defaultfont} = $value;
        } elsif ($type eq "vf") {        #default value format number (old)
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $sheetattribs->{defaultnontextvalueformat} = $value;
          $sheetattribs->{defaulttextvalueformat}    = "";
        } elsif ($type eq "tvf") {       #default text value format number
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $sheetattribs->{defaulttextvalueformat} = $value;
        } elsif ($type eq "ntvf")
        {    #default non-text (number) value format number
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $sheetattribs->{defaultnontextvalueformat} = $value;
        } elsif ($type eq "color") {    #default text color
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $sheetattribs->{defaultcolor} = $value;
        } elsif ($type eq "bgcolor") {    #default cell background color
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $sheetattribs->{defaultbgcolor} = $value;
        } elsif ($type eq "circularreferencecell")
        {                                 #cell with a circular reference
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $sheetattribs->{circularreferencecell} = $value;
        } elsif ($type eq "recalc") {     #recalc on or off
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $sheetattribs->{recalc} = $value;
        } elsif ($type eq "needsrecalc")
        {    #recalculation needed, computed values may not be correct
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $sheetattribs->{needsrecalc} = $value;
        } else {
          $errortext = "Unknown type '$type' in line:\n$_\n";
          last;
        }
      }
    } elsif ($linetype eq "name") {
      ($namename, $namedesc, $value) = split (/:/, $rest, 3);
      $namename                         = uc(decode_from_save($namename));
      $names->{$namename}->{desc}       = decode_from_save($namedesc);
      $names->{$namename}->{definition} = decode_from_save($value);
    } elsif ($linetype eq "layout") {
      ($layoutnum, $value) = split (/:/, $rest, 2);
      $layoutstyles->[$layoutnum] = $value;
      $layoutstylehash->{$value} = $layoutnum;
    } elsif ($linetype eq "font") {
      ($fontnum, $value) = split (/:/, $rest, 2);
      $fonts->[$fontnum] = $value;
      $fonthash->{$value} = $fontnum;
    } elsif ($linetype eq "color") {
      ($colornum, $value) = split (/:/, $rest, 2);
      $colors->[$colornum] = $value;
      $colorhash->{$value} = $colornum;
    } elsif ($linetype eq "border") {
      ($style, $value) = split (/:/, $rest, 2);
      $borderstyles->[$style] = $value;
      $borderstylehash->{$value} = $style;
    } elsif ($linetype eq "cellformat") {
      ($style, $value) = split (/:/, $rest, 2);
      $cellformats->[$style] = decode_from_save($value);
      $cellformathash->{$value} = $style;
    } elsif ($linetype eq "valueformat") {
      ($style, $value) = split (/:/, $rest, 2);
      $value = decode_from_save($value);
      if ($sheetdata->{version} < 1.2) {    # old format definitions - convert
        $value =
          length($old_formats_map{$value}) >= 1
          ? $old_formats_map{$value}
          : $value;
      }
      if ($value eq "General-separator") {    # convert from 0.91
        $value = "[,]General";
      }
      $valueformats->[$style] = $value;
      $valueformathash->{$value} = $style;
    } elsif ($linetype eq "version") {
      $sheetdata->{version} = $rest;
    } elsif ($linetype eq "") {
    } elsif ($linetype eq "clipboardrange") {
      $sheetdata->{clipboard} = {};               # clear and create clipboard
      $sheetdata->{clipboard}->{datavalues} = {};
      $clipdatavalues = $sheetdata->{clipboard}->{datavalues};
      $sheetdata->{clipboard}->{datatypes} = {};
      $clipdatatypes = $sheetdata->{clipboard}->{datatypes};
      $sheetdata->{clipboard}->{valuetypes} = {};
      $clipvaluetypes = $sheetdata->{clipboard}->{valuetypes};
      $sheetdata->{clipboard}->{formulas} = {};
      $clipdataformulas = $sheetdata->{clipboard}->{formulas};
      $sheetdata->{clipboard}->{cellerrors} = {};
      $clipcellerrors = $sheetdata->{clipboard}->{cellerrors};
      $sheetdata->{clipboard}->{cellattribs} = {};
      $clipcellattribs = $sheetdata->{clipboard}->{cellattribs};

      $coord = uc($rest);
      $sheetdata->{clipboard}->{range} = $coord;
    } elsif ($linetype eq "clipboard")
    {    # must have a clipboardrange command somewhere before it
      ($coord, $type, $rest) = split (/:/, $rest, 3);
      $coord = uc($coord);
      if (!$sheetdata->{clipboard}->{range}) {
        $errortext = "Missing clipboardrange before clipboard data in file\n";
        $type      = "norange";
      }
      $clipcellattribs->{$coord} = { 'coord', $coord };
      while ($type) {
        if ($type eq "v") {
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $clipdatavalues->{$coord} = decode_from_save($value);
          $clipdatatypes->{$coord}  = "v";
          $clipvaluetypes->{$coord} = "n";
        } elsif ($type eq "t") {
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $clipdatavalues->{$coord} = decode_from_save($value);
          $clipdatatypes->{$coord}  = "t";
          $clipvaluetypes->{$coord} =
            "tw";    # Typed in text is treated as wiki text by default
        } elsif ($type eq "vt") {
          ($valuetype, $value, $type, $rest) = split (/:/, $rest, 4);
          $clipdatavalues->{$coord} = decode_from_save($value);
          if (substr($valuetype, 0, 1) eq "n") {
            $clipdatatypes->{$coord} = "v";
          } else {
            $clipdatatypes->{$coord} = "t";
          }
          $clipvaluetypes->{$coord} = $valuetype;
        } elsif ($type eq "vtf") {
          ($valuetype, $value, $formula, $type, $rest) =
            split (/:/, $rest, 5);
          $clipdatavalues->{$coord}   = decode_from_save($value);
          $clipdataformulas->{$coord} = decode_from_save($formula);
          $clipdatatypes->{$coord}    = "f";
          $clipvaluetypes->{$coord}   = $valuetype;
        } elsif ($type eq "vtc") {
          ($valuetype, $value, $formula, $type, $rest) =
            split (/:/, $rest, 5);
          $clipdatavalues->{$coord}   = decode_from_save($value);
          $clipdataformulas->{$coord} = decode_from_save($formula);
          $clipdatatypes->{$coord}    = "c";
          $clipvaluetypes->{$coord}   = $valuetype;
        } elsif ($type eq "vf") {    # old format
          ($value, $formula, $type, $rest) = split (/:/, $rest, 4);
          $clipdatavalues->{$coord}   = decode_from_save($value);
          $clipdataformulas->{$coord} = decode_from_save($formula);
          $clipdatatypes->{$coord}    = "f";
          if (substr($value, 0, 1) eq "N") {
            $clipvaluetypes->{$coord} = "n";
            $clipdatavalues->{$coord} =
              substr($clipdatavalues->{$coord}, 1); # remove initial type code
          } elsif (substr($value, 0, 1) eq "T") {
            $clipvaluetypes->{$coord} = "t";
            $clipdatavalues->{$coord} =
              substr($clipdatavalues->{$coord}, 1); # remove initial type code
          } elsif (substr($value, 0, 1) eq "H") {
            $clipvaluetypes->{$coord} = "th";
            $clipdatavalues->{$coord} =
              substr($clipdatavalues->{$coord}, 1); # remove initial type code
          } else {
            $clipvaluetypes->{$coord} =
              $clipvaluetypes->{$coord} =~ m/[^0-9+\-\.]/ ? "t" : "n";
          }
        } elsif ($type eq "e") {
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $clipcellerrors->{$coord} = decode_from_save($value);
        } elsif ($type eq "b") {
          my ($t, $r, $b, $l);
          ($t, $r, $b, $l, $type, $rest) = split (/:/, $rest, 6);
          $clipcellattribs->{$coord}->{bt} = $t;
          $clipcellattribs->{$coord}->{br} = $r;
          $clipcellattribs->{$coord}->{bb} = $b;
          $clipcellattribs->{$coord}->{bl} = $l;
        } elsif ($type eq "l") {
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $clipcellattribs->{$coord}->{layout} = $value;
        } elsif ($type eq "f") {
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $clipcellattribs->{$coord}->{font} = $value;
        } elsif ($type eq "c") {
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $clipcellattribs->{$coord}->{color} = $value;
        } elsif ($type eq "bg") {
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $clipcellattribs->{$coord}->{bgcolor} = $value;
        } elsif ($type eq "cf") {
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $clipcellattribs->{$coord}->{cellformat} = $value;
        } elsif ($type eq "cvf") {    # old
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $clipcellattribs->{$coord}->{nontextvalueformat} = $value;
        } elsif ($type eq "ntvf") {
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $clipcellattribs->{$coord}->{nontextvalueformat} = $value;
        } elsif ($type eq "tvf") {
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $clipcellattribs->{$coord}->{textvalueformat} = $value;
        } elsif ($type eq "colspan") {
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $clipcellattribs->{$coord}->{colspan} = $value;
        } elsif ($type eq "rowspan") {
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $clipcellattribs->{$coord}->{rowspan} = $value;
        } elsif ($type eq "cssc") {
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $clipcellattribs->{$coord}->{cssc} = $value;
        } elsif ($type eq "csss") {
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $clipcellattribs->{$coord}->{csss} = decode_from_save($value);
        } elsif ($type eq "mod") {
          ($value, $type, $rest) = split (/:/, $rest, 3);
          $clipcellattribs->{$coord}->{mod} = $value;
        } elsif ($type eq "norange") {
          last;
        } else {
          $errortext = "Unknown type '$type' in line:\n$_\n";
          last;
        }
      }
    } else {

      #!!!!!!
      $errortext = "Unknown linetype: $linetype\n"
        unless $linetype =~ m/^\s*#/;
    }
  }

  $sheetattribs->{lastcol} ||= $maxcol || 1;
  $sheetattribs->{lastrow} ||= $maxrow || 1;
}

=head2 create_sheet_save

  my $outstr = create_sheet_save(\%sheetdata)

Sheet output routine. Returns a string ready to be saved in a file.

=cut

sub create_sheet_save {

  my (
    $rest,     $linetype, $coord,  $type,   $value, $formula, $style,
    $colornum, $check,    $maxrow, $maxcol, $row,   $col
  );

  my $sheetdata = shift @_;
  my $outstr;

  # Get references to the parts

  my $datavalues      = $sheetdata->{datavalues};
  my $datatypes       = $sheetdata->{datatypes};
  my $valuetypes      = $sheetdata->{valuetypes};
  my $dataformulas    = $sheetdata->{formulas};
  my $cellerrors      = $sheetdata->{cellerrors};
  my $cellattribs     = $sheetdata->{cellattribs};
  my $colattribs      = $sheetdata->{colattribs};
  my $rowattribs      = $sheetdata->{rowattribs};
  my $sheetattribs    = $sheetdata->{sheetattribs};
  my $layoutstyles    = $sheetdata->{layoutstyles};
  my $layoutstylehash = $sheetdata->{layoutstylehash};
  my $names           = $sheetdata->{names};
  my $fonts           = $sheetdata->{fonts};
  my $fonthash        = $sheetdata->{fonthash};
  my $colors          = $sheetdata->{colors};
  my $colorhash       = $sheetdata->{colorhash};
  my $borderstyles    = $sheetdata->{borderstyles};
  my $borderstylehash = $sheetdata->{borderstylehash};
  my $cellformats     = $sheetdata->{cellformats};
  my $cellformathash  = $sheetdata->{cellformathash};
  my $valueformats    = $sheetdata->{valueformats};
  my $valueformathash = $sheetdata->{valueformathash};

  $outstr .= "version:1.3\n";    # sheet save version

  for (my $row = 1 ; $row <= $sheetattribs->{lastrow} ; $row++) {
    for (my $col = 1 ; $col <= $sheetattribs->{lastcol} ; $col++) {
      $coord = cr_to_coord($col, $row);
      next
        unless $cellattribs->{$coord}
        ->{coord};               # skip if nothing set for this one
      $outstr .= "cell:$coord";
      if ($datatypes->{$coord} eq "v") {
        $value = encode_for_save($datavalues->{$coord});
        if (!$valuetypes->{$coord} || $valuetypes->{$coord} eq "n")
        {                        # use simpler version
          $outstr .= ":v:$value";
        } else {                 # if we do fancy parsing to determine a type
          $outstr .= ":vt:$valuetypes->{$coord}:$value";
        }
      } elsif ($datatypes->{$coord} eq "t") {
        $value = encode_for_save($datavalues->{$coord});
        if (!$valuetypes->{$coord} || $valuetypes->{$coord} eq "tw")
        {                        # use simpler version
          $outstr .= ":t:$value";
        } else {                 # if we do fancy parsing to determine a type
          $outstr .= ":vt:$valuetypes->{$coord}:$value";
        }
      } elsif ($datatypes->{$coord} eq "f") {
        $value   = encode_for_save($datavalues->{$coord});
        $formula = encode_for_save($dataformulas->{$coord});
        $outstr .= ":vtf:$valuetypes->{$coord}:$value:$formula";
      } elsif ($datatypes->{$coord} eq "c") {
        $value   = encode_for_save($datavalues->{$coord});
        $formula = encode_for_save($dataformulas->{$coord});
        $outstr .= ":vtc:$valuetypes->{$coord}:$value:$formula";
      }

      if ($cellerrors->{$coord}) {
        $value = encode_for_save($cellerrors->{$coord});
        $outstr .= ":e:$value";
      }

      my ($t, $r, $b, $l);
      $t = $cellattribs->{$coord}->{bt};
      $r = $cellattribs->{$coord}->{br};
      $b = $cellattribs->{$coord}->{bb};
      $l = $cellattribs->{$coord}->{bl};
      $outstr .= ":b:$t:$r:$b:$l" if ($t || $r || $b || $l);

      $outstr .= ":l:$cellattribs->{$coord}->{layout}"
        if $cellattribs->{$coord}->{layout};
      $outstr .= ":f:$cellattribs->{$coord}->{font}"
        if $cellattribs->{$coord}->{font};
      $outstr .= ":c:$cellattribs->{$coord}->{color}"
        if $cellattribs->{$coord}->{color};
      $outstr .= ":bg:$cellattribs->{$coord}->{bgcolor}"
        if $cellattribs->{$coord}->{bgcolor};
      $outstr .= ":cf:$cellattribs->{$coord}->{cellformat}"
        if $cellattribs->{$coord}->{cellformat};
      $outstr .= ":tvf:$cellattribs->{$coord}->{textvalueformat}"
        if $cellattribs->{$coord}->{textvalueformat};
      $outstr .= ":ntvf:$cellattribs->{$coord}->{nontextvalueformat}"
        if $cellattribs->{$coord}->{nontextvalueformat};
      $outstr .= ":colspan:$cellattribs->{$coord}->{colspan}"
        if $cellattribs->{$coord}->{colspan};
      $outstr .= ":rowspan:$cellattribs->{$coord}->{rowspan}"
        if $cellattribs->{$coord}->{rowspan};
      $outstr .= ":cssc:$cellattribs->{$coord}->{cssc}"
        if $cellattribs->{$coord}->{cssc};
      $outstr .= ":csss:" . encode_for_save($cellattribs->{$coord}->{csss})
        if $cellattribs->{$coord}->{csss};
      $outstr .= ":mod:$cellattribs->{$coord}->{mod}"
        if $cellattribs->{$coord}->{mod};

      $outstr .= "\n";
    }
  }

  for (my $col = 1 ; $col <= $sheetattribs->{lastcol} ; $col++) {
    $coord = cr_to_coord($col, 1);
    $coord =~ s/\d+//;
    $outstr .= "col:$coord:w:$colattribs->{$coord}->{width}\n"
      if $colattribs->{$coord}->{width};
    $outstr .= "col:$coord:hide:$colattribs->{$coord}->{hide}\n"
      if $colattribs->{$coord}->{hide};
  }

  for (my $row = 1 ; $row <= $sheetattribs->{lastrow} ; $row++) {
    $outstr .= "row:$row:w:$rowattribs->{$row}->{height}\n"
      if $rowattribs->{$row}->{height};
    $outstr .= "row:$row:hide:$rowattribs->{$row}->{hide}\n"
      if $rowattribs->{$row}->{hide};
  }

  $outstr .= "sheet";
  foreach my $field (keys %sheetfields) {
    my $value = encode_for_save($sheetattribs->{$field});
    $outstr .= ":$sheetfields{$field}:$value" if $value;
  }
  $outstr .= "\n";

  foreach my $namename (sort keys %$names) {
    my $namesc           = encode_for_save(uc $namename);
    my $namedescsc       = encode_for_save($names->{$namename}->{desc});
    my $namedefinitionsc = encode_for_save($names->{$namename}->{definition});
    $outstr .= "name:$namesc:$namedescsc:$namedefinitionsc\n";
  }

  for (my $i = 1 ; $i < @$layoutstyles ; $i++) {
    $outstr .= "layout:$i:$layoutstyles->[$i]\n";
  }

  for (my $i = 1 ; $i < @$fonts ; $i++) {
    $outstr .= "font:$i:$fonts->[$i]\n";
  }

  for (my $i = 1 ; $i < @$colors ; $i++) {
    $outstr .= "color:$i:$colors->[$i]\n";
  }

  for (my $i = 1 ; $i < @$borderstyles ; $i++) {
    $outstr .= "border:$i:$borderstyles->[$i]\n";
  }

  for (my $i = 1 ; $i < @$cellformats ; $i++) {
    $style = encode_for_save($cellformats->[$i]);
    $outstr .= "cellformat:$i:$style\n";
  }

  for (my $i = 1 ; $i < @$valueformats ; $i++) {
    $style = encode_for_save($valueformats->[$i]);
    $outstr .= "valueformat:$i:$style\n";
  }

  if ($sheetdata->{clipboard}) {
    my $clipdatavalues   = $sheetdata->{clipboard}->{datavalues};
    my $clipdatatypes    = $sheetdata->{clipboard}->{datatypes};
    my $clipvaluetypes   = $sheetdata->{clipboard}->{valuetypes};
    my $clipdataformulas = $sheetdata->{clipboard}->{formulas};
    my $clipcellerrors   = $sheetdata->{clipboard}->{cellerrors};
    my $clipcellattribs  = $sheetdata->{clipboard}->{cellattribs};

    $outstr .= "clipboardrange:$sheetdata->{clipboard}->{range}\n";

    foreach my $coord (sort keys %$clipcellattribs) {
      $outstr .= "clipboard:$coord";
      if ($clipdatatypes->{$coord} eq "v") {
        $value = encode_for_save($clipdatavalues->{$coord});
        if (!$clipvaluetypes->{$coord} || $clipvaluetypes->{$coord} eq "n")
        {    # use simpler version
          $outstr .= ":v:$value";
        } else {    # if we do fancy parsing to determine a type
          $outstr .= ":vt:$clipvaluetypes->{$coord}:$value";
        }
      } elsif ($clipdatatypes->{$coord} eq "t") {
        $value = encode_for_save($clipdatavalues->{$coord});
        if (!$clipvaluetypes->{$coord} || $clipvaluetypes->{$coord} eq "tw")
        {           # use simpler version
          $outstr .= ":t:$value";
        } else {    # if we do fancy parsing to determine a type
          $outstr .= ":vt:$clipvaluetypes->{$coord}:$value";
        }
      } elsif ($clipdatatypes->{$coord} eq "f") {
        $value   = encode_for_save($clipdatavalues->{$coord});
        $formula = encode_for_save($clipdataformulas->{$coord});
        $outstr .= ":vtf:$clipvaluetypes->{$coord}:$value:$formula";
      } elsif ($clipdatatypes->{$coord} eq "c") {
        $value   = encode_for_save($clipdatavalues->{$coord});
        $formula = encode_for_save($clipdataformulas->{$coord});
        $outstr .= ":vtc:$clipvaluetypes->{$coord}:$value:$formula";
      }

      if ($clipcellerrors->{$coord}) {
        $value = encode_for_save($clipcellerrors->{$coord});
        $outstr .= ":e:$value";
      }

      my ($t, $r, $b, $l);
      $t = $clipcellattribs->{$coord}->{bt};
      $r = $clipcellattribs->{$coord}->{br};
      $b = $clipcellattribs->{$coord}->{bb};
      $l = $clipcellattribs->{$coord}->{bl};
      $outstr .= ":b:$t:$r:$b:$l" if ($t || $r || $b || $l);

      $outstr .= ":l:$clipcellattribs->{$coord}->{layout}"
        if $clipcellattribs->{$coord}->{layout};
      $outstr .= ":f:$clipcellattribs->{$coord}->{font}"
        if $clipcellattribs->{$coord}->{font};
      $outstr .= ":c:$clipcellattribs->{$coord}->{color}"
        if $clipcellattribs->{$coord}->{color};
      $outstr .= ":bg:$clipcellattribs->{$coord}->{bgcolor}"
        if $clipcellattribs->{$coord}->{bgcolor};
      $outstr .= ":cf:$clipcellattribs->{$coord}->{cellformat}"
        if $clipcellattribs->{$coord}->{cellformat};
      $outstr .= ":tvf:$clipcellattribs->{$coord}->{textvalueformat}"
        if $clipcellattribs->{$coord}->{textvalueformat};
      $outstr .= ":ntvf:$clipcellattribs->{$coord}->{nontextvalueformat}"
        if $clipcellattribs->{$coord}->{nontextvalueformat};
      $outstr .= ":colspan:$clipcellattribs->{$coord}->{colspan}"
        if $clipcellattribs->{$coord}->{colspan};
      $outstr .= ":rowspan:$clipcellattribs->{$coord}->{rowspan}"
        if $clipcellattribs->{$coord}->{rowspan};
      $outstr .= ":cssc:$clipcellattribs->{$coord}->{cssc}"
        if $clipcellattribs->{$coord}->{cssc};
      $outstr .=
        ":csss:" . encode_for_save($clipcellattribs->{$coord}->{csss})
        if $clipcellattribs->{$coord}->{csss};
      $outstr .= ":mod:$clipcellattribs->{$coord}->{mod}"
        if $clipcellattribs->{$coord}->{mod};

      $outstr .= "\n";
    }

  }

  return $outstr;
}

=head2 execute_sheet_command

  $ok = execute_sheet_command($sheetdata, $command);

Executes commands that modify the sheet data. Sets sheet "needsrecalc" as needed.

The commands are in the forms:

    set sheet attributename value (plus lastcol and lastrow)
    set 22 attributename value
    set B attributename value
    set A1 attributename value1 value2... (see each attribute below for details)
    set A1:B5 attributename value1 value2...
    erase/copy/cut/paste/fillright/filldown A1:B5 all/formulas/format
    clearclipboard
    merge C3:F3
    unmerge C3
    insertcol/insertrow C5
    deletecol/deleterow C5:E7
    name define NAME definition
    name desc NAME description
    name delete NAME

=cut

sub execute_sheet_command {

  my ($sheetdata, $command) = @_;

  # Get references to the parts

  my $datavalues      = $sheetdata->{datavalues};
  my $datatypes       = $sheetdata->{datatypes};
  my $valuetypes      = $sheetdata->{valuetypes};
  my $dataformulas    = $sheetdata->{formulas};
  my $cellerrors      = $sheetdata->{cellerrors};
  my $cellattribs     = $sheetdata->{cellattribs};
  my $colattribs      = $sheetdata->{colattribs};
  my $rowattribs      = $sheetdata->{rowattribs};
  my $sheetattribs    = $sheetdata->{sheetattribs};
  my $layoutstyles    = $sheetdata->{layoutstyles};
  my $layoutstylehash = $sheetdata->{layoutstylehash};
  my $names           = $sheetdata->{names};
  my $fonts           = $sheetdata->{fonts};
  my $fonthash        = $sheetdata->{fonthash};
  my $colors          = $sheetdata->{colors};
  my $colorhash       = $sheetdata->{colorhash};
  my $borderstyles    = $sheetdata->{borderstyles};
  my $borderstylehash = $sheetdata->{borderstylehash};
  my $cellformats     = $sheetdata->{cellformats};
  my $cellformathash  = $sheetdata->{cellformathash};
  my $valueformats    = $sheetdata->{valueformats};
  my $valueformathash = $sheetdata->{valueformathash};

  my (
    $what,  $coord1, $coord2, $attrib, $name,
    $value, $v1,     $v2,     $v3,     $errortext
  );

  my ($cmd1, $rest) = split (/ /, $command, 2);
  return unless $cmd1;

  if ($cmd1 eq "set") {
    ($what, $attrib, $rest) = split (/ /, $rest, 3);
    if ($what eq "sheet") {    # sheet attributes
      if ($attrib eq "defaultcolwidth") {
        $sheetattribs->{defaultcolwidth} = $rest;
      } elsif ($attrib eq "defaultcolor" || $attrib eq "defaultbgcolor") {
        my $colordef = 0;
        $colordef = $colorhash->{$rest} if $rest;
        if (!$colordef) {
          if ($rest) {
            push @$colors, "" unless scalar @$colors;
            $colordef = (push @$colors, $rest) - 1;
            $colorhash->{$rest} = $colordef;
          }
        }
        $sheetattribs->{$attrib} = $colordef;
      } elsif ($attrib eq "defaultlayout") {
        my $layoutdef = 0;
        $layoutdef = $layoutstylehash->{$rest} if $rest;
        if (!$layoutdef) {
          if ($rest) {
            push @$layoutstyles, "" unless scalar @$layoutstyles;
            $layoutdef = (push @$layoutstyles, $rest) - 1;
            $layoutstylehash->{$rest} = $layoutdef;
          }
        }
        $sheetattribs->{$attrib} = $layoutdef;
      } elsif ($attrib eq "defaultfont") {
        my $fontdef = 0;
        $rest = "" if $rest eq "* * *";
        $fontdef = $fonthash->{$rest} if $rest;
        if (!$fontdef) {
          if ($rest) {
            push @$fonts, "" unless scalar @$fonts;
            $fontdef = (push @$fonts, $rest) - 1;
            $fonthash->{$rest} = $fontdef;
          }
        }
        $sheetattribs->{$attrib} = $fontdef;
      } elsif ($attrib eq "defaulttextformat"
        || $attrib eq "defaultnontextformat") {
        my $formatdef = 0;
        $formatdef = $cellformathash->{$rest} if $rest;
        if (!$formatdef) {
          if ($rest) {
            push @$cellformats, "" unless scalar @$cellformats;
            $formatdef = (push @$cellformats, $rest) - 1;
            $cellformathash->{$rest} = $formatdef;
          }
        }
        $sheetattribs->{$attrib} = $formatdef;
        } elsif ($attrib eq "defaulttextvalueformat"
        || $attrib eq "defaultnontextvalueformat") {
        my $formatdef = 0;
        $formatdef = $valueformathash->{$rest} if length($rest);
        if (!$formatdef) {
          if (length($rest)) {
            push @$valueformats, "" unless scalar @$valueformats;
            $formatdef = (push @$valueformats, $rest) - 1;
            $valueformathash->{$rest} = $formatdef;
          }
        }
        $sheetattribs->{$attrib} = $formatdef;
        } elsif ($attrib eq "lastcol") {
        $sheetattribs->{lastcol} = $rest + 0;
        $sheetattribs->{lastcol} = 1 if ($sheetattribs->{lastcol} <= 0);
        } elsif ($attrib eq "lastrow") {
        $sheetattribs->{lastrow} = $rest + 0;
        $sheetattribs->{lastrow} = 1 if ($sheetattribs->{lastrow} <= 0);
      }
    } elsif ($what =~ m/^(\d+)(\:(\d+)){0,1}$/) {    # row attributes
      my ($row1, $row2);
      if ($what =~ m/^(.+?):(.+?)$/) {
        $row1 = $1;
        $row2 = $2;
      } else {
        $row1 = $what;
        $row2 = $row1;
      }
      if ($attrib eq "hide") {
        for (my $r = $row1 ; $r <= $row2 ; $r++) {
          $rowattribs->{$r} = { 'coord' => $r } unless $rowattribs->{$r};
          $rowattribs->{$r}->{hide} = $rest;
        }
      } else {
        $errortext = "Unknown attributename '$attrib' in line:\n$command\n";
        return 0;
      }
    } elsif ($what =~ m/(^[a-zA-Z])([a-zA-Z])?(:[a-zA-Z][a-zA-Z]?){0,1}$/)
    {    # column attributes
      my ($col1, $col2);
      if ($what =~ m/(.+?):(.+?)/) {
        $col1 = col_to_number($1);
        $col2 = col_to_number($2);
      } else {
        $col1 = col_to_number($what);
        $col2 = $col1;
      }
      if ($attrib eq "width") {
        for (my $c = $col1 ; $c <= $col2 ; $c++) {
          my $colname = number_to_col($c);
          $colattribs->{$colname} = { 'coord' => $colname }
            unless $colattribs->{$colname};
          $colattribs->{$colname}->{width} = $rest;
        }
      }
      if ($attrib eq "hide") {
        for (my $c = $col1 ; $c <= $col2 ; $c++) {
          my $colname = number_to_col($c);
          $colattribs->{$colname} = { 'coord' => $colname }
            unless $colattribs->{$colname};
          $colattribs->{$colname}->{hide} = $rest;
        }
      } else {
        $errortext = "Unknown attributename '$attrib' in line:\n$command\n";
        return 0;
      }
    } elsif ($what =~ m/([a-z]|[A-Z])([a-z]|[A-Z])?(\d+)/) { # cell attributes
      $what = uc($what);
      ($coord1, $coord2) = split (/:/, $what);
      my ($c1, $r1) = coord_to_cr($coord1);
      my $c2 = $c1;
      my $r2 = $r1;
      ($c2, $r2) = coord_to_cr($coord2) if $coord2;
      $sheetattribs->{lastcol} = $c2 if $c2 > $sheetattribs->{lastcol};
      $sheetattribs->{lastrow} = $r2 if $r2 > $sheetattribs->{lastrow};

      for (my $r = $r1 ; $r <= $r2 ; $r++) {
        for (my $c = $c1 ; $c <= $c2 ; $c++) {
          my $cr = cr_to_coord($c, $r);
          if ($attrib eq "value") {    # set coord value type numeric-value
            $cellattribs->{$cr} = { 'coord' => $cr }
              unless $cellattribs->{$cr}->{coord};
            ($v1, $v2) = split (/ /, $rest, 2);
            $datavalues->{$cr} = $v2;
            delete $cellerrors->{$cr};
            $datatypes->{$cr}                         = "v";
            $valuetypes->{$cr}                        = $v1;
            $sheetdata->{sheetattribs}->{needsrecalc} = "yes";
          } elsif ($attrib eq "text") {    # set coord text type text-value
            $cellattribs->{$cr} = { 'coord' => $cr }
              unless $cellattribs->{$cr}->{coord};
            ($v1, $v2) = split (/ /, $rest, 2);
            $datavalues->{$cr} = $v2;
            delete $cellerrors->{$cr};
            $datatypes->{$cr}                         = "t";
            $valuetypes->{$cr}                        = $v1;
            $sheetdata->{sheetattribs}->{needsrecalc} = "yes";
          } elsif ($attrib eq "formula")
          {    # set coord formula formula-body-less-initial-=
            $cellattribs->{$cr} = { 'coord' => $cr }
              unless $cellattribs->{$cr}->{coord};
            $datavalues->{$cr} = 0;
            delete $cellerrors->{$cr};
            $datatypes->{$cr}    = "f";
            $valuetypes->{$cr}   = "n";     # until recalc'ed
            $dataformulas->{$cr} = $rest;
            $sheetdata->{sheetattribs}->{needsrecalc} = "yes";
          } elsif ($attrib eq "constant")
          {    # set coord constant type numeric-value source-text
            $cellattribs->{$cr} = { 'coord' => $cr }
              unless $cellattribs->{$cr}->{coord};
            ($v1, $v2, $v3) = split (/ /, $rest, 3);
            $datavalues->{$cr} = $v2;
            if (substr($v1, 0, 1) eq "e") {    # error
              $cellerrors->{$cr} = substr($v1, 1);
            } else {
              delete $cellerrors->{$cr};
            }
            $datatypes->{$cr}                         = "c";
            $valuetypes->{$cr}                        = $v1;
            $dataformulas->{$cr}                      = $v3;
            $sheetdata->{sheetattribs}->{needsrecalc} = "yes";
          } elsif ($attrib eq "empty") {    # erase value
            delete $datavalues->{$cr};
            delete $cellerrors->{$cr};
            delete $datatypes->{$cr};
            delete $valuetypes->{$cr};
            $sheetdata->{sheetattribs}->{needsrecalc} = "yes";
          } elsif ($attrib =~ m/^b[trbl]$/) {
            $cellattribs->{$cr} = { 'coord' => $cr }
              unless $cellattribs->{$cr}->{coord};
            my $borderdef = 0;
            $borderdef = $borderstylehash->{$rest} if $rest;
            if (!$borderdef) {
              if ($rest) {
                push @$borderstyles, "" unless scalar @$borderstyles;
                $borderdef = (push @$borderstyles, $rest) - 1;
                $borderstylehash->{$rest} = $borderdef;
              }
            }
            $cellattribs->{$cr}->{$attrib} = $borderdef;
          } elsif ($attrib eq "color" || $attrib eq "bgcolor") {
            $cellattribs->{$cr} = { 'coord' => $cr }
              unless $cellattribs->{$cr}->{coord};
            my $colordef = 0;
            $colordef = $colorhash->{$rest} if $rest;
            if (!$colordef) {
              if ($rest) {
                push @$colors, "" unless scalar @$colors;
                $colordef = (push @$colors, $rest) - 1;
                $colorhash->{$rest} = $colordef;
              }
            }
            $cellattribs->{$cr}->{$attrib} = $colordef;
          } elsif ($attrib eq "layout") {
            $cellattribs->{$cr} = { 'coord' => $cr }
              unless $cellattribs->{$cr}->{coord};
            my $layoutdef = 0;
            $layoutdef = $layoutstylehash->{$rest} if $rest;
            if (!$layoutdef) {
              if ($rest) {
                push @$layoutstyles, "" unless scalar @$layoutstyles;
                $layoutdef = (push @$layoutstyles, $rest) - 1;
                $layoutstylehash->{$rest} = $layoutdef;
              }
            }
            $cellattribs->{$cr}->{$attrib} = $layoutdef;
          } elsif ($attrib eq "font") {
            $cellattribs->{$cr} = { 'coord' => $cr }
              unless $cellattribs->{$cr}->{coord};
            my $fontdef = 0;
            $rest = "" if $rest eq "* * *";
            $fontdef = $fonthash->{$rest} if $rest;
            if (!$fontdef) {
              if ($rest) {
                push @$fonts, "" unless scalar @$fonts;
                $fontdef = (push @$fonts, $rest) - 1;
                $fonthash->{$rest} = $fontdef;
              }
            }
            $cellattribs->{$cr}->{$attrib} = $fontdef;
          } elsif ($attrib eq "cellformat") {
            $cellattribs->{$cr} = { 'coord' => $cr }
              unless $cellattribs->{$cr}->{coord};
            my $formatdef = 0;
            $formatdef = $cellformathash->{$rest} if $rest;
            if (!$formatdef) {
              if ($rest) {
                push @$cellformats, "" unless scalar @$cellformats;
                $formatdef = (push @$cellformats, $rest) - 1;
                $cellformathash->{$rest} = $formatdef;
              }
            }
            $cellattribs->{$cr}->{$attrib} = $formatdef;
          } elsif ($attrib eq "textvalueformat"
            || $attrib eq "nontextvalueformat") {
            $cellattribs->{$cr} = { 'coord' => $cr }
              unless $cellattribs->{$cr}->{coord};
            my $formatdef = 0;
            $formatdef = $valueformathash->{$rest} if length($rest);
            if (!$formatdef) {
              if (length($rest)) {
                push @$valueformats, "" unless scalar @$valueformats;
                $formatdef = (push @$valueformats, $rest) - 1;
                $valueformathash->{$rest} = $formatdef;
              }
            }
            $cellattribs->{$cr}->{$attrib} = $formatdef;
            } elsif ($attrib eq "cssc") {
            $cellattribs->{$cr} = { 'coord' => $cr }
              unless $cellattribs->{$cr}->{coord};
            $rest =~ s/[^a-zA-Z0-9\-]//g;
            $cellattribs->{$cr}->{$attrib} = $rest;
            } elsif ($attrib eq "csss") {
            $cellattribs->{$cr} = { 'coord' => $cr }
              unless $cellattribs->{$cr}->{coord};
            $rest =~ s/\n//g;
            $cellattribs->{$cr}->{$attrib} = $rest;
            } elsif ($attrib eq "mod") {
            $cellattribs->{$cr} = { 'coord' => $cr }
              unless $cellattribs->{$cr}->{coord};
            $rest =~ s/[^yY]//g;
            $cellattribs->{$cr}->{$attrib} = lc $rest;
            } else {
            $errortext =
              "Unknown attributename '$attrib' in line:\n$command\n";
            return 0;
          }
        }
      }
    }
  }

  elsif ($cmd1 =~ m/^(?:erase|copy|cut|paste|fillright|filldown|sort)$/) {
    ($what, $rest) = split (/ /, $rest, 2);
    $what = uc($what);
    ($coord1, $coord2) = split (/:/, $what);
    my ($c1, $r1) = coord_to_cr($coord1);
    my $c2 = $c1;
    my $r2 = $r1;
    ($c2, $r2) = coord_to_cr($coord2) if $coord2;
    $sheetattribs->{lastcol} = $c2 if $c2 > $sheetattribs->{lastcol};
    $sheetattribs->{lastrow} = $r2 if $r2 > $sheetattribs->{lastrow};

    if ($cmd1 eq "erase") {
      for (my $r = $r1 ; $r <= $r2 ; $r++) {
        for (my $c = $c1 ; $c <= $c2 ; $c++) {
          my $cr = cr_to_coord($c, $r);
          if ($rest eq "all") {
            delete $cellattribs->{$cr};
            delete $datavalues->{$cr};
            delete $dataformulas->{$cr};
            delete $cellerrors->{$cr};
            delete $datatypes->{$cr};
            delete $valuetypes->{$cr};
          } elsif ($rest eq "formulas") {
            delete $datavalues->{$cr};
            delete $dataformulas->{$cr};
            delete $cellerrors->{$cr};
            delete $datatypes->{$cr};
            delete $valuetypes->{$cr};
          } elsif ($rest eq "formats") {
            $cellattribs->{$cr} = { 'coord' => $cr }; # Leave with minimal set
          }
        }
      }
      $sheetdata->{sheetattribs}->{needsrecalc} = "yes";
    }

    elsif ($cmd1 eq "fillright" || $cmd1 eq "filldown") {
      my ($fillright, $rowstart, $colstart);
      if ($cmd1 eq "fillright") {
        $fillright = 1;
        $rowstart  = $r1;
        $colstart  = $c1 + 1;
      } else {
        $rowstart = $r1 + 1;
        $colstart = $c1;
      }
      for (my $r = $rowstart ; $r <= $r2 ; $r++) {
        for (my $c = $colstart ; $c <= $c2 ; $c++) {
          my $cr = cr_to_coord($c, $r);
          my ($crbase, $rowoffset, $coloffset);
          if ($fillright) {
            $crbase    = cr_to_coord($c1, $r);
            $coloffset = $c - $colstart + 1;
            $rowoffset = 0;
          } else {
            $crbase    = cr_to_coord($c, $r1);
            $coloffset = 0;
            $rowoffset = $r - $rowstart + 1;
          }
          if ($rest eq "all" || $rest eq "formats") {
            $cellattribs->{$cr} = { 'coord' => $cr }; # Start with minimal set
            foreach my $attribtype (keys %{ $cellattribs->{$crbase} }) {
              if ($attribtype ne "coord") {
                $cellattribs->{$cr}->{$attribtype} =
                  $cellattribs->{$crbase}->{$attribtype};
              }
            }
          }
          if ($rest eq "all" || $rest eq "formulas") {
            $cellattribs->{$cr} = { 'coord' => $cr }
              unless $cellattribs->{$cr}->{coord};    # Make sure this exists
            $datavalues->{$cr} = $datavalues->{$crbase};
            $datatypes->{$cr}  = $datatypes->{$crbase};
            $valuetypes->{$cr} = $valuetypes->{$crbase};
            if ($datatypes->{$cr} eq "f")
            {    # offset relative coords, even in sheet references
              $dataformulas->{$cr} =
                offset_formula_coords($dataformulas->{$crbase},
                $coloffset, $rowoffset);
            } else {
              $dataformulas->{$cr} = $dataformulas->{$crbase};
            }
            $cellerrors->{$cr} = $cellerrors->{$crbase};
          }
        }
      }
      $sheetdata->{sheetattribs}->{needsrecalc} = "yes";
    }

    elsif ($cmd1 eq "copy" || $cmd1 eq "cut") {
      $sheetdata->{clipboard} = {};               # clear and create clipboard
      $sheetdata->{clipboard}->{datavalues} = {};
      my $clipdatavalues = $sheetdata->{clipboard}->{datavalues};
      $sheetdata->{clipboard}->{datatypes} = {};
      my $clipdatatypes = $sheetdata->{clipboard}->{datatypes};
      $sheetdata->{clipboard}->{valuetypes} = {};
      my $clipvaluetypes = $sheetdata->{clipboard}->{valuetypes};
      $sheetdata->{clipboard}->{formulas} = {};
      my $clipdataformulas = $sheetdata->{clipboard}->{formulas};
      $sheetdata->{clipboard}->{cellerrors} = {};
      my $clipcellerrors = $sheetdata->{clipboard}->{cellerrors};
      $sheetdata->{clipboard}->{cellattribs} = {};
      my $clipcellattribs = $sheetdata->{clipboard}->{cellattribs};

      for (my $r = $r1 ; $r <= $r2 ; $r++) {
        for (my $c = $c1 ; $c <= $c2 ; $c++) {
          my $cr = cr_to_coord($c, $r);
          $clipcellattribs->{$cr}->{ 'coord' => $cr } =
            '';    # make sure something (used for save)
          if ($rest eq "all" || $rest eq "formats") {
            foreach my $attribtype (keys %{ $cellattribs->{$cr} }) {
              $clipcellattribs->{$cr}->{$attribtype} =
                $cellattribs->{$cr}->{$attribtype};
            }
            if ($cmd1 eq "cut") {
              delete $cellattribs->{$cr};
              $cellattribs->{$cr} = { 'coord' => $cr } if $rest eq "formats";
            }
          }
          if ($rest eq "all" || $rest eq "formulas") {
            $clipcellattribs->{$cr}->{coord} =
              $cellattribs->{$cr}->{coord};    # used by save
            $clipdatavalues->{$cr}   = $datavalues->{$cr};
            $clipdataformulas->{$cr} = $dataformulas->{$cr};
            $clipcellerrors->{$cr}   = $cellerrors->{$cr};
            $clipdatatypes->{$cr}    = $datatypes->{$cr};
            $clipvaluetypes->{$cr}   = $valuetypes->{$cr};
            if ($cmd1 eq "cut") {
              delete $datavalues->{$cr};
              delete $dataformulas->{$cr};
              delete $cellerrors->{$cr};
              delete $datatypes->{$cr};
              delete $valuetypes->{$cr};
            }
          }
        }
      }
      $sheetdata->{clipboard}->{range} =
        $coord2 ? "$coord1:$coord2" : "$coord1:$coord1";
      $sheetdata->{sheetattribs}->{needsrecalc} = "yes" if $cmd1 eq "cut";
    }

    elsif ($cmd1 eq "paste") {
      my $crbase = $sheetdata->{clipboard}->{range};
      if (!$crbase) {
        $errortext = "Empty clipboard\n";
        return 0;
      }
      my $clipdatavalues   = $sheetdata->{clipboard}->{datavalues};
      my $clipdatatypes    = $sheetdata->{clipboard}->{datatypes};
      my $clipvaluetypes   = $sheetdata->{clipboard}->{valuetypes};
      my $clipdataformulas = $sheetdata->{clipboard}->{formulas};
      my $clipcellerrors   = $sheetdata->{clipboard}->{cellerrors};
      my $clipcellattribs  = $sheetdata->{clipboard}->{cellattribs};

      my ($clipcoord1, $clipcoord2) = split (/:/, $crbase);
      $clipcoord2 = $clipcoord1 unless $clipcoord2;
      my ($clipc1, $clipr1) = coord_to_cr($clipcoord1);
      my ($clipc2, $clipr2) = coord_to_cr($clipcoord2);
      my $coloffset = $c1 - $clipc1;
      my $rowoffset = $r1 - $clipr1;
      my $numcols   = $clipc2 - $clipc1 + 1;
      my $numrows   = $clipr2 - $clipr1 + 1;
      $sheetattribs->{lastcol} = $c1 + $numcols - 1
        if $c1 + $numcols - 1 > $sheetattribs->{lastcol};
      $sheetattribs->{lastrow} = $r1 + $numrows - 1
        if $r1 + $numrows - 1 > $sheetattribs->{lastrow};

      for (my $r = 0 ; $r < $numrows ; $r++) {
        for (my $c = 0 ; $c < $numcols ; $c++) {
          my $cr     = cr_to_coord($c1 + $c,     $r1 + $r);
          my $clipcr = cr_to_coord($clipc1 + $c, $clipr1 + $r);
          if ($rest eq "all" || $rest eq "formats") {
            $cellattribs->{$cr} = { 'coord' => $cr }; # Start with minimal set
            foreach my $attribtype (keys %{ $clipcellattribs->{$clipcr} }) {
              if ($attribtype ne "coord") {
                $cellattribs->{$cr}->{$attribtype} =
                  $clipcellattribs->{$clipcr}->{$attribtype};
              }
            }
          }
          if ($rest eq "all" || $rest eq "formulas") {
            $cellattribs->{$cr} = { 'coord' => $cr }
              unless $cellattribs->{$cr}->{coord};    # Make sure this exists
            $datavalues->{$cr} = $clipdatavalues->{$clipcr};
            $datatypes->{$cr}  = $clipdatatypes->{$clipcr};
            $valuetypes->{$cr} = $clipvaluetypes->{$clipcr};
            if ($datatypes->{$cr} eq "f")
            { # offset coord refs, even to *** relative *** coords in other sheets
              $dataformulas->{$cr} =
                offset_formula_coords($clipdataformulas->{$clipcr},
                $coloffset, $rowoffset);
            } else {
              $dataformulas->{$cr} = $clipdataformulas->{$clipcr};
            }
            $cellerrors->{$cr} = $clipcellerrors->{$clipcr};
          }
        }
      }
      $sheetdata->{sheetattribs}->{needsrecalc} = "yes";
    }

    elsif ($cmd1 eq "sort")
    {    # sort cr1:cr2 col1 up/down col2 up/down col3 up/down
      my @col_dirs = split (/\s+/, $rest);
      my (@cols, @dirs);
      ($cols[1], $dirs[1], $cols[2], $dirs[2], $cols[3], $dirs[3]) =
        @col_dirs;
      my $nsortcols = int((scalar @col_dirs) / 2);
      my $sortdata = {};    # make a place to hold data to sort
      $sortdata->{datavalues} = {};
      my $sortdatavalues = $sortdata->{datavalues};
      $sortdata->{datatypes} = {};
      my $sortdatatypes = $sortdata->{datatypes};
      $sortdata->{valuetypes} = {};
      my $sortvaluetypes = $sortdata->{valuetypes};
      $sortdata->{formulas} = {};
      my $sortdataformulas = $sortdata->{formulas};
      $sortdata->{cellerrors} = {};
      my $sortcellerrors = $sortdata->{cellerrors};
      $sortdata->{cellattribs} = {};
      my $sortcellattribs = $sortdata->{cellattribs};

      my (@sortlist, @sortvalues, @sorttypes, @rowvalues, @rowtypes);
      for (my $r = $r1 ; $r <= $r2 ; $r++)
      {    # make a copy to replace over original in new order
        for (my $c = $c1 ; $c <= $c2 ; $c++) {
          my $cr = cr_to_coord($c, $r);
          next if !$cellattribs->{$cr}->{coord};    # don't copy blank cells
          $sortcellattribs->{$cr}->{ 'coord' => $cr } = '';
          foreach my $attribtype (keys %{ $cellattribs->{$cr} }) {
            $sortcellattribs->{$cr}->{$attribtype} =
              $cellattribs->{$cr}->{$attribtype};
          }
          $sortcellattribs->{$cr}->{coord} =
            $cellattribs->{$cr}->{coord};           # used by save
          $sortdatavalues->{$cr}   = $datavalues->{$cr};
          $sortdataformulas->{$cr} = $dataformulas->{$cr};
          $sortcellerrors->{$cr}   = $cellerrors->{$cr};
          $sortdatatypes->{$cr}    = $datatypes->{$cr};
          $sortvaluetypes->{$cr}   = $valuetypes->{$cr};
        }
        push @sortlist, scalar @sortlist;   # make list to sort (0..numrows-1)
        @rowvalues = ();
        @rowtypes  = ();
        for (my $i = 1 ; $i <= $nsortcols ; $i++)
        {    # save values and types for comparing
          my $cr = "$cols[$i]$r";    # get from each sorting column
          push @rowvalues, $datavalues->{$cr};
          push @rowtypes,
            (substr($valuetypes->{$cr}, 0, 1) || "b");    # just major type
        }
        push @sortvalues, [@rowvalues];
        push @sorttypes,  [@rowtypes];
      }

      # Do the sort

      my ($a1, $b1, $ta, $tb, $cresult);
      @sortlist = sort {
        for (my $i = 0 ; $i < $nsortcols ; $i++) {
          if ($dirs[ $i + 1 ] eq "up") {    # handle sort direction
            $a1 = $a;
            $b1 = $b;
          } else {
            $a1 = $b;
            $b1 = $a;
          }
          $ta = $sorttypes[$a1][$i];
          $tb = $sorttypes[$b1][$i];
          if ($ta eq "t")
          {    # numbers < text < errors, blank always last no matter what dir
            if ($tb eq "t") {
              $cresult =
                (lc $sortvalues[$a1][$i]) cmp(lc $sortvalues[$b1][$i]);
            } elsif ($tb eq "n") {
              $cresult = 1;
            } elsif ($tb eq "b") {
              $cresult = $dirs[ $i + 1 ] eq "up" ? -1 : 1;
            } elsif ($tb eq "e") {
              $cresult = -1;
            }
          } elsif ($ta eq "n") {
            if ($tb eq "t") {
              $cresult = -1;
            } elsif ($tb eq "n") {
              $cresult = $sortvalues[$a1][$i] <=> $sortvalues[$b1][$i];
            } elsif ($tb eq "b") {
              $cresult = $dirs[ $i + 1 ] eq "up" ? -1 : 1;
            } elsif ($tb eq "e") {
              $cresult = -1;
            }
          } elsif ($ta eq "e") {
            if ($tb eq "e") {
              $cresult = $sortvalues[$a1][$i] <=> $sortvalues[$b1][$i];
            } elsif ($tb eq "b") {
              $cresult = $dirs[ $i + 1 ] eq "up" ? -1 : 1;
            } else {
              $cresult = 1;
            }
          } elsif ($ta eq "b") {
            if ($tb eq "b") {
              $cresult = 0;
            } else {
              $cresult = $dirs[ $i + 1 ] eq "up" ? 1 : -1;
            }
          }
          return $cresult if $cresult;
        }
        return $a cmp $b;
      } @sortlist;

      my $originalrow;
      for (my $r = $r1 ; $r <= $r2 ; $r++)
      {    # copy original back over in new rows
        $originalrow = $sortlist[ $r - $r1 ];
        for (my $c = $c1 ; $c <= $c2 ; $c++) {
          my $cr       = cr_to_coord($c, $r);
          my $sortedcr = cr_to_coord($c, $r1 + $originalrow);
          if (!$sortcellattribs->{$sortedcr}->{coord})
          {    # copying an empty cell
            delete $cellattribs->{$cr};
            delete $datavalues->{$cr};
            delete $dataformulas->{$cr};
            delete $cellerrors->{$cr};
            delete $datatypes->{$cr};
            delete $valuetypes->{$cr};
            next;
          }
          $cellattribs->{$cr} = { 'coord' => $cr };
          foreach my $attribtype (keys %{ $sortcellattribs->{$sortedcr} }) {
            if ($attribtype ne "coord") {
              $cellattribs->{$cr}->{$attribtype} =
                $sortcellattribs->{$sortedcr}->{$attribtype};
            }
          }
          $datavalues->{$cr} = $sortdatavalues->{$sortedcr};
          $datatypes->{$cr}  = $sortdatatypes->{$sortedcr};
          $valuetypes->{$cr} = $sortvaluetypes->{$sortedcr};
          if ($sortdatatypes->{$sortedcr} eq "f")
          { # offset coord refs, even to ***relative*** coords in other sheets
            $dataformulas->{$cr} =
              offset_formula_coords($sortdataformulas->{$sortedcr},
              0, ($r - $r1) - $originalrow);
          } else {
            $dataformulas->{$cr} = $sortdataformulas->{$sortedcr};
          }
          $cellerrors->{$cr} = $sortcellerrors->{$sortedcr};
        }
      }
      $sheetdata->{sheetattribs}->{needsrecalc} = "yes";
    }
  }

  elsif ($cmd1 eq "clearclipboard") {
    delete $sheetdata->{clipboard};
  }

  elsif ($cmd1 eq "merge") {
    ($what, $rest) = split (/ /, $rest, 2);
    $what = uc($what);
    ($coord1, $coord2) = split (/:/, $what);
    my ($c1, $r1) = coord_to_cr($coord1);
    my $c2 = $c1;
    my $r2 = $r1;
    ($c2, $r2) = coord_to_cr($coord2) if $coord2;
    $sheetattribs->{lastcol} = $c2 if $c2 > $sheetattribs->{lastcol};
    $sheetattribs->{lastrow} = $r2 if $r2 > $sheetattribs->{lastrow};

    $cellattribs->{$coord1} = { 'coord' => $coord1 }
      unless $cellattribs->{$coord1}->{coord};

    delete $cellattribs->{$coord1}->{colspan};
    $cellattribs->{$coord1}->{colspan} = $c2 - $c1 + 1 if $c2 > $c1;
    delete $cellattribs->{$coord1}->{rowspan};
    $cellattribs->{$coord1}->{rowspan} = $r2 - $r1 + 1 if $r2 > $r1;
  }

  elsif ($cmd1 eq "unmerge") {
    ($what, $rest) = split (/ /, $rest, 2);
    $what = uc($what);
    ($coord1, $coord2) = split (/:/, $what);

    $cellattribs->{$coord1} = { 'coord' => $coord1 }
      unless $cellattribs->{$coord1}->{coord};

    delete $cellattribs->{$coord1}->{colspan};
    delete $cellattribs->{$coord1}->{rowspan};
  }

  elsif ($cmd1 eq "insertcol" || $cmd1 eq "insertrow") {
    ($what, $rest) = split (/ /, $rest, 2);
    $what = uc($what);
    ($coord1, $coord2) = split (/:/, $what);
    my ($c1, $r1) = coord_to_cr($coord1);
    my $lastcol = $sheetattribs->{lastcol};
    my $lastrow = $sheetattribs->{lastrow};
    my (
      $coloffset,   $rowoffset, $colend,      $rowend,
      $newcolstart, $newcolend, $newrowstart, $newrowend
    );
    if ($cmd1 eq "insertcol") {
      $coloffset   = 1;
      $colend      = $c1;
      $rowend      = 1;
      $newcolstart = $c1;
      $newcolend   = $c1;
      $newrowstart = 1;
      $newrowend   = $lastrow;
    } else {
      $rowoffset   = 1;
      $rowend      = $r1;
      $colend      = 1;
      $newcolstart = 1;
      $newcolend   = $lastcol;
      $newrowstart = $r1;
      $newrowend   = $r1;
    }

    for (my $row = $lastrow ; $row >= $rowend ; $row--)
    {    # copy the cells forward
      for (my $col = $lastcol ; $col >= $colend ; $col--) {
        my $coord = cr_to_coord($col, $row);
        my $coordnext = cr_to_coord($col + $coloffset, $row + $rowoffset);
        if (!$cellattribs->{$coord}) {    # copying empty cell
          delete $cellattribs->{$coordnext};
          delete $datavalues->{$coordnext};
          delete $datatypes->{$coordnext};
          delete $valuetypes->{$coordnext};
          delete $dataformulas->{$coordnext};
          delete $cellerrors->{$coordnext};
          next;
        }
        $cellattribs->{$coordnext} =
          { 'coord' => $coordnext };      # Start with minimal set
        foreach my $attribtype (keys %{ $cellattribs->{$coord} }) {
          if ($attribtype ne "coord") {
            $cellattribs->{$coordnext}->{$attribtype} =
              $cellattribs->{$coord}->{$attribtype};
          }
        }
        $datavalues->{$coordnext}   = $datavalues->{$coord};
        $datatypes->{$coordnext}    = $datatypes->{$coord};
        $valuetypes->{$coordnext}   = $valuetypes->{$coord};
        $dataformulas->{$coordnext} = $dataformulas->{$coord};
        $cellerrors->{$coordnext}   = $cellerrors->{$coord};
      }
    }
    for (my $r = $newrowstart ; $r <= $newrowend ; $r++)
    {    # fill the new cells
      for (my $c = $newcolstart ; $c <= $newcolend ; $c++) {
        my $cr = cr_to_coord($c, $r);
        delete $cellattribs->{$cr};
        delete $datavalues->{$cr};
        delete $datatypes->{$cr};
        delete $valuetypes->{$cr};
        delete $dataformulas->{$cr};
        delete $cellerrors->{$cr};
        my $crbase =
          cr_to_coord($c - $coloffset, $r - $rowoffset)
          ;    # copy attribs of the one before (0 give you A or 1)

        if ($cellattribs->{$crbase}) {
          $cellattribs->{$cr} = { 'coord' => $cr };
          foreach my $attribtype (keys %{ $cellattribs->{$crbase} }) {
            if ($attribtype ne "coord") {
              $cellattribs->{$cr}->{$attribtype} =
                $cellattribs->{$crbase}->{$attribtype};
            }
          }
        }
      }
    }
    foreach my $cr (keys %$dataformulas)
    {    # update cell references to moved cells in calculated formulas
      if ($datatypes->{$cr} eq "f") {
        $dataformulas->{$cr} =
          adjust_formula_coords($dataformulas->{$cr}, $c1, $coloffset, $r1,
          $rowoffset);
      }
    }
    foreach my $name (keys %$names)
    {    # update cell references to moved cells in names
      if ($names->{$name}) { # works with "A1", "A1:A20", and "=formula" forms
        $v1 = $names->{$name}->{definition};
        $v2 = "";
        if (substr($v1, 0, 1) eq "=") {
          $v2 = "=";
          $v1 = substr($v1, 1);
        }
        $names->{$name}->{definition} =
          $v2 . adjust_formula_coords($v1, $c1, $coloffset, $r1, $rowoffset);
      }
    }
    for (my $row = $lastrow ;
      $row >= $rowend && $cmd1 eq "insertrow" ; $row--)
    {    # copy the row attributes forward
      my $rownext = $row + $rowoffset;
      $rowattribs->{$rownext} = { 'coord' => $rownext };    # start clean
      foreach my $attribtype (keys %{ $rowattribs->{$row} }) {
        if ($attribtype ne "coord") {
          $rowattribs->{$rownext}->{$attribtype} =
            $rowattribs->{$row}->{$attribtype};
        }
      }
    }
    for (my $col = $lastcol ;
      $col >= $colend && $cmd1 eq "insertcol" ; $col--)
    {    # copy the column attributes forward
      my $colthis = number_to_col($col);
      my $colnext = number_to_col($col + $coloffset);
      $colattribs->{$colnext} = { 'coord' => $colnext };
      foreach my $attribtype (keys %{ $colattribs->{$colthis} }) {
        if ($attribtype ne "coord") {
          $colattribs->{$colnext}->{$attribtype} =
            $colattribs->{$colthis}->{$attribtype};
        }
      }
    }

    $sheetattribs->{lastcol} += $coloffset;
    $sheetattribs->{lastrow} += $rowoffset;
    $sheetdata->{sheetattribs}->{needsrecalc} = "yes";
  }

  elsif ($cmd1 eq "deletecol" || $cmd1 eq "deleterow") {
    ($what, $rest) = split (/ /, $rest, 2);
    $what = uc($what);
    ($coord1, $coord2) = split (/:/, $what);
    my ($c1, $r1) = coord_to_cr($coord1);
    my $c2 = $c1;
    my $r2 = $r1;
    ($c2, $r2) = coord_to_cr($coord2) if $coord2;
    my $lastcol = $sheetattribs->{lastcol};
    my $lastrow = $sheetattribs->{lastrow};
    my ($coloffset, $rowoffset, $colstart, $rowstart);

    if ($cmd1 eq "deletecol") {
      $coloffset = $c1 - $c2 - 1;
      $colstart  = $c2 + 1;
      $rowstart  = 1;
    } else {
      $rowoffset = $r1 - $r2 - 1;
      $rowstart  = $r2 + 1;
      $colstart  = 1;
    }

    for (my $row = $rowstart ; $row <= $lastrow - $rowoffset ; $row++)
    {    # copy the cells backwards - extra so no dup of last set
      for (my $col = $colstart ; $col <= $lastcol - $coloffset ; $col++) {
        my $coord = cr_to_coord($col, $row);
        my $coordbefore = cr_to_coord($col + $coloffset, $row + $rowoffset);
        if (!$cellattribs->{$coord}) {    # copying empty cell
          delete $cellattribs->{$coordbefore};
          delete $datavalues->{$coordbefore};
          delete $datatypes->{$coordbefore};
          delete $valuetypes->{$coordbefore};
          delete $dataformulas->{$coordbefore};
          delete $cellerrors->{$coordbefore};
          next;
        }
        $cellattribs->{$coordbefore} =
          { 'coord' => $coordbefore };    # Start with minimal set
        foreach my $attribtype (keys %{ $cellattribs->{$coord} }) {
          if ($attribtype ne "coord") {
            $cellattribs->{$coordbefore}->{$attribtype} =
              $cellattribs->{$coord}->{$attribtype};
          }
        }
        $datavalues->{$coordbefore}   = $datavalues->{$coord};
        $datatypes->{$coordbefore}    = $datatypes->{$coord};
        $valuetypes->{$coordbefore}   = $valuetypes->{$coord};
        $dataformulas->{$coordbefore} = $dataformulas->{$coord};
        $cellerrors->{$coordbefore}   = $cellerrors->{$coord};
      }
    }
    foreach my $cr (keys %$dataformulas)
    {    # update references to moved cells in calculated formulas
      if ($datatypes->{$cr} eq "f") {
        $dataformulas->{$cr} =
          adjust_formula_coords($dataformulas->{$cr}, $c1, $coloffset, $r1,
          $rowoffset);
      }
    }
    foreach my $name (keys %$names)
    {    # update cell references to moved cells in names
      if ($names->{$name}) { # works with "A1", "A1:A20", and "=formula" forms
        $v1 = $names->{$name}->{definition};
        $v2 = "";
        if (substr($v1, 0, 1) eq "=") {
          $v2 = "=";
          $v1 = substr($v1, 1);
        }
        $names->{$name}->{definition} =
          $v2 . adjust_formula_coords($v1, $c1, $coloffset, $r1, $rowoffset);
      }
    }
    for (
      my $row = $rowstart ;
      $row <= $lastrow - $rowoffset && $cmd1 eq "deleterow" ;
      $row++
      ) {    # copy the row attributes backward
      my $rowbefore = $row + $rowoffset;
      $rowattribs->{$rowbefore} =
        { 'coord' => $rowbefore };    # start with only coord
      foreach my $attribtype (keys %{ $rowattribs->{$row} }) {
        if ($attribtype ne "coord") {
          $rowattribs->{$rowbefore}->{$attribtype} =
            $rowattribs->{$row}->{$attribtype};
        }
      }
    }
    for (
      my $col = $colstart ;
      $col <= $lastcol - $coloffset && $cmd1 eq "deletecol" ;
      $col++
      ) {                             # copy the column attributes backward
      my $colthis   = number_to_col($col);
      my $colbefore = number_to_col($col + $coloffset);
      $colattribs->{$colbefore} = { 'coord' => $colbefore };
      foreach my $attribtype (keys %{ $colattribs->{$colthis} }) {
        if ($attribtype ne "coord") {
          $colattribs->{$colbefore}->{$attribtype} =
            $colattribs->{$colthis}->{$attribtype};
        }
      }
    }

    if ($cmd1 eq "deletecol") {
      if ($c1 <= $lastcol)
      {    # shrink sheet unless deleted phantom cols off the end
        if ($c2 <= $lastcol) {
          $sheetattribs->{lastcol} += $coloffset;
        } else {
          $sheetattribs->{lastcol} = $c1 - 1;
        }
      }
    } else {
      if ($r1 <= $lastrow)
      {    # shrink sheet unless deleted phantom rows off the end
        if ($r2 <= $lastrow) {
          $sheetattribs->{lastrow} += $rowoffset;
        } else {
          $sheetattribs->{lastrow} = $r1 - 1;
        }
      }
    }
    $sheetdata->{sheetattribs}->{needsrecalc} = "yes";
  }

  elsif ($cmd1 eq "name") {
    ($what, $name, $rest) = split (/ /, $rest, 3);
    $name = uc $name;
    if ($what eq "define") {
      $value = $names->{$name} ? $names->{$name}->{desc} : "";
      $names->{$name} = { definition => $rest, desc => $value };
    } elsif ($what eq "desc") {
      if ($names->{$name}) {
        $names->{$name}->{desc} = $rest;
      } else {
        $names->{$name} = { definition => "", desc => $rest };
      }
    } elsif ($what eq "delete") {
      delete $names->{$name};
    }
  }

  else {
    $errortext = "Unknown command '$cmd1' in line:\n$command\n";
    return 0;
  }

  return $command;
}

=head2 recalc_sheet

  recalc_sheet(\%sheetdata);

Recalculates the entire spreadsheet

=cut

sub recalc_sheet {
  my $Sheet = shift;

  $Sheet->{checked} = {};
  delete $Sheet->{sheetattribs}->{circularreferencecell};

  foreach my $coord (keys %{ $Sheet->{formulas} }) {
    my $err = check_and_calc_cell($Sheet, $coord) if $coord;
  }

  delete $Sheet
    ->{checked}; # save memory and clear out for name lookup formula evaluation
  delete $Sheet->{sheetattribs}->{needsrecalc};    # remember recalc done
}

=head2 parse_header_save

   parse_header_save(\@lines, my \%headerdata);

Returns "" if OK, otherwise error string.

Fills in %headerdata:

  $headerdata{version} - version number, currently 1.1
  $headerdata{fullname} - title of page
  $headerdata{templatetext} - template HTML
  $headerdata{templatefile} - where to get template (location:name), see get_template
  $headerdata{lastmodified} - date/time last modified
  $headerdata{lastauthor} - author when last modified
  $headerdata{basefiledt} - date/time of backup file before this set of edits or blank if new file first edits (survives rename)
  $headerdata{backupfiledt} - date/time of backup file holding this data (blank during edits, yyyy-mm-... in published/backup/archive)
  $headerdata{reverted} - if non-blank, name of backup file this came from (only during initial editing)
  $headerdata{editcomments} - comment text about this series of edits, used when listing backups and RSS
  $headerdata{publishhtml} - publish the HTML for this page - sometimes you only want access-controlled live view (yes/no - default yes)
  $headerdata{publishsource} - put a copy of the published .txt file along with HTML and allow live view of source (yes/no - default no)
  $headerdata{publishjs} - put an embeddable copy of the published HTML as a .js file along with HTML (yes/no - default no)
  $headerdata{publishlive} - (ignored and removed after 0.91) make the HTML be a redirect to the recalc code (yes/no - default no)
  $headerdata{viewwithoutlogin} - allow live view without being logged in (ignore login for this page)
  $headerdata{editlog} - array of entries about edits made since editing started (cleared on new open for edit)
     [0] - log entry: command string to execute_sheet_command or comment (starts with "# ")

=cut

sub parse_header_save {
  my ($lines, $headerdata) = @_;
  foreach my $line (@$lines) {
    chomp $line;
    $line =~ s/\r//g;
    my ($linetype, $rest) = split (/:/, $line, 2);
    next if !$linetype or $linetype =~ /^#/ or $linetype !~ /\S/;

    if ($linetype eq 'edit') {
      push @{ $headerdata->{editlog} }, decode_from_save($rest);
    } else {
      $headerdata->{$linetype} = decode_from_save($rest);
    }
  }

  return "";
}

=head2 create_header_save

  my $outstr = create_header_save(\%headerdata);

Header output routine

=cut

sub create_header_save {

  my $headerdata = shift @_;

  my $outstr;

  $headerdata->{version} = "1.1";    # this is the current version

  foreach my $val (@headerfieldnames) {
    my $valstr = encode_for_save($headerdata->{$val});
    $outstr .= "$val:$valstr\n";
  }

  foreach my $logentry (@{ $headerdata->{editlog} }) {
    my $valstr = encode_for_save($logentry);
    $outstr .= "edit:$valstr\n";
  }

  return $outstr;

}

=head2 add_to_editlog

  add_to_editlog(\%headerdata, $str);

Adds $str to the header editlog.  This should be either a string
acceptable to execute_sheet_command or start with "# "

=cut

sub add_to_editlog {
  my ($headerdata, $str) = @_;
  $headerdata->{editlog} ||= ();    # make sure array exists
  push @{ $headerdata->{editlog} }, $str;
  return;
}

=head1 OTHER EXPORTS

These are currently exported, as they are used from multiple places. You
shouldn't rely on this, however, as they will likely move somewhere else
RSN.

=head2 convert_date_gregorian_to_julian

  $juliandate = convert_date_gregorian_to_julian($year, $month, $day);

From: http://aa.usno.navy.mil/faq/docs/JD_Formula.html

Uses: Fliegel, H. F. and van Flandern, T. C. (1968). Communications of the ACM, Vol. 11, No. 10 (October, 1968).
Translated from the FORTRAN.

=cut

sub convert_date_gregorian_to_julian {

  my ($year, $month, $day) = @_;

  my $juliandate =
    $day - 32075 + int(1461 * ($year + 4800 + int(($month - 14) / 12)) / 4);
  $juliandate += int(367 * ($month - 2 - int(($month - 14) / 12) * 12) / 12);
  $juliandate = $juliandate -
    int(3 * int(($year + 4900 + int(($month - 14) / 12)) / 100) / 4);

  return $juliandate;

}

=head2 convert_date_julian_to_gregorian

  ($year, $month, $day) = convert_date_julian_to_gregorian($juliandate)

From: http://aa.usno.navy.mil/faq/docs/JD_Formula.html

Uses: Fliegel, H. F. and van Flandern, T. C. (1968). Communications of the ACM, Vol. 11, No. 10 (October, 1968).
Translated from the FORTRAN.

=cut

sub convert_date_julian_to_gregorian {

  my $juliandate = shift @_;

  my ($L, $N, $I, $J, $K);

  $L = $juliandate + 68569;
  $N = int(4 * $L / 146097);
  $L = $L - int((146097 * $N + 3) / 4);
  $I = int(4000 * ($L + 1) / 1461001);
  $L = $L - int(1461 * $I / 4) + 31;
  $J = int(80 * $L / 2447);
  $K = $L - int(2447 * $J / 80);
  $L = int($J / 11);
  $J = $J + 2 - 12 * $L;
  $I = 100 * ($N - 49) + $I + $L;

  return ($I, $J, $K);
}

=head2 determine_value_type

  $value = determine_value_type($rawvalue, \$type)

Takes a value and looks for special formatting like $, %, numbers, etc.
Returns the value as a number or string and the type.
Tries to follow the spec for spreadsheet function VALUE(v).

=cut

sub determine_value_type {

  my ($rawvalue, $type) = @_;

  my $value = $rawvalue || '';

  $$type = "t";

  my $fch = substr($value, 0, 1);
  my $tvalue = $value;
  $tvalue =~ s/^\s+//;    # value with leading and trailing spaces removed
  $tvalue =~ s/\s+$//;

  if (length $value == 0) {
    $$type = "";
  } elsif ($value =~ m/^\s+$/) {    # just blanks
    ;                               # leave as is with type "t"
  } elsif ($tvalue =~ m/^[-+]?\d*(?:\.)?\d*(?:[eE][-+]?\d+)?$/)
  {                                 # general number, including E
    $value = $tvalue + 0;
    $$type = "n";
  } elsif ($tvalue =~ m/^[-+]?\d*(?:\.)?\d*\s*%$/) {    # 15.1%
    $value = substr($tvalue, 0, -1) / 100;
    $$type = "n%";
  } elsif ($tvalue =~ m/^[-+]?\$\s*\d*(?:\.)?\d*\s*$/ && $tvalue =~ m/\d/)
  {                                                     # $1.49
    $tvalue =~ s/\$//;
    $value = $tvalue;
    $$type = 'n$';
  } elsif ($tvalue =~ m/^[-+]?(\d*,\d*)+(?:\.)?\d*$/) {    # 1,234.49
    $tvalue =~ s/,//g;
    $value = $tvalue;
    $$type = 'n';
  } elsif ($tvalue =~ m/^[-+]?(\d*,\d*)+(?:\.)?\d*\s*%$/) {    # 1,234.49%
    $tvalue =~ s/,//g;
    $value = substr($tvalue, 0, -1) / 100;
    $$type = 'n%';
  } elsif ($tvalue =~ m/^[-+]?\$\s*(\d*,\d*)+(?:\.)?\d*$/ && $tvalue =~ m/\d/)
  {                                                            # $1,234.49
    $tvalue =~ s/,//g;
    $tvalue =~ s/\$//;
    $value = $tvalue;
    $$type = 'n$';
  } elsif ($value =~ m/^(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{1,4})\s*$/)
  {    # MM/DD/YYYY, MM/DD/YYYY
    my $year = $3 < 1000 ? $3 + 2000 : $3;
    $value = convert_date_gregorian_to_julian($year, $1, $2) - 2415019;
    $$type = 'nd';
  } elsif ($value =~ m/^(\d{4})[\/\-](\d{1,2})[\/\-](\d{1,2})\s*$/)
  {    # YYYY-MM-DD, YYYY/MM/DD
    my $year = $1 < 1000 ? $1 + 2000 : $1;
    $value = convert_date_gregorian_to_julian($year, $2, $3) - 2415019;
    $$type = 'nd';
  } elsif ($value =~ m/^(\d{1,2}):(\d{1,2})\s*$/) {    # HH:MM
    my $hour   = $1;
    my $minute = $2;
    if ($hour < 24 && $minute < 60) {
      $value = $hour / 24 + $minute / (24 * 60);
      $$type = 'nt';
    }
  } elsif ($value =~ m/^(\d{1,2}):(\d{1,2}):(\d{1,2})\s*$/) {    # HH:MM:SS
    my $hour   = $1;
    my $minute = $2;
    my $second = $3;
    if ($hour < 24 && $minute < 60 && $second < 60) {
      $value = $hour / 24 + $minute / (24 * 60) + $second / (24 * 60 * 60);
      $$type = 'nt';
    }
  } elsif ($value =~ m/^\s*([-+]?\d+) (\d+)\/(\d+)\s*$/) {       # 1 1/2
    my $int   = $1;
    my $num   = $2;
    my $denom = $3;
    if ($denom > 0) {
      $value = $int + $num / $denom;
      $$type = 'n';
    }
  } elsif ($input_constants{ uc($value) }) {
    ($value, $$type) = split (/,/, $input_constants{ uc($value) });
  }

  return $value;

}

=head2 test_criteria

  test_criteria($value, $type, $criteria);

Determines whether a value/type meets the criteria.  A criteria can
be a numeric value, text beginning with <, <=, =, >=, >, <>, text
by itself is start of text to match.

Returns 1 or 0 for true or false.

=cut

sub test_criteria {

  my ($value, $type, $criteria) = @_;

  my ($comparitor, $basevalue, $basetype);

  return 0
    unless defined $criteria;  # undefined (e.g., error value) is always false

  if ($criteria =~ m/^(<=|<>|<|=|>=|>)(.+?)$/) {    # has comparitor
    $comparitor = $1;
    $basevalue  = $2;
  } else {
    $comparitor = "none";
    $basevalue  = $criteria;
  }

  my $basevaluenum = determine_value_type($basevalue, \$basetype);
  if (!$basetype) {    # no criteria base value given
    return 0 if $comparitor eq "none";    # blank criteria matches nothing
    if (substr($type, 0, 1) eq "b") {     # empty cell
      return 1 if $comparitor eq "=";     # empty equals empty
    } else {
      return 1 if $comparitor eq "<>";    # something does not equal empty
    }
    return 0;                             # otherwise false
  }

  my $cond = 0;

  if (substr($basetype, 0, 1) eq "n" && substr($type, 0, 1) eq "t")
  {    # criteria is number, but value is text
    my $testtype;
    my $testvalue = determine_value_type($value, \$testtype);
    if (substr($testtype, 0, 1) eq "n") {    # could be number - make it one
      $value = $testvalue;
      $type  = $testtype;
    }
  }

  if (substr($type, 0, 1) eq "n" && substr($basetype, 0, 1) eq "n")
  {                                          # compare two numbers
    if    ($comparitor eq "<")  { $cond = $value < $basevaluenum  ? 1 : 0; }
    elsif ($comparitor eq "<=") { $cond = $value <= $basevaluenum ? 1 : 0; }
    elsif ($comparitor eq "=" || $comparitor eq "none") {
      $cond = $value == $basevaluenum ? 1 : 0;
    } elsif ($comparitor eq ">=") {
      $cond = $value >= $basevaluenum ? 1 : 0;
    } elsif ($comparitor eq ">") {
      $cond = $value > $basevaluenum ? 1 : 0;
    } elsif ($comparitor eq "<>") {
      $cond = $value != $basevaluenum ? 1 : 0;
    }
  } elsif (substr($value, 0, 1) eq "e") {    # error on left
    $cond = 0;
  } elsif (substr($basetype, 0, 1) eq "e") {    # error on right
    $cond = 0;
  } else {    # text maybe mixed with numbers or blank
    if (substr($type, 0, 1) eq "n") {
      $value = format_number_for_display($value, "n", "");
    }
    if (substr($basetype, 0, 1) eq "n") {
      return 0;    # if number and didn't match already, isn't a match
    }

    utf8::decode($value);    # ignore case and use UTF-8 as chars not bytes
    $value = lc $value;      # ignore case
    utf8::decode($basevalue);
    $basevalue = lc $basevalue;

    if    ($comparitor eq "<")  { $cond = $value lt $basevalue ? 1 : 0; }
    elsif ($comparitor eq "<=") { $cond = $value le $basevalue ? 1 : 0; }
    elsif ($comparitor eq "=") { $cond = $value eq $basevalue ? 1 : 0; }
    elsif ($comparitor eq "none") {
      $cond = $value =~ m/^$basevalue/ ? 1 : 0;
    } elsif ($comparitor eq ">=") {
      $cond = $value ge $basevalue ? 1 : 0;
    } elsif ($comparitor eq ">") {
      $cond = $value gt $basevalue ? 1 : 0;
    } elsif ($comparitor eq "<>") {
      $cond = $value ne $basevalue ? 1 : 0;
    }
  }

  return $cond;

}

=head2 lookup_result_type

  $resulttype = lookup_result_type($type1, $type2, \%typelookup);

%typelookup has values of the following form:

    $typelookup{"typespec1"} = "|typespec2A:resultA|typespec2B:resultB|..."

First $type1 is looked up. If no match, then the first letter (major
type) of $type1 plus "*" is looked up.  $resulttype is $type1 if
result is "1", $type2 if result is "2", otherwise the value of
result.

=cut

sub lookup_result_type {

  my ($type1, $type2, $typelookup) = @_;

  my $t2 = $type2;

  my $table1 = $typelookup->{$type1};
  if (!$table1) {
    $table1 = $typelookup->{ substr($type1, 0, 1) . '*' };
    return "e#VALUE! (missing)"
      unless $table1;    # missing from table -- please add it
  }
  if ($table1 =~ m/\Q|$type2:\E(.*?)\|/) {
    return $type1 if $1 eq '1';
    return $type2 if $1 eq '2';
    return $1;
  }
  $t2 = substr($t2, 0, 1) . '*';
  if ($table1 =~ m/\Q|$t2:\E(.*?)\|/) {
    return $type1 if $1 eq '1';
    return $type2 if $1 eq '2';
    return $1;
  }
  return "e#VALUE!";
}

=head2 copy_function_args

  copy_function_args(\@operand, \@foperand)

Pops operands from @operand and pushes on @foperand up to function start
reversing order in the process.

=cut

sub copy_function_args {

  my ($operand, $foperand) = @_;

  while (@$operand && $operand->[ @$operand - 1 ]->{type} ne "start")
  {    # get each arg
    push @$foperand, $operand->[ @$operand - 1 ];    # copy it
    pop @$operand;
  }
  pop @$operand;                                     # get rid of "start"

  return;
}

=head2 function_args_error

  function_args_error($fname, \@operand, $$errortext)

Pushes appropriate error on operand stack and sets errortext, including $fname

=cut

sub function_args_error {

  my ($fname, $operand, $errortext) = @_;

  $$errortext = qq!Incorrect arguments to function "$fname". !;
  push @$operand, { type => "e#VALUE!", value => $$errortext };

  return;
}

=head2 function_specific_error

  function_specific_error($fname, \@operand, $errortext, $errortype, $text)

Pushes specified error and text on operand stack

=cut

sub function_specific_error {

  my ($fname, $operand, $errortext, $errortype, $text) = @_;

  $$errortext = $text;
  push @$operand, { type => $errortype, value => $$errortext };

  return;
}

=head2 top_of_stack_value_and_type

  ($value, $type) = top_of_stack_value_and_type(\%sheetdata, \@operand, \$errortext,)

Returns top of stack value and type and then pops the stack

=cut

sub top_of_stack_value_and_type {
  my ($sheetdata, $operand, $errortext) = @_;
  if (@$operand) {
    my ($value, $type) = (
      $operand->[ @$operand - 1 ]->{value},
      $operand->[ @$operand - 1 ]->{type}
    );
    pop @$operand;
    if ($type eq "name") {
      $value = uc $value;
      $value = lookup_name($sheetdata, $value, \$type, $errortext);
    }
    return ($value, $type);
  } else {
    return ();
  }
}

=head2 operand_as_number

  $value = operand_as_number(\%sheetdata, \@operand, \$errortext, \$tostype)

Uses operand_value_and_type to get top of stack and pops it.
Returns numeric value and type.
Text values are treated as 0 if they can't be converted somehow.

=cut

sub operand_as_number {

  my ($sheetdata, $operand, $errortext, $tostype) = @_;

  my $value =
    operand_value_and_type($sheetdata, $operand, $errortext, $tostype);

  if (substr($$tostype, 0, 1) eq "n") {
    return 0 + $value;
  } elsif (substr($$tostype, 0, 1) eq "b") {    # blank cell
    $$tostype = "n";
    return 0;
  } elsif (substr($$tostype, 0, 1) eq "e") {    # error
    return 0;
  } else {
    $value = determine_value_type($value, $tostype);
    if (substr($$tostype, 0, 1) eq "n") {
      return 0 + $value;
    } else {
      return 0;
    }
  }
}

=head2 operand_as_text 

  $value = operand_as_text(\%sheetdata, \@operand, \$errortext, \$tostype)

Uses operand_value_and_type to get top of stack and pops it.
Returns text value, preserving sub-type.

=cut

sub operand_as_text {

  my ($sheetdata, $operand, $errortext, $tostype) = @_;

  my $value =
    operand_value_and_type($sheetdata, $operand, $errortext, $tostype);

  if (substr($$tostype, 0, 1) eq "t") {
    return $value;
  } elsif (substr($$tostype, 0, 1) eq "n") {
    $value    = "$value";
    $$tostype = "t";
    return $value;
  } elsif (substr($$tostype, 0, 1) eq "b") {    # blank
    $$tostype = "t";
    return "";
  } elsif (substr($$tostype, 0, 1) eq "e") {    # error
    return "";
  } else {
    $$tostype = "t";
    return "$value";
  }
}

=head2 operand_value_and_type

  $value = operand_value_and_type(\%sheetdata, \@operand, \$errortext, \$operandtype)

Pops the top of stack and returns it, following a coord reference
if necessary.  Ranges are returned as if they were pushed onto the
stack first coord first.  Also sets $operandtype with "t", "n",
"th", etc., as appropriate.  Errortext is set if there is a reference
to a cell with error.

=cut

sub operand_value_and_type {

  my ($sheetdata, $operand, $errortext, $operandtype) = @_;

  my $stacklen = scalar @$operand;
  if (!$stacklen) {    # make sure something is there
    $$operandtype = "";
    return "";
  }
  my $value   = $operand->[ $stacklen - 1 ]->{value};    # get top of stack
  my $tostype = $operand->[ $stacklen - 1 ]->{type};
  pop @$operand;    # we have data - pop stack

  if ($tostype eq "name") {
    $value = uc $value;
    $value = lookup_name($sheetdata, $value, \$tostype, $errortext);
  }

  if ($tostype eq "range") {
    $value = step_through_range_down($operand, $value, \$tostype);
  }

  if ($tostype eq "coord") {    # value is a coord reference
    my $coordsheetdata = $sheetdata;
    if ($value =~ m/^([^!]+)!(.+)$/) {    # sheet reference
      $value = $1;
      my $othersheet = $2;
      $coordsheetdata = find_in_sheet_cache($sheetdata, $othersheet);
      if ($coordsheetdata->{loaderror}) {    # this sheet is unavailable
        $$operandtype = "e#REF!";
        return 0;
      }
    }
    my $cellvtype =
      $coordsheetdata->{valuetypes}
      ->{$value};    # get type of value in the cell it points to
    $value = $coordsheetdata->{datavalues}->{$value};
    $tostype = $cellvtype || "b";
    if ($tostype eq "b") {    # blank
      $value = 0;
    }
  }

  $$operandtype = $tostype;    # return information
  return $value;

}

=head2 decode_range_parts

  ($sheetdata, $col1num, $ncols, $row1num, $nrows) = decode_range_parts(\@sheetdata, $rangevalue, $rangetype)

Returns \@sheetdata for the sheet where the range is, as well as
the number of the first column in the range, the number of columns,
and equivalent row information.

If any errors, $sheetdata is returned as null.

=cut

sub decode_range_parts {

  my ($sheetdata, $rangevalue, $rangetype) = @_;

  my ($value1, $value2, $sequence) = split (/\|/, $rangevalue);
  my ($sheet1, $sheet2);
  ($value1, $sheet1) = split (/!/, $value1);
  ($value2, $sheet2) = split (/!/, $value2);
  my $coordsheetdata = $sheetdata;
  if ($sheet1) {    # sheet reference
    $coordsheetdata = find_in_sheet_cache($sheetdata, $sheet1);
    if ($coordsheetdata->{loaderror}) {    # this sheet is unavailable
      $coordsheetdata = undef;
    }
  }

  my ($c1, $r1) = coord_to_cr($value1);
  my ($c2, $r2) = coord_to_cr($value2);
  ($c2, $c1) = ($c1, $c2) if ($c1 > $c2);
  ($r2, $r1) = ($r1, $r2) if ($r1 > $r2);
  return ($coordsheetdata, $c1, $c2 - $c1 + 1, $r1, $r2 - $r1 + 1);
}

=head2 coord_to_cr

  ($col, $row) = coord_to_cr($coord)

Turns B3 into (2, 3). The default for both is 1.
If range, only do this to first coord.

=cut

sub coord_to_cr {
  my $coord = shift @_;
  $coord = lc($coord);
  $coord =~ s/\$//g;
  $coord =~ m/([a-z])([a-z])?(\d+)/;
  my $col = ord($1) - ord('a') + 1;
  $col = 26 * $col + ord($2) - ord('a') + 1 if $2;
  return ($col, $3);
}

=head2 cr_to_coord

  $coord = cr_to_coord($col, $row)

Turns (2, 3) into B3. The default for both is 1.

=cut

sub cr_to_coord {
  my ($col, $row) = @_;
  $row = 1 unless $row > 1;
  $col = 1 unless $col > 1;
  my $col_high = int(($col - 1) / 26);
  my $col_low  = ($col - 1) % 26;
  my $coord    = chr(ord('A') + $col_low);
  $coord = chr(ord('A') + $col_high - 1) . $coord if $col_high;
  $coord .= $row;
  return $coord;
}

=head2 encode_for_save

  my $estring = encode_for_save($string)

Returns $estring where :, \n, and \ are escaped

=cut

sub encode_for_save {
  my $string = shift @_;
  $string =~ s/\\/\\b/g;    # \ to \b
  $string =~ s/:/\\c/g;     # : to \c
  $string =~ s/\n/\\n/g;    # line end to \n
  return $string;
}

=head2 decode_from_save

  my $estring = decode_from_save($string)

Returns $estring with \c, \n, \b and \\ un-escaped

=cut

sub decode_from_save {
  my $string = shift @_;
  $string =~ s/\\\\/\\/g;    # Old -- shouldn't get this, replace with \b
  $string =~ s/\\c/:/g;
  $string =~ s/\\n/\n/g;
  $string =~ s/\\b/\\/g;
  return $string;
}

=head2 html_escape / special_chars

  my $estring = html_escape($string)

Returns $estring where &, <, >, " are HTML escaped.

This used to be known as special_chars() but that usage is deprecated.

=cut

sub html_escape {
  my $string = shift @_;
  $string =~ s/&/&amp;/g;
  $string =~ s/</&lt;/g;
  $string =~ s/>/&gt;/g;
  $string =~ s/"/&quot;/g;
  return $string;
}
*special_chars = \&html_escape;

=head2 special_chars_nl

  my $estring = special_chars_nl($string)

Returns $estring where &, <, >, ", and LF are HTML escaped, CR's are removed

=cut

sub special_chars_nl {
  my $string = shift @_;
  $string =~ s/&/&amp;/g;
  $string =~ s/</&lt;/g;
  $string =~ s/>/&gt;/g;
  $string =~ s/"/&quot;/g;
  $string =~ s/\r//gs;
  $string =~ s/\n/&#10;/gs;
  return $string;
}

=head1 HELPERS

These are 'private' functions, not exported, and should not be relied
on. The interface to any of these is subject to change at any time.

=head2 offset_formula_coords

  $updatedformula = offset_formula_coords($formula, $coloffset, $rowoffset);

Change relative cell references by offsets (even those to other
worksheets so fill, paste, sort work as expected).  If not what you
want, use absolute references.

=cut

sub offset_formula_coords {

  my ($formula, $coloffset, $rowoffset, $othersheets) = @_;

  my $parseinfo = parse_formula_into_tokens($formula);

  my $parsed_token_text   = $parseinfo->{tokentext};
  my $parsed_token_type   = $parseinfo->{tokentype};
  my $parsed_token_opcode = $parseinfo->{tokenopcode};

  my ($ttype, $ttext, $sheetref, $updatedformula);
  for (my $i = 0 ; $i < scalar @$parsed_token_text ; $i++) {
    $ttype = $parsed_token_type->[$i];
    $ttext = $parsed_token_text->[$i];
    if ($ttype == $token_coord) {
      my ($c, $r) = coord_to_cr($ttext);
      my $abscol = $ttext =~ m/^\$/;
      $c += $coloffset unless $abscol;
      my $absrow = $ttext =~ m/^\${0,1}[a-zA-Z]{1,2}\$\d+$/;
      $r += $rowoffset unless $absrow;
      $ttext = cr_to_coord($c, $r);
      $ttext =~ s/^/\$/        if $abscol;
      $ttext =~ s/(\d+)$/\$$1/ if $absrow;

      if ($r < 1 || $c < 1) {
        $ttext = "ERRCELL";
      }
    } elsif ($ttype == $token_string) {
      $ttext =~ s/"/""/g;
      $ttext = '"' . $ttext . '"';
    } elsif ($ttype == $token_op) {
      $ttext = $token_op_expansion{$ttext}
        || $ttext;    # make sure short tokens (e.g., "G") go back full (">=")
    }
    $updatedformula .= $ttext;
  }

  return $updatedformula;
}

=head2 adjust_formula_coords

  $updatedformula = adjust_formula_coords($formula, $col, $coloffset, $row, $rowoffset)

Change all cell references to cells starting with $col/$row by offsets

=cut

sub adjust_formula_coords {

  my ($formula, $col, $coloffset, $row, $rowoffset) = @_;

  my $parseinfo = parse_formula_into_tokens($formula);

  my $parsed_token_text   = $parseinfo->{tokentext};
  my $parsed_token_type   = $parseinfo->{tokentype};
  my $parsed_token_opcode = $parseinfo->{tokenopcode};

  my ($ttype, $ttext, $sheetref, $updatedformula);
  for (my $i = 0 ; $i < scalar @$parsed_token_text ; $i++) {
    $ttype = $parsed_token_type->[$i];
    $ttext = $parsed_token_text->[$i];
    if ($ttype == $token_op)
    {    # references with sheet specifier are not offset
      if ($ttext eq "!") {
        $sheetref = 1;    # found a sheet reference
      } elsif ($ttext ne ":") {    # for everything but a range, reset
        $sheetref = 0;
      }
      $ttext = $token_op_expansion{$ttext}
        || $ttext;    # make sure short tokens (e.g., "G") go back full (">=")
    }
    if ($ttype == $token_coord) {
      my ($c, $r) = coord_to_cr($ttext);
      if (($c == $col && $coloffset < 0) || ($r == $row && $rowoffset < 0))
      {               # refs to deleted cells become invalid
        $c = 0 unless $sheetref;
        $r = 0 unless $sheetref;
      }
      my $abscol = $ttext =~ m/^\$/;
      $c += $coloffset if $c >= $col && !$sheetref;
      my $absrow = $ttext =~ m/^\${0,1}[a-zA-Z]{1,2}\$\d+$/;
      $r += $rowoffset if $r >= $row && !$sheetref;
      $ttext = cr_to_coord($c, $r);
      $ttext =~ s/^/\$/        if $abscol;
      $ttext =~ s/(\d+)$/\$$1/ if $absrow;

      if ($r < 1 || $c < 1) {
        $ttext = "ERRCELL";
      }
    } elsif ($ttype == $token_string) {
      $ttext =~ s/"/""/g;
      $ttext = '"' . $ttext . '"';
    }
    $updatedformula .= $ttext;
  }

  return $updatedformula;

}

=head2 format_value_for_display

  $displayvalue = format_value_for_display(\%sheetdata, $value, $cr, $linkstyle)

=cut

sub format_value_for_display {
  my ($sheetdata, $value, $cr, $linkstyle) = @_;

  # Get references to the parts
  my $datavalues   = $sheetdata->{datavalues};
  my $valuetypes   = $sheetdata->{valuetypes};
  my $cellerrors   = $sheetdata->{cellerrors};
  my $cellattribs  = $sheetdata->{cellattribs};
  my $sheetattribs = $sheetdata->{sheetattribs};
  my $valueformats = $sheetdata->{valueformats};
  my $datatypes    = $sheetdata->{datatypes};
  my $dataformulas = $sheetdata->{formulas};

  my $displayvalue = $value;

  my $valuetype =
    $valuetypes->{$cr};    # get type of value to determine formatting
  my $valuesubtype = substr($valuetype, 1);
  $valuetype = substr($valuetype, 0, 1);

  if ($cellerrors->{$cr}) {

    # TODO check this, now that expand_markup no longer exists
    # $displayvalue = expand_markup($cellerrors->{$cr}, $sheetdata, $linkstyle) || $valuesubtype || "Error in cell";
    $displayvalue = $cellerrors->{$cr} || $valuesubtype || "Error in cell";
    return $displayvalue;
  }

  if ($valuetype eq "t") {
    my $valueformat = $valueformats->[
      (      $cellattribs->{$cr}->{textvalueformat}
          || $sheetattribs->{defaulttextvalueformat})
      ]
      || "";
    if ($valueformat eq "formula") {
      if ($datatypes->{$cr} eq "f") {
        $displayvalue = html_escape("=$dataformulas->{$cr}") || "&nbsp;";
      } elsif ($datatypes->{$cr} eq "c") {
        $displayvalue = html_escape("'$dataformulas->{$cr}") || "&nbsp;";
      } else {
        $displayvalue = html_escape("'$displayvalue") || "&nbsp;";
      }
      return $displayvalue;
    }
    $displayvalue =
      format_text_for_display($displayvalue, $valuetypes->{$cr}, $valueformat,
      $sheetdata, $linkstyle);
  }

  elsif ($valuetype eq "n") {
    my $valueformat = $cellattribs->{$cr}->{nontextvalueformat};
    if (length($valueformat) == 0) {    # "0" is a legal value format
      $valueformat = $sheetattribs->{defaultnontextvalueformat};
    }
    $valueformat = $valueformats->[$valueformat];
    if (length($valueformat) == 0) {
      $valueformat = "";
    }
    $valueformat = "" if $valueformat eq "none";
    if ($valueformat eq "formula") {
      if ($datatypes->{$cr} eq "f") {
        $displayvalue = html_escape("=$dataformulas->{$cr}") || "&nbsp;";
      } elsif ($datatypes->{$cr} eq "c") {
        $displayvalue = html_escape("'$dataformulas->{$cr}") || "&nbsp;";
      } else {
        $displayvalue = html_escape("'$displayvalue") || "&nbsp;";
      }
      return $displayvalue;
    } elsif ($valueformat eq "forcetext") {
      if ($datatypes->{$cr} eq "f") {
        $displayvalue = html_escape("=$dataformulas->{$cr}") || "&nbsp;";
      } elsif ($datatypes->{$cr} eq "c") {
        $displayvalue = html_escape($dataformulas->{$cr}) || "&nbsp;";
      } else {
        $displayvalue = html_escape($displayvalue) || "&nbsp;";
      }
      return $displayvalue;
    }
    $displayvalue =
      format_number_for_display($displayvalue, $valuetypes->{$cr},
      $valueformat);
  }

  else {    # unknown type - probably blank
    $displayvalue = "&nbsp;";
  }

  return $displayvalue;

}

=head2 format_text_for_display

  $displayvalue = format_text_for_display($rawvalue, $valuetype, $valueformat, $sheetdata, $linkstyle)

=cut

sub format_text_for_display {

  my ($rawvalue, $valuetype, $valueformat, $sheetdata, $linkstyle) = @_;

  my $valuesubtype = substr($valuetype, 1);

  my $displayvalue = $rawvalue;

  $valueformat = "" if $valueformat eq "none";
  $valueformat = "" unless $valueformat =~ m/^(text-|custom|hidden)/;
  if (!$valueformat || $valueformat eq "General")
  {    # determine format from type
    $valueformat = "text-html" if ($valuesubtype eq "h");
    $valueformat = "text-wiki" if ($valuesubtype eq "w");
    $valueformat = "text-plain" unless $valuesubtype;
  }
  if ($valueformat eq "text-html") {    # HTML - output as it as is
    ;
  } elsif ($valueformat eq "text-wiki") {    # wiki text
    die "Wiki text not handled";
  } elsif ($valueformat eq "text-url") {     # text is a URL for a link
    my $dvsc = html_escape($displayvalue);
    my $dvue = url_encode($displayvalue);
    $dvue =~ s/\Q{{amp}}/%26/g;
    $displayvalue = qq!<a href="$dvue">$dvsc</a>!;
  } elsif ($valueformat eq "text-link")
  {    # text is a URL for a link shown as Link
    my $dvsc = html_escape($displayvalue);
    my $dvue = url_encode($displayvalue);
    $dvue =~ s/\Q{{amp}}/%26/g;
    $displayvalue = qq!<a href="$dvue">Link</a>!;
  } elsif ($valueformat eq "text-image") {    # text is a URL for an image
    my $dvue = url_encode($displayvalue);
    $dvue =~ s/\Q{{amp}}/%26/g;
    $displayvalue = qq!<img src="$dvue">!;
  } elsif ($valueformat =~ m/^text-custom\:/)
  { # construct a custom text format: @r = text raw, @s = special chars, @u = url encoded
    my $dvsc = html_escape($displayvalue);    # do special chars
    $dvsc =~ s/  /&nbsp; /g;                  # keep multiple spaces
    $dvsc =~ s/\n/<br>/g;                     # keep line breaks
    my $dvue = url_encode($displayvalue);
    $dvue =~ s/\Q{{amp}}/%26/g;
    my %textval;
    $textval{r}   = $displayvalue;
    $textval{s}   = $dvsc;
    $textval{u}   = $dvue;
    $displayvalue = $valueformat;
    $displayvalue =~ s/^text-custom\://;
    $displayvalue =~ s/@(r|s|u)/$textval{$1}/ge;
  } elsif ($valueformat =~ m/^custom/) {      # custom
    $displayvalue = html_escape($displayvalue);    # do special chars
    $displayvalue =~ s/  /&nbsp; /g;               # keep multiple spaces
    $displayvalue =~ s/\n/<br>/g;                  # keep line breaks
    $displayvalue .= " (custom format)";
  } elsif ($valueformat eq "hidden") {
    $displayvalue = "&nbsp;";
  } else {                                         # plain text
    $displayvalue = html_escape($displayvalue);    # do special chars
    $displayvalue =~ s/  /&nbsp; /g;               # keep multiple spaces
    $displayvalue =~ s/\n/<br>/g;                  # keep line breaks
  }

  return $displayvalue;

}

=head2 format_number_for_display

  $displayvalue = format_number_for_display($rawvalue, $valuetype, $valueformat)

=cut

sub format_number_for_display {

  my ($rawvalue, $valuetype, $valueformat) = @_;

  my ($has_parens, $has_commas);

  my $displayvalue = $rawvalue;
  my $valuesubtype = substr($valuetype, 1);

  if ($valueformat eq "Auto" || length($valueformat) == 0)
  {    # cases with default format
    if ($valuesubtype eq "%") {    # will display a % character
      $valueformat = "#,##0.0%";
    } elsif ($valuesubtype eq '$') {
      $valueformat = '[$]#,##0.00';
    } elsif ($valuesubtype eq 'dt') {
      $valueformat = 'd-mmm-yyyy h:mm:ss';
    } elsif ($valuesubtype eq 'd') {
      $valueformat = 'd-mmm-yyyy';
    } elsif ($valuesubtype eq 't') {
      $valueformat = '[h]:mm:ss';
    } elsif ($valuesubtype eq 'l') {
      $valueformat = 'logical';
    } else {
      $valueformat = "General";
    }
  }

  if ($valueformat eq "logical") {    # do logical format
    return $rawvalue ? 'TRUE' : 'FALSE';
  }

  if ($valueformat eq "hidden") {     # do hidden format
    return "&nbsp;";
  }

  # Use format

  return format_number_with_format_string($rawvalue, $valueformat);

}

=head2 format_number_with_format_string

  $result = format_number_with_format_string($value, $format_string, $currency_char)

Use a format string to format a numeric value. Returns a string with the result.
This is a subset of the normal styles accepted by many other spreadsheets, without fractions, E format, and @,
and with any number of comparison fields and with [style=style-specification] (e.g., [style=color:red])

=cut

my %allowedcolors = (
  BLACK   => "#000000",
  BLUE    => "#0000FF",
  CYAN    => "#00FFFF",
  GREEN   => "#00FF00",
  MAGENTA => "#FF00FF",
  RED     => "#FF0000",
  WHITE   => "#FFFFFF",
  YELLOW  => "#FFFF00"
);

my %alloweddates =
  (H => "h]", M => "m]", MM => "mm]", "S" => "s]", "SS" => "ss]");

my %format_definitions;
my $cmd_copy                 = 1;
my $cmd_color                = 2;
my $cmd_integer_placeholder  = 3;
my $cmd_fraction_placeholder = 4;
my $cmd_decimal              = 5;
my $cmd_currency             = 6;
my $cmd_general              = 7;
my $cmd_separator            = 8;
my $cmd_date                 = 9;
my $cmd_comparison           = 10;
my $cmd_section              = 11;
my $cmd_style                = 12;

sub format_number_with_format_string {

  my ($rawvalue, $format_string, $currency_char) = @_;

  $currency_char ||= '$';

  my ($op, $operandstr, $fromend, $cval, $operandstrlc);
  my ($yr, $mn, $dy, $hrs, $mins, $secs, $ehrs, $emins, $esecs, $ampmstr);
  my $result;

  my $value = $rawvalue + 0;    # get a working copy that's numeric

  my $negativevalue = $value < 0 ? 1 : 0;    # determine sign, etc.
  $value = -$value if $negativevalue;
  my $zerovalue = $value == 0 ? 1 : 0;

  parse_format_string(\%format_definitions, $format_string)
    ;                                        # make sure format is parsed
  my $thisformat = $format_definitions{$format_string}; # Get format structure

  return "Format error!" unless $thisformat;

  my $section =
    (scalar @{ $thisformat->{sectioninfo} }) - 1; # get number of sections - 1

  if ($thisformat->{hascomparison})
  {    # has comparisons - determine which section
    $section = 0;    # set to which section we will use
    my $gotcomparison = 0;    # this section has no comparison
    for (my $cpos ; ; $cpos++) {    # scan for comparisons
      $op         = $thisformat->{operators}->[$cpos];
      $operandstr =
        $thisformat->{operands}->[$cpos];    # get next operator and operand
      if (!$op) {                            # at end with no match
        if ($gotcomparison) {                # if comparison but no match
          $format_string = "General";        # use default of General
          parse_format_string(\%format_definitions, $format_string);
          $thisformat = $format_definitions{$format_string};
          $section    = 0;
        }
        last;    # if no comparision, matchines on this section
      }
      if ($op == $cmd_section) {    # end of section
        if (!$gotcomparison) {      # no comparison, so it's a match
          last;
        }
        $gotcomparison = 0;
        $section++;                 # check out next one
        next;
      }
      if ($op == $cmd_comparison) {    # found a comparison - do we meet it?
        my ($compop, $compval) = split (/:/, $operandstr, 2);
        $compval = 0 + $compval;
        if ( ($compop eq "<" && $rawvalue < $compval)
          || ($compop eq "<=" && $rawvalue <= $compval)
          || ($compop eq "<>" && $rawvalue != $compval)
          || ($compop eq ">=" && $rawvalue >= $compval)
          || ($compop eq ">"  && $rawvalue > $compval)) {    # a match
          last;
        }
        $gotcomparison = 1;
      }
    }
  } elsif ($section > 0) {    # more than one section (separated by ";")
    if ($section == 1) {      # two sections
      if ($negativevalue) {
        $negativevalue = 0; # sign will provided by section, not automatically
        $section       = 1; # use second section for negative values
      } else {
        $section = 0;       # use first for all others
      }
    } elsif ($section == 2) {    # three sections
      if ($negativevalue) {
        $negativevalue = 0; # sign will provided by section, not automatically
        $section       = 1; # use second section for negative values
      } elsif ($zerovalue) {
        $section = 2;       # use third section for zero values
      } else {
        $section = 0;       # use first for positive
      }
    }
  }

  # Get values for our section
  my ($sectionstart, $integerdigits, $fractiondigits, $commas, $percent,
    $thousandssep)
    = map $_ || 0,
    @{ $thisformat->{sectioninfo}->[$section] }
    {qw(sectionstart integerdigits fractiondigits commas percent thousandssep)
    };

  if ($commas > 0) {    # scale by thousands
    for (my $i = 0 ; $i < $commas ; $i++) {
      $value /= 1000;
    }
  }
  if ($percent > 0) {    # do percent scaling
    for (my $i = 0 ; $i < $percent ; $i++) {
      $value *= 100;
    }
  }

  my $decimalscale = 1;    # cut down to required number of decimal digits
  for (my $i = 0 ; $i < $fractiondigits ; $i++) {
    $decimalscale *= 10;
  }
  my $scaledvalue = int($value * $decimalscale + 0.5);
  $scaledvalue = $scaledvalue / $decimalscale;

  $negativevalue = 0
    if ($scaledvalue == 0 && ($fractiondigits || $integerdigits))
    ;                      # no "-0" unless using multiple sections or General

  my $strvalue = "$scaledvalue";    # convert to string
  if ($strvalue =~ m/e/) {          # converted to scientific notation
    return "$rawvalue";             # Just return plain converted raw value
  }
  $strvalue =~ m/^\+{0,1}(\d*)(?:\.(\d*)){0,1}$/
    ;    # get integer and fraction as character arrays
  my $integervalue = $1 || "";
  my @integervalue = split (//, $integervalue);
  my $fractionvalue = $2 || "";
  my @fractionvalue = split (//, $fractionvalue);

  if ($thisformat->{sectioninfo}->[$section]->{hasdate})
  {      # there are date placeholders
    if ($rawvalue < 0) {    # bad date
      return "??-???-??&nbsp;??:??:??";
    }
    my $startval =
      ($rawvalue - int($rawvalue)) * $seconds_in_a_day;  # get date/time parts
    my $estartval =
      $rawvalue * $seconds_in_a_day;    # do elapsed time version, too
    $hrs      = int($startval / $seconds_in_an_hour);
    $ehrs     = int($estartval / $seconds_in_an_hour);
    $startval = $startval - $hrs * $seconds_in_an_hour;
    $mins     = int($startval / 60);
    $emins    = int($estartval / 60);
    $secs     = $startval - $mins * 60;
    $decimalscale = 1;    # round appropriately depending if there is ss.0

    for (my $i = 0 ; $i < $fractiondigits ; $i++) {
      $decimalscale *= 10;
    }
    $secs  = int($secs * $decimalscale + 0.5);
    $secs  = $secs / $decimalscale;
    $esecs = int($estartval * $decimalscale + 0.5);
    $esecs = $esecs / $decimalscale;
    if ($secs >= 60) {    # handle round up into next second, minute, etc.
      $secs = 0;
      $mins++;
      $emins++;
      if ($mins >= 60) {
        $mins = 0;
        $hrs++;
        $ehrs++;
        if ($hrs >= 24) {
          $hrs = 0;
          $rawvalue++;
        }
      }
    }
    @fractionvalue = split (//, $secs - int($secs));    # for "hh:mm:ss.00"
    shift @fractionvalue;
    shift @fractionvalue;
    ($yr, $mn, $dy) =
      convert_date_julian_to_gregorian(int($rawvalue + $julian_offset));

    my $minOK;    # says "m" can be minutes
    my $mspos = $sectionstart;    # m scan position in ops
    for (; ; $mspos++)
    {    # scan for "m" and "mm" to see if any minutes fields, and am/pm
      $op         = $thisformat->{operators}->[$mspos];
      $operandstr =
        $thisformat->{operands}->[$mspos];    # get next operator and operand
      last unless $op;                        # don't go past end
      last if $op == $cmd_section;
      if ($op == $cmd_date) {
        if ((lc($operandstr) eq "am/pm" || lc($operandstr) eq "a/p")
          && !$ampmstr) {
          if ($hrs >= 12) {
            $hrs -= 12;
            $ampmstr = lc($operandstr) eq "a/p" ? "P" : "PM";
          } else {
            $ampmstr = lc($operandstr) eq "a/p" ? "A" : "AM";
          }
          $ampmstr = lc $ampmstr if $operandstr !~ m/$ampmstr/;
        }
        if ($minOK && ($operandstr eq "m" || $operandstr eq "mm")) {
          $thisformat->{operands}->[$mspos] .=
            "in";    # turn into "min" or "mmin"
        }
        if (substr($operandstr, 0, 1) eq "h") {
          $minOK = 1;    # m following h or hh or [h] is minutes not months
        } else {
          $minOK = 0;
        }
      } elsif ($op != $cmd_copy) {    # copying chars can be between h and m
        $minOK = 0;
      }
    }
    $minOK = 0;
    for (--$mspos ; ; $mspos--) {     # scan other way for s after m
      $op         = $thisformat->{operators}->[$mspos];
      $operandstr =
        $thisformat->{operands}->[$mspos];    # get next operator and operand
      last unless $op;                        # don't go past end
      last if $op == $cmd_section;
      if ($op == $cmd_date) {
        if ($minOK && ($operandstr eq "m" || $operandstr eq "mm")) {
          $thisformat->{operands}->[$mspos] .=
            "in";                             # turn into "min" or "mmin"
        }
        if ($operandstr eq "ss") {
          $minOK = 1;    # m before ss is minutes not months
        } else {
          $minOK = 0;
        }
      } elsif ($op != $cmd_copy) {    # copying chars can be between ss and m
        $minOK = 0;
      }
    }
  }

  my $integerdigits2 = 0;             # init counters, etc.
  my $integerpos     = 0;
  my $fractionpos    = 0;
  my $textcolor      = "";
  my $textstyle      = "";
  my $separatorchar  = ",";
  my $decimalchar    = '.';

  my $oppos = $sectionstart;

  while ($op = $thisformat->{operators}->[$oppos]) {    # execute format
    $operandstr =
      $thisformat->{operands}->[ $oppos++ ];   # get next operator and operand
    if ($op == $cmd_copy) {                    # put char in result
      $result .= $operandstr;
    }

    elsif ($op == $cmd_color) {                # set color
      $textcolor = $operandstr;
    }

    elsif ($op == $cmd_style) {                # set style
      $textstyle = $operandstr;
    }

    elsif ($op == $cmd_integer_placeholder) {    # insert number part
      if ($negativevalue) {
        $result .= "-";
        $negativevalue = 0;
      }
      $integerdigits2++;
      if ($integerdigits2 == 1) {                # first one
        if ((scalar @integervalue) > $integerdigits)
        {    # see if integer wider than field
          for (
            ;
            $integerpos < ((scalar @integervalue) - $integerdigits) ;
            $integerpos++
            ) {
            $result .= $integervalue[$integerpos];
            if ($thousandssep) {    # see if this is a separator position
              $fromend = (scalar @integervalue) - $integerpos - 1;
              if ($fromend > 2 && $fromend % 3 == 0) {
                $result .= $separatorchar;
              }
            }
          }
        }
      }
      if ((scalar @integervalue) < $integerdigits
        && $integerdigits2 <= $integerdigits - (scalar @integervalue))
      {                             # field is wider than value
        if ($operandstr eq "0" || $operandstr eq "?")
        {                           # fill with appropriate characters
          $result .= $operandstr eq "0" ? "0" : "&nbsp;";
          if ($thousandssep) {      # see if this is a separator position
            $fromend = $integerdigits - $integerdigits2;
            if ($fromend > 2 && $fromend % 3 == 0) {
              $result .= $separatorchar;
            }
          }
        }
      } else {    # normal integer digit - add it
        $result .= $integervalue[$integerpos];
        if ($thousandssep) {    # see if this is a separator position
          $fromend = (scalar @integervalue) - $integerpos - 1;
          if ($fromend > 2 && $fromend % 3 == 0) {
            $result .= $separatorchar;
          }
        }
        $integerpos++;
      }
    } elsif ($op == $cmd_fraction_placeholder) { # add fraction part of number
      if ($fractionpos >= scalar @fractionvalue) {
        if ($operandstr eq "0" || $operandstr eq "?") {
          $result .= $operandstr eq "0" ? "0" : "&nbsp;";
        }
      } else {
        $result .= $fractionvalue[$fractionpos];
      }
      $fractionpos++;
    }

    elsif ($op == $cmd_decimal) {                # decimal point
      if ($negativevalue) {
        $result .= "-";
        $negativevalue = 0;
      }
      $result .= $decimalchar;
    }

    elsif ($op == $cmd_currency) {               # currency symbol
      if ($negativevalue) {
        $result .= "-";
        $negativevalue = 0;
      }
      $result .= $operandstr;
    }

    elsif ($op == $cmd_general) {                # insert "General" conversion
      my $gvalue = $rawvalue + 0;                # make sure it's numeric
      if ($negativevalue) {
        $result .= "-";
        $negativevalue = 0;
        $gvalue        = -$gvalue;
      }
      $strvalue = "$gvalue";    # convert original value to string
      if ($strvalue =~ m/e/) {  # converted to scientific notation
        $result .= "$strvalue";
        next;
      }
      $strvalue =~ m/^\+{0,1}(\d*)(?:\.(\d*)){0,1}$/;
      $integervalue  = $1;
      $integervalue  = "" if ($integervalue == 0);
      @integervalue  = split (//, $integervalue);
      $fractionvalue = $2;
      $fractionvalue ||= "";
      @fractionvalue = split (//, $fractionvalue);
      $integerpos    = 0;
      $fractionpos   = 0;

      if (scalar @integervalue) {
        for (; $integerpos < scalar @integervalue ; $integerpos++) {
          $result .= $integervalue[$integerpos];
          if ($thousandssep) {    # see if this is a separator position
            $fromend = (scalar @integervalue) - $integerpos - 1;
            if ($fromend > 2 && $fromend % 3 == 0) {
              $result .= $separatorchar;
            }
          }
        }
      } else {
        $result .= "0";
      }
      if (scalar @fractionvalue) {
        $result .= $decimalchar;
        for (; $fractionpos < scalar @fractionvalue ; $fractionpos++) {
          $result .= $fractionvalue[$fractionpos];
        }
      }
    }

    elsif ($op == $cmd_date) {    # date placeholder
      $operandstrlc = lc $operandstr;
      if ($operandstrlc eq "y" || $operandstrlc eq "yy") {
        $result .= substr("$yr", -2);
      } elsif ($operandstrlc eq "yyyy") {
        $result .= "$yr";
      } elsif ($operandstrlc eq "d") {
        $result .= "$dy";
      } elsif ($operandstrlc eq "dd") {
        $cval = 1000 + $dy;
        $result .= substr("$cval", -2);
      } elsif ($operandstrlc eq "ddd") {
        my @names = qw/Sun Mon Tue Wed Thu Fri Sat/;
        $cval = int($rawvalue + 6) % 7;
        $result .= $names[$cval];
      } elsif ($operandstrlc eq "dddd") {
        my @names =
          qw/Sunday Monday Tuesday Wednesday Thursday Friday Saturday/;
        $cval = int($rawvalue + 6) % 7;
        $result .= $names[$cval];
      } elsif ($operandstrlc eq "m") {
        $result .= "$mn";
      } elsif ($operandstrlc eq "mm") {
        $cval = 1000 + $mn;
        $result .= substr("$cval", -2);
      } elsif ($operandstrlc eq "mmm") {
        my @names = qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;
        $result .= $names[ $mn - 1 ];
      } elsif ($operandstrlc eq "mmmm") {
        my @names = qw/
          January February March April May June
          July August September October November December
          /;
        $result .= $names[ $mn - 1 ];
      } elsif ($operandstrlc eq "mmmmm") {
        my @names = qw/J F M A M J J A S O N D/;
        $result .= $names[ $mn - 1 ];
      } elsif ($operandstrlc eq "h") {
        $result .= "$hrs";
      } elsif ($operandstrlc eq "h]") {
        $result .= "$ehrs";
      } elsif ($operandstrlc eq "mmin") {
        $cval = 1000 + $mins;
        $result .= substr("$cval", -2);
      } elsif ($operandstrlc eq "mm]") {
        if ($emins < 100) {
          $cval = 1000 + $emins;
          $result .= substr("$cval", -2);
        } else {
          $result .= "$emins";
        }
      } elsif ($operandstrlc eq "min") {
        $result .= "$mins";
      } elsif ($operandstrlc eq "m]") {
        $result .= "$emins";
      } elsif ($operandstrlc eq "hh") {
        $cval = 1000 + $hrs;
        $result .= substr("$cval", -2);
      } elsif ($operandstrlc eq "s") {
        $cval = int($secs);
        $result .= "$cval";
      } elsif ($operandstrlc eq "ss") {
        $cval = 1000 + int($secs);
        $result .= substr("$cval", -2);
      } elsif ($operandstrlc eq "am/pm" || $operandstrlc eq "a/p") {
        $result .= $ampmstr;
      } elsif ($operandstrlc eq "ss]") {
        if ($esecs < 100) {
          $cval = 1000 + int($esecs);
          $result .= substr("$cval", -2);
        } else {
          $cval   = int($esecs);
          $result = "$cval";
        }
      }
    }

    elsif ($op == $cmd_section) {    # end of section
      last;
    }

    elsif ($op == $cmd_comparison) {    # ignore
      next;
    }

    else {
      $result .= "!! Parse error !!";
    }
  }

  if ($textcolor) {
    $result = qq!<span style="color:$textcolor;">$result</span>!;
  }
  if ($textstyle) {
    $result = qq!<span style="$textstyle;">$result</span>!;
  }

  return $result;
}

=head2 parse_format_string

  parse_format_string(\%format_defs, $format_string)

Takes a format string (e.g., "#,##0.00_);(#,##0.00)") and fills in %foramt_defs with the parsed info

 %format_defs
    {"#,##0.0"}->{} # elements in the hash are one hash for each format
       {operators}->[] # array of operators from parsing the format string (each a number)
       {operands}->[] # array of corresponding operators (each usually a string)
       {sectioninfo}->[] # one hash for each section of the format
          {start}
          {integerdigits}
          {fractiondigits}
          {commas}
          {percent}
          {thousandssep}
          {hasdates}
       {hascomparison} # true if any section has [<100], etc.

=cut

sub parse_format_string {

  my ($format_defs, $format_string) = @_;

  return
    if ($format_defs->{$format_string});    # already defined - nothing to do

  my $thisformat =
    { operators => [], operands => [],
    sectioninfo => [ {} ] };    # create info structure for this format
  $format_defs->{$format_string} =
    $thisformat;                # add to other format definitions

  my $section     = 0;          # start with section 0
  my $sectioninfo =
    $thisformat->{sectioninfo}->[$section]
    ;                           # get reference to info for current section
  $sectioninfo->{sectionstart} =
    0;    # position in operands that starts this section

  my @formatchars = split //,
    $format_string;    # break into individual characters

  my $integerpart = 1; # start out in integer part
  my $lastwasinteger;  # last char was an integer placeholder
  my $lastwasslash; # last char was a backslash - escaping following character
  my $lastwasasterisk;    # repeat next char
  my $lastwasunderscore
    ;    # last char was _ which picks up following char for width
  my ($inquote,   $quotestr);            # processing a quoted string
  my ($inbracket, $bracketstr, $cmd);    # processing a bracketed string
  my ($ingeneral, $gpos);                # checks for characters "General"
  my $ampmstr;    # checks for characters "A/P" and "AM/PM"
  my $indate;     # keeps track of date/time placeholders

  foreach my $ch (@formatchars) {    # parse
    if ($inquote) {
      if ($ch eq '"') {
        $inquote = 0;
        push @{ $thisformat->{operators} }, $cmd_copy;
        push @{ $thisformat->{operands} },  $quotestr;
        next;
      }
      $quotestr .= $ch;
      next;
    }
    if ($inbracket) {
      if ($ch eq ']') {
        $inbracket = 0;
        ($cmd, $bracketstr) = parse_format_bracket($bracketstr);
        if ($cmd == $cmd_separator) {
          $sectioninfo->{thousandssep} = 1;    # explicit [,]
          next;
        }
        if ($cmd == $cmd_date) {
          $sectioninfo->{hasdate} = 1;
        }
        if ($cmd == $cmd_comparison) {
          $thisformat->{hascomparison} = 1;
        }
        push @{ $thisformat->{operators} }, $cmd;
        push @{ $thisformat->{operands} },  $bracketstr;
        next;
      }
      $bracketstr .= $ch;
      next;
    }
    if ($lastwasslash) {
      push @{ $thisformat->{operators} }, $cmd_copy;
      push @{ $thisformat->{operands} },  $ch;
      $lastwasslash = 0;
      next;
    }
    if ($lastwasasterisk) {
      push @{ $thisformat->{operators} }, $cmd_copy;
      push @{ $thisformat->{operands} },  $ch x 5;
      $lastwasasterisk = 0;
      next;
    }
    if ($lastwasunderscore) {
      push @{ $thisformat->{operators} }, $cmd_copy;
      push @{ $thisformat->{operands} },  "&nbsp;";
      $lastwasunderscore = 0;
      next;
    }
    if ($ingeneral) {
      if (substr("general", $ingeneral, 1) eq lc $ch) {
        $ingeneral++;
        if ($ingeneral == 7) {
          push @{ $thisformat->{operators} }, $cmd_general;
          push @{ $thisformat->{operands} },  $ch;
          $ingeneral = 0;
        }
        next;
      }
      $ingeneral = 0;
    }
    if ($indate) {    # last char was part of a date placeholder
      if (substr($indate, 0, 1) eq $ch) {    # another of the same char
        $indate .= $ch;                      # accumulate it
        next;
      }
      push @{ $thisformat->{operators} },
        $cmd_date;                           # something else, save date info
      push @{ $thisformat->{operands} }, $indate;
      $sectioninfo->{hasdate} = 1;
      $indate = "";
    }
    if ($ampmstr) {
      $ampmstr .= $ch;
      if ("am/pm" =~ m/^$ampmstr/i || "a/p" =~ m/^$ampmstr/i) {
        if (("am/pm" eq lc $ampmstr) || ("a/p" eq lc $ampmstr)) {
          push @{ $thisformat->{operators} }, $cmd_date;
          push @{ $thisformat->{operands} },  $ampmstr;
          $ampmstr = "";
        }
        next;
      }
      $ampmstr = "";
    }
    if ($ch eq "#" || $ch eq "0" || $ch eq "?") {    # placeholder
      if ($integerpart) {
        $sectioninfo->{integerdigits}++;
        if ($sectioninfo->{commas}) {   # comma inside of integer placeholders
          $sectioninfo->{thousandssep} =
            1;                          # any number is thousands separator
          $sectioninfo->{commas} = 0;   # reset count of "thousand" factors
        }
        $lastwasinteger = 1;
        push @{ $thisformat->{operators} }, $cmd_integer_placeholder;
        push @{ $thisformat->{operands} },  $ch;
      } else {
        $sectioninfo->{fractiondigits}++;
        push @{ $thisformat->{operators} }, $cmd_fraction_placeholder;
        push @{ $thisformat->{operands} },  $ch;
      }
    } elsif ($ch eq ".") {    # decimal point
      $lastwasinteger = 0;
      push @{ $thisformat->{operators} }, $cmd_decimal;
      push @{ $thisformat->{operands} },  $ch;
      $integerpart = 0;
    } elsif ($ch eq '$') {    # currency char
      $lastwasinteger = 0;
      push @{ $thisformat->{operators} }, $cmd_currency;
      push @{ $thisformat->{operands} },  $ch;
    } elsif ($ch eq ",") {
      if ($lastwasinteger) {
        $sectioninfo->{commas}++;
      } else {
        push @{ $thisformat->{operators} }, $cmd_copy;
        push @{ $thisformat->{operands} },  $ch;
      }
    } elsif ($ch eq "%") {
      $lastwasinteger = 0;
      $sectioninfo->{percent}++;
      push @{ $thisformat->{operators} }, $cmd_copy;
      push @{ $thisformat->{operands} },  $ch;
    } elsif ($ch eq '"') {
      $lastwasinteger = 0;
      $inquote        = 1;
      $quotestr       = "";
    } elsif ($ch eq '[') {
      $lastwasinteger = 0;
      $inbracket      = 1;
      $bracketstr     = "";
    } elsif ($ch eq '\\') {
      $lastwasslash   = 1;
      $lastwasinteger = 0;
    } elsif ($ch eq '*') {
      $lastwasasterisk = 1;
      $lastwasinteger  = 0;
    } elsif ($ch eq '_') {
      $lastwasunderscore = 1;
      $lastwasinteger    = 0;
    } elsif ($ch eq ";") {
      $section++;    # start next section
      $thisformat->{sectioninfo}->[$section] = {};    # create a new section
      $sectioninfo =
        $thisformat->{sectioninfo}->[$section]
        ;    # set to point to the new section
      $sectioninfo->{sectionstart} =
        1 + scalar @{ $thisformat->{operators} };   # remember where it starts
      $integerpart    = 1;                          # reset for new section
      $lastwasinteger = 0;
      push @{ $thisformat->{operators} }, $cmd_section;
      push @{ $thisformat->{operands} },  $ch;
    } elsif ((lc $ch) eq "g") {
      $ingeneral      = 1;
      $lastwasinteger = 0;
    } elsif ((lc $ch) eq "a") {
      $ampmstr        = $ch;
      $lastwasinteger = 0;
    } elsif ($ch =~ m/[dmyhHs]/) {
      $indate = $ch;
    } else {
      $lastwasinteger = 0;
      push @{ $thisformat->{operators} }, $cmd_copy;
      push @{ $thisformat->{operands} },  $ch;
    }
  }

  if ($indate) {    # last char was part of unsaved date placeholder
    push @{ $thisformat->{operators} }, $cmd_date;    # save what we got
    push @{ $thisformat->{operands} },  $indate;
    $sectioninfo->{hasdate} = 1;
  }

  return;

}

=head2 parse_format_bracket

  ($operator, $operand) = parse_format_bracket($bracketstr)

=cut

sub parse_format_bracket {

  my $bracketstr = shift @_;

  my ($operator, $operand);

  if (substr($bracketstr, 0, 1) eq '$') {    # currency
    $operator = $cmd_currency;
    if ($bracketstr =~ m/^\$(.+?)(\-.+?){0,1}$/) {
      $operand = $1 || '$';
    } else {
      $operand = substr($bracketstr, 1) || '$';
    }
  } elsif ($bracketstr eq '?$') {
    $operator = $cmd_currency;
    $operand  = '[?$]';
  } elsif ($allowedcolors{ uc $bracketstr }) {
    $operator = $cmd_color;
    $operand  = $allowedcolors{ uc $bracketstr };
  } elsif ($bracketstr =~ m/^style=([^"]*)$/) {    # [style=...]
    $operator = $cmd_style;
    $operand  = $1;
  } elsif ($bracketstr eq ",") {
    $operator = $cmd_separator;
    $operand  = $bracketstr;
  } elsif ($alloweddates{ uc $bracketstr }) {
    $operator = $cmd_date;
    $operand  = $alloweddates{ uc $bracketstr };
  } elsif ($bracketstr =~ m/^[<>=]/) {             # comparison operator
    $bracketstr =~ m/^([<>=]+)(.+)$/;              # split operator and value
    $operator = $cmd_comparison;
    $operand  = "$1:$2";
  } else {                                         # unknown bracket
    $operator = $cmd_copy;
    $operand  = "[$bracketstr]";
  }

  return ($operator, $operand);

}

=head2 check_and_calc_cell

  $circref = check_and_calc_cell(\%sheetdata, $coord)

Recalculates one cell after making sure dependencies are calc'ed, too.
If circular reference, returns non-null.
Circular referenced detected by using $sheetdata->{checked}->{$coord}:
    null - not evaluated
    1 - cell is being recursed into -- if get back here => circular reference
    2 - cell was fully recursed into and calculated this recalc cycle

=cut

sub check_and_calc_cell {

  my ($Sheet, $coord) = @_;

  my $coordchecked = $Sheet->{checked};

  return ""
    if !$Sheet->{datatypes}->{$coord}
    or $Sheet->{datatypes}->{$coord} ne 'f';

  if ($Sheet->{checked}->{$coord}) {
    return $Sheet->{cellerrors}->{$coord} = "Circular reference to $coord"
      if $Sheet->{checked}->{$coord} == 1;
    return "";
  }
  $Sheet->{checked}->{$coord} = 1;

  my $line      = $Sheet->{formulas}->{$coord};
  my $parseinfo = parse_formula_into_tokens($line);

  my $parsed_token_text = $parseinfo->{tokentext};
  my $parsed_token_type = $parseinfo->{tokentype};
  my ($ttype, $ttext, $sheetref);
  for (my $i = 0 ; $i < @$parsed_token_text ; $i++) {
    $ttype = $parsed_token_type->[$i];
    $ttext = $parsed_token_text->[$i];
    if ($ttype == $token_op)
    {    # references with sheet specifier are not recursed into
      if ($ttext eq "!") {
        $sheetref = 1;    # found a sheet reference
      } elsif ($ttext ne ":") {    # for everything but a range, reset
        $sheetref = 0;
      }
    }
    if ($ttype == $token_name) {    # look for named range
      my ($valuetype, $errortext);
      my $value = lookup_name($Sheet, $ttext, \$valuetype, \$errortext);
      if ($valuetype eq "range")
      {    # only need to recurse for range, which may be just one cell
        my ($cr1, $cr2) = split (/\|/, $value);
        $cr2 ||= $cr1;
        my ($c1, $r1) = coord_to_cr($cr1);
        my ($c2, $r2) = coord_to_cr($cr2);
        ($c2, $c1) = ($c1, $c2) if ($c1 > $c2);
        ($r2, $r1) = ($r1, $r2) if ($r1 > $r2);
        for (my $r = $r1 ; $r <= $r2 ; $r++) {
          for (my $c = $c1 ; $c <= $c2 ; $c++) {
            my $rangecoord = cr_to_coord($c,             $r);
            my $circref    = check_and_calc_cell($Sheet, $rangecoord);
            $Sheet->{sheetattribs}->{circularreferencecell} =
              "$coord|$rangecoord"
              if $circref;
          }
        }
      }
    }
    if ($ttype == $token_coord) {
      if ( $i >= 2
        && $parsed_token_type->[ $i - 1 ] == $token_op
        && $parsed_token_text->[ $i - 1 ] eq ':'
        && $parsed_token_type->[ $i - 2 ] == $token_coord
        && !$sheetref) {    # Range -- check each cell
        my ($c1, $r1) = coord_to_cr($parsed_token_text->[ $i - 2 ]);
        my ($c2, $r2) = coord_to_cr($ttext);
        ($c2, $c1) = ($c1, $c2) if ($c1 > $c2);
        ($r2, $r1) = ($r1, $r2) if ($r1 > $r2);
        for (my $r = $r1 ; $r <= $r2 ; $r++)
        {    # Checks first cell a second time, but that should just return
          for (my $c = $c1 ; $c <= $c2 ; $c++) {
            my $rangecoord = cr_to_coord($c,             $r);
            my $circref    = check_and_calc_cell($Sheet, $rangecoord);
            $Sheet->{sheetattribs}->{circularreferencecell} =
              "$coord|$rangecoord"
              if $circref;
          }
        }
        } elsif (!$sheetref) {    # Single cell reference
        $ttext =~ s/\$//g;
        my $circref = check_and_calc_cell($Sheet, $ttext);
        $Sheet->{sheetattribs}->{circularreferencecell} = "$coord|$ttext"
          if $circref;            # remember at least one circ ref
      }
    }
  }
  my ($value, $valuetype, $errortext) =
    evaluate_parsed_formula($parseinfo, $Sheet);
  $Sheet->{datavalues}->{$coord} = $value;
  $Sheet->{valuetypes}->{$coord} = $valuetype;
  if ($errortext) {
    $Sheet->{cellerrors}->{$coord} = $errortext;
  } elsif ($Sheet->{cellerrors}->{$coord}) {
    delete $Sheet->{cellerrors}->{$coord};
  }
  $Sheet->{checked}->{$coord} = 2;    # Remember we were here
  return "";
}

=head2 parse_formula_into_tokens

  \%parseinfo = parse_formula_into_tokens($line)

Parses a text string as if it was a spreadsheet formula

This uses a simple state machine run on each character in turn.
States remember whether a number is being gathered, etc.
The result is %parseinfo which has the following arrays with one entry for each token:
   {tokentext}->[] - the characters making up the parsed token,
   {tokentype}->[] - the type of the token,
   {tokenopcode}->[] - a single character version of an operator suitable for use in the
                       precedence table and distinguishing between unary and binary + and -.

=cut

sub parse_formula_into_tokens {

  my $line = shift @_;

  my @ch = unpack("C*", $line);
  push @ch, ord('#');    # add eof at end

  my $state              = 0;
  my $state_num          = 1;
  my $state_alpha        = 2;
  my $state_coord        = 3;
  my $state_string       = 4;
  my $state_stringquote  = 5;
  my $state_numexp1      = 6;
  my $state_numexp2      = 7;
  my $state_alphanumeric = 8;

  my $str;
  my ($cclass, $chrc, $ucchrc, $last_token_type, $last_token_text, $t);

  my %parseinfo;

  $parseinfo{tokentext}   = [];
  $parseinfo{tokentype}   = [];
  $parseinfo{tokenopcode} = [];
  my $parsed_token_text   = $parseinfo{tokentext};
  my $parsed_token_type   = $parseinfo{tokentype};
  my $parsed_token_opcode = $parseinfo{tokenopcode};

  foreach my $c (@ch) {
    $chrc   = chr($c);
    $ucchrc = uc $chrc;
    $cclass = $char_class[ ($c <= 127 ? (($c >= 32) ? $c : 32) : 32) - 32 ];

    if ($state == $state_num) {
      if ($cclass == $char_class_num) {
        $str .= $chrc;
      } elsif ($cclass == $char_class_numstart && index($str, '.') == -1) {
        $str .= $chrc;
      } elsif ($ucchrc eq 'E') {
        $str .= $chrc;
        $state = $state_numexp1;
      } else {    # end of number - save it
        push @$parsed_token_text,   $str;
        push @$parsed_token_type,   $token_num;
        push @$parsed_token_opcode, 0;
        $state = 0;
      }
    }

    if ($state == $state_numexp1) {
      if ($cclass == $state_num) {
        $state = $state_numexp2;
      } elsif (($chrc eq '+' || $chrc eq '-') && (uc substr($str, -1)) eq 'E')
      {
        $str .= $chrc;
      } elsif ($ucchrc eq 'E') {
        ;
      } else {
        push @$parsed_token_text,   "Improperly formed number exponent";
        push @$parsed_token_type,   $token_error;
        push @$parsed_token_opcode, 0;
        $state = 0;
      }
    }

    if ($state == $state_numexp2) {
      if ($cclass == $char_class_num) {
        $str .= $chrc;
      } else {    # end of number - save it
        push @$parsed_token_text,   $str;
        push @$parsed_token_type,   $token_num;
        push @$parsed_token_opcode, 0;
        $state = 0;
      }
    }

    if ($state == $state_alpha) {
      if ($cclass == $char_class_num) {
        $state = $state_coord;
      } elsif ($cclass == $char_class_alpha) {
        $str .=
          $ucchrc;    # coords and functions are uppercase, names ignore case
      } elsif ($cclass == $char_class_incoord) {
        $state = $state_coord;
      } elsif ($cclass == $char_class_op
        || $cclass == $char_class_numstart
        || $cclass == $char_class_space
        || $cclass == $char_class_eof) {
        push @$parsed_token_text,   $str;
        push @$parsed_token_type,   $token_name;
        push @$parsed_token_opcode, 0;
        $state = 0;
        } else {
        push @$parsed_token_text,   $str;
        push @$parsed_token_type,   $token_error;
        push @$parsed_token_opcode, 0;
        $state = 0;
      }
    }

    if ($state == $state_coord) {
      if ($cclass == $char_class_num) {
        $str .= $chrc;
      } elsif ($cclass == $char_class_incoord) {
        $str .= $chrc;
      } elsif ($cclass == $char_class_alpha) {
        $state = $state_alphanumeric;
      } elsif ($cclass == $char_class_op
        || $cclass == $char_class_numstart
        || $cclass == $char_class_eof) {
        if ($str =~ m/^\$?[A-Z]{1,2}\$?[1-9]\d*$/) {
          $t = $token_coord;
        } else {
          $t = $token_name;
        }
        push @$parsed_token_text,   $str;
        push @$parsed_token_type,   $t;
        push @$parsed_token_opcode, 0;
        $state = 0;
        } else {
        push @$parsed_token_text,   $str;
        push @$parsed_token_type,   $token_error;
        push @$parsed_token_opcode, 0;
        $state = 0;
      }
    }

    if ($state == $state_alphanumeric) {
      if ($cclass == $char_class_num || $cclass == $char_class_alpha) {
        $str .=
          $ucchrc;    # coords and functions are uppercase, names ignore case
      } elsif ($cclass == $char_class_op
        || $cclass == $char_class_numstart
        || $cclass == $char_class_space
        || $cclass == $char_class_eof) {
        push @$parsed_token_text,   $str;
        push @$parsed_token_type,   $token_name;
        push @$parsed_token_opcode, 0;
        $state = 0;
        } else {
        push @$parsed_token_text,   $str;
        push @$parsed_token_type,   $token_error;
        push @$parsed_token_opcode, 0;
        $state = 0;
      }
    }

    if ($state == $state_string) {
      if ($cclass == $char_class_quote) {
        $state =
          $state_stringquote
          ; # got quote in string: is it doubled (quote in string) or by itself (end of string)?
      } else {
        $str .= $chrc;
      }
    } elsif ($state == $state_stringquote) {    # note elseif here
      if ($cclass == $char_class_quote) {
        $str .= '"';
        $state =
          $state_string;  # double quote: add one then continue getting string
      } else {            # something else -- end of string
        push @$parsed_token_text,   $str;
        push @$parsed_token_type,   $token_string;
        push @$parsed_token_opcode, 0;
        $state = 0;       # drop through to process
      }
    }

    if ($state == 0) {
      if ($cclass == $char_class_num || $cclass == $char_class_numstart) {
        $str   = $chrc;
        $state = $state_num;
      } elsif ($cclass == $char_class_alpha || $cclass == $char_class_incoord)
      {
        $str   = $ucchrc;
        $state = $state_alpha;
      } elsif ($cclass == $char_class_op) {
        $str = chr($c);
        if (@$parsed_token_type) {
          $last_token_type = $parsed_token_type->[ @$parsed_token_type - 1 ];
          $last_token_text = $parsed_token_text->[ @$parsed_token_text - 1 ];
          if ($last_token_type == $char_class_op) {
            if ($last_token_text eq '<' || $last_token_text eq ">") {
              $str = $last_token_text . $str;
              pop @$parsed_token_text;
              pop @$parsed_token_type;
              pop @$parsed_token_opcode;
              if (@$parsed_token_type) {
                $last_token_type =
                  $parsed_token_type->[ @$parsed_token_type - 1 ];
                $last_token_text =
                  $parsed_token_text->[ @$parsed_token_text - 1 ];
              } else {
                $last_token_type = $char_class_eof;
                $last_token_text = "EOF";
              }
            }
          }
        } else {
          $last_token_type = $char_class_eof;
          $last_token_text = "EOF";
        }
        $t = $token_op;
        if (
          (@$parsed_token_type == 0)
          || ( $last_token_type == $char_class_op
            && $last_token_text ne ')'
            && $last_token_text ne '%')
          ) {    # Unary operator
          if ($str eq '-') {    # M is unary minus
            $str = "M";
            $c   = ord($str);
          } elsif ($str eq '+') {    # P is unary plus
            $str = "P";
            $c   = ord($str);
          } elsif ($str eq ')' && $last_token_text eq '(')
          {                          # null arg list OK
            ;
          } elsif ($str ne '(') {    # binary-op open-paren OK, others no
            $t   = $token_error;
            $str =
              "Error in formula (two operators inappropriately in a row)";
          }
          } elsif (length $str > 1) {
          if ($str eq '>=') {        # G is >=
            $str = "G";
            $c   = ord($str);
          } elsif ($str eq '<=') {    # L is <=
            $str = "L";
            $c   = ord($str);
          } elsif ($str eq '<>') {    # N is <>
            $str = "N";
            $c   = ord($str);
          } else {
            $t   = $token_error;
            $str =
              "Error in formula (two operators inappropriately in a row)";
          }
        }
        push @$parsed_token_text,   $str;
        push @$parsed_token_type,   $t;
        push @$parsed_token_opcode, $c;
        $state = 0;
      } elsif ($cclass == $char_class_quote) {    # starting a string
        $str   = "";
        $state = $state_string;
      } elsif ($cclass == $char_class_space)
      {    # store so can reconstruct spacing
        push @$parsed_token_text,   " ";
        push @$parsed_token_type,   $token_space;
        push @$parsed_token_opcode, 0;
      } elsif ($cclass == $char_class_eof) {    # ignore
      }
    }
  }

  return \%parseinfo;
}

=head2 evaluate_parsed_formula

  ($value, $valuetype, $errortext) = evaluate_parsed_formula(\%parseinfo, \%sheetdata, $allowrangereturn)

Does the calculation expressed in a parsed formula, returning a value,
its type, and error info.

If $allowrangereturn is present and true, can return a range (e.g., "A1:A10" - translated from "A1|A10|")

=cut

sub evaluate_parsed_formula {

  my ($parseinfo, $sheetdata, $allowrangereturn) = @_;

  my $parsed_token_text   = $parseinfo->{tokentext};
  my $parsed_token_type   = $parseinfo->{tokentype};
  my $parsed_token_opcode = $parseinfo->{tokenopcode};

  # # # # # # #
  #
  # Convert infix to reverse polish notation
  #
  # Based upon the algorithm shown in Wikipedia "Reverse Polish notation" article
  # and then enhanced for additional spreadsheet things
  #
  # The @revpolish array ends up with a sequence of references to tokens by number
  #

  my @revpolish;
  my @parsestack;

  my $function_start = -1;

  my ($ttype, $ttext, $tprecedence, $tstackprecedence, $errortext);

  for (my $i = 0 ; $i < scalar @$parsed_token_text ; $i++) {
    $ttype = $parsed_token_type->[$i];
    $ttext = $parsed_token_text->[$i];
    if ( $ttype == $token_num
      || $ttype == $token_coord
      || $ttype == $token_string) {
      push @revpolish, $i;
      } elsif ($ttype == $token_name) {
      push @parsestack, $i;
      push @revpolish,  $function_start;
      } elsif ($ttype == $token_space) {    # ignore
      next;
      } elsif ($ttext eq ',') {
      while (@parsestack
        && $parsed_token_text->[ $parsestack[ @parsestack - 1 ] ] ne '(') {
        push @revpolish, pop @parsestack;
      }
      if (@parsestack == 0) {               # no ( -- error
        $errortext = "Missing open parenthesis in list with comma(s).";
        last;
      }
      } elsif ($ttext eq '(') {
      push @parsestack, $i;
      } elsif ($ttext eq ')') {
      while (@parsestack
        && $parsed_token_text->[ $parsestack[ @parsestack - 1 ] ] ne '(') {
        push @revpolish, pop @parsestack;
      }
      if (@parsestack == 0) {               # no ( -- error
        $errortext = "Closing parenthesis without open parenthesis.";
        last;
      }
      pop @parsestack;
      if ( @parsestack
        && $parsed_token_type->[ $parsestack[ @parsestack - 1 ] ] ==
        $token_name) {
        push @revpolish, pop @parsestack;
      }
      } elsif ($ttype == $token_op) {
      if ( @parsestack
        && $parsed_token_type->[ $parsestack[ @parsestack - 1 ] ] ==
        $token_name) {
        push @revpolish, pop @parsestack;
      }
      while (@parsestack
        && $parsed_token_type->[ $parsestack[ @parsestack - 1 ] ] == $token_op
        && $parsed_token_text->[ $parsestack[ @parsestack - 1 ] ] ne '(') {
        $tprecedence = $token_precedence[ $parsed_token_opcode->[$i] - 32 ];
        $tstackprecedence =
          $token_precedence[ $parsed_token_opcode
          ->[ $parsestack[ @parsestack - 1 ] ] - 32 ];
        if ($tprecedence >= 0 && $tprecedence < $tstackprecedence) {
          last;
        } elsif ($tprecedence < 0) {
          $tprecedence = -$tprecedence;
          $tstackprecedence = -$tstackprecedence if $tstackprecedence < 0;
          if ($tprecedence <= $tstackprecedence) {
            last;
          }
        }
        push @revpolish, pop @parsestack;
      }
      push @parsestack, $i;
      } elsif ($ttype == $token_error) {
      $errortext = $ttext;
      last;
      } else {
      $errortext = "Internal error while processing parsed formula. ";
      last;
    }
  }
  while (@parsestack) {
    if ($parsed_token_text->[ $parsestack[ @parsestack - 1 ] ] eq '(') {
      $errortext = "Missing close parenthesis.";
      last;
    }
    push @revpolish, pop @parsestack;
  }

  # # # # # # #
  #
  # Execute it
  #

  # Operand values are hashes with {value} and {type}
  # Type can have these values (many are type and sub-type as two or more letters):
  #    "tw", "th", "t", "n", "nt", "coord", "range", "start", "eErrorType", "b" (blank)
  # The value of a coord is in the form A57 or A57!sheetname
  # The value of a range is coord|coord|number where number starts at 0 and is
  # the offset of the next item to fetch if you are going through the range one by one
  # The number starts as a null string ("A1|B3|")
  #

  my @operand;

  my ($value1, $value2, $tostype, $tostype2, $resulttype);

  for (my $i = 0 ; $i < scalar @revpolish ; $i++) {
    if ($revpolish[$i] == $function_start)
    {    # Remember the start of a function argument list
      push @operand, { type => "start" };
      next;
    }

    $ttype = $parsed_token_type->[ $revpolish[$i] ];
    $ttext = $parsed_token_text->[ $revpolish[$i] ];

    if ($ttype == $token_num) {

      # TODO t/date.t gives lots of warnings here. Work out why.
      no warnings;
      push @operand, { type => "n", value => 0 + $ttext };
    }

    elsif ($ttype == $token_coord) {
      $ttext =~ s/[^0-9A-Z]//g;
      push @operand, { type => "coord", value => $ttext };
    }

    elsif ($ttype == $token_string) {
      push @operand, { type => "t", value => $ttext };
    }

    elsif ($ttype == $token_op) {
      if (@operand <= 0) {    # Nothing on the stack...
        $errortext = "Missing operand. ";    # remember error
        push @operand, { type => "n", value => 0 };    # put something there
      }

      # Unary minus

      if ($ttext eq 'M') {
        $value1 =
          operand_as_number($sheetdata, \@operand, \$errortext, \$tostype);
        $resulttype =
          lookup_result_type($tostype, $tostype, $typelookup{unaryminus});
        push @operand, { type => $resulttype, value => -$value1 };
      }

      # Unary plus

      elsif ($ttext eq 'P') {
        $value1 =
          operand_as_number($sheetdata, \@operand, \$errortext, \$tostype);
        $resulttype =
          lookup_result_type($tostype, $tostype, $typelookup{unaryplus});
        push @operand, { type => $resulttype, value => $value1 };
      }

      # Unary % - percent, left associative

      elsif ($ttext eq '%') {
        $value1 =
          operand_as_number($sheetdata, \@operand, \$errortext, \$tostype);
        $resulttype =
          lookup_result_type($tostype, $tostype, $typelookup{unarypercent});
        push @operand, { type => $resulttype, value => 0.01 * $value1 };
      }

      # & - string concatenate

      elsif ($ttext eq '&') {
        if (@operand == 1) {    # Need at least two things on the stack...
          $errortext = "Missing operand. ";    # remember error
          push @operand, { type => "t",
            value => "" };    # put something there as second operand
        }
        $value2 =
          operand_as_text($sheetdata, \@operand, \$errortext, \$tostype2);
        $value1 =
          operand_as_text($sheetdata, \@operand, \$errortext, \$tostype);
        $resulttype =
          lookup_result_type($tostype, $tostype2, $typelookup{concat});
        push @operand, { type => $resulttype, value => ($value1 . $value2) };
      }

      # : - Range constructor

      elsif ($ttext eq ':') {
        if (@operand == 1) {    # Need at least two things on the stack...
          $errortext = "Missing operand. ";    # remember error
          push @operand, { type => "n",
            value => 0 };    # put something there as second operand
        }
        $value1 =
          operands_as_range_on_sheet($sheetdata, \@operand, \$tostype,
          \$errortext);      # get coords even if use name on other sheet
        push @operand, { type => $tostype,
          value => $value1 };    # push sheetname with range on that sheet
      }

      # ! - sheetname!coord

      elsif ($ttext eq '!') {
        if (@operand == 1) {     # Need at least two things on the stack...
          $errortext = "Missing operand. ";    # remember error
          push @operand, { type => "e#REF!",
            value => 0 };    # put something there as second operand
        }
        $value1 =
          operands_as_coord_on_sheet($sheetdata, \@operand, \$tostype,
          \$errortext);      # get coord even if name on other sheet
        push @operand,
          { type => $tostype, value =>
            $value1 };    # push sheetname with coord or range on that sheet
      }

      # Comparison operators: < L = G > N (< <= = >= > <>)

      elsif ($ttext =~ m/[<L=G>N]/) {
        if (@operand == 1) {    # Need at least two things on the stack...
          $errortext = "Missing operand. ";    # remember error
          push @operand, { type => "n",
            value => 0 };    # put something there as second operand
        }
        $value2 =
          operand_value_and_type($sheetdata, \@operand, \$errortext,
          \$tostype2);
        $value1 =
          operand_value_and_type($sheetdata, \@operand, \$errortext,
          \$tostype);
        if (substr($tostype, 0, 1) eq "n" && substr($tostype2, 0, 1) eq "n")
        {                    # compare two numbers
          my $cond = 0;
          if    ($ttext eq "<") { $cond = $value1 < $value2  ? 1 : 0; }
          elsif ($ttext eq "L") { $cond = $value1 <= $value2 ? 1 : 0; }
          elsif ($ttext eq "=") { $cond = $value1 == $value2 ? 1 : 0; }
          elsif ($ttext eq "G") { $cond = $value1 >= $value2 ? 1 : 0; }
          elsif ($ttext eq ">") { $cond = $value1 > $value2  ? 1 : 0; }
          elsif ($ttext eq "N") { $cond = $value1 != $value2 ? 1 : 0; }
          push @operand, { type => "nl", value => $cond };
        } elsif (substr($tostype, 0, 1) eq "e") {    # error on left
          push @operand, { type => $tostype, value => 0 };
        } elsif (substr($tostype2, 0, 1) eq "e") {    # error on right
          push @operand, { type => $tostype2, value => 0 };
        } else {    # text maybe mixed with numbers or blank
          if (substr($tostype, 0, 1) eq "n") {
            $value1 = format_number_for_display($value1, "n", "");
          }
          if (substr($tostype2, 0, 1) eq "n") {
            $value2 = format_number_for_display($value2, "n", "");
          }
          my $cond     = 0;
          my $value1u8 = $value1;
          my $value2u8 = $value2;
          utf8::decode($value1u8);    # handle UTF-8
          utf8::decode($value2u8);
          $value1u8 = lc $value1u8;    # ignore case
          $value2u8 = lc $value2u8;
          if    ($ttext eq "<") { $cond = $value1u8 lt $value2u8 ? 1 : 0; }
          elsif ($ttext eq "L") { $cond = $value1u8 le $value2u8 ? 1 : 0; }
          elsif ($ttext eq "=") { $cond = $value1u8 eq $value2u8 ? 1 : 0; }
          elsif ($ttext eq "G") { $cond = $value1u8 ge $value2u8 ? 1 : 0; }
          elsif ($ttext eq ">") { $cond = $value1u8 gt $value2u8 ? 1 : 0; }
          elsif ($ttext eq "N") { $cond = $value1u8 ne $value2u8 ? 1 : 0; }
          push @operand, { type => "nl", value => $cond };
        }
      }

      # Normal infix arithmethic operators: +, -. *, /, ^

      else {    # what's left are the normal infix arithmetic operators
        if (@operand == 1) {    # Need at least two things on the stack...
          $errortext = "Missing operand. ";    # remember error
          push @operand, { type => "n",
            value => 0 };    # put something there as second operand
        }
        $value2 =
          operand_as_number($sheetdata, \@operand, \$errortext, \$tostype2);
        $value1 =
          operand_as_number($sheetdata, \@operand, \$errortext, \$tostype);
        if ($ttext eq '+') {
          $resulttype =
            lookup_result_type($tostype, $tostype2, $typelookup{plus});
          push @operand, { type => $resulttype, value => $value1 + $value2 };
        } elsif ($ttext eq '-') {
          $resulttype =
            lookup_result_type($tostype, $tostype2, $typelookup{plus});
          push @operand, { type => $resulttype, value => $value1 - $value2 };
        } elsif ($ttext eq '*') {
          $resulttype =
            lookup_result_type($tostype, $tostype2, $typelookup{plus});
          push @operand, { type => $resulttype, value => $value1 * $value2 };
        } elsif ($ttext eq '/') {
          if ($value2 != 0) {
            push @operand, { type => "n",
              value => $value1 / $value2 };  # gives plain numeric result type
          } else {
            push @operand, { type => "e#DIV/0!", value => 0 };
          }
        } elsif ($ttext eq '^') {
          push @operand, { type => "n",
            value => $value1**$value2 };     # gives plain numeric result type
        }
      }
    }

    # function or name

    elsif ($ttype == $token_name) {

      # TODO fix cyclic dependency
      require Spreadsheet::Engine::Functions;
      Spreadsheet::Engine::Functions::calculate_function($ttext, \@operand,
        \$errortext, \%typelookup, $sheetdata);
    }

    else {
      $errortext = "Unknown token $ttype ($ttext). ";
    }
  }

  # look at final value and handle special cases

  my $value = $operand[0]->{value};
  my $valuetype;
  $tostype = $operand[0]->{type} || '';

  if ($tostype eq "name") {    # name - expand it
    $value = lc $value;
    $value = lookup_name($sheetdata, $value, \$tostype, \$errortext);
  }

  if ($tostype eq "coord")
  {    # the value is a coord reference, get its value and type
    $value =
      operand_value_and_type($sheetdata, \@operand, \$errortext, \$tostype);
    $tostype = "n" if ($tostype eq "b");
  }

  if (scalar @operand > 1) {    # something left - error
    $errortext .= "Error in formula.";
  }

  # set return type

  $valuetype = $tostype;

  if (substr($tostype, 0, 1) eq "e") {    # error value
    $errortext ||= substr($tostype, 1) || "Error value in formula";
  } elsif ($tostype eq "range") {
    $value =~ m/^(.*)\|(.*)\|/;
    $value = uc "$1:$2";
    if (!$allowrangereturn) {
      $errortext = "Formula results in range value: $value.";
    }
  }

  if ($errortext && substr($valuetype, 0, 1) ne "e") {
    $value     = $errortext;
    $valuetype = "e";
  }

  # look for overflow

  if (substr($tostype, 0, 1) eq "n" && defined $value && $value =~ m/1\.#INF/)
  {
    $value     = 0;
    $valuetype = "e#NUM!";
    $errortext = "Numeric overflow";
  }
  return ($value, $valuetype, $errortext);
}

=head2 operand_as_coord

  $value = operand_as_coord(\%sheetdata, \@operand, \$errortext)

Gets top of stack and pops it.  Returns coord value. All others are
treated as an error.

=cut

sub operand_as_coord {

  my ($sheetdata, $operand, $errortext) = @_;

  my $stacklen = scalar @$operand;
  my $value    = $operand->[ $stacklen - 1 ]->{value};    # get top of stack
  my $tostype  = $operand->[ $stacklen - 1 ]->{type};
  pop @$operand;    # we have data - pop stack

  if ($tostype eq "name") {
    $value = uc $value;
    $value = lookup_name($sheetdata, $value, \$tostype, $errortext);
  }

  if ($tostype eq "coord") {    # value is a coord reference
    return $value;
  } else {
    $$errortext = "Cell reference missing when expected.";
    return 0;
  }
}

=head2 operands_as_coord_on_sheet

  $value = operands_as_coord_on_sheet(\%sheetdata, \@operand, \$returntype, \$errortext)

Gets 2 at top of stack and pops them, treating them as sheetname!coord-or-name.
Returns stack-style coord value (coord!sheetname, or coord!sheetname|coord|) and
sets $returntype to coord or range. All others are treated as an error.

=cut

sub operands_as_coord_on_sheet {

  my ($sheetdata, $operand, $returntype, $errortext) = @_;

  my $stacklen = scalar @$operand;
  my $value    =
    $operand->[ $stacklen - 1 ]->{value};   # get top of stack - coord or name
  my $tostype = $operand->[ $stacklen - 1 ]->{type};
  pop @$operand;                            # we have data - pop stack

  my $sheetname =
    operand_as_sheetname($sheetdata, $operand, $errortext)
    ;                                       # get sheetname as text
  my $othersheetdata = find_in_sheet_cache($sheetdata, $sheetname);
  if ($othersheetdata->{loaderror}) {       # this sheet is unavailable
    $$errortext  = "Cell reference missing when expected.";
    $$returntype = "e#REF!";
    return "";
  }

  if ($tostype eq "name") {
    $value = uc $value;
    $value = lookup_name($othersheetdata, $value, \$tostype, $errortext);
  }
  $$returntype = $tostype;
  if ($tostype eq "coord") {                # value is a coord reference
    return "$value!$sheetname";    # return in the format as used on stack
  } elsif ($tostype eq "range") {    # value is a range reference
    my ($c1, $c2, $c3) = split (/\|/, $value, 3);
    return "$c1!$sheetname|$c2|";
  } else {
    $$errortext  = "Cell reference missing when expected.";
    $$returntype = "e#REF!";
    return "";
  }
}

=head2 operands_as_range_on_sheet

  $value = operands_as_range_on_sheet(\%sheetdata, \@operand, \$returntype, \$errortext)

Gets 2 at top of stack and pops them, treating them as
coord2-or-name:coord1.  Name is evaluated on sheet of coord1.
Returns stack-style range value (coord!sheetname|coord|) and sets
$returntype to range. All others are treated as an error.

=cut

sub operands_as_range_on_sheet {

  my ($sheetdata, $operand, $returntype, $errortext) = @_;

  my $stacklen = scalar @$operand;
  my $value2   =
    $operand->[ $stacklen - 1 ]
    ->{value};    # get top of stack - coord or name for "right" side
  my $tostype = $operand->[ $stacklen - 1 ]->{type};
  pop @$operand;    # we have data - pop stack

  my $value1 =
    operand_as_coord($sheetdata, $operand, $errortext);    # get "left" coord
  if (!$value1) {    # not a coord, which it must be
    $$returntype = "e#REF!";
    return "";
  }

  my $othersheetdata = $sheetdata;

  if ($value1 =~ m/^.*!([^\|]+)$/) {    #
    $othersheetdata = find_in_sheet_cache($sheetdata, $1);
    if ($othersheetdata->{loaderror}) {    # this sheet is unavailable
      $$errortext  = "Cell reference missing when expected.";
      $$returntype = "e#REF!";
      return "";
    }
  }

  if ($tostype eq "name") {  # coord:name is allowed, if name is just one cell
    $value2 = uc $value2;
    $value2 = lookup_name($othersheetdata, $value2, \$tostype, $errortext);
  }
  if ($tostype eq "coord")
  {    # value is a coord reference, so return the combined range
    $$returntype = "range";
    return "$value1|$value2|";    # return in the format as used on stack
  } else {                        # bad form
    $$errortext  = "Cell reference missing when expected.";
    $$returntype = "e#REF!";
    return "";
  }
}

=head2 operand_as_sheetname

  $value = operand_as_sheetname(\%sheetdata, \@operand, \$errortext)

Gets top of stack and pops it.
Returns sheetname value. All others are treated as an error.
Accepts text, cell reference, and named value which is one of those two.

=cut

sub operand_as_sheetname {

  my ($sheetdata, $operand, $errortext) = @_;

  my $stacklen = scalar @$operand;
  my $value    = $operand->[ $stacklen - 1 ]->{value};    # get top of stack
  my $tostype  = $operand->[ $stacklen - 1 ]->{type};
  pop @$operand;    # we have data - pop stack
  if ($tostype eq "name") {    # either a named cell or a sheet name bare
    my $ignoreerror;
    my $lookupname =
      lookup_name($sheetdata, $value, \$tostype, \$ignoreerror);
    if (!$lookupname)
    {    # not a known name - return bare name as the name value
      return $value;
    }
    $value = $lookupname;    # try this value and type
  }
  if ($tostype eq "coord")
  {    # value is a coord reference, follow it to find sheet name
    my $cellvtype =
      $sheetdata->{valuetypes}
      ->{$value};    # get type of value in the cell it points to
    $value = $sheetdata->{datavalues}->{$value};
    $tostype = $cellvtype || "b";
  }
  if (substr($tostype, 0, 1) eq "t")
  {                  # value is a string which could be a sheet name
    return $value;
  } else {
    $$errortext = "Sheet name missing when expected.";
    return "";
  }
}

=head2 lookup_name

  $value = lookup_name(\%sheetdata, $name, \$valuetype, \$errortext)

Returns value and type of a named value.
Names are case insensitive.
Names may have a definition which is a coord (A1), a range (A1:B7), or a formula (=OFFSET(A1,0,0,5,1))

=cut

sub lookup_name {

  my ($sheetdata, $name, $valuetype, $errortext) = @_;

  my $names = $sheetdata->{names};

  if (defined $names->{ uc $name }) {    # is name defined?

    my $value = $names->{ uc $name }->{definition};    # yes

    if (substr($value, 0, 1) eq "=") {                 # formula
      my $startedwalk;
      if (!$sheetdata->{checknamecirc})
      {    # are we possibly walking the name tree?
        $sheetdata->{checknamecirc} = {};    # not yet
        $startedwalk = 1;                    # remember we started it
      } else {
        if ($sheetdata->{checknamecirc}->{$name}) {    # circular reference
          $$valuetype = "e#NAME?";
          $$errortext = qq!Circular name reference to name "$name".!;
          return "";
        }
      }
      $sheetdata->{checknamecirc}->{$name} = 1;

      my $parseinfo = parse_formula_into_tokens(substr($value, 1));
      ($value, $$valuetype, $$errortext) =
        evaluate_parsed_formula($parseinfo, $sheetdata, 1)
        ;    # parse formula, allowing range return

      delete $sheetdata->{checknamecirc}->{$name};    # done with us
      delete $sheetdata->{checknamecirc} if $startedwalk;    # done with walk

      if ($$valuetype ne "range") {
        return $value;
      }
    }

    if ($value =~ m/^(.*)\:(.*)$/) {                         # range
      $$valuetype = "range";
      $value      = uc "$1|$2|";
    } else {
      $$valuetype = "coord";
      $value      = uc $value;
    }
    return $value;
  } else {
    $$valuetype = "e#NAME?";
    $$errortext = qq!Unknown name "$name".!;
    return "";
  }
}

=head2 step_through_range_up

  $value = step_through_range_up(\@operand, $rangevalue, \$operandtype)

Returns next coord in a range, keeping track on the operand stack.
Goes from bottom right across and up to upper left.

=cut

sub step_through_range_up {

  my ($operand, $value, $operandtype) = @_;

  my ($value1, $value2, $sequence) = split (/\|/, $value);
  my ($sheet1, $sheet2);
  ($value1, $sheet1) = split (/!/, $value1);
  $sheet1 = "!$sheet1" if $sheet1;
  ($value2, $sheet2) = split (/!/, $value2);
  my ($c1, $r1) = coord_to_cr($value1);
  my ($c2, $r2) = coord_to_cr($value2);
  ($c2, $c1) = ($c1, $c2) if ($c1 > $c2);
  ($r2, $r1) = ($r1, $r2) if ($r1 > $r2);
  my $count;
  $sequence = ($r2 - $r1 + 1) * ($c2 - $c1 + 1) - 1
    if length($sequence) == 0;    # start at the end

  for (my $r = $r1 ; $r <= $r2 ; $r++) {
    for (my $c = $c1 ; $c <= $c2 ; $c++) {
      $count++;
      if ($count > $sequence) {
        $sequence--;
        push @$operand,
          { type => "range", value => "$value1$sheet1|$value2|$sequence" }
          unless $sequence < 0;
        $$operandtype = "coord";
        return cr_to_coord($c, $r) . $sheet1;
      }
    }
  }
}

=head2 step_through_range_down

  $value = step_through_range_down(\@operand, $rangevalue, \$operandtype)

Returns next coord in a range, keeping track on the operand stack.
Goes from upper left across and down to bottom right.

=cut

sub step_through_range_down {

  my ($operand, $value, $operandtype) = @_;

  my ($v1, $v2, $sequence) = split (/\|/, $value);
  $sequence ||= 0;

  my ($value1, $sheet1) = split (/!/, $v1);
  ($sheet1 &&= "!$sheet1") ||= '';
  my ($value2, $sheet2) = split (/!/, $v2);

  my ($c1, $r1) = coord_to_cr($value1);
  my ($c2, $r2) = coord_to_cr($value2);
  ($c2, $c1) = ($c1, $c2) if ($c1 > $c2);
  ($r2, $r1) = ($r1, $r2) if ($r1 > $r2);

  my $count = 0;
  for (my $r = $r1 ; $r <= $r2 ; $r++) {
    for (my $c = $c1 ; $c <= $c2 ; $c++) {
      $count++;
      if ($count > $sequence) {
        push @$operand,
          { type => "range", value => "$value1$sheet1|$value2|$count" }
          unless ($r == $r2 && $c == $c2);
        $$operandtype = "coord";
        return cr_to_coord($c, $r) . $sheet1;
      }
    }
  }
}

=head2 col_to_number

  $col = col_to_number($colname)

Turns B into 2. The default is 1.

=cut

sub col_to_number {
  my $coord = shift @_;
  $coord = lc($coord);
  $coord =~ m/([a-z])([a-z])?/;
  return 1 unless $1;
  my $col = ord($1) - ord('a') + 1;
  $col = 26 * $col + ord($2) - ord('a') + 1 if $2;
  return $col;
}

=head2 number_to_col

  $coord = number_to_col($col)

Turns 2 into B. The default is 1.

=cut

sub number_to_col {
  my $col = shift @_;
  $col = $col > 1 ? $col : 1;
  my $col_high = int(($col - 1) / 26);
  my $col_low  = ($col - 1) % 26;
  my $coord    = chr(ord('A') + $col_low);
  $coord = chr(ord('A') + $col_high - 1) . $coord if $col_high;
  return $coord;
}

=head2 special_chars_markup

  my $estring = special_chars_markup($string)

Returns $estring where &, <, >, " are HTML escaped ready for expand markup

=cut

sub special_chars_markup {
  my $string = shift @_;
  $string =~ s/&/{{amp}}amp;/g;
  $string =~ s/</{{amp}}lt;/g;
  $string =~ s/>/{{amp}}gt;/g;
  $string =~ s/"/{{amp}}quot;/g;
  return $string;
}

=head2 url_encode

  my $estring = url_encode($string)

Returns $estring with special chars URL encoded.

Based on Mastering Regular Expressions, Jeffrey E. F. Friedl,
additional legal characters added

=cut

sub url_encode {
  my $string = shift @_;
  $string =~ s!([^a-zA-Z0-9_\-;/?:@=#.])!sprintf('%%%02X', ord($1))!ge;
  $string =~
    s/%26/{{amp}}/gs;   # let ampersands in URLs through -- convert to {{amp}}
  return $string;
}

=head2 url_encode_plain

  my $estring = url_encode_plain($string)

Returns $estring with special chars URL encoded for sending to others by
HTTP, not publishing.

Based on Mastering Regular Expressions, Jeffrey E. F. Friedl, additional
legal characters added.

=cut

sub url_encode_plain {
  my $string = shift @_;
  $string =~ s!([^a-zA-Z0-9_\-/?:@=#.])!sprintf('%%%02X', ord($1))!ge;
  return $string;
}

=head2 find_in_sheet_cache

  my $othersheet_sheetdata = find_in_sheet_cache(\%sheetdata, $datafilename)

Load additional sheet's information for worksheet references as a sheetdata structure
stored in $sheetdata->{sheetcache}->{sheets}->{$datafilename} if necessary.
Return that structure as \%othersheet_sheetdata

=cut 

sub find_in_sheet_cache {

  # TODO have a way for applications to specify how this should work

  my ($sheetdata, $datafilename) = @_;

  my $sdsc = $sheetdata->{sheetcache};

  if ($datafilename !~ m/^http:/i) {    # not URL
    $datafilename = lc $datafilename;    # lower case for consistency
  }

  if ($sdsc->{sheets}->{$datafilename}) {    # already in cache
    return $sdsc->{sheets}->{$datafilename};
  }

  my (@headerlines, @sheetlines, $loaderror);

  $loaderror = "Cross-sheet references are not yet supported";

  # assume local pagename
  # my $editpath = get_page_published_datafile_path($sdsc->{params}, $sdsc->{hostinfo}, $sdsc->{sitename}, $datafilename);
  # $loaderror = load_page($editpath, \@headerlines, \@sheetlines);

  $sdsc->{sheets}->{$datafilename} = {};     # start fresh
  my $ok = parse_sheet_save(\@sheetlines, $sdsc->{sheets}->{$datafilename});

  $sdsc->{sheets}->{$datafilename}->{loaderror} = $loaderror if $loaderror;

  return $sdsc->{sheets}->{$datafilename};

}

1;

__END__

=head1 HISTORY

Modified version of SocialCalc::Sheet from SocialCalc 1.1.0

=head1 COPYRIGHT

Portions (c) Copyright 2005, 2006, 2007 Software Garden, Inc.
All Rights Reserved.

Portions (c) Copyright 2007 Socialtext, Inc.
All Rights Reserved.

Portions (c) Copyright 2007, 2008 Tony Bowden

=head1 LICENSE

The contents of this file are subject to the Artistic License 2.0;
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
  http://www.perlfoundation.org/artistic_license_2_0

