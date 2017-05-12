use Perl6::Form;

my @data = ("foo","bar","","baz");

print form "| {[[[[[[[} |", \@data;

print "====================\n";

print map {form "| {[[[[[[[} |", $_}
				   @data;
