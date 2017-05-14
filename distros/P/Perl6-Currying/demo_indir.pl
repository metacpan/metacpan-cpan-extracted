use Perl6::Currying;

sub add($a,$b) { $a + $b };

my $incr = prebind &add: b=>1;

print $incr->(7), "\n";

my $div =  sub ($x, $y) { $x / $y };

print $div->(22,7), "\n";

my $half_of = prebind &$div: y=>2;
my $reciprocal = prebind $div: (x=>1);

print $half_of->(7), "\n";
print $reciprocal->(7), "\n";

my $pi_ish = prebind &$div: y=>7, x=>22;

print $pi_ish->(), "\n";

my $one_half = prebind &{$half_of}: (x=>1);

print $one_half->(), "\n";

sub getdiv { return $div };

my $tenth = prebind &{getdiv()}: y=>10;

print $tenth->(7), "\n";

eval { my $bad = prebind $div: (q=>'???') } or print $@;
