package PDF::Extract;  
use strict;
#use warnings;
use vars qw($VERSION);
$VERSION = '3.04';

=head1 NAME

PDF::Extract - Extracting sub PDF documents from a multi page PDF document

=head1 SYNOPSIS

 use PDF::Extract;
 $pdf=new PDF::Extract;
 $pdf->servePDFExtract( PDFDoc=>"c:/Docs/my.pdf", PDFPages=>"1-3 31-36" );

or 

 use PDF::Extract;
 $pdf = new PDF::Extract( PDFDoc=>'C:/my.pdf' );
 $pdf->getPDFExtract( PDFPages=>$PDFPages );
 print "Content-Type text/plain\n\n<xmp>",  $pdf->getVars("PDFExtract");
 print $pdf->getVars("PDFError");
 
 or 
 
 # Extract and save, in the current directory,  all the pages in a pdf document
 use PDF::Extract;
 $pdf=new PDF::Extract( PDFDoc=>"test.pdf");
 $i=1;
 $i++ while ( $pdf->savePDFExtract( PDFPages=>$i ) );


=head1 DESCRIPTION

PDF Extract is a group of methods that allow the user to quickly grab pages
as a new PDF document from a pre-existing PDF document.

With PDF::Extract a new PDF document can be:-

=over 4

=item * 

assigned to a scalar variable with getPDFExtract.

=item * 

saved to disk with savePDFExtract.

=item * 

printed to STDOUT as a PDF web document with servePDFExtract.

=item * 

cached and served for a faster PDF web document service with fastServePDFExtract.

=back

These four main methods can be called with or without arguments. The methods 
will not work unless they know the location of the original PDF document. 
PDFPages defaults to "1". There are no other default values.

There are four other methods that deal with setting and getting the public variables.

=over 4

=item * 

getPDFExtractVariables can return an array of variables. 

=item * 

getVars is an alias of getPDFExtractVariables

=item * 

setPDFExtractVariables can set the public variables. 

=item * 

setVars is an alias of setPDFExtractVariables

=back

=cut


my ( $pages, $fileNumber, $filename, $CatalogPages, $Catalog, $Root, $pdf, $pdfFile, $object, $encryptedPdf, $trailerObject )=(1,1); #default PDFPages to 1
my ( @object, @obj, @instnum, @pages ); 
my ( %vars, %getPages, %pageObject );

$vars{"PDFCache"}="."; # defaults to this directory

my $CRLF = '[ \t\r\n\f\0]'."*(?:\015|\012|(?:\015\012))";

# ----------------------------------------------------------- The Public Methods --------------------------------------------------------------

=head1 METHODS

=head2 new PDF::Extract

Creates a new Extract object with empty state information ready for processing
data both input and output. New can be called with a hash array argument.

 new PDF::Extract( PDFDoc=>"c:/Docs/my.pdf", PDFPages=>"1-3 31-36" )

This will cause a new PDF document to be generated unless there is an error.
Extract->new() simply calls getPDFExtract() if there is an argument.

=cut

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {};
    bless $self, $class;
    $self->getPDFExtract(@_) if @_;
    return $self;
}

=head2 getPDFExtract

This method is the main workhorse of the package. It does all the PDF processing
and sets PDFError if its unable to create a new PDF document. It requires
PDFDoc and PDFPages to be set either in this call of before to function. 
It outputs a PDF document as a string or undef if there is an error.

To create an array of PDF documents, each consisting of a single page, 
from a multi page PDF document.

 $pdf = new PDF::Extract( PDFDoc=>'C:/my.pdf' );
 $i=1;
 while ( $pdf[$i++]=$pdf->getPDFExtract( PDFPages=>$i ) );

The lowest valid page number for PDFPages is 1. A value of undef will produce no 
output and raise an error. An error will be raised if the PDFPages values do
not correspond to any pages.

=cut

