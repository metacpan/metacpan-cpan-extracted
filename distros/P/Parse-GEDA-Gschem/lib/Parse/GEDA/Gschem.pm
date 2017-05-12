################################################################################
# Parse::GEDA::Gschem.pm                                                       #
################################################################################
#
# DESCRIPTION:
# Collection of routines used to parse and write back schematic files of the
# format specified by gEDA gschem schematic capture tool as detailed at:
# http://www.geda.seul.org/wiki/geda:file_format_spec
#
# EXAMPLE:
# my @schFiles = (); # array of schematic file names
# my @files = ();    # array of schematic objects
# bakSchFiles(\@schFiles); # backup schematic files in bak/year-m-d_h-m-s/
# $files = @{readSchFiles(\@schFiles)}; # parses the schematic files
# writeMsg(1, Dumper(\@files)); # prints out the entire data structure
# writeSchFiles(\@files); # write the data structure into schematic files
#
# REQUIREMENTS:
# perl 5.10
#
################################################################################
#
#   Copyright (C) 2008, JP Fricker. All rights reserved.
#
#   This file is part of Parse::GEDA::Gschem
#
#   Parse::GEDA::Gschem is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   Parse::GEDA::Gschem is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with Parse::GEDA::Gschem.  If not, see <http://www.gnu.org/licenses/>.
#
################################################################################
package Parse::GEDA::Gschem;

use 5.10.0;
use feature "switch";
use File::Copy;
use File::Basename;
use Parse::RecDescent;
$::RD_HINT = 1;
#$::RD_TRACE = 30; # Uncomment this if you want much detail about the parsing process
use Data::Dumper;
use Storable qw(dclone);
#use re 'debug';
#use re 'eval';

BEGIN {
  use Exporter ();
  our ($VERSION, @ISA, @EXPORT);

  # set the version for version checking
  use version; $VERSION = qv('1.00');

  @ISA = qw(Exporter);
  @EXPORT = qw(
    writeMsg
    bakSchFiles
    readSchFiles
    writeSchFiles
  );
}
################################################################################

our $VERBOSE = 0; # set it to greater values to get more details
our $ERRORFILENAME = $1.".log" if ($0 =~ m/.*\/([^\/]+?(\.pl){0})(\.pl)?$/);


#==============================================================================
# Write Message
#==============================================================================
sub writeMsg
{
  my ($verbosity) = shift @_;
  my ($message) = shift @_;

  open(ErrorFile,">>$ERRORFILENAME") or die "Unable to open error file $ERRORFILENAME for writing.\n";

  print(ErrorFile $message);
  print($message) if ($verbosity <= $VERBOSE);

} # writeMsg

#==============================================================================
# Backup schematic files
#==============================================================================
sub bakSchFiles {
  use strict;
  my @schFiles = @{shift @_};
  my @bakFiles;
  my $bakDir = "bak";
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);

  writeMsg (1, "Creating backup directory $bakDir ...\n");
  mkdir($bakDir);
  ($! =~ m/|File exists/) or die "Can't create backup directory $bakDir : $!\n";

  $bakDir .= sprintf("/%04d-%02d-%02d_%02d-%02d-%02d", $year+1900, $mon, $mday, $hour, $min, $sec);
  writeMsg (1, "Creating backup directory $bakDir ...\n");
  mkdir($bakDir);
  ($! =~ m/|File exists/) or die "Can't create backup directory $bakDir : $!\n";

  if (1) { # change it to 0 if you don't want to save the program itself
     writeMsg (1, "Copying program file to backup directory ...\n");
     my $progFile = $bakDir."/".$1 if ($0 =~ m/.*\/([^\/]+(\.pl)?)$/);
     copy($0, $progFile) or die "Can't copy $0 to $progFile : $!\n";
  }

  writeMsg (1, "Copying backup files to backup directory ...\n");
  foreach my $schFile (@schFiles) {
    my $bakFile = $bakDir."/".$schFile;
    push(@bakFiles, ($bakFile));
    mkdir(dirname($bakFile));
    ($! =~ m/|File exists/) or die "Can't create backup directory $bakDir : $!\n";
    copy($schFile, $bakFile) or die "Can't copy $schFile to $bakFile : $!\n";
  }
  [ @bakFiles ]
} # bakSchFiles



