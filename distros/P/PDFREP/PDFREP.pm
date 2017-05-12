package PDFREP;

#-----------------------------------------------------------------------------#
#                                                                             #
#                               PDFREP                                        #
#                                                                             #
# OVERVIEW                                                                    #
#                                                                             #
# This module is used to create a basic data generated PDF file it's main     #
# Purpose is to be generic and usable by all perl scripts in an easy manner   #
# It does create all the indexes, but not the thumbnails                      #
#                                                                             #
# DEVELOPMENT                                                                 #
#                                                                             #
# STARTED                       26th June   2001                              #
# COMPLETED                     23rd July   2007                              #
#                                                                             #
# VERSION                       2.20                                          #
#                                                                             #
# WRITTEN BY                    Trevor Ward                                   #
#                                                                             #
# Copyright (c) 2001 Trevor Ward. All rights reserved.                        #
# This program is free software; you can redistribute it and/or               #
# modify it under the same terms as Perl itself                               #
# MODIFICATION INDEX                                                          #
#                                                                             #
# This comments area to include all modifications from Version 1.0            #
# The version number to be incremented by .1 for each modification            #
#                                                                             #
# Date        Version    By        Comments                                   #
#                                                                             #
# 25/06/2001  1.00       TRW       Initial Version                            #
# 10/07/2001  1.01       TRW       Added Column offsets                       #
# 12/09/2001  1.02       TRW       Added text () escaping                     #
# 10/10/2001  1.03       TRW       Removed backslashes from text except octal #
# 29/01/2002  1.04       TRW       Added columns for Graphics   cm            #
# 16/02/2003  1.05       TRW       PFS VERSION Removed GD for base system     #
# 17/03/2003  1.06       TRW       Fixed 100 < 99 Bug                         #
#-----------------------------------------------------------------------------#
# Version 2 Updates                                                           #
#                                                                             #
# 04/08/2005  2.00       TRW       New Function lcnt for counting lines left  #
# 23/07/2007  2.20       TRW       Bug fix of bracket display issue           #
#-----------------------------------------------------------------------------#

use strict;
use English;
use GD;

#-----------------------------------------------------------------------------#
# Exporter set the exporter information for the module                        #
#-----------------------------------------------------------------------------#

use vars qw(@ISA @EXPORT $VERSION);

use Exporter;

$VERSION = '2.20';

@ISA = qw(Exporter);

#-----------------------------------------------------------------------------#
# As all parts of this module are required to be used  @EXPORT is used        #
#-----------------------------------------------------------------------------#

@EXPORT  = qw(catalog
              crashed
              fontset
              heading
              include_image
              outlines
              pagedata
              trailer
              writepdf
              xreftrl
              lcnt);

#-----------------------------------------------------------------------------#
# GLOBAL VARIABLES                                                            #
#                                                                             #
# The following list details the global variables and the functions they are  #
# Updated in and used in                                                      #
#                                                                             #
# $objcount - This is used to store the total amount of objects created       #
#             It is updated in the ???????  function                          #
#             It is output in the trailer function                            #
#                                                                             #
# $startxref - This is used to store the cross reference start value          #
#              It is updated in the ????????? function                        #
#              It is output in the trailer function                           #
#                                                                             #
# $rc - This is used as the return code to the calling program which allows   #
#       for the checking of print return codes.                               #
#                                                                             #
# %pdoffs - This hash is used to store the byte offset of the new object      #
#           when created for use by the cross reference. This should then     #
#           ba able to create the index afterwards                            #
#                                                                             #
# $offset - This is used to store the current offset value from all the text  #
#           which has been printed to the file                                #
#                                                                             #
# $pagecnt - This is used to store up the total count of new pages within the #
#            pdf file.                                                        #
#                                                                             #
# %pageref - This is used to store up the page number reference as the key    #
#            and the object reference of the page.                            #
#                                                                             #
# %fontstr - This is used to store the font internal name and the font's      #
#            physical name for all the fonts defined.                         #
#                                                                             #
# $filetyp - This is used to store the physical location of the PDF data file #
#                                                                             #
# $temptyp - This is used to store the physical location of the TMP data file #
#                                                                             #
# $fontcnt - This is used to store the total number of fonts for calculation  #
#                                                                             #
# @pdpageline - This is the variable used to store the lines of data to be    #
#               output as the text within the document                        #
#                                                                             #
# $pditem - This is used within the pagedata sub as a global counter which    #
#           needs retaining                                                   #
#                                                                             #
# $pdlcnt - This keeps track of how many line of data have to be written in   #
#           the sub pagedata.                                                 #
#                                                                             #
# $pdlgth - This is used within the pagedata sub as the total length of the   #
#           data passed to the stream part of the pdf file                    #
#                                                                             #
# $lnum   - This is used to store the current line number of the page. It     #
#           starts at line 80 top of page and subtracts down.                 #
#                                                                             #
# $lcnt   - This is used to check the amount of lines written out to the page #
#                                                                             #
# @image_name - This is used to store the image names                         #
#                                                                             #
#-----------------------------------------------------------------------------#

