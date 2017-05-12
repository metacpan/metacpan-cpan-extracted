#! /usr/bin/perl -w 

################################################################################
#
# COPYRIGHT AND LICENCE
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
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with Parse::GEDA::Gschem. If not, see <http://www.gnu.org/licenses/>.
#
################################################################################
#
# Requires perl 5.10
#
# Comments with tab as first character after # are displayed in by the -H option
#
# DESCRIPTION:
#	This program provides a command line interface to handling gEDA schematics.
#	It uses Parse::GEDA::Gschem.pm module to parse and write back schematics.
#	The first thing is does is to create a backup into a directory of the form:
#	./bak/year-month-day_hour-minute-second/
#	

use 5.10.0;
use feature "switch";
use File::Copy;
use Data::Dumper;
use Storable qw(dclone);

use lib $0."/..";

use Parse::RecDescent;
$::RD_HINT = 1;
#$::RD_TRACE = 30; # Uncomment this if you want much detail about the parsing process

use Parse::GEDA::Gschem;

#use re 'debug';
#use re 'eval';

@schFiles = ();

$VERBOSE = 0; # set it to greater values to get more details

#==============================================================================
# Usage
#==============================================================================
sub Usage {
  print "Usage: $0 [-hH] schematicFile1 schematicFile2 ... \n";
  print "\n";
  print "  -h            Help; this message\n";
  print "  -H            Extended help\n";
  print "  -v...v        Verbosity level.\n";
  print "  -update_xref  Update xref attributes\n";
  print "  -no_bak       Do not create backup before processing files\n";
  print "\n";
} # Usage

#==============================================================================
# Extended Help
#==============================================================================
sub Help {
   &Usage;
   # Comments in this file with tab as first character after # are displayed
   print `grep -P "^\#\t" $0 | sed -e "s/^\#\t//" -e "s/([\/\#])/\\$1/g"`
} # Help

#==============================================================================
# Check and read the command line arguments
#==============================================================================
# could be more sophisticated, but just good enough for now...
sub chkArgs {
  use strict;
  our @schFiles;
  our @ARGV;
  our $VERBOSE;
  our $do_no_bak = 0;
  our $do_update_xref = 0;

  my $errorFileName = $1.".log" if ($0 =~ m/.*\/([^\/]+?(\.pl){0})(\.pl)?$/);
  my $i = 0;

  &Usage if (scalar(@ARGV) == 0);

  while ($i<scalar(@ARGV)) {
    if ($ARGV[$i] =~ /^-h(elp)?$/) {
      &Usage;
      exit(0);
    } elsif ($ARGV[$i] eq "-H") {
      &Help;
      exit(0);
    } elsif ($ARGV[$i] eq "-v") {
      $VERBOSE = 1;
    } elsif ($ARGV[$i] eq "-vv") {
      $VERBOSE = 2;
    } elsif ($ARGV[$i] eq "-vvv") {
      $VERBOSE = 3;
    } elsif ($ARGV[$i] eq "-vvvv") {
      $VERBOSE = 4;
    } elsif ($ARGV[$i] eq "-vvvvv") {
      $VERBOSE = 5;
    } elsif ($ARGV[$i] eq "-update_xref") {
      $do_update_xref = 1;
    } elsif ($ARGV[$i] eq "-no_bak") {
      $do_no_bak = 1;
    } elsif ($ARGV[$i] =~ m/^[-]/) {
      print "Option $ARGV[$i] not supported.\n";
      &Usage;
      exit(0);
    } else {
      push @schFiles, $ARGV[$i];
    }
    $i++;
  }

  $Parse::GEDA::Gschem::VERBOSE = $VERBOSE;
  $Parse::GEDA::Gschem::ERRORFILENAME = $errorFileName;

} # chkArgs

#==============================================================================
# main program begins
#==============================================================================
&chkArgs;
Parse::GEDA::Gschem::bakSchFiles(\@schFiles) if (!$do_no_bak && @schFiles);
my @files = @{Parse::GEDA::Gschem::readSchFiles(\@schFiles)};
writeMsg(1, Dumper(\@files)) if (0);

update_xref(\@files) if ($do_update_xref);

writeMsg(1, Dumper(\@files)) if (0);
Parse::GEDA::Gschem::writeSchFiles(\@files) if (1);
exit();