sub getPDFExtract{                   
	&setEnv(@_);    
	&getDoc;
    $vars{"PDFExtract"} ? $vars{"PDFExtract"} : undef;
}

=head2  savePDFExtract

This method saves its output to the directory defined for PDFCache.  (see PDFCache)
If PDFSaveAs is unset the new PDF's filename will be an amalgam of the original filename, the 
requested page numbers and the .pdf file type suffix. If more than one page is extracted into a new PDF 
the page numbers will be separated with an underscore "_" for individual pages,  ".." for a range of pages.
eg. my6.pdf for a single page (page 6) and my1_3..6.pdf  for a multi page PDF (pages 1, 3, 4, 5, 6)

 $pdf->savePDFExtract(PDFPages=>"1 3-6", PDFDoc=>'C:/my.pdf', PDFCache=>"C:/myCache" );

If there is an error then an error page will be served and savePDFExtract will return a "0". 
Otherwise savePDFExtract will return "1" and the saved PDF location and file name will be "C:/myCache/my1_3..5.pdf".

=cut


sub savePDFExtract{
	&setEnv(@_);    
	&getDoc;
	&savePdfDoc;
	$vars{"PDFError"} ? 0 : 1;
}

=head2  servePDFExtract

This method serves its output to STDOUT with the correct header for a PDF document served on the web. 

 $pdf = PDF::Extract->new(
            PDFDoc=>'C:/my.pdf', 
            PDFErrorPage=>"C:/myErrorPage.html" );
 $pdf->servePDFExtract( PDFPages=>1);

If there is an error then an error page will be served and servePDFExtract will return "0". 
Otherwise servePDFExtract will return "1"

=cut

sub servePDFExtract{
    &setEnv(@_);    
    &getDoc;
    &uploadPDFDoc;
	$vars{"PDFError"} ? 0 : 1;
}

=head2  fastServePDFExtract

This method serves its output to STDOUT with the correct header for a PDF document served on the web. 

If PDFSaveAs is unset the new PDF's filename will be an amalgam of the original filename, the 
requested page numbers and the .pdf file type suffix. If more than one page is extracted into a new PDF 
the page numbers will be separated with an underscore "_" for individual pages,  ".." for a range of pages.
eg. my6.pdf for a single page (page 6) and my1_3..6.pdf  for a multi page PDF (pages 1, 3, 4, 5, 6).
If there is an error then an error page will be served and fastServePDFExtract will return "0".
fastServePDFExtract will return "1" on success.
 
 $pdf->setVars(
            PDFDoc=>'C:/my.pdf', 
            PDFCache=>"C:/myCache", 
            PDFErrorPage=>"C:/myErrorPage.html",
            PDFPages=>1);
 unless ($pdf->fastServePDFExtract ) {   
    # there was an error  
    $error=$pdf->getVars("PDFError") ;
 }

=cut

sub fastServePDFExtract{
	&setEnv(@_);    
	&redirect if -e "$vars{\"PDFCache\"}/$vars{\"PDFFilename\"} ";
	&getDoc;
	&savePdfDoc;
	&redirect;
	&uploadPDFDoc;
	$vars{"PDFError"} ? 0 : 1;
}

=head2 getPDFExtractVariables

Get any of the public variables using a list of the variables to get

 ($error,$found)=$pdf->getPDFExtractVariables( "PDFError", "PDFPagesFound");

This method returns an an array of variables corresponding to the named variables passed in as arguments.
If a variable is undefined then its returned value will be undefined.

=cut

sub getPDFExtractVariables {   
    my @var;
    my $i;
    shift;
    foreach my $key (@_) {
     $var[$i++]=$vars{$key};  
    }
    @var;
}

=head2 getVars

This methos is an alias for getPDFExtractVariables. Get any of the public variables using a list of the variables to get

 @vars=$pdf->getVars( @varNames );

This method returns an an array of variables corresponding to the named variables passed in as arguments.
If a variable is undefined then its returned value will be undefined.

=cut