# These variables are initialised within the heading sub routine

my ($objcount, $startxref, $rc, %pdoffs, $offset, $pagecnt, %pageref, %fontstr, $filetyp, $temptyp);
my ($fontcnt, @pdprintline, $item, $lcnt, $pdlgth, @image_name, $tmpoffs, $rootobj, $infoobj);

#-----------------------------------------------------------------------------#
# SUB NEW                                                                     #
#-----------------------------------------------------------------------------#

sub new 
{
    my($proto) = @ARG;
    my $class  = ref($proto) || $proto;
    my $self   = {};

    bless ($self, $class);

    return $self;
}

#-----------------------------------------------------------------------------#
# SUB LCNT                                                                    #
#-----------------------------------------------------------------------------#

sub lcnt
{
    return $lcnt;
}

#-----------------------------------------------------------------------------#
# SUB HEADING                                                                 #
#                                                                             #
# This receives the file name and directory from the calling program and      #
# Opens the output file for the first time writing the PDF Header record      #
# It returns the Message and Status code as with all the functions within     #
# this package Status code 0 is succesful and 1 is failure. It also           #
# Initialises all the global variables and counters used                      #
#-----------------------------------------------------------------------------#

sub heading
{
    # Receive the passed variables
    # $callpgm is always PDFREP set by using the Package information
    # $filenam is the name of the output PDF file required
    # $filedir is the directory for this file to be created in
    # $title   is the document title
    # $author  is the document author
    # @rubbish is a catchall filed used incase additional parameters are entered - this is not used

    my ($callpgm, $filenam, $filedir, $title, $author, @rubbish) = @_;

    # Initialise all the global variables

    undef %pdoffs;
    undef $offset;
    undef $objcount;
    undef $startxref;
    undef $pagecnt;
    undef %pageref;
    undef %fontstr;
    undef $fontcnt;
    undef $rc;

    # Set the heading text value this will remain constant

    my $heading = "%PDF-1.3";

    # Check the passed parameters contain values return false if not

    my $mess;

    if (!$filenam)
    {
        $mess = "No File Name";
        return ('0', $mess);
    }
    if (!$filedir)
    {
        $mess = "No Directory Details";
        return ('0', $mess);
    }

    # Create the data file name variable and open the file return false if file open fails
    # Also create the temporary work file which is used to store the page data

    $filetyp = $filedir . $filenam . ".pdf";
    $temptyp = $filedir . $filenam . ".tmp";

    open(PDFFILE, "> $filetyp") || warn return ('0' , "File open failure - $filetyp - $!");
    binmode(PDFFILE);
    open(TMPFILE, "> $temptyp") || warn return ('0' , "File open failure - $temptyp - $!");

    # Write the heading record to the file check the return value

    $rc = print PDFFILE "$heading\015\012";

    $offset = 0 if (!$offset);
    $offset = $offset + length($heading) + 2;
    if (!$rc)
    {
        return ('0', 'PDFREP Write PDF File Failure - Heading');
    }
    # Write the info line

    $objcount++;
    $infoobj = $objcount;

    my @outline;
    my $linecnt = 0;

    $outline[$linecnt] = "$objcount 0 obj";
    $linecnt++;
    $outline[$linecnt] = "<< ";

    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime();
    $year = $year + 1900;
    $mon  = $mon  + 1;
    $mon  = '0' . "$mon"  if (length($mon) < 2);
    $mday = '0' . "$mday" if (length($mday) < 2);

    if ($title)
    {
        $outline[$linecnt] .= "/Title ( $title)";
        $linecnt++;
    }
    if ($author)
    {
        $outline[$linecnt] .= "/Author ( $author)";
        $linecnt++;
    }
    $outline[$linecnt] .= "/Creator (Perlrep Module V1.00 copyright T.R.Ward 2001)";
    $linecnt++;
    $outline[$linecnt] .= "/Producer (Perlrep Module V1.00 copyright T.R.Ward 2001)";
    $linecnt++;
    $outline[$linecnt] .= "/CreationDate ( D:$mday-$mon-$year $hour-$min-$sec)";
    $linecnt++;
    $outline[$linecnt] .= "/ModDate ( D:$mday-$mon-$year $hour-$min-$sec)";
    $linecnt++;

    $outline[$linecnt] = ">>";
    $linecnt++;
    $outline[$linecnt] = "endobj";

    # Set the Offset for this object in the offset hash store

    $tmpoffs = $objcount;

    while (length($tmpoffs) < 4)
    {
        $tmpoffs = "0" . $tmpoffs;
    }
    #(length($objcount) < 2) ? ($tmpoffs = '0' . $objcount) : ($tmpoffs = $objcount);
    $pdoffs{$tmpoffs}   = $offset;

    # Write out the data to the PDF file check the return code and throw error if failure

    foreach $item (@outline)    
    {
        $rc = print PDFFILE "$item\015\012";

        $offset = $offset + length($item) + 2;
    }
    # Call the Catalogue sub which produces the catalogue object 

    $rc = &catalog();

    if (!$rc)
    {
        return ('0', 'PDFREP Write PDF File Failure - Catalog');
    }
    # Call the Outline sub which produces the Outlines object

    $rc = &outlines();

    if (!$rc)
    {
        return ('0', 'PDFREP Write PDF File Failure - Outline');
    }
    # Return the succesful message and true value to the called program.

    return ('1', "PDFREP Heading Succesful");
}

