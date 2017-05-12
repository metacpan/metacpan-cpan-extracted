####################################################################
# Copyright @ 2002 Joseph A. White and The Institute for Genomic
#       Research (TIGR)
# All rights reserved.
####################################################################

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use SlideMap;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $sm = SlideMap->new(machine => 'IAS', x_spacing => 24, y_spacing => 25);

#$sm->diagnostics;

print "2..1";

$row=1; $col = 21;
my($plate_num,$well) = $sm->convert_spot($row,$col);
if($plate_num != 63 || $well != 19) {
	print "...failed\n";
} else {
	print "...OK\n";
}
#print "$row\t$col\t$plate_num\t$well\n";

$sm->fill_map;
$map = $sm->getMap;
$ref = $sm->{_map}->[21];
$plate_num = $ref->[2];
$well = $ref->[3];
print "3..1";
if($plate_num != 63 || $well != 19) {
	print "...failed\n";
} else {
	print "...OK\n";
}
#$sm->print_spots;

$sm->setMachine("IAS");
$arrayer = $sm->getMachine;
#print "Arrayer: $arrayer\n";
  
$sm->setPrintHead(4, 12);
($x_pin, $y_pin) = $sm->getPrintHead;
#print "x_pin: $x_pin\ty_pin: $y_pin\n";
  
$sm->setBlockDimensions(26, 26);
($x_spacing, $y_spacing) = $sm->getBlockDimensions;
#print "x_spacing: $x_spacing\ty_spacing: $y_spacing\n";
  
$sm->setNoComplement(0);
$noComplement = $sm->getNoComplement;
#print "noComplement: $noComplement\n";
  
$sm->setRepeats(1,1);
($x_repeat,$y_repeat) = $sm->getRepeats;
#print "x_repeat: $x_repeat\ty_repeat: $y_repeat\n";
  
$sm->setFormat(2);
$plate_format = $sm->getFormat;
#print "format: $plate_format\n";
  
$sm->setPrintDirection(0);
$direction = $sm->getPrintDirection;
if($direction) {
#	print "print_direction: left->right\n";
} else {
#	print "print_direction: top->bottom\n";
}
  
$sm->setPlateOrder("AA,AB,AC,AD,AE,AF,AG,AH,AI,AJ,AK,AL,AM,AN,AO,AP,AQ,AR,AS,AT,AU,AV,AW,AX,AY,AZ,BA,BB,BC,BD,BE,BF,BG,BH,BI,BJ,BK,BL,BM,BN,BO,BP,BQ,BR,BS,BT,BU,BV,BW,BX,BY,BZ,CA,CB,CC,CD,CE,CF,CG,CH,CI,CJ,CK,CL,CM,CN,CO,CP,CQ,CR,CS,CT,CU,CV,CW,CX,CY,CZ,DA,DB,DC,DD,DE,DF,DG");
$plate_order = $sm->getPlateOrder;
#print "plate_order: @{ $plate_order }\n";

$sm->fill_map;
$map = $sm->getMap;
foreach $row (@$map) {
	($row,$col,$plate,$well) = @$row;
#	print "$row\t$col\t$plate\t$well\n";
}
print "4..1";

$sm->fill_map;
$map = $sm->getMap;
$ref = $map->[21];
$plate_num = $ref->[2];
$well = $ref->[3];
#print "plate: $plate_num\twell: $well\n";
if($plate_num ne 'CN' || $well != 73) {
	print "...failed\n";
} else {
	print "...OK\n";
}

$sm->initialize;

$sm->fill_map;
$map = $sm->getMap;
foreach $row (@$map) {
	($row,$col,$plate,$well) = @$row;
#	print "$row\t$col\t$plate\t$well\n";
}

print "5..1";
$row=1; $col = 21;
my($plate_num,$well) = $sm->convert_spot($row,$col);
if($plate_num != 66 || $well != 73) {
	print "...failed\n";
} else {
	print "...OK\n";
}

#$sm->diagnostics;

$sm->setMachine("MD3");
$arrayer = $sm->getMachine;
#print "Arrayer: $arrayer\n";
  
$sm->setBlockDimensions(32, 12);
($x_spacing, $y_spacing) = $sm->getBlockDimensions;
#print "x_spacing: $x_spacing\ty_spacing: $y_spacing\n";

$sm->initialize;

$sm->fill_map;
$map = $sm->getMap;
foreach $row (@$map) {
	($row,$col,$plate,$well) = @$row;
#	print "$row\t$col\t$plate\t$well\n";
}
print "6..1";
$row=1; $col = 21;
my($plate_num,$well) = $sm->convert_spot($row,$col);
if($plate_num != 1 || $well != 109) {
	print "...failed\n";
} else {
	print "...OK\n";
}
#$sm->print_spots;

#$sm->diagnostics;

$sm->setMachine("Lucidia");
$arrayer = $sm->getMachine;
#print "Arrayer: $arrayer\n";
  
$sm->setBlockDimensions(24, 24);
($x_spacing, $y_spacing) = $sm->getBlockDimensions;
#print "x_spacing: $x_spacing\ty_spacing: $y_spacing\n";

$sm->setRepeats(2,1);
($xrep,$yrep) = $sm->getRepeats;
#print "x_repeat: $xrep\ty_repeat: $yrep\n";

$sm->initialize;

$sm->fill_map;
$map = $sm->getMap;
foreach $row (@$map) {
	($row,$col,$plate,$well) = @$row;
#	print "$row\t$col\t$plate\t$well\n";
}
print "7..1";
$row=1; $col = 21;
my($plate_num,$well) = $sm->convert_spot($row,$col);
if($plate_num != 2 || $well != 73) {
	print "...failed\n";
} else {
	print "...OK\n";
}
#$sm->print_spots;

#$sm->print_wells;

#$sm->diagnostics;

$sm->setMachine("Stanford");
$sm->setPrintHead(4,4);
$sm->setBlockDimensions(20,20);
$sm->initialize;
#$sm->diagnostics;

print "8..1";
$row=1; $col = 21;
my($plate_num,$well) = $sm->convert_spot($row,$col);
#print "plate: $plate_num\twell: $well\n";
if($plate_num != 16 || $well != 345) {
	print "...failed\n";
} else {
	print "...OK\n";
}
