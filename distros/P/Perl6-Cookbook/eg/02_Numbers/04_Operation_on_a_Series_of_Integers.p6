#!/usr/bin/perl6
use v6;

=begin pod

Iterating over a series of integers in a range is similar in Perl 6
to the same code in Perl 5 except of slightly different format of the
foreach loop that is spelled C<for> now.

=end pod

my $x = 23;
my $z = 25;

for $x .. $z -> $i {
	say $i;
}
say '-----';

=begin pod

C-style, 3-part for loops are now called loop but they are not really recommended.
Better to use the for loop as described above.

=end pod

# The following produced 2 in Rakudo which is probably a bug
# as for should not work that way
# for (my $i = 1; $i <= 3; $i++) { say $i; }

loop (my $i = $x; $i <= $z; $i++) { 
	say $i;
}
say '-----';

=begin pod

Iterating over every 2nd number is also possible with the for loop
of Perl 6.

=end pod

# the following code does not YET work in Rakudo

#for 1..8:by(2) -> $i {
#	say $i;
#}
#say '-----';


