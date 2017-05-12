#
# PDF::Parse.pm, version 1.11 February 2000 antro
#
# Copyright (c) 1998 - 2000 Antonio Rosella Italy antro@tiscalinet.it, Johannes Blach dw235@yahoo.com 
#
# Free usage under the same Perl Licence condition.
#

package PDF::Parse;

$PDF::Parse::VERSION = "1.11";

=pod

=head1 NAME

PDF::Parse - Library with parsing functions for PDF library

=head1 SYNOPSIS

  use PDF::Parse;

  $pdf->TargetFile($filename);
  $pdf->LoadPageInfo;

  $version = $pdf->Version;
  $bool = $pdf->IsaPDF;
  $bool = $pdf->IscryptPDF;

  $info = $pdf->GetInfo ($key);
  $pagenum = $pdf->Pages;

  @size = $pdf->PageSize ($page);
  # or
  @size = $pdf->PageSize;

  $rotation = $pdf->PageRotation ($page);
  # or
  $rotation = $pdf->PageRotation;

=head1 DESCRIPTION

The main purpose of the PDF::Parse library is to provide parsing functions
for the more general PDF library.

=head1 Methods

The available methods are:

=cut

require 5.005;
require PDF::Core;

use strict;
use Carp;
use Exporter ();

use vars qw(@ISA @EXPORT_OK);

@ISA = qw(Exporter PDF::Core);

@EXPORT_OK = qw( LoadPageInfo GetInfo TargetFile
				 Pages PageSize PageRotation IsaPDF
				 Version IscryptPDF );

#################################################################
sub ReadCrossReference_pass1 {
  my $fd = shift;
  my $offset=shift;
  my $self=shift;

  my $initial_number;
  my $obj_counter=0;
  my $global_obj_counter=0;
  my $buf;

  binmode $fd;

  $_=PDF::Core::PDFGetline ($fd,\$offset);

  die "Can't read cross-reference section, according to trailer\n" if ! /xref\r?\n?/  ;

  while () {
    $_=PDF::Core::PDFGetline ($fd,\$offset);
    s/^\n//;
    s/^\r//;
    last if (m/\btrailer\b/) ;
#
# An Object
#
    /^\d+\s+\d+\s+n\r?\n?/ && do { my $buf =$_;
	       my $ind = $initial_number + ($obj_counter++);
               ( not defined $self->{Objects}[$ind] )&& 
		  do { $self->{Objects}[$ind] = int substr($buf,0,10);
		       $self->{Gen_Num}[$ind] = int substr($buf,11,5);
		     };
	       $_=$buf;
	       s/^.{18}//; 
	       next ;
   }; 
#
# A Freed Object
#
    /^\d+\s+\d+\s+f\r?\n?/ && do { my $buf =$_;
   	       my $objects_generation_nr = substr($buf,11,5);
	       my $Num=substr($buf,0,10);
	       my $ind = $initial_number + ($obj_counter++);
	       # $ind = $ind . "_" . $objects_generation_nr;
		       $self->{Objects}[$ind] = - $Num;
		       $self->{Gen_Num}[$ind] = $objects_generation_nr;
		       $_=$buf;
		       s/^.{18}//; 
		       next ;
     };
#
# A subsection
#
    /^\d+\s+\d+\r?\n?/  && do { 
 	my $buf = $_ ; 
 	 $initial_number = $buf; 
 	 $initial_number=~ s/^(\d+)\s+\d+\r?\n?.*/$1/; 
	 $global_obj_counter += $obj_counter;
 	 $obj_counter=0; 
	 next ;
    };
  }

  $global_obj_counter +=$obj_counter;
#
# Now the trailer for updates 
#

#
# Skip to start of dictionary.
#
    until (m/<</)
		{
		$_=PDF::Core::PDFGetline ($fd,\$offset);
		}

#
# Read the dictionary
#
    my %trailer = ( PDF::Core::PDFGetPrimitive ($fd, $offset) );

    if ($self->{"Trailer"}{"/Root"} eq "")
		{
		$self->{"Trailer"} = \%trailer;
		#
		# This code is here for backward compatibility only. If the content
		# of the root trailer is needed, use $self->{"Trailer"} instead.
		#
		$self->{"Cross_Reference_Size"} = $trailer{"/Size"};
		$self->{"Root_Object"} = $trailer{"/Root"};
		$self->{"Crypt_Object"} = $trailer{"/Encrypt"};
		}
	if ($trailer{"/Prev"} =~ m/^\d+$/)
		{  
  		$self->{"Updated"} = 1;
		my $old_seek = tell $fd;
		$global_obj_counter += ReadCrossReference_pass1 ($fd,
            $trailer{"/Prev"}, $self );
		seek $fd, $old_seek, 0;
		}


  return $global_obj_counter;
}

