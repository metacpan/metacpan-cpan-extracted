#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Encode qw(encode_utf8);
use Mock::Person::CZ;

# Get all last male names.
my @last_males = @Mock::Person::CZ::last_male;

# Print out.
print sort map { encode_utf8($_)."\n" } @last_males;

# Output:
# Bartoš
# Beneš
# Blažek
# Bláha
# Bureš
# Doležal
# Dostál
# Dušek
# Dvořák
# Fiala
# Havlíček
# Holub
# Horák
# Hrubý
# Hruška
# Hájek
# Janda
# Jelínek
# Kadlec
# Kolář
# Konečný
# Kopecký
# Kovář
# Kratochvíl
# Krejčí
# Král
# Kučera
# Kříž
# Liška
# Mach
# Malý
# Marek
# Mareš
# Matoušek
# Mašek
# Moravec
# Musil
# Müller
# Navrátil
# Nguyen
# Novotný
# Novák
# Němec
# Pavlík
# Pokorný
# Polák
# Pospíšil
# Procházka
# Růžička
# Sedláček
# Soukup
# Staněk
# Svoboda
# Sýkora
# Tichý
# Urban
# Valenta
# Vaněk
# Veselý
# Vlček
# Vávra
# Zeman
# Čech
# Čermák
# Černý
# Říha
# Ševčík
# Šimek
# Štěpánek
# Šťastný