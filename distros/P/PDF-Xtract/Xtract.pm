# 1. Ensure all file names are quoted
# 2. Try keep bare minimum processing so that user programs will not get loaded with stuff they dont need!
# 3. Comment-out performance tester, it is only usefull during development/testing.

package PDF::Xtract;
use strict;
use vars qw($VERSION);
use File::Temp;
# use Time::HiRes qw(gettimeofday);

$VERSION = '0.08';

my ( $balance, $trailerObject, $RootObject, $EncryptedObject, $InfoObject, $TempExtractFile, $LastExtractFile, $CatalogPages);
my ( %vars, %objval, %parent, %Referals, %IncludeObjects, %kids, %page, %BabyCountOfObject, %BabiesOfObject );

my $CRLF = '[ \t\r\n\f\0]'."*(?:\015|\012|(?:\015\012))";
# ---------------------------------------------------
=head1 NAME

PDF::Xtract - Extracting sub PDF documents from a multi page PDF document, much faster than PDF::Extract!

=head1 SYNOPSIS

	Please read Manual-PDF-Xtract.pdf in the distribution for detailed documentation.
	
	use PDF::Xtract;
	$pdf=new PDF::Xtract;
	@pages=(10..30,5,7); # Defining pages to be extracted ( 10 to 30, 5 and 7 - in the order required for output).
	$pages=\@pages;
	$pdf->savePDFExtract( PDFDoc=>"c:/Docs/my.pdf", PDFSaveAs="out.pdf", PDFPages=>$pages ); # Saves extracted pages to "out.pdf"

	print "Content-Type text/plain\n\n<xmp>",  $pdf->getPDFExtract; # May be useful for a web-site!
 
OR

	# Extract and save, in the current directory, all the pages in a PDF document with nice names.
	use PDF::Xtract;
	$pdf=new PDF::Xtract( PDFDoc=>"test.pdf" );
	@tmp=$pdf->getPDFExtractVariables(PDFPageCountIn);
	$PageCount=${$tmp[0]};
	print STDERR "Total Pages = $PageCount\n";
	$tmp=length($PageCount);
	for ( $CurPage=1; $CurPage <= $PageCount; $CurPage++ ) {
		@CurPage=($CurPage); $CurRef=\@CurPage;
		$index=sprintf("%0${tmp}d",$CurPage);
		$pdf->savePDFExtract( PDFPages=>$CurRef,PDFSaveAs=>"$index.pdf" );
	}

=head1 DESCRIPTION

PDF Xtract module is derived from Noel Sharrok's PDF::Extract module, but a MUCH faster one. It is a group
of methods that allow the user to extract required pages as a new PDF document from a pre-existing PDF document.

PDF::Xtract is published as a separate module, because of some significant differences with PDF::Extract in variables
and functions implemented. While the code, for most part is a shameless copy of PDF::Extract, there are certain
changes in the logic that allow this module to be much much faster with large PDF files.

Notable differences between Xtract and Extract are also highlighted in this document

With PDF::Xtract one can:-

=over 4

=item *
Associate a PDF document to a PDF::Xtract object.

=item *
Get total number of pages in PDF document.

=item *
Extract required pages from a PDF document , as a new PDF document, in any specified page number order.

=item *
Specify name of file to save extracted PDF document.

=back

=cut
# ----------------------------- The Public Methods --------------------------------

# We can put the following 2 lines around a block to see the time taken to execute that.
# my $start=&lt;
# print STDERR "Timer says : ThisBloc: ",&lt-$start,"\n";

sub new {
	my $this = shift;
	my $class = ref($this) || $this;
	my $self = {};
	bless $self, $class;
	# Have a temperory file for storing output...
	(undef,$TempExtractFile)=File::Temp->tempfile("xtract.tmp.XXXX");
	$vars{PDFErrorLevel}=3;
	$self->setEnv(@_);
	return $self;
}