#-----------------------------------------------------------------------------#
# SUB CATALOG                                                                 #
#                                                                             #
# This sub produces the catalog reference which is used to identify the       #
# Pages object and the Outlines object Which are also fixed objects numbers.  #
# The Catalog object number is always 1                                       #
# This sub is called from the heading sub as it is fixed                      #
#-----------------------------------------------------------------------------#

sub catalog
{
    my @catline = '';
    my $item    = '';

    # Setup the array of all the data required to produce the catalog object

    $objcount++;
    $rootobj = $objcount;
    my $pages = $objcount + 2;
    my $outls = $objcount + 1;

    $catline[0] = "$objcount 0 obj";
    $catline[1] = "<<";
    $catline[2] = "/Type /Catalog";
    $catline[3] = "/Pages $pages 0 R";
    $catline[4] = "/Outlines $outls 0 R";
    $catline[5] = ">>";
    $catline[6] = "endobj";

    # Set the Offset for this object in the offset hash store

    $tmpoffs = $objcount;

    while (length($tmpoffs) < 4)
    {
        $tmpoffs = "0" . $tmpoffs;
    }
    #(length($objcount) < 2) ? ($tmpoffs = '0' . $objcount) : ($tmpoffs = $objcount);
    $pdoffs{$tmpoffs}   = $offset;

    # Write out the data to the PDF file check the return code and throw error if failure

    foreach $item (@catline)    
    {
        $rc = print PDFFILE "$item\015\012";

        $offset = $offset + length($item) + 2;

        if (!$rc)
        {
            return 0;
        }
    }
    return 1;
}

#-----------------------------------------------------------------------------#
# SUB OUTLINES                                                                #
#                                                                             #
# This sub produces the outlines object reference in a fixed format during    #
# testing at anyway.                                                          #
# The Outlines object is always number 2                                      #
# This sub is called from the heading sub as it is fixed                      #
#-----------------------------------------------------------------------------#

sub outlines
{
    my @outline;
    my $item    = '';

    # Setup the data into the array required for the Outlines object

    $objcount++;

    $outline[0] = "$objcount 0 obj";
    $outline[1] = "<<";
    $outline[2] = "/Type /Outlines";
    $outline[3] = ">>";
    $outline[4] = "endobj";

    # Set the offset for this object using the offset hash

    $tmpoffs = $objcount;

    while (length($tmpoffs) < 4)
    {
        $tmpoffs = "0" . $tmpoffs;
    }
    #(length($objcount) < 2) ? ($tmpoffs = '0' . $objcount) : ($tmpoffs = $objcount);
    $pdoffs{$tmpoffs}   = $offset;

    # Write out the data to the PDF file check the return code and throw error if failure

    foreach $item (@outline)    
    {
        $rc = print PDFFILE "$item\015\012";

        $offset = $offset + length($item) + 2;

        if (!$rc)
        {
            return 0;
        }
    }
    return 1;
}

#-----------------------------------------------------------------------------#
# SUB FONTSET                                                                 #
#                                                                             #
# This sub is where the font will be set during page creation. Hopefully      #
# this is will sort out all font changes within the text which is to be       #
# printed. It accepts the font name from the calling program                  #
#-----------------------------------------------------------------------------#

sub fontset
{
    # Receive the passed variables
    # $callpgm is always PDFREP set by using the Package information
    # $fontnam is the internal name of the font
    # $fonttyp is the physical font used
    # @rubbish is a catchall filed used incase additional parameters are entered - this is not used

    my ($callpgm, $fontnam, $fonttyp, @rubbish) = @_;

    # Now need to store these values until after the pages have been created into a global hash
    # storing the font name as the key and adding 1 to the total font counter

    $fontstr{$fontnam} = $fonttyp;
    $fontcnt++;

    # Return a succesful code

    return ('1', 'PDFREP Font Set Succesful');
}

#-----------------------------------------------------------------------------#
# SUB PAGEDATA                                                                #
#                                                                             #
# This sub is where the page data is set it is run after the page head has    #
# been run and it produces a line of data at a time to enable the page to be  #
# built as opposed to constructed. It receives various parameters prior to    #
# the text.                                                                   #
# Type of Info                                                                #
# np = new page                                                               #
# nl = new line                                                               #
# nc = new column                                                             #
#-----------------------------------------------------------------------------#