sub getVars {   
    &getPDFExtractVariables(@_);
}

=head2 setPDFExtractVariables

Set any of the public variables using a hash of the variables and their values.

 ($doc,$pages)=$pdf->setPDFExtractVariables(PDFDoc=>'C:/my.pdf', PDFPages=>1);

This method sets the variables specified in the argument hash. 
They return an array of the new values set.

=cut

sub setPDFExtractVariables {
    &setEnv( @_ );
    shift;
    my %var=@_;
    &getVars( undef, keys %var);
}

=head2 setVars

This methos is an alias for setPDFExtractVariables. Set any of the public variables using a hash of the variables and their values.

 @vars=$pdf->setVars( %vars );

This method sets the variables specified in the argument hash. 
They return an array of the new values set.

=cut

sub setVars {   
    &setPDFExtractVariables(@_);
}

=head1 VARIABLES

=head2 PDFDoc 
(set and get)

 $file=$pdf->getVars("PDFDoc");

This variable contains the path to the last original PDF document accessed by 
getPDFExtract, savePDFExtract, servePDFExtract and fastServePDFExtract.
PDFDoc will be an empty string if there was an error.

=head2 PDFPages
(set and get)
 
 $pages=$pdf->setVars( PDFPages =>"1 18-23");
 or
 $pages=$pdf->getVars("PDFPages");

This variable contains a list of pages to extract from the original PDF document accessed by 
getPDFExtract, savePDFExtract, servePDFExtract and fastServePDFExtract. 
Use the join function to create a list of pages from an array. 
Such a an array of pages sent from a multi select box on a web form.
PDFPages will default to "1" if unset or there is an error processing the pages string.

 PDFPages => join( " ", $cgi->param( "PDFPages" )),

=head2 PDFCache
(set and get)

 $cachePath=$pdf->setVars( PDFCache =>"C:/myCache");
 or
 $cachePath=$pdf->getVars("PDFCache");

This variable, if set, should contain the FULL PATH to the PDF document cache. 
This value is used by savePDFExtract and fastServePDFExtract method calls.
PDFCache will be an empty string if there was an error in setting the value.
If PDFCache path does not exist an attempt will be made to create it recursively. 
Any directories that need to be created will be created with permissions of 0x777.
PDFCache defaults to ".", the current directory.

=head2 PDFSaveAs
(set and get)

 $filename=$pdf->setVars( PDFSaveAs =>"myFileName");
 or
 $filename=$pdf->getVars("PDFSaveAs");
 
If PDFSaveAs is unset the new PDF's filename will be an amalgam of the original filename, the 
requested page numbers and the .pdf file type suffix. If more than one page is extracted into a new PDF 
the page numbers will be separated with an underscore "_" for individual pages,  ".." for a range of pages.
eg. my6.pdf for a single page (page 6) and my1_3..6.pdf  for a multi page PDF (pages 1, 3, 4, 5, 6)

Setting PDFSaveAs to something other than "" or 0 will cause the output to be named with the content of PDFSaveAs.
The .pdf filename extension and any path informationwill be stripped from the variable if set.
PDFFilename will contain the actual filename used for the last extracted pdf'.

=head2 PDFErrorPage
(set and get)

 $errorPagePath=$pdf->setVars("PDFErrorPage"=>"C:/myError.html");
 or
 $errorPagePath=$pdf->getVars("PDFErrorPage");

PDFErrorPage is a text file that can be used as a template for the error page.
If the PDFErrorPage contains [PDFError], the word PDFError surrounded by square brackets, 
then the error description will replace [PDFError].
Otherwise you can devise a generic error description and describe remedial actions to be taken by the viewer.

If this variable is not set then a default error page will be used.
The default page has a message in red at the top,
"There is system problem in processing your PDF Pages request.", 
and then a description of the actual error follows underneath in black.

=head2 PDFExtract 
(get only)
 
 $out=$pdf->getVars("PDFExtract");