sub getPDFExtract{				
	local undef $/;
	&setEnv(@_);
	unless ( -f "$LastExtractFile" ) {&error(3,"No extract available at this time"); return 0}
	open ( tmp,"$LastExtractFile" ) or return undef; binmode tmp;
	return <tmp>;
}

sub savePDFExtract{
	# Work expected by this is already done! (if possible); so just move the $TempExtractFile to $vars{PDFSaveAs}
	&setEnv(@_);

	if ( $vars{PDFSaveAs} eq $vars{PDFDoc} ) {
		&error(3,"Attempt to clobber input file @ savePDFExtract!!");
		return 0;
	}

	print STDERR "Info: Please read docs! Xtract autosaves pages to known PDFSaveAS\n" if ( $vars{PDFVerbose} );

	if ( ! $vars{PDFSaveAs} ) {
		&error(3,"No file name specified via PDFSaveAs, so savePDFExtract cant do anything!"); }
	elsif ( "$vars{PDFSaveAs}" eq "$LastExtractFile" ) {
		&error(1,"Redundant operation! Extract already there in $vars{PDFSaveAs}"); return 1;
   	}
	elsif ( -f "$LastExtractFile" ) {
		rename "$LastExtractFile","$vars{PDFSaveAs}";
		$LastExtractFile="$vars{PDFSaveAs}";
		return 1; }
	else {
		&error(3,"No extract available at this time!");}
}

sub getPDFExtractVariables {
	my @var; my $i;
	shift;
	foreach my $key (@_) {
		$var[$i++]=$vars{$key};
	}
	@var;
}

sub getVars { &getPDFExtractVariables(@_); }

sub setPDFExtractVariables {
	my @var;
	&setEnv( @_ );
	shift;
	my %var=@_;
	&getVars( undef, keys %var);
}

sub setVars { &setPDFExtractVariables(@_); }

# ----------------------------- The Private Functions --------------------------------