sub pagedata
{
    # Receive the passed variables
    # $callpgm is always PDFREP set by using the Package information
    # $ltype this is the type of data either new page (np) or new line (nl)
    # $lcol this is the column offset from the left hand side of the page
    # $lfont this is the size of the font
    # $nfont this is the internal name of the font
    # $ldata this is the actual text data to be used
    # $psize this is the page size
    # $porin This is the page orientation
    # @rubbish is a catchall filed used incase additional parameters are entered - this is not used

    my ($callpgm, $ltype, $lcol, $lfont, $nfont, $nextf, $ital, $red, $green, $blue, $ldata, $psize, $porin, @rubbish) = @_;

    # Keep a check on the line count per page current maximum is 38 if over blow away files return error

    # Version 1.03 duplicate all backslashes to remove errors when passed.
    # Also allow for octal characters to be passed by using a space either end of a three number field

    $ldata =~ s/\\/\\\\/gis;
    $ldata =~ s/ \\\\(\d\d\d) /\\$1/gis;

    # End of version 1.03 update

    # Version 1.02 setup the correct values for escaped characters

    $ldata =~ s/\(/\\\(/gis;
    $ldata =~ s/\)/\\\)/gis;

    # End of version 1.02 update

    # Version 2.00 update

#    $ldata =~ s/([\(\)])/\\$1/gis;

    if ($ltype eq 'nl')
    {
        $lcnt = $lcnt - $lfont;
        $rc   = print TMPFILE "$red $green $blue rg $lcol $nextf Td ($ldata) Tj\n";

        if (!$rc)
        {
            return ('0', 'PDFCGI Write TMP File Failure - New Line');
        }
        $rc = print TMPFILE "/$nfont $lfont Tf 1 0 $ital 1 10 $lcnt Tm\n";

        if (!$rc)
        {
            return ('0', 'PDFCGI Write TMP File Failure - New Line');
        }
        if ($lcnt <= 10)
        {
            &crashed();

            return ('0', 'PDFCGI Write Page over Max Lines - Files Deleted');
        }
    }
    if ($ltype eq 'nc')
    {
        $lcnt = $lcnt;
        $rc   = print TMPFILE "$red $green $blue rg $lcol $nextf Td ($ldata) Tj\n";

        if (!$rc)
        {
            return ('0', 'PDFCGI Write TMP File Failure - New Line');
        }
        $rc = print TMPFILE "/$nfont $lfont Tf 1 0 $ital 1 10 $lcnt Tm\n";

        if (!$rc)
        {
            return ('0', 'PDFCGI Write TMP File Failure - New Line');
        }
        if ($lcnt <= 10)
        {
            &crashed();

            return ('0', 'PDFCGI Write Page over Max Lines - Files Deleted');
        }
    }
    if ($ltype eq 'np')
    {
        $lcnt  = '760';
        $lcnt  = '760' if ($psize eq 'LE' && $porin eq 'PO');
        $lcnt  = '582' if ($psize eq 'LE' && $porin eq 'LA');
        $lcnt  = '810' if ($psize eq 'A4' && $porin eq 'PO');
        $lcnt  = '565' if ($psize eq 'A4' && $porin eq 'LA');

        $pagecnt++;

        # After reseting line count and incrementing page count output unique line for identification 
        # to tmp file

        $rc = print TMPFILE "XXXXXXXXXXNEW PAGE - $pagecnt\n";

        if (!$rc)
        {
            return ('0', 'PDFCGI Write TMP File Failure - New Page');
        }
        $rc = print TMPFILE "$red $green $blue rg $lcol $nextf Td($ldata) Tj\n";

        if (!$rc)
        {
            return ('0', 'PDFCGI Write TMP File Failure - New Line');
        }
        $rc = print TMPFILE "/$nfont $lfont Tf 1 0 $ital 1 10 $lcnt Tm\n";

        if (!$rc)
        {
            return ('0', 'PDFCGI Write TMP File Failure - New Line');
        }
    }
    if ($ltype eq 'im')
    {
        my ($pt1,$pt2,$pt3) = split (/\s/, $ldata);

        $lcnt = $lcnt - $pt3 - 5;
        $rc = print TMPFILE "IMAGEXXXXXXXXX $ldata $lcnt $lcol\n";
        $lcnt = $lcnt - 20;
    }
    # 1.04 Added columns for images type CM.
    if ($ltype eq 'cm')
    {
        my ($pt1,$pt2,$pt3) = split (/\s/, $ldata);

        $rc = print TMPFILE "IMAGEXXXXXXXXX $ldata $lcnt $lcol\n";
    }
    return ('1', "PDFREP Page Data Succesful");
}

#-----------------------------------------------------------------------------#
# SUB INCLUDE IMAGE                                                           #
#                                                                             #
# This sub includes a png image file to enable the use of the chart module    #
# to generate the required graphs and include them                            #
#-----------------------------------------------------------------------------#

sub include_image
{
    my ($pgmname, $iname, $image, $iwidth, $iheight, $type, $ipath) = @_;

    my $tmpdata = "$iname" . ":::" . "$image" . ":::" . "$iheight" . ":::" . "$iwidth" . ":::" . 
                  "$type" . ":::". "$ipath";

    push(@image_name, $tmpdata);

    # Return a succesful code

    return ('1', 'PDFREP Include Image Succesful');
}