#==============================================================================
#	-update_xref
#==============================================================================
#		Update xref attributes on net names to show on which page the
#		same netname is being used. Three or more consecutive pages are
#		aggregated as <first>-<last>. If the xref does not exist on a
#		net that appears on multiple pages then it is added and its
#		text properties are copied from the netname attribute with the
#		text origin mirrored horrizontally.
#	
sub update_xref {
  use strict;
  my @files = @{shift @_};

  my %idx_by_netname = ();
  my %sheets_by_netname = ();

  if (0) {
    $Data::Dumper::Purity = 1;
    my $result = Data::Dumper->new( [ \@files ], ["files"] );
    writeMsg(1, $result->Dump);
  }

  writeMsg(1, "Checking and fixing cross references ...\n");

  # build a idxs_by_netname hash where each netname entry
  # contains an array of indexes of instances of nets
  writeMsg(1, "Building netname_idxs_by_netname, xref_idx_by_object_idx hashes ...\n");

  # Go through each file
  for (my $file_idx = 0; $file_idx < @files; $file_idx++) {

    my $fileName = $files[$file_idx]->{fileName};
    writeMsg(2, "Processing file $fileName ...\n");

    next if (!($files[$file_idx]->{objects}));

    # Go through each object
    for (my $object_idx = 0; $object_idx < @{$files[$file_idx]->{objects}}; $object_idx++) {

      writeMsg(3, "Processing object $object_idx ...\n");

      # next if it is not a net
      next if (!($files[$file_idx]->{objects}->[$object_idx]->{type} eq 'N'));

      # next if it has no attributes
      next if (!($files[$file_idx]->{objects}->[$object_idx]->{Attributes}));

      # next if it's attribute table is empty
      next if (!(@{$files[$file_idx]->{objects}->[$object_idx]->{Attributes}}));

      my @netname_attr_idxs = ();
      my @xref_attr_idxs = ();
      my $netname = "";

      # Go through each attribute
      for (my $attr_idx = 0; $attr_idx < @{$files[$file_idx]->{objects}->[$object_idx]->{Attributes}}; $attr_idx++) {

        # next if there is no name or no value
        next if (!($files[$file_idx]->{objects}->[$object_idx]->{Attributes}->[$attr_idx]->{name}));
        next if (!($files[$file_idx]->{objects}->[$object_idx]->{Attributes}->[$attr_idx]->{value}));
 
        my $name = $files[$file_idx]->{objects}->[$object_idx]->{Attributes}->[$attr_idx]->{name};
        my $value = $files[$file_idx]->{objects}->[$object_idx]->{Attributes}->[$attr_idx]->{value};

        writeMsg(4, "Processing attribute $attr_idx $name\=$value ...\n");

        given ($name) {

          when ( "netname" ) {
            if ($netname ne "") {
              writeMsg(0, "WARNING: Found net $netname with multiple netname attributes.\n");
              if ($netname ne $value) {
                writeMsg(0, "WARNING: Found different netname attributes on same net! Using $value.\n");
              }
            }
            $netname = $value;
            push(@netname_attr_idxs, $attr_idx);
          }

          when ( "xref" ) {
            push(@xref_attr_idxs, $attr_idx);
          }

          # Ignores other attributes

        } # end given ( $name )
      } # end foreach my $attr_idx

      # Check if there is at least one netname attribute if there are any xref ones
      if (!@netname_attr_idxs && @xref_attr_idxs) {
        writeMsg(0, "NOTE: file $fileName : xref attribute(s) found on a net with no netname attribute at (x,y) = ");
        foreach my $idx (@xref_attr_idxs) {
          writeMsg(0, "(".$files[$file_idx]->{objects}->[$object_idx]->{Attributes}->[$idx]->{x}.",");
          writeMsg(0, $files[$file_idx]->{objects}->[$object_idx]->{Attributes}->[$idx]->{y}.") ");
        }
        writeMsg(0, "\n");
      }

      # Add references to netname and xref attributes in the %idx_by_netname hash
      foreach my $idx (@netname_attr_idxs) {
        push(@{$idx_by_netname{$netname}}, { (
          file_idx => $file_idx,
          object_idx => $object_idx,
          netname_attr_idx => $idx,
          xref_attr_idxs => [],
        ) } );
        foreach my $xref_attr_idx (@xref_attr_idxs) {
          push(@{$idx_by_netname{$netname}->[@{$idx_by_netname{$netname}}-1]->{xref_attr_idxs}}, $xref_attr_idx);
        }
        # sheets are 1 based, file_idx are 0 based
        push(@{$sheets_by_netname{$netname}}, $file_idx + 1);
      }

    } # end foreach my $object_idx
  } # end foreach my $file_idx

  if (0) {
    writeMsg("Hashes have been built ...\n");
    $Data::Dumper::Purity = 1;
    my $result = Data::Dumper->new( [ \%idx_by_netname  ], ["idx_by_netname"]);
    writeMsg(1, $result->Dump);
  }

  # Now that the hashes have been built
  # we can modify (or add) the xref attributes

  writeMsg(1, "Processing found netnames ...\n");

  # Go through each netname
  foreach my $netname (keys %idx_by_netname) {

    writeMsg(2, "Processing net named $netname ...\n");

    # no xref on nets that appear only once
    next if (@{$idx_by_netname{$netname}} < 2); 

    # Go through each occurence of such netname
    for (my $occurence = 0; $occurence < @{$idx_by_netname{$netname}}; $occurence++) {

      my $file_idx =   $idx_by_netname{$netname}->[$occurence]->{file_idx};
      my $object_idx = $idx_by_netname{$netname}->[$occurence]->{object_idx};

      # check if any xref attribute already exists
      if (!@{$idx_by_netname{$netname}->[$occurence]->{xref_attr_idxs}}) {

        # If none exists, we need to create one
        # Note that this will create one for each occurence of the netname attribute
        # and there could be multiple ones on the same net!

        # To do so we copy the netname attribute
        my $netname_attr_idx_2_copy = $idx_by_netname{$netname}->[$occurence]->{netname_attr_idx};
        my $new_attr_idx = @{$files[$file_idx]->{objects}->[$object_idx]->{Attributes}};
        my %netname_attr_2_copy = %{ dclone(\%{$files[$file_idx]->{objects}->[$object_idx]->{Attributes}->[$netname_attr_idx_2_copy]}) };

        # Channge the attribute name and value
        # The value will be fixed later
        $netname_attr_2_copy{name} = "xref";
        $netname_attr_2_copy{value} = "NEW_FIXME";

        # Change the text alignemnt such that the text will be aligned
        # the opposite way compared to the netname one (unless it is centered...)
        $netname_attr_2_copy{alignment} =~ tr/012345678/678345012/;

        $files[$file_idx]->{objects}->[$object_idx]->{Attributes}->[$new_attr_idx] = { %netname_attr_2_copy };
        writeMsg(3, "We just created a new xref attribute for net $object_idx named $netname on sheet ".($file_idx+1)."\n");

        # We can now add its references to the hash so it will be parsed and fixed below
        push(@{$idx_by_netname{$netname}->[$occurence]->{xref_attr_idxs}}, $new_attr_idx);
      }

      # Go through each occurence of xref attribute and update its value
      foreach my $attr_idx (@{$idx_by_netname{$netname}->[$occurence]->{xref_attr_idxs}}) {

	my $sheets = join(",", sort(@{$sheets_by_netname{$netname}}));

        writeMsg(3, "Packing sheet references from $sheets to ");
        
        # remove first occurence of own sheet
        # if net of same name appears a secont time elsewhere on same sheet it
        # should still appear
        my $thisSheet = $idx_by_netname{$netname}->[$occurence]->{file_idx} + 1;
        $sheets =~ s/^$thisSheet$//;
        $sheets =~ s/^$thisSheet,//;
        $sheets =~ s/,$thisSheet$//;
        $sheets =~ s/,$thisSheet,/,/;

        # pack consecutive pages
        $sheets =~ m/^/;
        foreach my $sheet (split(/,/, $sheets)) {
          my $p = $sheet-1;
          my $pp = $p-1;
          $sheets =~ s/^$pp,$p,$sheet$/$pp\-$sheet/;
          $sheets =~ s/^$pp,$p,$sheet,/$pp\-$sheet,/;
          $sheets =~ s/,$pp,$p,$sheet$/,$pp\-$sheet/;
          $sheets =~ s/,$pp,$p,$sheet,/,$pp\-$sheet,/;
          $sheets =~ s/-$p,$sheet$/-$sheet/;
          $sheets =~ s/-$p,$sheet,/-$sheet,/;
        }

        writeMsg(3, "$sheets for a net $netname on sheet $thisSheet\n");

        writeMsg(3, "Modifying xref attribute for net $netname from ".$files[$file_idx]->{objects}->[$object_idx]->{Attributes}->[$attr_idx]->{value});

        $files[$file_idx]->{objects}->[$object_idx]->{Attributes}->[$attr_idx]->{value} = $sheets;
        writeMsg(3, " to ".$files[$file_idx]->{objects}->[$object_idx]->{Attributes}->[$attr_idx]->{value}."\n");

        # adjust xref attribute visibility
        $files[$file_idx]->{objects}->[$object_idx]->{Attributes}->[$attr_idx]->{visibility} = ($sheets eq "") ? 0 : 1;

        # adjust xref text origin
        $files[$file_idx]->{objects}->[$object_idx]->{Attributes}->[$attr_idx]->{alignment} =~ tr/012345678/111444777/;

      } # end foreach my $xref_attr_idx
    } # end foreach my $occurence
  } # end foreach my $netname

  if (0) {
    $Data::Dumper::Purity = 1;
    my $result = Data::Dumper->new( [ \@files  ], ["files"]);
    writeMsg(1, $result->Dump);
  }
 
} # update_xref