sub setEnv {
	my (undef,%PDF)=@_;

	if ($PDF{"PDFDebug"} || $vars{PDFDebug} ) {
		$vars{PDFDebug}=$PDF{PDFDebug};
		print STDERR "These variables are to be set\n";
		foreach my $key (keys %PDF) { print STDERR "\t$key=\"$PDF{$key}\"\n"; }
	}

	if ( $PDF{PDFReadSize} ) { $vars{PDFReadSize}=$PDF{PDFReadSize} }
	if ( $PDF{PDFWriteSize} ) { $vars{PDFWriteSize}=$PDF{PDFWriteSize} }
	if ( $PDF{RetainPDFComments} ) { $vars{RetainPDFComments}=$PDF{RetainPDFComments} }
	if ( $PDF{PDFVerbose} ) { $vars{PDFVerbose}=$PDF{PDFVerbose} }; # Put errors to STDERR too
	if ( $PDF{PDFErrorLevel} ) { $vars{PDFErrorLevel}=$PDF{PDFErrorLevel} }; # Errors of higher gravity are
																			 # reported
	if ( $PDF{PDFErrorSize} ) {
		$vars{PDFErrorSize}=$PDF{PDFErrorSize};
		if ( $vars{PDFError} ) { splice @{$vars{PDFError}},0,-$vars{PDFErrorSize} }
	}; # Size of array holding errors

	if ( $PDF{PDFClean} ) { $vars{PDFClean}=$PDF{PDFClean} }; # Generate output only of there is no error

	if ($PDF{PDFDoc} ) {
		# SS: Major changes here!
		# File read mode changed to slurp, understanding the document etc are here.
		# Initialisations:
		$vars{PDFPageCountIn}=$vars{PDFPageCountOut}=$vars{PDFPageCountErr}=undef;
		$vars{PDFPagesFound}=$vars{PDFPagesNotFound}={};

		unless ( -f "$PDF{PDFDoc}" ) { &error(3,"PDF document \"$PDF{PDFDoc}\" not found",__FILE__,__LINE__); }
		my $tmp=join(undef,stat("$PDF{PDFDoc}"));
		if ( $vars{PDFDocStat} eq $tmp ) { # SS: Y should you bother if the file is same!
			print STDERR "PDFXtract: You are re-setting object to same PDF Document! I am ignoring it.\n" if ( $vars{PDFVerbose}>0 );
		} else {
			# A new document is being processed.
			$vars{PDFDocStat}=$tmp;
			if ( ! open FILE, "$PDF{PDFDoc}" ) {
				&error(3,"Can't open PDF document  \"$PDF{PDFDoc}\" to read\n",__FILE__,__LINE__);		
			} else {
				#----------------------------------
				my $CarryOver; my $ChunkCount;
				binmode FILE;
				while(read FILE,my $str,$vars{PDFReadSize}?$vars{PDFReadSize}:1024000) {
					$ChunkCount++; print STDERR "Reading chunk number $ChunkCount\r" if $vars{PDFVerbose};
					my @tmp; my $pieces=(@tmp=split(/endobj\s*$CRLF/,"$CarryOver$str",-1)); undef $CarryOver;
					my $count=0;
					foreach $tmp (@tmp) {
						$count++;
						if ( $count == $pieces ) {
							$CarryOver=$tmp; last;
						} else {
							if ( $tmp=~/^(.*?)(\d+)(\s+\d+\s+obj)$CRLF(.*)$/si ) {
								$balance.=$1; my $obj=$2; $objval{$obj}="$obj$3\015\012$4endobj\015\012\015\012";
								my $ref='(?:\s*\d+\s+\d+\s+R\s*)';
								my @allRefs=($objval{$obj}=~/\/(\S+?[\[\s]+${ref}+[\]\s]?)/gs);
								next unless @allRefs;
								foreach ( @allRefs ) {
									if 		( /^kids/is ) 	{ push (@{$kids{$obj}},&findRefs($_)); }
									elsif 	( /^parent/is ) { $parent{$obj}=(&findRefs($_))[0] }
									else 	{ push (@{$Referals{$obj}},&findRefs($_)); }
								}
							} else { $balance.=$tmp; }					
						}
					}
				} $balance.=$CarryOver; print STDERR "\n" if $vars{PDFVerbose};
				#----------------------------------
				$vars{"PDFDoc"}=$PDF{"PDFDoc"};
				# SS: Understand the document .....
				#----------------------------------
				# getTrailer, Info etc.
				if ( $balance=~/(trailer\s*<<.*?>>\s*)/s ) {
						$trailerObject=$1;
						$trailerObject=~s/\/Size\s+\d+/\/Size __Size__/s;
						$trailerObject=~s/\/Prev.*?$CRLF//s;

						if ( $trailerObject=~/\/Root\s+(\d+)\s+0\s+R/s ) 	{ $RootObject=$1 }
						if ( $trailerObject=~/\/Encrypt\s+(\d+)\s+0\s+R/s ) 	{ $EncryptedObject=$1 }
						if ( $trailerObject=~/\/Info\s+(\d+)\s+0\s+R/s ) 	{ $InfoObject=$1 }
				}	
				if ( $objval{$RootObject}=~/\/Pages\s+(\d+)\s+0\s+R/s ) 	{ $CatalogPages=$1 }

				&getPages($CatalogPages);
			}
		}
	}

	if ( exists $PDF{PDFSaveAs} ) {   # we also want to be able to set PDFSaveAs to nothing ("")	
		$vars{"PDFSaveAs"}=$PDF{"PDFSaveAs"};
	}

	if ( $PDF{PDFPages} ) {

		$vars{PDFPageCountOut}=$vars{PDFPageCountErr}=undef;
		$vars{PDFPagesFound}=$vars{PDFPagesNotFound}={};

		# SS: Major change. We plan to accept only array as an input (well, a reference to an array!)
		my $tmp=ref($PDF{PDFPages}); $tmp=$tmp?$tmp:"Not even a reference!"; 
		unless ( $tmp eq "ARRAY" ) {
			&error(3,"Value of PDFPages has to be an array reference, now it is $tmp, No output possible.");
			return 1; }
		my @tmp=@{$PDF{PDFPages}};
		unless ( @tmp ) {
				&error(3,"Can't get PDF Pages. No page numbers were set with 'PDFPages' ",__FILE__,__LINE__);
		}
		@{$vars{PDFPages}}=@tmp;
		$vars{PDFPagesFound}=""; # $vars{PDFExtract}="";
		%IncludeObjects=(); # %IncludeObjects=undef;
		%BabyCountOfObject=();

		&getPDFDoc(@{$vars{PDFPages}});
		&makePDF;
	}

	if ( $PDF{"PDFDebug"} || $vars{PDFDebug} ) {
		print "These variables have been set\n";
		foreach my $key (keys %vars) { print "\t$key=\"$vars{$key}\"\n"; }

		delete($PDF{PDFDebug});
	}

	# A little buggy, but easier to read in other Xtract environment vars.
	# Allows populating any variables with name starting with "My" to the object's space.
	foreach ( keys %PDF ) { $vars{$_}=$PDF{$_} if ( /^My/ ) }; %PDF=();
}

