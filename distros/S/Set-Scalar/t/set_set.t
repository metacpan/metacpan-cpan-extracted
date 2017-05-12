use Set::Scalar;

print "1..8\n";

my $s = Set::Scalar->new("a");
my $t = Set::Scalar->new("b");

$s->insert($t);

print "not " unless $s == "(a (b))";
print "ok 1\n";

$t->insert($s);

print "not " unless $s == "(a (b (a ...)))";
print "ok 2\n";

print "not " unless $t == "(b (a (b ...)))";
print "ok 3\n";

my $u = Set::Scalar->new("c");

$u->insert($u);

print "not " unless $u == "(c (c ...))";
print "ok 4\n";

$s->insert($u);

# There is some nondeterminism that needs to be resolved.
print "not " unless $s == "(a (b (a ...)) (c ...))" or
                    $s == "(a (b (a (c ...) ...)) (c ...))";
print "ok 5\n";

print "not " unless $t == "(b (a (b ...) (c ...)))" or
                    $t == "(b (a (b (c ...) ...) (c ...)))";
print "ok 6\n";

$t->delete($s);

print "not " unless $s == "(a (b) (c ...))";
print "ok 7\n";

print "not " unless $t == "(b)";
print "ok 8\n";

