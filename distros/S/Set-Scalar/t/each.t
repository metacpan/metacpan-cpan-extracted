use Set::Scalar;

print "1..2\n";

my @a = ("a".."e",0);
my $a = Set::Scalar->new(@a);

my $e;
my %e;

while (defined($e = $a->each)) {
    print "# e = $e\n";
    $e{$e}++;
}

print "not " if defined $e;
print "ok 1\n";

my $n;

for my $e (@a) {
    $n++ if exists $e{$e} && $e{$e} == 1;
}

print "not " unless $n == @a && keys %e == @a;
print "ok 2\n";