#------------------------------------ support  Routines --------------------------------------------

sub error {
	# Populates an array of maximum size PDFErrorSize
	my %error_level=(0=>"Silly", 1=>"Info", 2=>"Warn", 3=>"Error");

	my ($error_level,$error)=@_;
	return 0 unless ( $error_level >= $vars{PDFErrorLevel} ); # Ignore those errors below set errorlevel
	if ( $vars{PDFError} && ( @{$vars{PDFError}} >= $vars{PDFErrorSize}) ) {
		shift @{$vars{PDFError}};
	}
	my $error_string="$error_level{$error_level}: $error";
	push ( @{$vars{PDFError}},"$error_string"); 
	print STDERR "$error_string\n" if ( $vars{PDFVerbose} );
	return 1;
}

#------------------------------------ PDF Page Routines --------------------------------------------

sub getPages {
	# Populates Page Number -> Page Object map (%page)
	my @tmp=(shift); my $pageno;
	while ( @tmp ) {
		my $obj=int(shift @tmp);
		if ( $kids{$obj} ) { unshift (@tmp,@{$kids{$obj}}); }
		else { $page{++$pageno}=$obj;
		}
	}
	$vars{PDFPageCountIn}=$pageno;
}

sub Includes{
	# Populates the hash %Includes with (object id)->(objectes refered by object id).
	my @getRefs=@_;
	foreach my $obj ( @getRefs ) {
		foreach my $refered (@{$Referals{$obj}}) {
			next if ( $IncludeObjects{$refered} );
			$IncludeObjects{$refered}++;
			&Includes($refered);
		}
	}
}

sub getPDFDoc {
	# Key function!!
	# For the given set of pages, generate the page tree for output.

	# Initialisations
	my @pickPages=@_;
	%BabiesOfObject=();
	$vars{PDFPagesFound}=$vars{PDFPageCountOut}=$vars{PDFPageCountErr}=0;
	$vars{PDFPagesFound}=$vars{PDFPagesNotFound}=();
	my $tmp; my $err=0;

	foreach my $pageno ( @pickPages ) {
		unless ( $page{$pageno} ) {	# if the page object is not in %page
			$err++;
			&error(2,"Page No. $pageno is not there in the given PDF file($vars{PDFDoc})");
			$vars{PDFPageCountErr}++; push(@{$vars{PDFPagesNotFound}},$pageno);
			next;
		}
		$tmp=$page{$pageno};
		$vars{PDFPageCountOut}++; push(@{$vars{PDFPagesFound}},$pageno);
		&Includes($tmp); # Will add refered objs. to %IncludeObjects
		while( $parent{$tmp} ) {	# Contruct/Adjust the object tree for this page
			# Array because, it is important to keep the kids order.
			unless ( grep { /^$tmp$/ } @{$BabiesOfObject{$parent{$tmp}}} ) {
				push (@{$BabiesOfObject{$parent{$tmp}}},$tmp);
				$IncludeObjects{$parent{$tmp}}++;
			} 
			$BabyCountOfObject{$parent{$tmp}}++;
			$tmp=$parent{$tmp};
		}
		$IncludeObjects{$page{$pageno}}++;
	}
	return $err;
}