#################################################################
sub LoadPageSubtree (\*$;%)
	{
	my $self = shift;
	my $ref = shift;
	my %inheritance = @_ ;

	my $data = $self->GetObject ($ref);

	# Check which attributes are inherited. Adobe did not add any new
	# inherited attributes in version 1.2 or later, so this list is
	# complete.

	# Do simple values.
	foreach my $key ("/Rotate", "/Dur", "/Hid", "/Trans", 
					 "/MediaBox", "/CropBox")
		{
		if (defined ($data->{$key}))
			{
			# Check if it is an indirect reference
			if ($data->{$key} =~ m/^\d+ \d+ R$/)
				{
				my $dataref = $data->{$key};
				do
					{
					$dataref = $self->GetObject ($dataref);
					}
				while ($dataref =~ m/^\d+ \d+ R$/);

				if (UNIVERSAL::isa ($data, "ARRAY"))
					{
					$inheritance{$key} = [];
					foreach my $i (@{$data})
						{
						# Each element may be a reference.
						while ($i =~ m/^\d+ \d+ R$/)
							{
							$i = $self->GetObject ($i);
							}

						push @{$inheritance{$key}}, $i;
						}
					}
				else
					{
					$inheritance{$key} = $dataref;
					}
				}
			else
				{
				$inheritance{$key} = $data->{$key};
				}
			}
		}

	# If this objects contains ressources, replace information in inheritance
	$inheritance{"Resource_Object"} = $data->{"/Resources"}
	    if (defined ($data->{"/Resources"}));

	if ($data->{"/Type"} eq "/Pages")
		{
		# It's just an intermediate Node
		foreach my $kid (@{$data->{"/Kids"}})
			{
			$self->LoadPageSubtree ($kid, %inheritance);
			}
		}
	elsif ($data->{"/Type"} eq "/Page")
		{
		# We have a real page!
		$inheritance{"Page_Object"} = $ref;
		push @{$self->{"Page"}}, +{ %inheritance };
		}
	else
		{
		# Strange stuff. Complain and discard.
		carp "While loading pages got object of type '", $data->{"/Type"}, "'";
		}
	}

#################################################################
=pod

=head2 TargetFile ( filename )

This method links the filename to the pdf descriptor and parses all
kind of header information.

=cut

sub TargetFile {
  my $self = shift;
  my $file = shift;

  croak "Already linked to the file ",$self->{File_Name},"\n" 
      if $self->{File_Name} ;
  
  my $offset;

  if ( $file ) {
    open(FILE, "< $file") or croak "can't open $file: $!";
    binmode FILE;
    $self->{File_Name} = $file ;
    $self->{File_Handler} = \*FILE;
    my $buf;
    read(FILE,$buf,4);
    if ( $buf ne "%PDF" ) {
     print "File $_[0] is not PDF compliant !\n" if $PDF::Verbose ;
     return 0 ;
    }
    read(FILE,$buf,4);
    $buf =~ s/-//;
    $self->{Header}= $buf;
    seek FILE,-50,2;
    read( FILE, $offset, 50 );
    $offset =~ s/[^s]*startxref\r?\n?(\d*)\r?\n?%%EOF\r?\n?/$1/;

	$self->{"Last_XRef_Offset"} = $offset;
    ReadCrossReference_pass1 (\*FILE, $offset, $self);
	$self->{"Info"} = $self->GetObject ($self->{"Trailer"}{"/Info"});
	$self->{"Catalog"} = $self->GetObject ($self->{"Trailer"}{"/Root"});
	$self->{"PageTree"} = $self->GetObject ($self->{"Catalog"}{"/Pages"});
    return 1;
  } else {
    croak "I need a file name (!)";
	}
}

#################################################################
=pod

=head2 LoadPageInfo

This function loads the information for all pages. This process can
take some time for big PDF-files.

=cut

