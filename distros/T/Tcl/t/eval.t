use Tcl;

$| = 1;

print "1..6\n";

$i = Tcl->new;
$i->Eval(q(puts "ok 1"));
($a, $b) = $i->Eval(q(list 2 ok));
print "$b $a\n";
eval { $i->Eval(q(error "ok 3\n")) };
print $@;
$i->call("puts", "ok 4");
$i->EvalFileHandle(\*DATA);

print $i->Eval(("# some many text \n" x 10_000) . "return {foo bar!}") ne 'foo bar!' ? 'NOT ' :'',
  'ok 6';

__END__
set foo ok
set bar 5
puts "$foo $bar"
