sub fib1 {
    my $n = shift;
    if ($n < 2) {
        return $n
    } else {
        return fib1($n-1) + fib1($n-2)
    }
}

sub fib2 {
    my $n = shift;
    die "asdf\n" if $n <= 0;
    if ($n < 2) {
        return $n
    } else {
        return fib2($n-1) + fib2($n-2)
    }
}

sub rec
{
    my $n = shift;
    print "rec($n)\n";
    my $ret;
    if ($n == 0) {
        $ret = 0;
    } else {
        $ret = rec($n - 1);
    }
    print $ret+1, " = rec($n)\n";
    return $ret + 1;
}

sub crec
{
    print STDERR "crec(@_)\n";
    my $ret = rec(@_);
    print STDERR "$ret = crec(@_)\n";
    return $ret;
}
