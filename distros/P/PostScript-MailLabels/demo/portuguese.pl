#!/usr/bin/perl -w

#	 Thanks to Nuno Faria for supplying the prototype for this script,
#	and more importantly, the requirements *he* needed to do the job.

#	This is an example of generating mailing labels in Portuguese. We
#	redefine the components of the label, redefine the layout of the
#	label, use A4 paper and metric units, and use the ISO Latin1
#	character encoding. Note that this will turn off the address
#	trimming logic, since I have problems calculating a string length
#	with ISOLatin1 characters - I just haven't worked out how to do it.

use strict;

use PostScript::MailLabels 2.0;

my $labels=PostScript::MailLabels->new;

$labels -> labelsetup(

   #    Other controls

   Postnet     => 'no',
   Font        => 'Helvetica',
   FontSize    => 10,
   Units       => 'metric',
   FirstLabel  => 1,

   #	Character encoding for Portuguese characters

   Encoding => 'ISOLatin1Encoding',

   #    paper size

   PaperSize   => 'A4',

   #    printable area on physical page

   Printable_Left  => 0.00,
   Printable_Right => 0.00,
   Printable_Top   => 0.0,
   Printable_Bot   => 0.0,

   #    define where the labels live (ideally)

   Output_Top     => 1.303,
   Output_Left    => 0.60,
   Output_Width   => 6.200,
   Output_Height  => 3.387,
   X_Gap          => 0.4,
   Y_Gap          => 0.0,
   Number         => 24,

   #    Adjustments for printer idiosyncracies

   X_Adjust        => 0.0,
   Y_Adjust        => 0.0,


   # set equal to the Avery(tm) product code, and the label description
   # will be updated from the database.
   Avery        => undef,
);

#	redefine the address components

$labels->editcomponent('fname',  'name', 'no',  0, 'Helvetica');
$labels->editcomponent('lname',  'name', 'no',  1, 'Helvetica');
$labels->editcomponent('street', 'name', 'no',  2, 'Helvetica');
$labels->editcomponent('city',   'name', 'no',  3, 'Helvetica');
$labels->editcomponent('state',  'name', 'no',  4, 'Helvetica');
$labels->editcomponent('zip',    'name', 'no',  5, 'Helvetica');

#	Redefine the address layout on the label
#	Clear default definition first
$labels->definelabel('clear');
#                   line number, component list
$labels->definelabel(0,'fname','lname');
$labels->definelabel(1,'street',);
$labels->definelabel(2,'city','state');
$labels->definelabel(3,'zip',);


#	Calibration plot

my $output = $labels->labelcalibration;
open (UT,">labels_out1.ps");
print UT $output;          
close UT;

#	Plot boxes

$output = $labels->labeltest;
open (UT,">labels_out2.ps");
print UT $output;          
close UT;

#	Set up address array
my @dado=('Nuno','Faria','Rua de não sei onde lá longe nº 12','Porto muito grande','Norte','1234-123 Vila Nova de Famalicão');

my @addresses;
for (my $i=0;$i<=28;$i++) {
	push @addresses,\@dado;
}

#	Generate address labels

$output = $labels->makelabels(\@addresses);
open (UT,">labels_out3.ps");
print UT $output;          
close UT;

#---------- end of example --------------
