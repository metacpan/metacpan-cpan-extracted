#!/usr/bin/perl

# Pragmas----------
use warnings;
use strict;
# Utilizarea clasei CNPclass1 din Fila: CNPclass1.pm
use lib '/home/mhcrnl/MyPerlCode/Person-CNPclass/lib/Person';
use CNPclass;

my $myCNP = new Person::CNPclass("Mihai", "Cornel", "1750878909876", "0722196164", "mhcrnl\@gmail.com");
	
print $myCNP->getNume()."\n";	
print $myCNP->getPrenume()."\n";
print $myCNP->getCNP()."\n";

$myCNP->setNume("Irina");
$myCNP->afiseazaVersion();

print $myCNP->getNume()."\t"."\n";
print "Nume/Prenume: ".$myCNP->getNume()." ".$myCNP->getPrenume()."\n";
print "Numar de Telefon: ".$myCNP->getNrTel()."\n";
print "Email:	".$myCNP->getEmail();
