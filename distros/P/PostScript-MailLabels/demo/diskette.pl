#!/usr/bin/perl -w

#	This is an example where we create a whole new set of components
#	that are appropriate for labeling software diskettes, and also
#	define the labels appropriately (with blank lines).

use PostScript::MailLabels 2.0;

$labels = PostScript::MailLabels->new;

#	Simple setup using predefined Avery label (I happen to know this is the
#	3.5 inch diskette label
$labels -> labelsetup(
			Avery		=> 5196,
			PaperSize 	=> 'letter',
			Font		=> 'Times-Roman',
			);

#	turn off barcode, get a big font, start labels at beginning
my $setup = $labels->labelsetup( 
					PostNet		=> 'no',
					FontSize 	=> 16,
					FirstLabel	=> 1,
				   );

#	here's what the canned diskette label definition looks like
print "\n\nLabel definition for diskette labels\n";
print "                  num, left, top, width, height\n";
print "label description : ", $setup->{number}, " : ",
                              $setup->{output_left}, " : ",
                              $setup->{output_top}, " : ",
                              $setup->{output_width}, " : ",
                              $setup->{output_height}, "\n";

#	Add some new components
#                   component-name, type, adjustable?, index, font
#	where index is position in input array
$labels->editcomponent('pgm_name',   'name', 'no', 0, 'Times-Bold');
$labels->editcomponent('version',    'name', 'no', 1, 'Times-Bold');
$labels->editcomponent('author',     'name', 'no', 2, 'Times-Roman');
$labels->editcomponent('blank',      'name', 'no', 6, 'Times-Roman');
$labels->editcomponent('comments-1', 'name', 'no', 3, 'Times-Roman');
$labels->editcomponent('comments-2', 'name', 'no', 4, 'Times-Roman');
$labels->editcomponent('comments-3', 'name', 'no', 5, 'Times-Roman');

#	Let's prove we added the new ones
print "\n\nList of the components, including the new ones\n";
print join(' : ',@{$labels->editcomponent()}),"\n";

#	Now lets create a label definition
#	first clear the old (default) definition
$labels->definelabel('clear');
#                   line number, component list
$labels->definelabel(0,'pgm_name','version');
$labels->definelabel(1,'blank',);
$labels->definelabel(2,'author',);
$labels->definelabel(3,'blank',);
$labels->definelabel(4,'comments-1',);
$labels->definelabel(5,'comments-2',);
$labels->definelabel(6,'comments-3',);

#	I defined a component called 'blank' which I use for inserting
#	blank lines, and I load the aray with a final entry which is a
#	single space that I will use for the blank. 

#	now load up my data to be printed...
my @titles;
my @title;
my $indx = 0;
foreach (<DATA>) {
	chomp;
	if ($indx%7 == 0) {
		@title = $_;
	}
	elsif ($indx%7 >= 1 && $indx%7 <= 5) {
		push @title,$_;
	}
	elsif ($indx%7 == 6) {
		push @titles,[@title, " "]; # add a blank field at end for blank
	}
	$indx++;
}

print "\n\n-------- input data -------\n";
foreach (@titles) {
	print "Titles : $_->[0] $_->[1] $_->[2] $_->[3] \n";
}
print "\n******* Output is in diskette.ps. View with ghostscript *******\n";

#	Make them labels!

$output = $labels->makelabels(\@titles);
open (OUT,">diskette.ps") || die "Can't open diskette.ps, $!\n";
print OUT $output;

1;

__DATA__
Wizbang
version 3.2
Ferd Burfle
A wonderful addition 
to your collection


Perl
version 5.2
Larry Wall
All you need to 
solve your problems


Word
version 6.0
Microsoft
Why pay less for more 
when you can pay more 
for less?

