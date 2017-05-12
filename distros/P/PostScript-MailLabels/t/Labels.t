#!/usr/bin/perl -w

#		test Labels.pm

print "1..3\n";

require PostScript::MailLabels;

$labels = PostScript::MailLabels->new;

$labels -> labelsetup(
					Avery		=> $labels->averycode(8460),
					PaperSize 	=> 'letter',
					Font		=> 'Times-Roman',
					);

#		print calibration sheet

	$labels->labelsetup( Units =>'metric');
  my $output = $labels->labelcalibration;
  open (VIEW,"> calibration.ps") || warn "Can't write file calibration.ps, $!\n";
  print VIEW $output;
  close VIEW;
  print "ok 1\n";

#		adjust printable area and draw test boxes

	$labels->labelsetup( Units => 'english',
						Printable_Left		=> 0.25,
						Printable_Right		=> 0.25,
						Printable_Top		=> 0.0,
						Printable_Bot		=> 0.55,
						
						Output_Top		=> 0.5, 
						Output_Width	=> 2.625, 
						Output_Height	=> 1.0, 
						X_Gap			=> 0.16,
						Y_Gap			=> 0.0,
						Number			=> 30,

						#	Adjustments for printer idiosyncracies

						X_Adjust		=> 0.05,
						Y_Adjust		=> 0.05,

	                   );

	$output = $labels->labeltest;
  open (VIEW,"> testboxes.ps") || warn "Can't write file testboxes.ps, $!\n";
  print VIEW $output;
  close VIEW;
  print "ok 2\n";

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
		print "Address : $_->[0] $_->[1] $_->[2] $_->[3] $_->[4]\n";
	}
	$setup = $labels -> labelsetup( Font => 'Helvetica');
	$setup = $labels -> labelsetup( FirstLabel => 7);
	$setup = $labels ->	labelsetup( Output_Width => 2.625), 

	$output = $labels->makelabels(\@addrs);
  open (VIEW,"> labelsheet.ps") || warn "Can't write file labelsheet.ps, $!\n";
  print VIEW $output;
  close VIEW;
  print "ok 3\n";

  print STDERR "\n\n","-"x30,"\n",
               "There are 3 files that have been created, calibration.ps, testboxes.ps, and labelsheet.ps\n",
               "Please view them with ghostview, ghostscript, or try printing them.\n";

1;

__DATA__
John and Jane (esq):Doe
1234 Robin Ave 
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

