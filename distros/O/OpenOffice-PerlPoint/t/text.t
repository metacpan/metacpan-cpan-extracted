

# = HISTORY SECTION =====================================================================

# ---------------------------------------------------------------------------------------
# version | date     | author   | changes
# ---------------------------------------------------------------------------------------
# 0.02    |03.07.2005| JSTENZEL | added cleanup;
#         |          | JSTENZEL | image buffer directories now located under t/;
# 0.01    |19.06.2005| JSTENZEL | new.
# ---------------------------------------------------------------------------------------

# an OpenOffice::PerlPoint test script

# pragmata
use strict;

# load modules
use File::Path;
use Text::Diff;
use OpenOffice::PerlPoint;
use Test::More qw(no_plan);



# define a meta data template
my $template=<<'EOT';

// document description, packed into a condition for readability
? 0

 Description: {$metaData{description}}

 Format:      This file is written in PerlPoint (www.sf.net/projects/perlpoint).
              It can be translated into several documents and formats, see the
              PerlPoint documentation for details.

              The original source of this document was stored by
              {$tools{generator}}.

              It was converted into PerlPoint by {$tools{converter}}.

 Source:      {$source}.

 Author:      {$metaData{author}}

 Copyright:   {$metaData{copyright}}

 Version:     {$metaData{version}}

// start document
? 1


// ------------------------------------------------------------

// set document data
$docTitle={$metaData{title}}

$docSubtitle={$metaData{subject}}

$docDescription={$metaData{description}}

// ------------------------------------------------------------

EOT



# Open Office 1.0 format
{
 # build a converter object
 my $oo2pp=new OpenOffice::PerlPoint(
                                     file               => 't/text.sxw',
                                     imagebufferdir     => 't/ibd1',
                                     metadataTemplate   => $template,
                                     userdefinedDocdata => [qw(author copyright version)],
                                    );

 # convert document
 my $perlpoint=$oo2pp->oo2pp;

 # check result
 is(diff('t/text-sxw.pp', \$perlpoint), '', 'OO Text 1.0');
}


# Open Office 2.0 (OASIS Open Document) format
{
 local($TODO)="Open Document support is incomplete at the moment.";

 # build a converter object
 my $oo2pp=new OpenOffice::PerlPoint(
                                     file => 't/text.odt',
                                     imagebufferdir => 't/ibd2',
                                     metadataTemplate   => $template,
                                     userdefinedDocdata => [qw(author copyright version)],
                                    );

 # convert document
 my $perlpoint=$oo2pp->oo2pp;

 # check result
 is(diff('t/text-odt.pp', \$perlpoint), '', 'OASIS Open Document');
}

# clean up
rmtree("t/$_") for qw(ibd1 ibd2);