This variable contains the last PDF document processed by getPDFExtract, savePDFExtract, servePDFExtract and fastServePDFExtract.
PDFExtract will be an empty string if there was an error.

=head2 PDFPagesFound
(get only)
 
 $pagesFound=$pdf->getVars("PDFPagesFound");
 or
 @pages = split ", ", $pdf->getVars("PDFPagesFound");

This variable contains a comma seperated list of the page numbers that were selected and found within the original PDF document.
PDFPagesFound will be a undefined if there was an error in finding any pages.

=head2 PDFPageCount
(get only)
 
 $pageCount=$pdf->getVars("PDFPageCount");


This variable contains the number of the pages that were selected and found within the original PDF document.
PDFPageCount will be an empty string if there was an error in finding any pages.

=head2 PDFFileName
(get only)

 $filename=$pdf->getVars("PDFFilename");
 
This variable will contain the actual filename.
If PDFSaveAs is unset the new PDF's filename will be an amalgam of the original filename, the 
requested page numbers and the .pdf file type suffix. If more than one page is extracted into a new PDF 
the page numbers will be separated with an underscore "_" for individual pages,  ".." for a range of pages.
eg. my6.pdf for a single page (page 6) and my1_3..6.pdf  for a multi page PDF (pages 1, 3, 4, 5, 6).
If PDFSaveAs is set then PDFSaveAs will be used to construct PDFFilename.
The full path to the extracted pdf file can be obtained by - 

 $fullpath = $pdf->getVars("PDFCache") ."/". $pdf->getVars("PDFFilename");
 or
 ($path,$filename) = $pdf->getVars("PDFCache","PDFFilename");

=head2 PDFError
(get only)

 $error=$pdf->getVars("PDFError");

This variable contains a string describing the errors if any in processing the original PDF file.
PDFError is guarenteed to be set if  getPDFExtract, savePDFExtract, servePDFExtract or fastServePDFExtract fail and return a "0".
PDFError will be an empty string if there was no error.

=head2 PDFDebug
(set for method call duration only)

 $pdf->setVars(
            PDFDoc=>'C:\docs\pdf', 
            PDFPages=>"2 6-8 ",
            PDFDebug=>1);

This really a directive and not a true variable. It is used to debug the setting of variables in a PDF::Extract method call.
PDFDebug as used above will print:-

 These variables are to be set
	PDFDoc="C:\docs\pdf/"
	PDFPages="2 6-8 "
	PDFDebug="1"
 These variables have been set
	PDFCache="C:/myCache"
	PDFFilename="2_6..8_.pdf"
	PDFPagesFound=""
	PDFDoc=""
    PDFPages="2, 6, 7, 8"
	PDFPageCount=""
	PDFExtract=""
	PDFError="PDF document "" not found at C:/Perl/site/lib/PDF/Extract.pm line 467"

=cut


# ----------------------------------------------------------- The Private Functions --------------------------------------------------------------

