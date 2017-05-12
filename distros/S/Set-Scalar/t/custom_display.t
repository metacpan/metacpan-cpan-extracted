use Set::Scalar;

print "1..7\n";

$a = Set::Scalar->new("a".."e");
$b = Set::Scalar->new("a".."e");

print "not " unless $a eq "(a b c d e)";
print "ok 1 # $a\n";

my $cb = Set::Scalar->as_string_callback;

Set::Scalar->as_string_callback(sub{join(",",sort shift->elements)});

print "not " unless $a eq "a,b,c,d,e";
print "ok 2 # $a\n";

$b->as_string_callback(sub{join("-",sort shift->elements)});

print "not " unless $b eq "a-b-c-d-e";
print "ok 3 # $b\n";

print "not " unless $a eq "a,b,c,d,e";
print "ok 4 # $a\n";

Set::Scalar->as_string_callback($cb);

print "not " unless $a eq "(a b c d e)";
print "ok 5 # $a\n";

print "not " unless $b eq "a-b-c-d-e";
print "ok 6 # $b\n";

$b->as_string_callback(undef);

print "not " unless $b eq "(a b c d e)";
print "ok 7 # $b\n";

