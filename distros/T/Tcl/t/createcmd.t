use Tcl;

$| = 1;

# 5.8.0 has an order destroy issue that prevents proper Tcl finalization
my $tests = $] == 5.008 ? 3 : 4;
print "1..$tests\n";

sub foo {
    my($clientdata, $interp, @args) = @_;
    print "$clientdata->{OK} $args[1]\n";
}

sub foogone {
    my($clientdata) = @_;
    print "$clientdata->{OK} 3\n";
}

sub bar { "ok 2" }

sub bargone {
    print "ok $_[0]\n";
}

$i = Tcl->new;

$i->CreateCommand("foo", \&foo, {OK => "ok"}, \&foogone);
$i->CreateCommand("bar", \&bar, 4, \&bargone);
$i->Eval("foo 1");
$i->Eval("puts [bar]");
$i->DeleteCommand("foo");
# final destructor of $i triggers destructor for Tcl proc bar (!5.8.0)