sub LoadPageInfo (\*)
	{
	my $self = shift;

	# Reset Page Array
	$#{$self->{"Page"}} = -1;

	# Recurse
	$self->LoadPageSubtree ($self->{"Catalog"}{"/Pages"});
	}								



#################################################################
=pod

=head2 Version

Returns the PDF version used for writing the object file.

=cut

sub Version { 
  return ($_[0]->{Header}); 
}

#################################################################
=pod

=head2 IsaPDF

Returns true, if the file could be parsed and is a PDF-file.

=cut

sub IsaPDF { 
  return ($_[0]->{Header} != undef) ; 
}

#################################################################
=pod

=head2 IscryptPDF

Returns true if the PDF contains a crypt object. This indicates that
the data of the PDF-File is encrypted. In this case, not all function
work as expected.

=cut

sub IscryptPDF { 
  return ($_[0]->{Crypt_Object} != undef) ; 
}

#################################################################
=pod

=head2 GetInfo ( key )

Returns the various information contained in the info section of a PDF
file (if present). A PDF file can have:

  a title ==> GetInfo ("Title")
  a subject ==> GetInfo ("Subject")
  an author ==> GetInfo("Author")
  a creation date ==> GetInfo("CreationDate")
  a creator ==> GetInfo("Creator")
  a producer ==> GetInfo("Producer")
  a modification date ==> GetInfo("ModDate")
  some keywords ==> GetInfo("Keywords")

=cut

sub GetInfo (\*$)
	{
	my $self = shift;
	my $type = shift;

	return PDF::Core::UnQuoteString ($self->{"Info"}{"/" . $type})
	}

#################################################################
=pod

=head2 Pages

Returns the number of pages of the PDF-file.

=cut

sub Pages 
	{
	my $self = shift;

	return $self->{"PageTree"}{"/Count"};
	}

#################################################################
=pod

=head2 PageSize ( [ page ] )

Returns the size of a page in the PDF-file. If no parameter is given,
the default size of the root page will be returned. This value may be
overridden for any page.

If the size of an individual page is requested and the page data is
not already loaded, the method B<LoadPageInfo> will be executed. This
may take some time for large PDF-files. The size of the root page is
always available and will never execute B<LoadPageInfo>.

=cut

sub PageSize (;$)
	{
	my $self = shift;
	my $page = shift;

	if ($page > 0)
		{
		return undef if ($page > $self->{"PageTree"}{"/Count"});
		$self->LoadPageInfo unless ($#{$self->{"Page"}} >= 0);
		
		return @{$self->{"Page"}[$page - 1]{"/MediaBox"}}
		if (defined $self->{"Page"}[$page - 1]{"/MediaBox"});
		}
	else
		{
		return @{$self->{"PageTree"}{"/MediaBox"}}
		if (defined $self->{"PageTree"}{"/MediaBox"});
		}

	return undef;
	}

#################################################################
=pod

=head2 PageRotation ( [ page ] )

Returns the rotation of a page in the PDF-file. If no parameter is given,
the default rotation of the root page will be returned. This value may be
overridden for any page.

If the rotation of an individual page is requested and the page data is
not already loaded, the method B<LoadPageInfo> will be executed. This
may take some time for large PDF-files. The rotation of the root page is
always available and will never execute B<LoadPageInfo>.

=cut
sub PageRotation (;$)
	{
	my $self = shift;
	my $page = shift;

	my $rotate = 0;

	if ($page > 0)
		{
		return undef if ($page > $self->{"PageTree"}{"/Count"});
		$self->LoadPageInfo unless ($#{$self->{"Page"}} >= 0);
		
		$rotate = $self->{"Page"}[$page - 1]{"/Rotate"};
		}
	else
		{
		$rotate = $self->{"PageTree"}{"/Rotate"};
		}

	print "Rotation ", 0 + $rotate if ($PDF::Verbose);

	return 0 + $rotate;
	}
#################################################################
1;
__END__

=head1 Variables

The only available variable is :

=over

=item B<$PDF::Parse::VERSION>

Contains the version of the library installed

=back


=head1 Copyright

  Copyright (c) 1998 - 2000 Antonio Rosella Italy antro@tiscalinet.it, Johannes Blach dw235@yahoo.com 

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 Availability

The latest version of this library is likely to be available from:

http://www.geocities.com/CapeCanaveral/Hangar/4794/

=cut