#-----------------------------------------------------------------------------#
# SUB WRITEPDF                                                                #
#                                                                             #
# This is the final subroutine called from the caling program. It writes the  #
# PDF file from all the data input so far with all the references and so on   #
# It is interesting in the fact that it has to be called but it also ends the #
# PDFREP program's output- Don't try adding anymore after this                #
# ----------------------------------------------------------------------------#

sub writepdf
{
    # Lets start by closing and opening the TMPFILE which stores the page data.
    # To get it back to the first record.

    my ($pgmname, $psize, $porin) = @_;

    print TMPFILE "XXXXXXXXXXNEW END - 0\n";

    close(TMPFILE)               || warn return ('0' , "File Close failure A1 - $temptyp - $!");
    open (TMPFILE, "< $temptyp") || warn return ('0' , "File open failure - $temptyp - $!");

    # Now it's time to initialise the variables which are used to output the data
    # @pdprintline - this is used to store the data ready for printing. Local because not needed elsewhere

    my @pdprintline;
    my $lcnt = '0';
    my $item;
    my $pobjcnt = '0';

    # read first line of page data file and split it down

    my $firstln = <TMPFILE>;
    chomp $firstln;

    my ($pt1, $pt2, $pt3, $pt4, $pt5, $pt6) = split(/\s/, $firstln);

    # Write the Pages Header Object Which calculates the total number of objects and the page objects
    # It works on 2 objects per page and 1 object per font thus needing these object numbers
    # OK Calculate the page and font object numbers.
    # Use two hashes to store the data.
    # Added include images

    my %pagenum;
    my %fontnum;
    my %imagnum;
    my $procset;
    my $tmpcnt  = '0000';
    my $tmpobj  = $objcount + 2;

    while ($pagecnt > $tmpcnt)
    {
        $pagenum{$tmpcnt} = $tmpobj;
        $tmpcnt++;
        while (length($tmpcnt) < 4)
        {
            $tmpcnt = "0" . $tmpcnt;
        }
        $tmpobj = $tmpobj + 2;
    }
    foreach $item (@image_name)
    {
        my ($pta, @rest) = split (/:::/, $item);
        $imagnum{$pta} = $tmpobj;
        $tmpobj++;
    }
    # set the proset object number

    $procset = $tmpobj;
    $tmpobj++;

    foreach $item (sort keys(%fontstr))
    {
        $fontnum{$item} = $tmpobj;
        $tmpobj++;
    }
    # Start of new object add object count, should = 3 for this object.
    # Update Offset for this object.

    $objcount++;
    $tmpoffs = $objcount;

    while (length($tmpoffs) < 4)
    {
        $tmpoffs = "0" . $tmpoffs;
    }
    #(length($objcount) < 2) ? ($tmpoffs = '0' . $objcount) : ($tmpoffs = $objcount);
    $pdoffs{$tmpoffs}   = $offset;
    $pobjcnt            = $objcount;

    $pdprintline[$lcnt] = "$objcount 0 obj";
    $lcnt++;
    $pdprintline[$lcnt] = "<<";
    $lcnt++;
    $pdprintline[$lcnt] = "/Type /Pages";
    $lcnt++;

    # Setup the kids info

    $pdprintline[$lcnt] = "/Kids [";

    $tmpcnt = 0;

    foreach $item (sort keys(%pagenum))
    {
        ($tmpcnt > 0) ? ($pdprintline[$lcnt] = $pdprintline[$lcnt] . " $pagenum{$item} 0 R")
                      : ($pdprintline[$lcnt] = $pdprintline[$lcnt] . " $pagenum{$item} 0 R");

        $tmpcnt++;
    }
    $pdprintline[$lcnt] = $pdprintline[$lcnt] . "]";
    $lcnt++;
    $pdprintline[$lcnt] = "/Count $pagecnt";
    $lcnt++;
    $pdprintline[$lcnt] = ">>";
    $lcnt++;
    $pdprintline[$lcnt] = "endobj";
    $lcnt++;

    # Write the Pages object out

    foreach $item (@pdprintline)
    {
        $rc = print PDFFILE "$item\015\012";

        $offset = $offset + length($item) + 2;

        if (!$rc)
        {
            return ('0', 'PDFREP Write PDF File Failure - Pages Object');
        }
    }
    # OK now it's time to produce the page data output which will use the font's defined within the
    # Page heading and the temporary file to retrieve the actual page data.

    $tmpcnt            = '0';

    while ($pagecnt > $tmpcnt)
    {
        $objcount++;
        $tmpoffs = $objcount;

        while (length($tmpoffs) < 4)
        {
            $tmpoffs = "0" . $tmpoffs;
        }
        #(length($objcount) < 2) ? ($tmpoffs = '0' . $objcount) : ($tmpoffs = $objcount);
        $pdoffs{$tmpoffs}   = $offset;
        $lcnt               = '0';
        undef @pdprintline;

        $pdprintline[$lcnt] = "$objcount 0 obj";
        $lcnt++;
        $pdprintline[$lcnt] = "<<";
        $lcnt++;
        $pdprintline[$lcnt] = "/Type /Page";
        $lcnt++;
        $pdprintline[$lcnt] = "/Parent $pobjcnt 0 R";
        $lcnt++;
        $pdprintline[$lcnt] = "/Resources << ";
        $pdprintline[$lcnt] = $pdprintline[$lcnt] . "/ProcSet $procset 0 R";

        # Setup the font references for for the page

        my $tmpk = keys (%fontnum);
        if ($tmpk > 0)
        {
            $pdprintline[$lcnt] = $pdprintline[$lcnt] . " /Font <<";

            foreach $item (sort keys(%fontnum))
            {
                $pdprintline[$lcnt] = $pdprintline[$lcnt] . " /$item $fontnum{$item} 0 R";
            }
            $pdprintline[$lcnt] = $pdprintline[$lcnt] . " >>";
        }
        # Setup the image references for for the page

        $tmpk = keys (%imagnum);
        if ($tmpk > 0)
        {
            $pdprintline[$lcnt] = $pdprintline[$lcnt] . "/XObject <<";

            foreach $item (sort keys(%imagnum))
            {
                $pdprintline[$lcnt] = $pdprintline[$lcnt] . " /$item $imagnum{$item} 0 R";
            }

            $pdprintline[$lcnt] = $pdprintline[$lcnt] . " >>";
        }
        $pdprintline[$lcnt] = $pdprintline[$lcnt] . " >>";
        $lcnt++;
        my $ncnt = $objcount + 1;

        if ($psize eq 'LE' && $porin eq 'PO')
        {
            $pdprintline[$lcnt] = "/MediaBox [0 0 612 792]";
        }
        if ($psize eq 'LE' && $porin eq 'LA')
        {
            $pdprintline[$lcnt] = "/MediaBox [0 0 792 612]";
        }
        if ($psize eq 'A4' && $porin eq 'PO')
        {
            $pdprintline[$lcnt] = "/MediaBox [0 0 595 842]";
        }
        if ($psize eq 'A4' && $porin eq 'LA')
        {
            $pdprintline[$lcnt] = "/MediaBox [0 0 842 595]";
        }
        $lcnt++;
        $pdprintline[$lcnt] = "/Contents  $ncnt 0 R";
        $lcnt++;
        $pdprintline[$lcnt] = ">>";
        $lcnt++;
        $pdprintline[$lcnt] = "endobj";
        $lcnt++;

        # Write the Page object out

        foreach $item (@pdprintline)
        {
            $rc = print PDFFILE "$item\015\012";

            $offset = $offset + length($item) + 2;

            if (!$rc)
            {
                return ('0', 'PDFREP Write PDF File Failure - Page $objcount Object');
            }
        }
        undef @pdprintline;
        $lcnt = '0';

        # So now it's time to write out the page data.
        # Lets get the page data for the current page.

        $ncnt = $tmpcnt + 1;

        if ($pt1 eq 'XXXXXXXXXXNEW' && $pt4 eq $ncnt)
        {
            $objcount++;
            $pdlgth = 0;
            $tmpoffs = $objcount;

            while (length($tmpoffs) < 4)
            {
                $tmpoffs = "0" . $tmpoffs;
            }
            #(length($objcount) < 2) ? ($tmpoffs = '0' . $objcount) : ($tmpoffs = $objcount);
            $pdoffs{$tmpoffs}   = $offset;
            $pdprintline[$lcnt] = "endobj";
            $lcnt++;
            $pdprintline[$lcnt] = "endstream";
            $lcnt++;
            $pdprintline[$lcnt] = "ET";
            $pdlgth = $pdlgth + length($pdprintline[$lcnt]) + 2;
            $lcnt++;
            while (<TMPFILE>)
            {
                chomp $_;
                my $ldata = $_;

                ($pt1, $pt2, $pt3, $pt4, $pt5, $pt6) = split (/\s/, $ldata);
                $ncnt = $tmpcnt + 1;

                if ($pt1 =~ m/IMAGEXXXXXXXXX/)
                {
                    $pdprintline[$lcnt] = "BT";
                    $pdlgth = $pdlgth + length($pdprintline[$lcnt]) + 2;
                    $lcnt++;

                    $pdprintline[$lcnt] = "q $pt3 0 0 $pt4 $pt6 $pt5 cm /$pt2 Do Q";
                    $pdlgth = $pdlgth + length($pdprintline[$lcnt]) + 2;
                    $lcnt++;
                    $pdprintline[$lcnt] = "ET";
                    $pdlgth = $pdlgth + length($pdprintline[$lcnt]) + 2;
                    $lcnt++;
                    next;
                }
                elsif ($pt1 eq 'XXXXXXXXXXNEW' && $pt4 ne $ncnt)
                {
                    $pdprintline[$lcnt] = "BT";
                    $pdlgth = $pdlgth + length($pdprintline[$lcnt]) + 2;
                    $lcnt++;
                    $pdprintline[$lcnt] = "stream";
                    $lcnt++;
                    $pdprintline[$lcnt] = "<< /Length $pdlgth >>";
                    $lcnt++;
                    $pdprintline[$lcnt] = "$objcount 0 obj";
                    $lcnt++;

                    my $tmplgth = @pdprintline;
                    $tmplgth--;
                    my $tmplgt1 = 0;
                    my @pdprintlin1;

                    while ($tmplgth >= 0)
                    {
                        $pdprintlin1[$tmplgt1] = $pdprintline[$tmplgth];
                        $tmplgth--;
                        $tmplgt1++;
                    }
                    foreach $item (@pdprintlin1)
                    {
                        $rc = print PDFFILE "$item\015\012";

                        $offset = $offset + length($item) + 2;

                        if (!$rc)
                        {
                            return ('0', 'PDFREP Write PDF File Failure - Page $objcount Data');
                        }
                    }
                    last;
                }
                else
                {
                    $pdprintline[$lcnt] = $ldata . "";

                    $pdlgth = $pdlgth + length($pdprintline[$lcnt]) + 2;
                    $lcnt++;
                }
            }
        }
        $tmpcnt++;	
    }
    # Include image definitions go here after pages and before fonts

    foreach $item (@image_name)
    {
        my ($pt1, $pt2, $pt3, $pt4, $pt5, $i_path) = split(/:::/, $item);

        undef @pdprintline;
        $lcnt        = '0';
        $objcount++;
        $tmpoffs = $objcount;

        while (length($tmpoffs) < 4)
        {
            $tmpoffs = "0" . $tmpoffs;
        }
        #(length($objcount) < 2) ? ($tmpoffs = '0' . $objcount) : ($tmpoffs = $objcount);
        $pdoffs{$tmpoffs}   = $offset;

        $pdprintline[$lcnt] = "$objcount 0 obj";
        $lcnt++;
        $pdprintline[$lcnt] = "<<";
        $lcnt++;
        $pdprintline[$lcnt] = "/Type /XObject";
        $lcnt++;
        $pdprintline[$lcnt] = "/Subtype /Image";
        $lcnt++;
        $pdprintline[$lcnt] = "/Name /$pt1";
        $lcnt++;
        $pdprintline[$lcnt] = "/Width $pt4";
        $lcnt++;
        $pdprintline[$lcnt] = "/Height $pt3";
        $lcnt++;

        my $iname = "$i_path". "$pt2";
        my $myImage;
        my $imout;
        my $imlgth = 0;

        open (INIMAGE, "< $iname");

        $pdprintline[$lcnt] = "/BitsPerComponent 8";
        $lcnt++;
        $pdprintline[$lcnt] = "/ColorSpace /DeviceRGB";
        $lcnt++;
        $pdprintline[$lcnt] = "/Filter /DCTDecode";
        $lcnt++;

        if ($pt5 eq 'jpg')
        {
            $myImage = newFromJpeg GD::Image(\*INIMAGE) || die;
        }
        elsif ($pt5 eq 'png')
        {
            $myImage = newFromPng GD::Image(\*INIMAGE) || die;
        }
        $imout = $myImage->jpeg(600);
        $imlgth = length($imout);

        close (INIMAGE);

        $pdprintline[$lcnt] = "/Length $imlgth";
        $lcnt++;
        $pdprintline[$lcnt] = ">>";
        $lcnt++;
        $pdprintline[$lcnt] = "stream";
        $lcnt++;
        $pdprintline[$lcnt] = "$imout";
        $lcnt++;
        $pdprintline[$lcnt] = "endstream";
        $lcnt++;
        $pdprintline[$lcnt] = "endobj";
        $lcnt++;

        foreach $item (@pdprintline)
        {
            $rc = print PDFFILE "$item\015\012";

            $offset = $offset + length($item) + 2;

            if (!$rc)
            {
                return ('0', 'PDFREP Write PDF File Failure - Font $objcount Object');
            }
        }
    }
    # set the procset area

    undef @pdprintline;
    $lcnt        = '0';
    $objcount++;

    $tmpoffs = $objcount;

    while (length($tmpoffs) < 4)
    {
        $tmpoffs = "0" . $tmpoffs;
    }
    #(length($objcount) < 2) ? ($tmpoffs = '0' . $objcount) : ($tmpoffs = $objcount);
    $pdoffs{$tmpoffs}   = $offset;

    $pdprintline[$lcnt] = "$objcount 0 obj";
    $lcnt++;
    $pdprintline[$lcnt] = "[/PDF]";
    $lcnt++;
    $pdprintline[$lcnt] = "endobj";
    $lcnt++;

    foreach $item (@pdprintline)
    {
        $rc = print PDFFILE "$item\015\012";

        $offset = $offset + length($item) + 2;

        if (!$rc)
        {
            return ('0', 'PDFREP Write PDF File Failure - ProcSet $objcount Object');
        }
    }
    # Well were getting there guess what comes now
    # Your right it's the font definitions.

    foreach $item (sort keys(%fontstr))
    {
        undef @pdprintline;
        $lcnt        = '0';
        $objcount++;
        $tmpoffs = $objcount;

        while (length($tmpoffs) < 4)
        {
            $tmpoffs = "0" . $tmpoffs;
        }
        #(length($objcount) < 2) ? ($tmpoffs = '0' . $objcount) : ($tmpoffs = $objcount);
        $pdoffs{$tmpoffs}   = $offset;

        $pdprintline[$lcnt] = "$objcount 0 obj";
        $lcnt++;
        $pdprintline[$lcnt] = "<<";
        $lcnt++;
        $pdprintline[$lcnt] = "/Type /Font";
        $lcnt++;
        $pdprintline[$lcnt] = "/Subtype /Type1";
        $lcnt++;
        $pdprintline[$lcnt] = "/Name /$item";
        $lcnt++;
        $pdprintline[$lcnt] = "/BaseFont /$fontstr{$item}";
        $lcnt++;

        # Version 2 make more usable Encoding.
#        $pdprintline[$lcnt] = "/Encoding /MacRomanEncoding";
        $pdprintline[$lcnt] = "/Encoding /WinAnsiEncoding";
        $lcnt++;
        $pdprintline[$lcnt] = ">>";
        $lcnt++;
        $pdprintline[$lcnt] = "endobj";
        $lcnt++;

        foreach $item (@pdprintline)
        {
            $rc = print PDFFILE "$item\015\012";

            $offset = $offset + length($item) + 2;

            if (!$rc)
            {
                return ('0', 'PDFREP Write PDF File Failure - Font $objcount Object');
            }
        }
    }
    # Now lets do the cross reference and trailer data bits

    &xreftrl();
    &trailer();

    close(PDFFILE) || warn return ('0' , "File close failure - $filetyp - $!");
    close(TMPFILE) || warn return ('0' , "File close failure - $temptyp - $!");

    return ("1", "PDFREP Write PDF Data Succesful");
}

