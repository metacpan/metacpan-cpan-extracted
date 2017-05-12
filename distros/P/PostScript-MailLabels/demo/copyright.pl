#!/usr/bin/perl -w

#		Build labels for photographic negative sheets

use PostScript::MailLabels 2.0;

$labels = PostScript::MailLabels->new;


$labels->labelsetup( 
	 Units => 'metric',  # Means cm
	 PaperSize => 'A4',  # This is Europe...
	 #   printable area on physical page - these numbers represent border widths
	 Printable_Left   => 0.0,
	 Printable_Right  => 0.0,
	 Printable_Top    => 0.0,
	 Printable_Bot    => 0.0,
	 #    define where the labels live (ideally)
	 Output_Top       => 6.0, # Measured
	 Output_Left      => 3.125, # Measured
	 Output_Width     => 4.60, # Spec
	 Output_Height    => 1.111, # Spec
	 X_Gap            => 0.475, # Measured
	 Y_Gap            => 0.160, # Measured and adjusted
	 Number           => 42, # Spec
	 Columns          => 3,  # Measured
	 #    Adjustments for printer idiosyncracies
	 X_Adjust         => 0.1,
	 Y_Adjust         => 0.1,
	 #    Other controls
	 Postnet          => 'no', # No barcodes
	 Font             => 'Helvetica',
	 FontSize         => 10,
	 FirstLabel       => 1,  # We set this again below
	 Avery            => undef,
	 Encoding         => 'ISOLatin1Encoding', # for copyright sign
				   );

#	Let's define the labels for 35 mm slides

$labels->editcomponent('number', 'name', 'no', 0, 'Helvetica');
$labels->editcomponent('title',  'name', 'no', 1, 'Helvetica');
$labels->editcomponent('author', 'name', 'no', 2, 'Helvetica');

#       Now lets create a label definition
#       first clear the old (default) definition
$labels->definelabel('clear');
#                   line number, component list
$labels->definelabel(0,'number','title');
$labels->definelabel(1,'author',);

my $copyright = pack "c a17", 169, " Allan Engelhardt" ;
#my $copyright = '© Allan Engelhardt' ;
my @labels = (
	[1,'nice slide', $copyright ],
	[2,'nicer slide',$copyright ],
	[3,'very nice slide', $copyright ],
);

$output = $labels->makelabels(\@labels);
open (OUT,">slides.ps") || die "Can't open slides.ps, $!\n";
print OUT $output;
close OUT;
print "\n******* slide output in  slides.ps *******\n";

1;
# Look in 
# man iso_8859-1
# to find the special characters and their encoding.

# Note that you have to use Helvetica to get the copyright symbol, 
# Times-Roman doesn't seem to support it.
