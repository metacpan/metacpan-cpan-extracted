package PsionToGnomecard;

#      psiontognomecard: Converts Psion vcard format from Epoc
#      Contacts application to GnomeCard vcard format
#      Copyright (C) 2001 Ramin Nakisa

#      This program is free software; you can redistribute it and/or modify
#      it under the terms of the GNU General Public License as published by
#      the Free Software Foundation; either version 2 of the License, or
#      (at your option) any later version.

#      This program is distributed in the hope that it will be useful,
#      but WITHOUT ANY WARRANTY; without even the implied warranty of
#      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#      GNU General Public License for more details.

#      You should have received a copy of the GNU General Public License
#      along with this program; if not, write to the Free Software
#      Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

require 5.005_62;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use PsionToGnomecard ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	convert
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.01';


# Preloaded methods go here.

sub convert {
  my $inputFile = shift;
  my $outputFile = shift;

  open( INPUT, $inputFile )
    or die( "Couldn't read exported Psion contacts file $inputFile." );
  open( OUTPUT, ">$outputFile" )
    or die( "Couldn't write gnomecard file $outputFile." );

  my $id = 0;
  my $NotesStarted = 0;
  my $fieldname;
  my $fieldvalue;
  my @fieldnames;
  my @fieldvalues;
  my %data;

  while ( <INPUT> ) {
    s/\cM//g;
    if (/^N;/)			# Name
      {
	chomp;
	s/^N;//;
	@_ = split(/\:/);
	$_[0] =~ s/X-EPOCCNTMODELLABEL\d+\=//g;
	@fieldnames = split( /\;/, $_[0] );
	@fieldvalues = split( /\;/, $_[1] );
	for ( my $i = 0; $i <= $#fieldnames; $i++ ) {
	  $data{$id,$fieldnames[$i]} = $fieldvalues[$i];
	}
      }

    if (/^ADR;/) {
      chomp;
      s/^ADR;(WORK|HOME);//;
      @_ = split(/\:/);
      $_[0] =~ s/X-EPOCCNTMODELLABEL\d+\=//g;
      $_[1] =~ s/=0D=0A/, /g;	# translate CR symbol
      @fieldnames = split( /\;/, $_[0] );
      @fieldvalues = split( /\;/, $_[1] );
      for ( my $i = 0; $i <= $#fieldnames; $i++ ) {
	$data{$id,$fieldnames[$i]} = $fieldvalues[$i];
      }
    }

    if (/^EMAIL;INTERNET;/) {
      chomp;
      s/^EMAIL;INTERNET;(WORK|HOME);//;
      @_ = split(/\:/);
      $_[0] =~ s/X-EPOCCNTMODELFIELDLABEL\=//g;
      $fieldname = $_[0];
      $fieldvalue = $_[1];
      $data{$id,$fieldname} = $fieldvalue;
    }

    if (/^TEL;/) {
      chomp;
      s/^TEL;(WORK|HOME);(CELL|FAX){0,1};{0,1}//;
      @_ = split(/\:/);
      $_[0] =~ s/X-EPOCCNTMODELFIELDLABEL\=//g;
      $fieldname = $_[0];
      $fieldvalue = $_[1];
      $data{$id,$fieldname} = $fieldvalue;
    }

    if (/^ORG;/) {
      chomp;
      s/^ORG;//;
      @_ = split(/\:/);
      $_[0] =~ s/X-EPOCCNTMODELFIELDLABEL\=//g;
      $fieldname = $_[0];
      ( $fieldvalue = join("",@_[1..$#_]) ) =~ s/;//;
      $data{$id,$fieldname} = $fieldvalue;
    }

    if (/^URL;/) {
      chomp;
      s/^URL;//;
      @_ = split(/\:/);
      $_[0] =~ s/X-EPOCCNTMODELFIELDLABEL\=//g;
      $fieldname = $_[0];
      ( $fieldvalue = join("",@_[1..$#_]) ) =~ s/;//;
      $data{$id,$fieldname} = $fieldvalue;
    }

    if ( /^NOTE;/ ) {
      $NotesStarted = 1;
      s/^NOTE;//;
      @_ = split(/\:/);
      $_[0] =~ s/X-EPOCCNTMODELFIELDLABEL\=//g;
      ( $fieldname = $_[0] ) =~ s/;ENCODING=QUOTED-PRINTABLE//;
      $fieldvalue = $_[1];
    }
    if ( $NotesStarted ) {
      my $l = $_;
      $l =~ s/X-EPOCCNTMODELFIELDLABEL=Notes(;ENCODING=QUOTED-PRINTABLE){0,1}://;
      $data{$id,$fieldname} .= $l;
      $data{$id,$fieldname} =~ s/=0D=0A/=0A/g; # translate CR symbol
      if ( $_ !~ /=$/ ) {
	$NotesStarted = 0;
      }
    }


    if ( /END:VCARD/ ) {
      print OUTPUT "BEGIN:VCARD\n";

      # First field is FN, which is the record name

      # Not a person (no first or last name), so must be a company
      if ( ! defined( $data{$id,"First name"} ) &&
	   ! defined( $data{$id,"Last name"} ) ) {
	print OUTPUT "FN:";
	print OUTPUT $data{$id,"Company"};
	print OUTPUT "\n";
      } else {
	print OUTPUT "FN:";
	if ( defined( $data{$id,"First name"} ) ) {
	  print OUTPUT $data{$id,"First name"};
	  if ( defined( $data{$id,"Middle name"} ) ||
	       defined( $data{$id,"Last name"} ) ) {
	    print OUTPUT " ";
	  }
	}
	if ( defined( $data{$id,"Middle name"} ) ) {
	  print OUTPUT $data{$id,"Middle name"};
	  if ( defined( $data{$id,"Last name"} ) ) {
	    print OUTPUT " ";
	  }
	}
	if ( defined( $data{$id,"Last name"} ) ) {
	  print OUTPUT $data{$id,"Last name"};
	}
	print OUTPUT "\n";
      }

      # N

      if ( defined( $data{$id,"Last name"} ) ||
	   defined( $data{$id,"Middle name"} ) ||
	   defined( $data{$id,"First name"} ) ) {
	print OUTPUT "N:";

	if ( defined( $data{$id,"Last name"} ) ) {
	  print OUTPUT $data{$id,"Last name"};
	}
	print OUTPUT ";";
	if ( defined( $data{$id,"First name"} ) ) {
	  print OUTPUT $data{$id,"First name"};
	}
	print OUTPUT ";";
	if ( defined( $data{$id,"Middle name"} ) ) {
	  print OUTPUT $data{$id,"Middle name"};
	}
	print OUTPUT ";";
	if ( defined( $data{$id,"Suffix"} ) ) {
	  print OUTPUT $data{$id,"Title"};
	}
	print OUTPUT ";";
	if ( defined( $data{$id,"Suffix"} ) ) {
	  print OUTPUT $data{$id,"Suffix"};
	}
	print OUTPUT "\n";
      }

      # ADR (Work)

      if ( defined( $data{$id,"Work address"} ) ) {
	print OUTPUT "ADR;WORK:";
	if ( defined( $data{$id,"Work PO box"} ) ) {
	  print OUTPUT $data{$id,"Work PO box"};
	}
	print OUTPUT ";";
	if ( defined( $data{$id,"Work ext address"} ) ) {
	  print OUTPUT $data{$id,"Work ext address"};
	}
	print OUTPUT ";";
	if ( defined( $data{$id,"Work address"} ) ) {
	  print OUTPUT $data{$id,"Work address"};
	}
	print OUTPUT ";";
	if ( defined( $data{$id,"Work city"} ) ) {
	  print OUTPUT $data{$id,"Work city"};
	}
	print OUTPUT ";";
	if ( defined( $data{$id,"Work region"} ) ) {
	  print OUTPUT $data{$id,"Work region"};
	}
	print OUTPUT ";";
	if ( defined( $data{$id,"Work p'code"} ) ) {
	  print OUTPUT $data{$id,"Work p'code"};
	}
	print OUTPUT ";";
	if ( defined( $data{$id,"Work country"} ) ) {
	  print OUTPUT $data{$id,"Work country"};
	}
	print OUTPUT "\n";
      }

      # ADR (Home)

      if ( defined( $data{$id,"Home address"} ) ) {
	print OUTPUT "ADR;HOME:";
	if ( defined( $data{$id,"Home PO box"} ) ) {
	  print OUTPUT $data{$id,"Home PO box"};
	}
	print OUTPUT ";";
	if ( defined( $data{$id,"Home ext address"} ) ) {
	  print OUTPUT $data{$id,"Home ext address"};
	}
	print OUTPUT ";";
	if ( defined( $data{$id,"Home address"} ) ) {
	  print OUTPUT $data{$id,"Home address"};
	}
	print OUTPUT ";";
	if ( defined( $data{$id,"Home city"} ) ) {
	  print OUTPUT $data{$id,"Home city"};
	}
	print OUTPUT ";";
	if ( defined( $data{$id,"Home region"} ) ) {
	  print OUTPUT $data{$id,"Home region"};
	}
	print OUTPUT ";";
	if ( defined( $data{$id,"Home p'code"} ) ) {
	  print OUTPUT $data{$id,"Home p'code"};
	}
	print OUTPUT ";";
	if ( defined( $data{$id,"Home country"} ) ) {
	  print OUTPUT $data{$id,"Home country"};
	}
	print OUTPUT "\n";
      }

      # TEL

      if ( defined( $data{$id,"Work tel"} ) ||
	   defined( $data{$id,"Home tel"} ) ) {
	if ( defined( $data{$id,"Home tel"} ) ) {
	  print OUTPUT "TEL;HOME:", $data{$id,"Home tel"}, "\n";
	}
	if ( defined( $data{$id,"Work tel"} ) ) {
	  print OUTPUT "TEL;WORK:", $data{$id,"Work tel"}, "\n";
	}
	if ( defined( $data{$id,"Mobile"} ) ) {
	  print OUTPUT "TEL;CELL:", $data{$id,"Mobile"}, "\n";
	}
      }

      # EMAIL

      if ( defined( $data{$id,"Work email"} ) ||
	   defined( $data{$id,"Home email"} ) ) {
	if ( defined( $data{$id,"Work email"} ) ) {
	  print OUTPUT "EMAIL;INTERNET:", $data{$id,"Work email"}, "\n";
	}
	if ( defined( $data{$id,"Home email"} ) ) {
	  print OUTPUT "EMAIL;INTERNET:", $data{$id,"Home email"}, "\n";
	}
      }

      # URL

      if ( defined( $data{$id,"Web page"} ) ) {
	print OUTPUT "URL:", $data{$id,"Web page"}, "\n";
      }

      # NOTE

      if ( defined( $data{$id,"Notes"} ) ) {
	print OUTPUT "NOTE;QUOTED-PRINTABLE:", $data{$id,"Notes"};
      }

      print OUTPUT "END:VCARD\n\n";
      $id++;
    }
  }
  close( INPUT );
  close( OUTPUT );
}


# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

PsionToGnomecard - Perl extension for converting files exported from
the Psion Contacts application to vcard format suitable for Gnomecard.

=head1 SYNOPSIS

  use PsionToGnomecard;
  convert( "Contacts.vcf", "Contacts.txt" );

  use PsionToGnomecard 'convert';
  convert( "Contacts.vcf", "Contacts.txt" );

=head1 DESCRIPTION

This module converts a file exported from the Psion "Contacts"
application into standard vcard format, which can then be used
directly by the Gnome address book application GnomeCard.  It s known
to work with a Psion 5mx and version 1.2.0 of GnomeCard.  You must
first export the address file from Contacts on your Psion by starting
up Contacts, then select "File->More->Export contact" which will bring
up an "Export contact" dialog box.  In the "Contacts" pull-down menu,
select "All contacts in view" and remember the filename you chose and
directory you chose.  Then import the file to your windows machine
with the usual Psion connectivity software and then you can use this
module to perform the conversion.

=head1 AUTHOR

Ramin Charles Nakisa, raminnakisa@yahoo.com

=cut
