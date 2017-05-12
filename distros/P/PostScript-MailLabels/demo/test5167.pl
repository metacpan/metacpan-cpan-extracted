#!/usr/bin/perl -w

#		This shows the capabilities of the program...

use PostScript::MailLabels 2.1;

$labels = PostScript::MailLabels->new;

#	Here is how to list all th Avery data
 # layout=>[paper-size,[list of product codes], description,
 #          number per sheet, left-offset, top-offset, width, height]
 #			distances measured in points

my %avery = %{$labels->averydata};
print "\n****** Avery(tm) data ******\n";
foreach (keys %avery) {
	print "$_ : $avery{$_}->[0] : ",
	       join(', ',@{$avery{$_}->[1]})," : ",
		   join(' : ',@{$avery{$_}}[2-7]),"\n";
}


#	Here are some more utilities

#	Simple setup using predefined Avery label
$labels -> labelsetup(
			Avery		=> $labels->averycode('8167'),
			PaperSize 	=> 'letter',
			Font		=> 'Times-Roman',
			);

print "\n                 num, left, top, width, height\n";
print "label description : ", $labels->{SETUP}->{number}, " : ",
                              $labels->{SETUP}->{output_left}, " : ",
                              $labels->{SETUP}->{output_top}, " : ",
                              $labels->{SETUP}->{output_width}, " : ",
                              $labels->{SETUP}->{output_height}, "\n";


#	We can fiddle the components...

#	Lets make the lname (lastname) bold-faced
print "\n******* make the lname field boldfaced *******\n";
print "lname : ",join(' : ',@{$labels->editcomponent('lname')}),"\n";
$labels->editcomponent('lname', 'name', 'no', 1, 'Times-Bold' );
print "lname : ",join(' : ',@{$labels->editcomponent('lname')}),"\n";

#	Lets switch the default ordering on the label from first-last to last-first
print "\n******* swap order from first-last to last-first *******\n";
print "Line 1 : ",join(' : ',@{$labels->definelabel(0)}),"\n";
$labels->definelabel(0,'lname','fname');
print "Line 1 : ",join(' : ',@{$labels->definelabel(0)}),"\n";

#		print calibration sheet, in metric

$labels->labelsetup( Units =>'metric');
my $output = $labels->labelcalibration;
open (FILE,"> calibration.ps") || warn "Can't open calibration.ps, $!\n";
print FILE $output;
close FILE;
print "\n******* metric Letter sized calibration sheet in calibration.ps *******\n";

#		adjust printable area and draw test boxes

$output = $labels->labeltest;
open (FILE,"> boxes.ps") || warn "Can't open boxes.ps, $!\n";
print FILE $output;
close FILE;
print "\n******* Letter sized test boxes sheet in boxes.ps *******\n";

#########################################################################
#	Build a test address array
exit;
my @label;
for (my $i=0; $i<=10; $i++) {
	push @label,"label $i";
}

#	Set up a few things...

$setup = $labels -> labelsetup( Font => 'Helvetica');

$output = $labels->makelabels(\@label);
open (OUT,">labeltest2.ps") || die "Can't open labeltest2.ps, $!\n";
print OUT $output;
close OUT;
print "\n******* label output in  labeltest2.ps *******\n";

1;

