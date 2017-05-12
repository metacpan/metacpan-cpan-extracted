use Perl6::Form;

my $bullet = "<>";

my @items = <DATA>;

for my $item (@items) {
	print form "{'{*}'} {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}",
		        $bullet,      $item;
}

__DATA__
A rubber sword, laminated with mylar to look suitably shiny.
Cotton tights (summer performances).
Woolen tights (winter performances or actors over 65 years).
Talcum powder.
Codpieces (assorted sizes).
Singlet.
Double.
Triplet (Kings and Emperors only).
Supercilious attitude (optional).