#-----------------------------------------------------------------------------#
# SUB XREFTRL                                                                 #
#                                                                             #
# This sub is the cross reference creation sub. It takes all the input and    #
# places the required cross reference into the PDF file no parameters are     #
# passed or required.                                                         #
#-----------------------------------------------------------------------------#

sub xreftrl
{
    my @xrefdata;
    my $item     = '';
    my $xcnt     = '0';
    my $tlcnt = 0;
    $objcount++;
    $xrefdata[0] = "xref";
    $tlcnt++;
    $xrefdata[1] = "0 $objcount";
    $tlcnt++;
    $startxref = $offset;
    $xrefdata[2] = "0000000000 65535 f";
    $tlcnt++;

#   Version 2 resolve aany number of pages.

#    foreach $item (sort keys(%pdoffs))
    foreach $item (sort {$a <=> $b} keys(%pdoffs))
    {
        my $tdata = $pdoffs{$item};
        my $tlgth = length($tdata);

        while ($tlgth < 10)
        {
            $tdata = "0$tdata";
            $tlgth++;
        }
        $xrefdata[$tlcnt] = "$tdata 00000 n";
        $offset = $offset + length($xrefdata[$tlcnt]);
        $tlcnt++;
    }
    foreach $item (@xrefdata)
    {
        $rc = print PDFFILE "$item\015\012";

        # Calculate the new offset afer calculating the amount of characters written.

        if (!$rc)
        {
            return ('0', 'PDFREP Write PDF File Failure - Cross Reference');
        }
    }
    return ('1', "PDFREP Cross Reference Succesful");
}

