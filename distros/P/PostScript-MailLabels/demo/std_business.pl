#!/usr/bin/perl -w

#		Using the USPS standard labeling, with a mix of domestic
#		and international mailings
#		Thanks to Andrew Smith for the suggestions

use PostScript::MailLabels 2.0;

$labels = PostScript::MailLabels->new;

#	Label setup
$labels->labelsetup( 
					Units 			=> 'English',
					PaperSize   	=> 'Letter',

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

#	Add the USPS standard components

$labels->editcomponent('endorsement',      'name',   'no',  0, 'Helvetica');
$labels->editcomponent('keylinedata',      'name',   'no',  1, 'Helvetica');
$labels->editcomponent('mailstop',         'name',   'no',  2, 'Helvetica');
$labels->editcomponent('attentionline',    'name',   'no',  3, 'Helvetica');
$labels->editcomponent('individualtitle',  'name',  'yes',  4, 'Helvetica');
$labels->editcomponent('functionaltitle',  'name',  'yes',  5, 'Helvetica');
$labels->editcomponent('groupname',        'name',  'yes',  6, 'Helvetica');
$labels->editcomponent('firmname',         'name',   'no',  7, 'Helvetica');
$labels->editcomponent('deliveryaddress',  'road',  'yes',  8, 'Helvetica');
$labels->editcomponent('city',             'name',   'no',  9, 'Helvetica');
$labels->editcomponent('state',            'name',   'no', 10, 'Helvetica');
$labels->editcomponent('zip',              'place', 'yes', 11, 'Helvetica');
$labels->editcomponent('postnet',          'bar',   'yes', 11, 'Helvetica');
$labels->editcomponent('country',          'name',   'no', 12, 'Helvetica');

#	define the label layout

#	Clear default definition first
$labels->definelabel('clear');
#                   line number, component list
$labels->definelabel(0,'endorsement',);
$labels->definelabel(1,'keylinedata',);
$labels->definelabel(2,'postnet',);
$labels->definelabel(3,'mailstop',);
$labels->definelabel(4,'attentionline',);
$labels->definelabel(5,'individualtitle',);
$labels->definelabel(6,'functionaltitle',);
$labels->definelabel(7,'groupname',);
$labels->definelabel(8,'firmname',);
$labels->definelabel(9,'deliveryaddress',);
$labels->definelabel(10,'city','state','zip',);
$labels->definelabel(11,'country',);


#########################################################################
#	Build a test address array
# address array elements are : first,last,street_addr,city,state,zip
my @address;
my @addrs;
foreach (<DATA>) {
	chomp;
	if (/^$/) {
		push @addrs, [@address];
		@address = ();
	}
	else {
		if (/^X$/) {
			push @address,'';
		}
		else {
			push @address, $_;
		}
	}
}

print "******* Adresses input *******\n";
foreach (@addrs) {
	print "\n","-"x10,"\n",join("\n",@{$_});
}

#	Set up a few things...

$setup = $labels -> labelsetup( Font => 'Helvetica');
$setup = $labels ->	labelsetup( Output_Width => 2.625), 
$setup = $labels ->	labelsetup( Columns => 3), 

$output = $labels->makelabels(\@addrs);
open (OUT,">labeltest.ps") || die "Can't open labeltest.ps, $!\n";
print OUT $output;
close OUT;
print "\n******* label output in  labeltest.ps *******\n";

1;

__DATA__
X
X
X
John and Jane Doe
X
X
X
X
1234 Robins Nest Sitting In a Tree Ave 
Katy
Tx
77453
X

X
X
X
William Clinton
President
X
Executive Branch
US Government
1300 Pennsylvania Ave.
Washington
DC
10000
USA

#BXNHJVF********C002
#ABCDEFGHIJKLMNO3#/12345678
MSC 4567ABCD
MS MILDRED DOE
Professional Engineer
Design Engineering Division
Brake Control Division
Big Business Incorporated
12 E Business LN STE 209
Kryton
TN
38188-0002
USA

X
X
X
Ferd Burfle
Professional Gadabout
X
X
Tiny Company Ltd
123 Small Drive
Epsom
Surrey
4E-2P
UK