#==============================================================================
# Read in sch files and parse them to build and return an array
#==============================================================================
sub readSchFiles {
  use strict;
  my  @schFiles = @{shift @_};

  my $grammar = q{

    # See how to write such grammar at
    # http://search.cpan.org/~dconway/Parse-RecDescent-v1.95.1/lib/Parse/RecDescent.pm

    # Grammar is based on the gschem sch/sym file format
    # http://geda.seul.org/wiki/geda:file_format_spec

    File:
      <skip: qr//> /\\A/
      <skip: qr//> Object(s)
      { $ return = [ @{$item[-1]} ]; }
      <skip: qr//> /\\n?\\z/
      
    Object:
      <skip: qr//>
      (
        Net
      | Component
      | Pin
      | Version
      | Line
      | Box
      | Circle
      | Arc
      | Attribute # same as Text with first string formated as name=value
      | Text
      | Picture
      )
      { $return = $item[-1]; }
      <skip: $item[1]>
      | <error>

    Version:
      /^v\\s+/ <commit>
      Int(2 /\\s+/)
      {
        $return = { (
          type               => 'v',
          version            => $item[-1]->[0], # version of gEDA/gaf that wrote this file
          fileformat_version => $item[-1]->[1], # gEDA/gaf file format version number
        ) };
      }
      /\\n/
      | <error?> <reject>
          
    Line:
      /^L\\s+/ <commit>
      Int(10 /\\s+/)
      {
        $return = { (
          type               => 'L',
          x1                 => $item[-1]->[ 0], # First X coordinate
          y1                 => $item[-1]->[ 1], # First Y coordinate
          x2                 => $item[-1]->[ 2], # Second X coordinate
          y2                 => $item[-1]->[ 3], # Second Y coordinate
          color              => $item[-1]->[ 4], # Color index
          width              => $item[-1]->[ 5], # Width of line
          capstyle           => $item[-1]->[ 6], # Line cap style
          dashstyle          => $item[-1]->[ 7], # Type of dash style
          dashlength         => $item[-1]->[ 8], # Length of dash
          dashspace          => $item[-1]->[ 9], # Space inbetween dashes
        ) };
      }
      /\\n/
      Attributes_Section
      {
        if ( @{$item[-1]} ) {
          $return->{Attributes} = [ @{$item[-1]} ];
        } else { 1 }
      }
      | <error?> <reject>


    Attributes_Section:
      /\\{\\n/ <commit>
      Attribute(s)
      {
        if ( @{$item[-1]} ) {
          $return = [ @{$item[-1]} ];
        }
      }
      /\\}\\n/
      | <error?> <reject>
      | { [] }

    Attribute:
      /^T\\s+/ <commit>
      Int(9 /\\s+/)
      {
        $return = { (
          type               => 'T',
          x                  => $item[-1]->[ 0], # First X coordinate
          y                  => $item[-1]->[ 1], # First Y coordinate
          color              => $item[-1]->[ 2], # Color index
          size               => $item[-1]->[ 3], # Size of textrdinate
          visibility         => $item[-1]->[ 4], # Visibility of text
          show_name_value    => $item[-1]->[ 5], # Attribute visibility control
          angle              => $item[-1]->[ 6], # Angle of the text
          alignment          => $item[-1]->[ 7], # Alignment/origin of the text
          num_lines          => $item[-1]->[ 8], # Number of lines of text (1 based)
        ) };
      }
      /\\n/
      name
      { $return->{name} = $item[-1] }
      /=/
      String[$return->{num_lines}]
      { $return->{value} = $item[-1] }
      /\\n/
      | <error?> <reject>

    name: /\\w+/

    Text:
      /^T\\s+/ <commit>
      Int(9 /\\s+/)
      {
        $return = { (
          type               => 'T',
          x                  => $item[-1]->[ 0], # First X coordinate
          y                  => $item[-1]->[ 1], # First Y coordinate
          color              => $item[-1]->[ 2], # Color index
          size               => $item[-1]->[ 3], # Size of textrdinate
          visibility         => $item[-1]->[ 4], # Visibility of text
          show_name_value    => $item[-1]->[ 5], # Attribute visibility control
          angle              => $item[-1]->[ 6], # Angle of the text
          alignment          => $item[-1]->[ 7], # Alignment/origin of the text
          num_lines          => $item[-1]->[ 8], # Number of lines of text (1 based)
        ) };
      }
      /\\n/
      String[$return->{num_lines}]
      { $return->{string} = $item[-1] }
      /\\n/
      | <error?> <reject>

    String: # takes the number of lines to be fetched as first argument
      /[^\\n]*/
      # if $arg[0] == 1 we don't need to fetch other lines
      ( <reject: !($arg[0] == 1)> | /\\n/ String[$arg[0]-1] )
      {
        if ($arg[0] gt 1) {
          $return = $item[1]."\\n".$item[2]
        } else {
          $return = $item[1];
        }
      }

    Picture:
      /^G\\s+/ <commit>
      Int(7 /\\s+/)
      {
        $return = { (
          type               => 'G',
          x                  => $item[-1]->[ 0], # Lower left X coordinate
          y                  => $item[-1]->[ 1], # Lower left Y coordinate
          width              => $item[-1]->[ 2], # Width of the picture
          height             => $item[-1]->[ 3], # Height of the picture
          angle              => $item[-1]->[ 4], # Angle of the picture
          mirrored           => $item[-1]->[ 5], # Mirrored or normal picture
          embedded           => $item[-1]->[ 6], # Embedded or link to the picture file
        ) };
      }
      /\\n/
      String[1]
      { $return->{filename} = $item[-1]; }
      /\\n/
      Embedded_Picture[$return->{embedded}]
      {
        if (defined($item[-1])) {
          $return->{embedded_picture_data} = $item[-1];
        }
      }
      | <error?> <reject>

    Embedded_Picture:
        <reject: !($arg[0] == 0)> 
      | {
          $text =~ s/(?<data>([^\\n]*\\n)*)\\.\\n//m;
          $return = $+{data};
        }
        
    Box:
      /^B\\s+/ <commit>
      Int(16 /\\s+/)
      {
        $return = { (
          type               => 'B',
          x                  => $item[-1]->[ 0], # Lower left hand X coordinate
          y                  => $item[-1]->[ 1], # Lower left hand Y coordinate
          span               => $item[-1]->[ 2], # Width of the box (x direction)
          height             => $item[-1]->[ 3], # Height of the box (y direction)
          color              => $item[-1]->[ 4], # Color index
          width              => $item[-1]->[ 5], # Width of lines
          capstyle           => $item[-1]->[ 6], # Lines cap style
          dashstyle          => $item[-1]->[ 7], # Type of dash style
          dashlength         => $item[-1]->[ 8], # Length of dash
          dashspace          => $item[-1]->[ 9], # Space inbetween dashes
          filltype           => $item[-1]->[10], # Type of fill
          fillwidth          => $item[-1]->[11], # Width of the fill lines
          angle1             => $item[-1]->[12], # First angle of fill
          pitch1             => $item[-1]->[13], # First pitch/spacing of fill
          angle2             => $item[-1]->[14], # Second angle of fill
          pitch2             => $item[-1]->[15], # Second pitch/spacing of fill
        ) };
      }
      /\\n/
      Attributes_Section
      {
        if ( @{$item[-1]} ) {
          $return->{Attributes} = [ @{$item[-1]} ];
        } else { 1 }
      }
      | <error?> <reject>

    Circle:
      /^V\\s+/ <commit>
      Int(15 /\\s+/)
      {
        $return = { (
          type               => 'V',
          x                  => $item[-1]->[ 0], # Center X coordinate
          y                  => $item[-1]->[ 1], # Center Y coordinate
          radius             => $item[-1]->[ 2], # Radius of the circle
          color              => $item[-1]->[ 3], # Color index
          width              => $item[-1]->[ 4], # Width of circle
          capstyle           => $item[-1]->[ 5], # 0 unused
          dashstyle          => $item[-1]->[ 6], # Type of dash style
          dashlength         => $item[-1]->[ 7], # Length of dash
          dashspace          => $item[-1]->[ 8], # Space inbetween dashes
          filltype           => $item[-1]->[ 9], # Type of fill
          fillwidth          => $item[-1]->[10], # Width of the fill lines
          angle1             => $item[-1]->[11], # First angle of fill
          pitch1             => $item[-1]->[12], # First pitch/spacing of fill
          angle2             => $item[-1]->[13], # Second angle of fill
          pitch2             => $item[-1]->[14], # Second pitch/spacing of fill
        ) };
      }
      /\\n/
      Attributes_Section
      {
        if ( @{$item[-1]} ) {
          $return->{Attributes} = [ @{$item[-1]} ];
        } else { 1 }
      }
      | <error?> <reject>

    Arc:
      /^A\\s+/ <commit>
      Int(11 /\\s+/)
      {
        $return = { (
          type               => 'A',
          x                  => $item[-1]->[ 0], # Center X coordinate
          y                  => $item[-1]->[ 1], # Center X coordinate
          radius             => $item[-1]->[ 2], # Radius of the arc
          startangle         => $item[-1]->[ 3], # Starting angle of the arc
          sweepangle         => $item[-1]->[ 4], # Amount the arc sweeps
          color              => $item[-1]->[ 5], # Color index
          width              => $item[-1]->[ 6], # Width of line
          capstyle           => $item[-1]->[ 7], # Line cap style
          dashstyle          => $item[-1]->[ 8], # Type of dash style
          dashlength         => $item[-1]->[ 9], # Length of dash
          dashspace          => $item[-1]->[10], # Space inbetween dashes
        ) };
      }
      /\\n/
      Attributes_Section
      {
        if ( @{$item[-1]} ) {
          $return->{Attributes} = [ @{$item[-1]} ];
        } else { 1 }
      }
      | <error?> <reject>

    Net:
      /^N\\s+/ <commit>
      Int(5 /\\s+/)
      {
        $return = { (
          type               => 'N',
          x1                 => $item[-1]->[ 0], # First X coordinate
          y1                 => $item[-1]->[ 1], # First Y coordinate
          x2                 => $item[-1]->[ 2], # Second X coordinate
          y2                 => $item[-1]->[ 3], # Second Y coordinate
          color              => $item[-1]->[ 4], # Color index
        ) };
      }
      /\\n/
      Attributes_Section
      {
        if ( @{$item[-1]} ) {
          $return->{Attributes} = [ @{$item[-1]} ];
        } else { 1 }
      }
      | <error?> <reject>

    Bus:
      /^U\\s+/ <commit>
      Int(6 /\\s+/)
      {
        $return = { (
          type               => 'U',
          x1                 => $item[-1]->[ 0], # First X coordinate
          y1                 => $item[-1]->[ 1], # First Y coordinate
          x2                 => $item[-1]->[ 2], # Second X coordinate
          y2                 => $item[-1]->[ 3], # Second Y coordinate
          color              => $item[-1]->[ 4], # Color index
          ripperdir          => $item[-1]->[ 5], # Direction of bus rippers
        ) };
      }
      /\\n/
      Attributes_Section
      {
        if ( @{$item[-1]} ) {
          $return->{Attributes} = [ @{$item[-1]} ];
        } else { 1 }
      }
      | <error?> <reject>

    Pin:
      /^P\\s+/ <commit>
      Int(7 /\\s+/)
      {
        $return = { (
          type               => 'P',
          x1                 => $item[-1]->[ 0], # First X coordinate
          y1                 => $item[-1]->[ 1], # First Y coordinate
          x2                 => $item[-1]->[ 2], # Second X coordinate
          y2                 => $item[-1]->[ 3], # Second Y coordinate
          color              => $item[-1]->[ 4], # Color index
          pintype            => $item[-1]->[ 5], # Type of pin
          whichend           => $item[-1]->[ 6], # Specifies the active end
        ) };
      }
      /\\n/
      Attributes_Section
      {
        if ( @{$item[-1]} ) {
          $return->{Attributes} = [ @{$item[-1]} ];
        } else { 1 }
      }
      | <error?> <reject>

    Component:
      /^C\\s+/ <commit>
      Int(5 /\\s+/)
      {
        $return = { (
          type               => 'C',
          x                  => $item[-1]->[ 0], # Origin X coordinate
          y                  => $item[-1]->[ 1], # Origin Y coordinate
          selectable         => $item[-1]->[ 2], # Selectable flag
          angle              => $item[-1]->[ 3], # Angle of the component
          mirror             => $item[-1]->[ 4], # Mirror around Y axis
        ) };
      }
      /\\s+/ String[1]
      {
        $return->{basename} = $item[-1];
      }
      /\\n/
      Embedded_Component_Section
      {
        if ( @{$item[-1]} ) {
          $return->{Embedded} = [ @{$item[-1]} ];
        } else { 1 }
      }
      Attributes_Section
      {
        if ( @{$item[-1]} ) {
          $return->{Attributes} = [ @{$item[-1]} ];
        } else { 1 }
      }
      | <error?> <reject>

    Embedded_Component_Section:
      /\\[\\n/ <commit>
      Object(s)
      {
        if ( @{$item[-1]} ) {
          $return = [ @{$item[-1]} ];
        }
      }
      /\\]\\n/
      | <error?> <reject>
      | { [] }

    Int: /[-+]?[0-9]+/m

  };

  my $parser = new Parse::RecDescent($grammar);

  my @files = ();

  writeMsg (1, "Parsing schematic files ...\n");
  foreach my $fileName (@schFiles) {
    writeMsg (2, "Parsing schematic file $fileName ...\n");
    open(SCHFILE,"<$fileName") or die "Can't open $fileName to read\n";
    undef $/;
    my $text = <SCHFILE>;
    my %fileHash = ();
    $fileHash{fileName} = $fileName;
    $fileHash{objects} = ($parser->File($text) or die "Couldn't complete parsing!\n");
    push(@files, { %fileHash } );
  }

  if (0) {
    $Data::Dumper::Purity = 1;
    my $result = Data::Dumper->new( [ \@files  ], ["files"] );
    writeMsg(1, $result->Dump);
  }

  [ @files ];

} # end readSchFiles