sub setEnv {
    my (undef,  %PDF)=@_;
    my $requestedPages=0;
    $vars{"PDFError"}="";
    if ($PDF{"PDFDebug"} ) {
        print "These variables are to be set\n";
        foreach my $key (keys %PDF) {
            print "\t$key=\"$PDF{$key}\"\n";
        } 
    }
     if ($PDF{"PDFErrorPage"} ) {
        $vars{"PDFErrorPage"}="";
         if ( -f $PDF{"PDFErrorPage"} ) {
	        if (open FILE, $PDF{"PDFErrorPage"} ) {
				$vars{"PDFErrorFile"} = join('', <FILE>);
				close FILE;
		        $vars{"PDFErrorPage"}=$PDF{ "PDFErrorPage"};
		    } else {
		        &error( "Can't open PDF Error page template file $PDF{\"PDFErrorPage\"} to read\n",__FILE__,__LINE__);	    
		    }
		} else {
            &error("PDF Error page template file \"$PDF{PDFErrorPage}\" not found",__FILE__,__LINE__);
		}
    } 
    if ($PDF{ "PDFDoc" } ) {
        $vars{"PDFDoc"}="";
        $vars{"PDFPageCount"}=$vars{"PDFPagesFound"}=$vars{"PDFExtract"}="";
        $pdfFile=$filename=$CatalogPages=$Root=$object=$encryptedPdf=$trailerObject="";
        @object=@obj=@pages=(); 
        %pageObject=();
        $filename=$1 if  $PDF{"PDFDoc"}=~/([^\\\/]+)\.pdf$/i;
        if ( -f $PDF{"PDFDoc"} ) {
	        if (open FILE, $PDF{"PDFDoc"} ) {
				binmode FILE;
				$pdfFile = join('', <FILE>);
				close FILE;
		        $vars{"PDFDoc"}=$PDF{"PDFDoc"};
		    } else {
		        &error( "Can't open PDF document  $PDF{\"PDFDoc\"} to read\n",__FILE__,__LINE__);	    
		    }
		} else {
            &error(" PDF document \"$filename\" not found",__FILE__,__LINE__);
		}
    } 
    if ($PDF{ "PDFPages" } ) {
        $vars{ "PDFPages"}="";
        $vars{"PDFPageCount"}=$vars{"PDFPagesFound"}=$vars{"PDFExtract"}="";
        $CatalogPages=$Root=$object=$encryptedPdf=$trailerObject="";
        @object=@obj=@pages=(); 
        %getPages=%pageObject=();
		$pages=$PDF{ "PDFPages" };
		my $pageError=$pages;
		$pages=~s/\.\./-/g;
		$pages=~s/\.//g;
		$pages=~s/\-/../g;
		$pages=~s/ +/,/g;
		$pages=~s/[^\d,\.]//g;                  # allow only numbers to be processed
		$pages=1 unless $pages; 				# defaults to 1
        $fileNumber=$pages;
        $fileNumber=~s/,/_/g;
		foreach my $page ( eval $pages ) {
		    next unless int $page;
	        $getPages{int $page}=1;
	        $requestedPages++;
	    }
	    if ( $requestedPages ) {
		    $pages="";
		    foreach my $page ( sort  keys %getPages) { 
		        $pages.="$page, ";
		    }
		    $pages=~s/, $//;
		    $vars{ "PDFPages"}=$pages;
		} else {
		    &error("Can't get PDF Pages. No page numbers were set with '$pages' ",__FILE__,__LINE__);
		}
	 }
	 if ($PDF{ "PDFCache"} ) {
        $vars{"PDFCache"}=dir($PDF{ "PDFCache"});
	 }
	 if ( defined $PDF{ "PDFSaveAs" } ) {   # we also want to be able to set PDFSaveAs to nothing ("")       
        $vars{"PDFSaveAs"} = $PDF{"PDFSaveAs"};
        $vars{"PDFSaveAs"}=~s/\.pdf$//i;    # just want the name, not the path and not the .pdf tag
        $vars{"PDFSaveAs"}=~s/^.*[\/\\]//;
     }
    $vars{"PDFFilename"}=$vars{"PDFSaveAs"} ? $vars{"PDFSaveAs"}.".pdf" : $filename.($fileNumber||1).'.pdf'; #  Reported bug 41628 - $fileNumber might not be defined. Suggested fix by Patrick Bourdon to avoid warnings

    if ( $PDF{"PDFDebug"} ) {
        print "These variables have been set\n";
        foreach my $key (keys %vars) {
            print "\t$key=\"$vars{$key}\"\n";
        } 
    }
}

sub dir {
	my($path,$dir,@folders)=@_;
	$path=~s/\\/\//g;
	(@folders)=split "/", $path;
	foreach my $folder (@folders) {
		$dir.= $folder=~/:/ ? $folder : "/$folder";
		next if $folder=~/:/;
		mkdir $dir, 0x777 unless -d $dir;
		#   print "$dir\n";
	}
  $path=~s/\//\\/g  if ($^O eq "MSWin32");
	return &error("This Cache path \"$path\" can't be created",__FILE__,__LINE__) 
	    unless -d $path;
	$path;
}