#-----------------------------------------------------------------------------#
# SUB TRAILER                                                                 #
#                                                                             #
# This receives the appropriate information from the calling program and      #
# uses the already opened pdf file to add the trailer record of the file      #
# It is the final part of the PDF file and contains all the required number   #
# of objects etc. It returns the required messages and status before closing  #
# The PDF File                                                                #
#-----------------------------------------------------------------------------#

sub trailer
{
    my ($callpgm, @rubbish) = @_;

    print PDFFILE "trailer\015\012";
    print PDFFILE "<<\015\012";
    print PDFFILE "/Size $objcount\015\012";
    print PDFFILE "/Root $rootobj 0 R\015\012";
    if ($infoobj)
    {
        print PDFFILE "/Info $infoobj 0 R\015\012";
    }
    print PDFFILE ">>\015\012";
    print PDFFILE "startxref\015\012";
    print PDFFILE "$startxref\015\012";
    print PDFFILE "%%EOF\015\012";

    return ('1', 'PDFREP Trailer Succesful');
}

#-----------------------------------------------------------------------------#
# SUB CRASHED                                                                 #
#                                                                             #
# This does not receive any parameters all it does is an unlink on the open   #
# files and then closes the said files which should release any links and     #
# physical disc space used. It is called from either the PDFREP package or    #
# can be called from the controlling program in case of ending required       #
#-----------------------------------------------------------------------------#

sub crashed
{
    close(PDFFILE) || warn return ('0' , "File close failure - $filetyp - $!");
    close(TMPFILE) || warn return ('0' , "File close failure - $temptyp - $!");

    $rc = unlink $filetyp;

    if (!$rc)
    {
        return ('0', "CANNOT DELETE - $filetyp");
    }
    $rc = unlink $temptyp;

    if (!$rc)
    {
        return ('0', "CANNOT DELETE - $temptyp");
    }
    return ('1', "FILE DELETION AND CLOSE WORKED SUCCESFULLY");
}
1;
