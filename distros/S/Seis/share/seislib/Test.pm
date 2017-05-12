# vim: ft=perl6
module Test;
my $failed = 0;
my $num_of_tests_planned;
my $num_of_tests_run = 0;

sub plan($n) is export {
    $num_of_tests_planned = $n;
    say("1..$n");
}

sub skip($reason, $count=1) is export {
    my $i = 1;
    while $i <= $count { proclaim(1, "# SKIP " ~ $reason); $i = $i + 1; }
}

sub skip_rest($reason = '<unknown>') is export {
    skip($reason, $num_of_tests_planned - $num_of_tests_run);
}

sub proclaim($cond, $desc) {
    unless ?$cond {
        print "not ";
        $failed++;
    }
    $num_of_tests_run++;
    print "ok $num_of_tests_run";
    if defined $desc {
        print " - $desc\n";
    } else {
        print "\n";
    }
    return $cond;
}

sub ok($cond, $desc) is export {
    proclaim(?$cond, $desc);
}

sub nok($cond, $desc=undef) is export {
    proclaim(!$cond, $desc);
}

sub is($x,$y, $desc=undef) is export {
    if (!proclaim($x eq $y, $desc)) {
        print "  GOT:      $x\n";
        print "  EXPECTED: $y\n";
    }
}

sub isnt($x,$y, $desc=undef) is export {
    if (!proclaim($x ne $y, $desc)) {
        print "  GOT:      $x\n";
        print "  EXPECTED: $y\n";
    }
}

sub isa_ok($x, $y, $desc=undef) is export {
    proclaim($x.isa($y), $desc);
}

sub lives_ok($closure, $reason='') is export {
    try {
        $closure();
    };
    proclaim((not defined $!), $reason);
}

sub dies_ok($closure, $reason='') is export {
    try {
        $closure();
    };
    proclaim((defined $!), $reason);
}

sub eval_dies_ok($code, $reason=undef) is export {
    my $ee = eval_exception($code);
    if defined $ee {
        proclaim(1, $reason);
    } else {
        proclaim(0, $reason);
    }
}

sub eval_lives_ok($code, $reason=undef) is export {
    my $ee = eval_exception($code);
    if defined $ee {
        proclaim(0, $reason);
    } else {
        proclaim(1, $reason);
    }
}

sub force_todo(*@ary) {
    ...
}

sub eval_exception($code) {
    try {
        eval $code;
    };
    $!;
}

sub done() is export {
    say("1..$num_of_tests_run");
}

sub pass($reason='passed') is export {
    proclaim(1, $reason);
}

sub flunk($reason) is export {
    proclaim(0, "flunk $reason");
}

sub diag($msg) is export {
    $*ERR.say("# " ~ $msg);
}

END {
    exit 1 if $failed > 0;
}
