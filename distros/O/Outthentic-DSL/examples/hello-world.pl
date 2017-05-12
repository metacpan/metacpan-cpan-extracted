use Outthentic::DSL;

my $otx = Outthentic::DSL->new(<<HERE, { debug_mod => 0 });
    Hello
    My name is Outthentic!
HERE

$otx->validate(<<'CHECK');
    Hello
    regexp: My\s+name\s+is\s+\S+
CHECK

print "status\tcheck\n";
print "==========================\n";

for my $r (@{$otx->results}) {
    print $r->{status} ? 'true' : 'false', "\t", $r->{message}, "\n";
}