sub redirect {
	exit print "Content-Type: text/html\n\n<META HTTP-EQUIV='refresh' content='0;url=$vars{'PDFFilename'}.pdf'>";
}

sub getDoc {
    return if $vars{"PDFExtract"};
	return &error("There is no pdf document to extract pages from",__FILE__,__LINE__) unless $pdfFile;   
	&getRoot;
	&getPages($CatalogPages,0);
	return &error("There are no pages in $filename.pdf that match  '".((defined $pages) ? $pages : '?')."' ",__FILE__,__LINE__) # Reported bug 41628 - $pages might not be defined.  Suggested fix by Patrick Bourdon to avoid warnings
	    unless $vars{"PDFPageCount"};
	&getObj($Root,0);
	&makePdfDoc;
}

sub savePdfDoc {
	return "" if $vars{"PDFError"};
	return &error("Can't open $vars{'PDFCache'}/$vars{'PDFFilename'}",__FILE__,__LINE__) 
	    unless open FILE, ">$vars{'PDFCache'}/$vars{'PDFFilename'}";
	binmode FILE;
	print FILE $vars{"PDFExtract"};
	close FILE;
}	

sub uploadPDFDoc {
    return &servError("") if $vars{"PDFError"};
    my $len=length $vars{"PDFExtract"};
    return &servError("PDF output is null, No output",__FILE__,__LINE__) unless $len;
    print <<EOF;
Content-Disposition: inline; filename=$vars{"PDFFilename"}\r
Content-Length: $len\r
Content-Type: application/pdf\r
\r
$vars{"PDFExtract"}\r
EOF
}

#------------------------------------ support  Routines --------------------------------------------

sub servError {
	my ($error,$file,$line)=@_;
	&error($error,$file,$line) if $error;
	if ($vars{"PDFErrorPage"}) {
	    $error=$vars{"PDFErrorFile"};
	    $error=~s/\[PDFError\]/$vars{"PDFError"}/sg;
	} else {
	    $error="<font color=red><h2>There is system problem in processing your PDF Pages request</h2></font><xmp>ERROR: $vars{\"PDFError\"} </xmp>";
    }
	print "Content-Type: text/html\n\n$error";
	"";
}

sub error {
	my ($error,$file,$line)=@_;
	$vars{"PDFError"}.="$error\nat $file line $line\n";
	"";
}

#------------------------------------ PDF Page Routines --------------------------------------------
sub getRoot {
	return "" if $vars{"PDFError"};
	return  if $Root;
	$pdf=$pdfFile;
    my $val=$1 if $pdf=~/(trailer\s*<<.*?>>\s*)/s;
    $Root=int $1 if $val=~/\/Root (\d+) 0 R/s;    
    $val=~s/\/Size \d+/\/Size __Size__/s;   
    $val=~s/\/Prev \d+//s;                   # delete Prev reference if its there was delelte to CRLF but croaked in 1.5
 
    &getObj($1, $2 ) if $val=~/\/Info (\d+) (\d+) R/s;
    &getObj( $encryptedPdf=$1, $2 ) if $val=~/\/Encrypt (\d+) (\d+) R/s;
    $trailerObject=$val; 
    $Catalog=$1 if $pdf=~/\D($Root 0 obj.*?endobj\s*)/s;
    $CatalogPages=int $1 if $Catalog=~/\/Pages (\d+) 0 R\s*/s; 
    $Catalog=~s/\/Outlines \d+ \d+ R//;      # delete outlines as they won't conform to extracted pages 3.01
    $Catalog=~s/\/PageLabels \d+ \d+ R//;      # delete PageLabels as they won't conform to extracted pages 3.01
    $Catalog=~s/\/Threads \d+ \d+ R//;      # delete Threads as they won't conform to extracted pages 3.01
    $Catalog=~s/\/StructTreeRoot \d+ \d+ R//;      # delete StructTreeRoot as it won't conform to extracted pages 3.01
    $pdf=~s/(\D)$Root 0 obj.*?endobj\s*/$1$Catalog/s;
}

