use Perl6::Currying;

sub add($a,$b) { $a + $b }

my $incr = &add.prebind(b=>1);

print $incr->(7), "\n";

my $div =  sub ($x, $y) { $x / $y };

print $div->(22,7), "\n";

my $half_of = &$div.prebind(y=>2);
my $reciprocal = $div.prebind(x=>1);

print $half_of->(7), "\n";
print $reciprocal->(7), "\n";

my $pi_ish = &$div.prebind(y=>7, x=>22);

print $pi_ish->(), "\n";

my $one_half = &{$half_of}.prebind(x=>1);

print $one_half->(), "\n";

sub getdiv { return $div };

my $tenth = &{getdiv()}.prebind(y=>10);

print $tenth->(7), "\n";

eval { my $bad = $tenth.prebind(y=>'???') } or print $@;
eval { my $bad = $div.prebind(q=>'???') } or print $@;