sub makePDF {

	# Check attempts to clobber input file.
	if ( $vars{PDFSaveAs} eq $vars{PDFDoc} ) {
		&error(3,"Attempt to clobber input file - check PDFSaveAs!!");
		return 0;
	}

	if ( $vars{PDFClean} ) {
		if ( $vars{PDFPageCountErr}>0 ) {
			&error(3,"PDFClean: $vars{PDFPageCountErr} pages to be extracted were not found");
			close FILE; unlink $LastExtractFile; return undef;
		}
	}
	if ( $vars{PDFPageCountOut}<1 ) { # Clean-up and return if we haven't got any page!
		&error(3,"No pages could be extracted!");
		close FILE; unlink $LastExtractFile; return undef;
	}

	my $eol=sprintf "\n"; if ( length ($eol) <2 ) { $eol=" $eol" }

	# Decide the file to hold the extracted PDF Stream
	close FILE; # unlink "$LastExtractFile";  ####### 
	$LastExtractFile=$vars{PDFSaveAs}?$vars{PDFSaveAs}:$TempExtractFile;
	open(FILE,">$LastExtractFile") or die; binmode FILE;

 	my %XrefBlock=();
	$objval{$RootObject}="$RootObject 0 obj\n<<\n/Type /Catalog\n/Pages $CatalogPages 0 R\n>>\nendobj\n";
	$IncludeObjects{$RootObject}++; # print STDERR "Root ($RootObject) Added\n";
	$IncludeObjects{$InfoObject}++; # print STDERR "Info ($InfoObject) Added\n";

	(my $CurrentBalance=$balance)=~s/\%\%EOF.*//s;
	$CurrentBalance=~s/^(.*?)$CRLF(.*?)$CRLF//s;

	print FILE "$1\015\012$2\015\012";
	my $startXref=length("$1\015\015$2\015\012");

	if ( $vars{RetainPDFComments} ) {
		while ( $CurrentBalance=~/\s*(%.*?$CRLF.*?$CRLF)/gs ) {
			print FILE "$1";
			$startXref+=length($1);
		}
	}
	my $xref=undef;
	my $xref="xxxxxxxxxx 65535 f$eol";
	$vars{PDFObjCountOut}=undef;

	my %addobj; my %objsize; my $accumulation; $vars{PDFWriteSize}=$vars{PDFWriteSize}?$vars{PDFWriteSize}:1024000; 
	my $ExpectObjID=1;	# Next Object ID
	my $lastObjID=undef; my $counter=0; my $CurXrefBlock=0;
	$XrefBlock{0}[1]="0000000000 65535 f \015\012";
	foreach my $objid ( sort {$a<=>$b} keys %IncludeObjects ) {
		$lastObjID=$objid;
		$addobj{$objid}=$objval{$objid};my $babiesofobject=undef;
		foreach ( @{$BabiesOfObject{$objid}} ) { $babiesofobject.="$_ 0 R "; }
		if ( $babiesofobject ) {
			$addobj{$objid}=~s/\/Kids\s+.*?\]/\/Kids \[$babiesofobject\]/s;
			$addobj{$objid}=~s/\/Count\s+\d+/\/Count $BabyCountOfObject{$objid}/s;
		}

		if ( int($objid) > $ExpectObjID ) {
			my $tmp=$ExpectObjID;
			for ( $ExpectObjID..int($objid)-1 ) {
				$xref.="xxxxxxxxxx 00001 f$eol";
				my $x=sprintf ("%0.10d",$ExpectObjID);
				$xref=~s/xxxxxxxxxx/$x/;
			}
			$xref.=sprintf("%0.10d %0.5d n$eol",$startXref,0);
		} else {
			$xref.=sprintf("%0.10d %0.5d n$eol",$startXref,0);
		}

		$ExpectObjID=$objid+1;

		$objsize{$objid}=length($addobj{$objid});
		$startXref+=$objsize{$objid};
		$accumulation+=$objsize{$objid};

		if ( $accumulation > $vars{PDFWriteSize} ) {
			foreach ( sort {$2<=>$b} keys %addobj ) { print FILE "$addobj{$_}"; delete $addobj{$_} };
			$accumulation=0;
			%addobj=();
		}
		$vars{PDFObjCountOut}++;
	}
	foreach ( sort {$a<=>$b} keys %addobj ) { print FILE "$addobj{$_}"; delete $addobj{$_} };
	$lastObjID++;

	$xref=~s/xxxxxxxxxx/0000000000/;
	print FILE "xref\0120 $lastObjID\n$xref";

	(my $CurrentTrailer=$trailerObject)=~s/__Size__/$lastObjID/s;
	print FILE "\015\012$CurrentTrailer\015\012startxref\015\012$startXref\015\012\%\%EOF\015\012";
	close FILE;
}