#==============================================================================
# Write files by running through the @files array
#==============================================================================
sub writeSchFiles {
  use strict;
  my @files = @{shift @_};
  my $newData = "";

  writeMsg(1, "Writing schematic files ...\n");
  for (my $file_idx = 0; $file_idx <  @files; $file_idx++) {
    my $fileName = $files[$file_idx]->{fileName};
    writeMsg(2, "Collecting data for schematic file $fileName ...\n");
    $newData = printObjects( \@{$files[$file_idx]->{objects}} );
    if (0) {
      writeMsg(1, $newData."\n");    
    }
    writeMsg(2, "Writing schematic file $fileName ...\n");
    open(SCHFILE,">$fileName") or die "Can't open $fileName to write\n";
    print SCHFILE $newData;
  }
} # end writeSchFiles


sub printAttributes {
  use strict;
  my @attributes = @{shift @_} if (ref($_[0]) eq "ARRAY") or return "";
  my $return = "";

  if (@attributes) {
    $return .= "{\n";
    foreach my $attribute (@attributes) {
      given ($attribute->{type}) {
        when ('T') {
          $return .= join(" ",
            $attribute->{type},
            $attribute->{x},
            $attribute->{y},
            $attribute->{color},
            $attribute->{size},
            $attribute->{visibility},
            $attribute->{show_name_value},
            $attribute->{angle},
            $attribute->{alignment},
            $attribute->{num_lines},
          )."\n";;
          $return .= $attribute->{name}."=".$attribute->{value}."\n";
        }    
      }
    }
    $return .= "}\n";
  }
  $return;
}  # end printAttributes