sub getObj {
	return "" if $vars{"PDFError"};
    my($obj,$instnum,$gd)=@_;
    unless ($obj[$obj] ) {
         if ($pdf=~/\D($obj $instnum obj.*?endobj\s*)/s ) {
            $object = $1;
#	        return "" if $object=~/\/GoToR/; # Don't want these link objects
            $obj[$obj]++;
	        $object[$obj]=$object;
            $instnum[$obj]=$instnum;
            
	        $object[$obj]=~s/(\/Dest \[ )(\d+)( \d.*?)/&uri($1,$2,$3)/es; # Convert page dest to uri if not present
	        $object[$obj]=~s/(\d+) (\d+) R([^GD])/&getObj($1, $2, $3)/ges; # Reported bug 33707 found 0 0 R in 0 0 0 RG generated by BUFFETTI software 
#	        $object[$obj]=~s/(\/Dest \[ \d+)==/$1 0/s; # Don't follow this path
	        $object[$obj]=~s/\/Annots \[\s+\]\s+//s; # Delete empty Annots array
	    } else {
	        &error("Can't find object $obj $instnum obj  ",__FILE__,__LINE__);
	    }
    }
    (defined $gd) ? "$obj 0 R$gd" : "$obj 0 R"; # Reported bugs 38579 & 41628 - $gd might not be defined. Suggested fix by Patrick Bourdon to avoid warnings
}

sub uri {
    my($dest,$obj,$param)=@_;
    return "$dest$obj$param" if $getPages{ $pageObject{$obj} }; # page is in document    
	#return "/A << /S /URI /URI ($web?PDFDoc%26$vars{PDFDoc}&PDFExtract%26$pageObject{$obj})>> \r"
	#    unless $encryptedPdf;
	"";
}

sub getPages {
	return "" if $vars{"PDFError"};
    my($obj, $instnum)=@_;
    my $val=$1 if $pdf=~/\s($obj $instnum obj.*?endobj\s*)/s;#by Stefano Capuzzimato. There can be even no space after endobj (* instead of +)
    my $found="";
    my $count=0;
    if ($val=~/\/Kids\s*\[\s*(.*?)\]/s ) {#by Stefano Capuzzimato. You can find spaces between "Kids" and "["
        my $kids=$1;
        $kids=~s/\s+/ /gs;
        foreach my $kid (split " R ", $kids) {      
            my($f,$c)=&getPages(split " ", $kid);
            $found.=$f;
            $count+=$c;
        }
        $pdf=~s/(\D$obj $instnum obj.*?\/Kids\s*\[).*?\]/$1$found\]/s;#by Stefano Capuzzimato. Between "Kids" and "[" there can be even no space
        $pdf=~s/(\D$obj $instnum obj.*?\/Count )\d+/$1$count/s;
        $found="$obj $instnum R " if $found;
    } else {
        $pageObject{$obj}=push @pages, $obj; # create a hash of all pages
	    if ( $getPages{$pageObject{$obj}} ) {
	        $found="$obj $instnum R ";
	        $count=1; 
	        $vars{"PDFPagesFound"}.= $vars{"PDFPagesFound"} ? ", $pageObject{$obj}" : $pageObject{$obj};
	        $vars{"PDFPageCount"}++;
        }
    }
    ($found,$count);
}

