#!/usr/bin/perl -w

#		This shows the capabilities of the program...

use PostScript::MailLabels 2.0;

$labels = PostScript::MailLabels->new;

#####################################################################`
#	Dumping information from the modules 
#####################################################################`

#	What address components are available?
print "\n****** components ******\n";
print join(' : ',@{$labels->editcomponent()}),"\n";

#	What is the current label layout?
print "\n****** layout ******\n";
my @layout = @{$labels->definelabel()};
foreach (@layout) {
	print join(' : ',@{$_}),"\n";
}

#	Here is how to list the available fonts
print "\n****** fonts ******\n";
@fonts = $labels->ListFonts;
foreach (@fonts) {
	print "$_\n";
}

#	Here is how to list the available papers
print "\n****** papers ******\n";
print join(' : ',@{$labels->papers}),"\n";

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

print "\nString width of 'this is a test' = ", 
		$labels->stringwidth("this is a test",)/72," inches\n";

my $setup = $labels -> labelsetup( Font => 'PostNetJHC');

print "\nzip code tests, 6,9, and 12 digit lengths barcodes:  ", 
		$labels->stringwidth("123456",)/72," : ",
		$labels->stringwidth("123456789",)/72," : ",
		$labels->stringwidth("123456789012",)/72,
		" inches\n";

print "\nPaper size Letter = ",($labels->papersize)->[0]," x ",
                             ($labels->papersize)->[1]," in points\n";

print "\nAvery(t) code for 8460 is >",$labels->averycode(8460),"<\n";

#	Simple setup using predefined Avery label
$labels -> labelsetup(
			Avery		=> $labels->averycode(8460),
			PaperSize 	=> 'letter',
			Font		=> 'Times-Roman',
			);

print "\n                 num, left, top, width, height\n";
print "label description : ", $setup->{number}, " : ",
                              $setup->{output_left}, " : ",
                              $setup->{output_top}, " : ",
                              $setup->{output_width}, " : ",
                              $setup->{output_height}, "\n";

#	More hands-on setup defining everything. Note that Columns is optional
$labels->labelsetup( 
					Units 			=> 'English',
					PaperSize   	=> 'A4',

					Printable_Left		=> 0.25,
					Printable_Right		=> 0.25,
					Printable_Top		=> 0.0,
					Printable_Bot		=> 0.55,
					
					Output_Top		=> 0.5, 
					Output_Left		=> 0.0,
					Output_Width	=> 2.625, 
					Output_Height	=> 1.0, 
					X_Gap			=> 0.16,
					Y_Gap			=> 0.0,
					Number			=> 30,
					Columns			=> 3,

					#	Adjustments for printer idiosyncracies

					X_Adjust	=> 0.05,
					Y_Adjust	=> 0.05,

					PostNet		=> 'yes',
					Font		=> 'Helvetica',
					FontSize 	=> 12,
					FirstLabel	=> 1,
				   );

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
# address array elements are : first,last,street_addr,city,state,zip
my @addrs;
my @address;
my $indx = 0;
foreach (<DATA>) {
	chomp;
	if ($indx%4 == 0) {
		@address = (split(':',$_));
	}
	elsif ($indx%4 == 1) {
		push @address,$_;
	}
	elsif ($indx%4 == 2) {
		push @address,(split(':',$_));
	}
	elsif ($indx%4 == 3) {
		push @addrs,[@address];
	}
	$indx++;
}

foreach (@addrs) {
	print "Address : $_->[0] $_->[1] $_->[2] $_->[3] $_->[4] $_->[5]\n";
}

#	Set up a few things...

$setup = $labels -> labelsetup( Font => 'Helvetica');
$setup = $labels -> labelsetup( FirstLabel => 25);
$setup = $labels ->	labelsetup( Output_Width => 2.625), 
$setup = $labels ->	labelsetup( Columns => 3), 

$output = $labels->makelabels(\@addrs);
open (OUT,">labeltest.ps") || die "Can't open labeltest.ps, $!\n";
print OUT $output;
close OUT;
print "\n******* label output in  labeltest.ps *******\n";

1;

__DATA__
John and Jane:Doe
1234 Robins Nest Sitting In a Tree Ave 
Katy:Tx:77453

William:Clinton
1300 Pennsylvania Ave.
Washington:DC:10000

Shirley:Temple
98765 Birch Point Drive 
Houston:TX:78450

Fred & June:Cleaver
11221 Beaver Rd 
Columbus:OH:07873-6305

Ernest and Julio:Gallo
1987 Chardonnay 
San Jose:CA:80880

Orville and Wilbur:Wright
7715 Kitty Hawk Dr 
Kitty Hawk:NC:87220

Ulysses:Grant
1856 Tomb Park Rd 
Washington:DC:10012

