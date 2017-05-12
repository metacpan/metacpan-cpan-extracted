#!/opt/ecelerity/3rdParty/bin/perl -w
use strict;
use Test::More tests => 15;
use Test::Builder;
use IO::File;

BASE: {
    package My::Base;
    sub new { bless {} => shift }
    sub list { wantarray ? (1,2,3,4) : [1,2,3,4] }
}

SUB: {
    package My::Sub;
    use base 'My::Base';
}

BEGIN {
    use_ok 'PHP::Interpreter' or die;
}

ok my $php = PHP::Interpreter->new, "Create new PHP interpreter";

## Try using a pure Perl class.
ok $php->eval(q/
    $perl = Perl::getInstance();
    $test = $perl->new('Test::Builder');
    return $test->ok(1, "This test should run from PHP!");
/), "The test should have passed and returned a true value";

# Try using an XS module.
sub file {  __FILE__ }
ok my $ret = $php->eval(q^
    $perl = Perl::getInstance();
    $file = $perl->call('file');
    $fh = $perl->new("IO::File", "<$file");
    if ($fh) {
        return $fh->getline();
    } else {
        throw new Exception("Couldn't open $file");
    }
^), "We should get a value back from the file";
like $ret, qr/^#\!.*perl\s+-w$/, "We should have a shebang line";

# Make sure that call() works on class methods, too.
ok $ret = $php->eval(q^
    $perl = Perl::getInstance();
    $file = $perl->call('file');
    $fh = $perl->call("IO::File::new", "IO::File", "<$file");
    if ($fh) {
        return $fh->getline();
    } else {
        throw new Exception("Couldn't open $file");
    }
^), "We should get a value back from the file";
like $ret, qr/^#\!.*perl\s+-w$/, "We should have a shebang line";

# Make sure that eval() works on class methods, too.
ok $ret = $php->eval(q^
    $perl = Perl::getInstance();
    $file = $perl->call('file');
    $fh = $perl->eval("return IO::File->new(\"<$file\");");
    if ($fh) {
        return $fh->getline();
    } else {
        throw new Exception("Couldn't open $file");
    }
^), "We should get a value back from the file";
like $ret, qr/^#\!.*perl\s+-w$/, "We should have a shebang line";

# Make sure that call_methodod() calls class methods, too.
ok $ret = $php->eval(q^
    $perl = Perl::getInstance();
    $file = $perl->call('file');
    $fh = $perl->new("IO::File", "<$file");
    $fh = $perl->call_method('IO::File', 'new_from_fd', $fh, 'r');
    if ($fh) {
        return $fh->getline();
    } else {
        throw new Exception("Couldn't open $file");
    }
^), "We should get a value back from the file";
like $ret, qr/^#\!.*perl\s+-w$/, "We should have a shebang line";

NO: {
    no warnings 'redefine';
    my $orig = \&UNIVERSAL::isa;
    local *UNIVERSAL::isa = sub {
        diag $orig->(@_);
        return $orig->(@_);
    };

# Make sure that new() uses inheritance.
ok $ret = $php->eval(q^
    $perl = Perl::getInstance();
    $sub  = $perl->new('My::Sub');
    # These seem to be returning NULL, even though the diag above shows 1.
    return $sub->isa('My::Base') && $sub->isa('My::Sub');
^), 'The object created by new() should obey inheritance';
}

# Make sure that a list is returned.
ok $ret = $php->eval(q^
    $perl = Perl::getInstance();
    return $perl->call_method('My::Sub', 'list');
^), 'We should get the return value of a class method call';
is_deeply $ret, [1,2,3,4], 'And it should be the proper array';