sub makePdfDoc {                        
	return "" if $vars{"PDFError"};
	return &error("$vars{PDFDoc} is not a PDF file \n$pdf",__FILE__,__LINE__) 
	    unless $pdf=~s/^(.*?)($CRLF+)/$2/;
	$vars{"PDFExtract"}=$1.$2;
	$vars{"PDFExtract"}.=$1.$2 
	    while( $pdf=~s/^\s+(\%.*?)($CRLF+)/$2/); #include comment lines if any
	my $xref="xxxxxxxxxx 65535 f\015\012";
	my $objCount=1;
	my $cnt=0;
	for( ;$objCount<@object;$objCount++) {
	    if ($object[$objCount]) {
	        $xref.=sprintf("%0.10d %0.5d n\015\012",
			       length $vars{"PDFExtract"}, 
			       $instnum[$objCount] );
	        $vars{"PDFExtract"}.=$object[$objCount];
	        $cnt++;
	    }
	}
	return &error("$vars{PDFDoc} does not contain objects",__FILE__,__LINE__) 
	    if $cnt==0;
	$xref=~s/xxxxxxxxxx/0000000000/s;
	my $startXref=length $vars{"PDFExtract"};
	$vars{"PDFExtract"}.="xref\n0 $cnt\n$xref";        # changed \r to \n for unixish systems by Alberto Accomazzi
	$trailerObject=~s/__Size__/$cnt/s;
	$vars{"PDFExtract"}.="$trailerObject\nstartxref\n$startXref\n\%\%EOF\n";        # changed \r to \n for unixish systems by Alberto Accomazzi
}

=head1 NOTES

This version of PDF::Extract has been designed to produce output to the PDF Standard as defined in the PDF Reference Seventh Edition.

However some third party PDF applications require a non standard feature of PDF documents. 
Namely: The sequential numbering of objects starting at zero.

PDF::Extract treats a PDF file as a flat file, for speed of processing, and consequently knows nothing of PDF objects. 
Objects extracted remain exactly as they were in the original document. 
These objects are not renumbered. There will be gaps in the object number sequence. This is allowed in the specification.
Only the catalog and page tree objects are altered.

See the web site if you need information how to make PDF documents comply with what your third party PDF application expects.

=head1 BUGS

There is a bug that Jon Schaeffer reported that had to do with some font resources not being found in the extracted PDF. 
The source of the bug has, as yet, not been found.
If you find such a bug can you email a one page original pdf that can produce a PDF extract that has this bug.

Please report any bugs you find.

=head1 AUTHOR

Noel Sharrock E<lt>mailto:nsharrok@lgmedia.com.auE<gt>

PDF::Extract's home page http://www.lgmedia.com.au/page.aspx?ID=8

Forum for users and developers has been hacked and database no longer exists. There are some sad folk around.

=head1 SUPPORT

Much thanks to:-

 Lyman Byrd for his welcome programming suggestions and editorial comments on the POD.
 Michael Cox for his suggestion of PDFSaveAs and for the time he spent in testing the module.
 Alberto Accomazzi for sharing his time and his knowledge of Unixish PDF voodoo magick.
 Stefano Capuzzimato for correcting some stuff in the regexes he found.
 Geert Theys for finding a small bug and supplying an excelent solution.
 Jon Schaeffer for help with finding a solution to a bug in extracting Adobe 6+ pages.
 Dario Santini for reporting a bug at http://rt.cpan.org//Ticket/Display.html?id=33707
 Patrick Bourdon suggested several fixes for undefind string concatination warnings.

=head1 COPYRIGHT

Copyright (c) 2005 by Noel Sharrock. All rights reserved.

=head1 LICENSE

This package is free software; you can redistribute it and/or modify it under the same terms as Perl itself, 
i.e., under the terms of the ``Artistic License'' or the ``GNU General Public License''.

The C library at the core of this Perl module can additionally be redistributed and/or modified 
under the terms of the ``GNU Library General Public License''.

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the ``GNU General Public License'' for more details.

PDF::Extract - Extracting sub PDF documents from a multipage PDF document

=cut

#------------------------------------------ End PDF Page ------------------------------------------   

1; 