sub printEmbedded_Components {
  use strict;
  my @embeddeds = @{shift @_} if (ref($_[0]) eq "ARRAY") or return "";
  my $return = "";

  if (@embeddeds) {
    $return .= "[\n";
    $return .= printObjects(\@embeddeds);
    $return .= "]\n";
  }
  $return;
} # printEmbedded_Components


sub printObjects {
  use strict;
  my @objects = @{shift @_};
  my $return = "";

  # Go through each object
  foreach my $object (@objects) {
     if (0) {
       $Data::Dumper::Purity = 1;
       my $result = Data::Dumper->new( [ \%{$object}  ], ["object"] );
       writeMsg(1, "Processing ".$result->Dump." ...\n");
     }

     given ($object->{type}) {

       when ('v') {
         $return .= join(" ",
           $object->{type},
           $object->{version},
           $object->{fileformat_version},
         )."\n";
       } # end when ('v')

       when ('L') {
         $return .= join(" ",
           $object->{type},
           $object->{x1},
           $object->{y1},
           $object->{x2},
           $object->{y2},
           $object->{color},
           $object->{width},
           $object->{capstyle},
           $object->{dashstyle},
           $object->{dashlength},
           $object->{dashspace},
         )."\n";
         $return .= printAttributes(\@{$object->{Attributes}});
       } # end when ('L')

       when ('T') {
         $return .= join(" ",
           $object->{type},
           $object->{x},
           $object->{y},
           $object->{color},
           $object->{size},
           $object->{visibility},
           $object->{show_name_value},
           $object->{angle},
           $object->{alignment},
           $object->{num_lines},
         )."\n";
         if ($object->{string}) {
           $return .= $object->{string}."\n";
         } elsif (($object->{name}) && ($object->{value})) {
           $return .= $object->{name}."=".$object->{value}."\n";
         }
       } # end when ('T')

       when ('G') {
         $return .= join(" ",
           $object->{type},
           $object->{x},
           $object->{y},
           $object->{width},
           $object->{height},
           $object->{angle},
           $object->{mirrored},
           $object->{embedded},
         )."\n";
         $return .= $object->{filename}."\n" if (defined($object->{filename}));
         $return .= $object->{embedded_picture_data}."\n.\n" if (defined($object->{embedded_picture_data}));
         $return .= printAttributes(\@{$object->{Attributes}});
       } # end when ('G')


       when ('B') {
         $return .= join(" ",
           $object->{type},
           $object->{x},
           $object->{y},
           $object->{span},
           $object->{height},
           $object->{color},
           $object->{width},
           $object->{capstyle},
           $object->{dashstyle},
           $object->{dashlength},
           $object->{dashspace},
           $object->{filltype},
           $object->{fillwidth},
           $object->{angle1},
           $object->{pitch1},
           $object->{angle2},
           $object->{pitch2},
         )."\n";
         $return .= printAttributes(\@{$object->{Attributes}});
       } # end when ('B')

       when ('V') {
         $return .= join(" ",
           $object->{type},
           $object->{x},
           $object->{y},
           $object->{radius},
           $object->{color},
           $object->{width},
           $object->{capstyle},
           $object->{dashstyle},
           $object->{dashlength},
           $object->{dashspace},
           $object->{filltype},
           $object->{fillwidth},
           $object->{angle1},
           $object->{pitch1},
           $object->{angle2},
           $object->{pitch2},
         )."\n";
         $return .= printAttributes(\@{$object->{Attributes}});
       } # end when ('V')

       when ('A') {
         $return .= join(" ",
           $object->{type},
           $object->{x},
           $object->{y},
           $object->{radius},
           $object->{startangle},
           $object->{sweepangle},
           $object->{color},
           $object->{width},
           $object->{capstyle},
           $object->{dashstyle},
           $object->{dashlength},
           $object->{dashspace},
         )."\n";
         $return .= printAttributes(\@{$object->{Attributes}});
       } # end when ('A')

       when ('N') {
         $return .= join(" ",
           $object->{type},
           $object->{x1},
           $object->{y1},
           $object->{x2},
           $object->{y2},
           $object->{color},
         )."\n";
         $return .= printAttributes(\@{$object->{Attributes}});
       } # end when ('N')

       when ('U') {
         $return .= join(" ",
           $object->{type},
           $object->{x1},
           $object->{y1},
           $object->{x2},
           $object->{y2},
           $object->{color},
           $object->{ripperdir},
         )."\n";
         $return .= printAttributes(\@{$object->{Attributes}});
       } # end when ('P')

       when ('P') {
         $return .= join(" ",
           $object->{type},
           $object->{x1},
           $object->{y1},
           $object->{x2},
           $object->{y2},
           $object->{color},
           $object->{pintype},
           $object->{whichend},
         )."\n";
         $return .= printAttributes(\@{$object->{Attributes}});
       } # end when ('P')

       when ('C') {
         $return .= join(" ",
           $object->{type},
           $object->{x},
           $object->{y},
           $object->{selectable},
           $object->{angle},
           $object->{mirror},
           $object->{basename},
         )."\n";
         $return .= printEmbedded_Components(\@{$object->{Embedded}});
         $return .= printAttributes(\@{$object->{Attributes}});
       } # end when ('C')

       default {
         $Data::Dumper::Purity = 1;
         my $result = Data::Dumper->new( [ \%{$object}  ], ["object"] );
         die "Object type '".$object->{type}."' not recognized: ".$result->Dump."\n";
       }

     } # end given my $object_type
  } # end foreach my $object
  $return
} # end printObjects

1;
