
use PLN::PT;
use Data::Dumper;
use utf8::all;

my $nlp = PLN::PT->new('http://api.pln.pt');
my $data = $nlp->tokenizer('A Maria tem razão.');

print Dumper $data;

__END__

print Dumper $nlp->tagger('A Maria tem razão.');
print Dumper $nlp->tagger('A Maria tem razão.', $opts);
print Dumper $data;

foreach (@$data) {
  print $_, "\n";
}