sub findRefs{
	return (/(?:(\d+)\s+\d+\s+R\s*)/gsi);
}

#sub lt{
#	# Stuff used while debugging and performance checks
#	my @timer=gettimeofday();
#	my $timeNow=$timer[0]+$timer[1]/1000000;
#	return $timeNow;
#}
=head1 AUTHOR

Sunil S, sunils_at_hpcl_co_in

Created by modifying PDF::Extract module by Noel Sharrock (http://www.lgmedia.com.au/PDF/Extract.asp)
(Without PDF::Extract this would not be there!)

Many thanx to inspiration by my collegues at Hindustan Petroleum Corporation Limited, Mumbai, India.

=head1 COPYRIGHT

Copyright (c) 2005 by Sunil S. All rights reserved.


=head1 LICENSE

This package is free software; you can redistribute it and/or modify it under the same terms as Perl itself,
i.e., under the terms of the ``Artistic License'' or the ``GNU General Public License''.

The C library at the core of this Perl module can additionally be redistributed and/or modified
under the terms of the ``GNU Library General Public License''.

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the ``GNU General Public License'' for more details.

PDF::Xtract - Extracting sub PDF documents from a multipage PDF document


=cut

1;

=head1 Notes


Fri Jun 17 00:01:21 IST 2005

Version 0.08

Output does not open properly in Acrobat Reader properly !  Xref table writing changed back to
what Noel was doing.

Fri Apr 15 21:15:17 IST 2005

Version 0.07

Trying to accelerate output generation, which seems to be the remaining bottleneck. 

Thu Apr  7 15:02:22 IST 2005

Version 0.06

Noticed that Xtract fails with very large PDFs (>400MB).  It is now fixed by changing the way the file is read and
understood.  Fringe benefit: module uses less memory than before.  Additional variable is introduced: PDFReadSize,
specify the number of bytes to read at a time when reading the input file.

Thu Mar  10 15:02:47 IST 2005

Noticed a problem with include objects!  Work around done.

Thu Feb  20 15:02:47 IST 2005

Operational sequences within the module is being changed.  New organisation will be as below:

Essentioal variable for doing anything is PDFDoc.
Extraction and making of document will run as and when PDFPages is defined.  It will be generated into
the disk file named as PDFSaveAs if one exist, else will be taken to default extract file named as
$TempExtractFile.

Populating the PDFExtract is now secondary!  If some one ask for that, we will return the content of the
file $TempExtractFile
