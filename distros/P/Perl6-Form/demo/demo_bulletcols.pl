use 5.010;
use warnings;

use Perl6::Form;

my $bullet = "<>";

my @items = <DATA>;
s/\\n/\n/g for @items;
s/\\r/\r/g for @items;

print form
	{bullet=>'<>'},
	 "<> {:[[[[[[[[[[[[[[[[[[:}    <> {:[[[[[[[[[[[[[[[[[[:}",
		 \@items,                     \@items;

my $items = join "", @items;

print form
	 "-----------------------",
     {bullet=>'<>'},
	 "<> {:[[[[[[[[[[[[[[[[[[:}    <> {:[[[[[[[[[[[[[[[[[[:}",
		 $items,                      $items;

__DATA__
A rubber sword, laminated with mylar to look suitably shiny.
Cotton tights (Summer performances).
Woolen tights (Winter performances.\rOr those actors who are willing to admit to being over 65 years of age).
Talcum powder.
Codpieces (assorted sizes).
Singlet.
Double.
Triplet (Kings and Emperors only).
Supercilious attitude (optional).
