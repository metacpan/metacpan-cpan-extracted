#!/usr/bin/perl -w

#		This shows the capabilities of the program...

use PostScript::MailLabels 2.26;

$labels = PostScript::MailLabels->new;

#####################################################################`
#	Dumping information from the modules 
#####################################################################`


#	Here is how to list the available papers
print "\n****** papers ******\n";
print join(' : ',@{$labels->papers}),"\n";

#	More hands-on setup defining everything. Note that Columns is optional
$labels->labelsetup( 
					Units 			=> 'English',
					PaperSize   	=> 'Userdefined',
                    Width           => 5,
                    Height          => 6,

					Printable_Left		=> 0.05,
					Printable_Right		=> 0.05,
					Printable_Top		=> 0.0,
					Printable_Bot		=> 0.55,
					
					Output_Top		=> 0.5, 
					Output_Left		=> 0.0,
					Output_Width	=> 2.4, 
					Output_Height	=> 1.0, 
					X_Gap			=> 0.1,
					Y_Gap			=> 0.0,
					Number			=> 8,
					Columns			=> 2,

					#	Adjustments for printer idiosyncracies

					X_Adjust	=> 0.05,
					Y_Adjust	=> 0.05,

					PostNet		=> 'yes',
					Font		=> 'Helvetica',
					FontSize 	=> 12,
					FirstLabel	=> 1,
				   );

#	We can fiddle the components...

#		print calibration sheet

my $output = $labels->labelcalibration;
open (FILE,"> calibration.ps") || warn "Can't open calibration.ps, $!\n";
print FILE $output;
close FILE;
print "\n******* Letter sized calibration sheet in calibration.ps *******\n";

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

