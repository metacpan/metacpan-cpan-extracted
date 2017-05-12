use Parse::RecDescent;
use Data::Dumper; $|++;
my $parser = Parse::RecDescent->new(q{

line: word(s) /\z/ {
my @words = @{$item[1]};
my %count;
(grep ++$count{$_} > 1, @words) ? undef : \@words;
}

word: "one" | "two" | "three"

}) or die;

for ("one two", "one one", "two three one", "three one two one") {
  print "$_ =>\n";
  print Dumper($parser->line($_));
}

# which generates:

one two =>
  $VAR1 = [
	   'one',
	   'two'
	  ];
one one =>
  $VAR1 = undef;
two three one =>
  $VAR1 = [
	   'two',
	   'three',
	   'one'
	  ];
three one two one =>
  $VAR1 = undef;
