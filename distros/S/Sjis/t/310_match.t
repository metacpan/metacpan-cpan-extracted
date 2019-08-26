# encoding: Sjis
# This file is encoded in ShiftJIS.
die "This file is not encoded in ShiftJIS.\n" if q{あ} ne "\x82\xa0";

use strict;
use Sjis;
print "1..11\n";

my $__FILE__ = __FILE__;

eval {
    require English;
    English->import;
};
if ($@) {
    for (1..11) {
        print qq{ok - $_ # PASS $^X $__FILE__\n};
    }
    exit;
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    if ($MATCH eq '123') {
        print qq{ok - 1 \$MATCH $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 \$MATCH $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 1 \$MATCH $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    if ("$MATCH" eq '123') {
        print qq{ok - 2 "\$MATCH" $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 2 "\$MATCH" $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 2 "\$MATCH" $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    if (qq{$MATCH} eq '123') {
        print qq{ok - 3 qq{\$MATCH} $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 3 qq{\$MATCH} $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 3 qq{\$MATCH} $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    if (<<END eq "123\n") {
$MATCH
END
        print qq{ok - 4 <<END\$MATCHEND $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 4 <<END\$MATCHEND $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 4 <<END\$MATCHEND $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    if (<<"END" eq "123\n") {
$MATCH
END
        print qq{ok - 5 <<"END"\$MATCHEND $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 5 <<"END"\$MATCHEND $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 5 <<"END"\$MATCHEND $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    if ('987123456' =~ /($MATCH)/) {
        if ($MATCH eq '123') {
            print qq{ok - 6 /\$MATCH/ $^X $__FILE__\n};
        }
        else {
            print qq{not ok - 6 /\$MATCH/ $^X $__FILE__\n};
        }
    }
    else {
        print qq{not ok - 6 /\$MATCH/ $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 6 /\$MATCH/ $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    if ('987123456' =~ m/($MATCH)/) {
        if ($MATCH eq '123') {
            print qq{ok - 7 m/\$MATCH/ $^X $__FILE__\n};
        }
        else {
            print qq{not ok - 7 m/\$MATCH/ $^X $__FILE__\n};
        }
    }
    else {
        print qq{not ok - 7 m/\$MATCH/ $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 7 m/\$MATCH/ $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    $_ = '987123456';
    if ($_ =~ s/($MATCH)/jkl/) {
        if ($_ eq '987jkl456') {
            print qq{ok - 8 s/\$MATCH// $^X $__FILE__\n};
        }
        else {
            print qq{not ok - 8 s/\$MATCH// $^X $__FILE__\n};
        }
    }
    else {
        print qq{not ok - 8 s/\$MATCH// $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 8 s/\$MATCH// $^X $__FILE__\n};
}

$_ = '123,456,789';
if ($_ =~ m/(,)/) {
    @_ = split(/$MATCH/,'AAA,BBB,CCC,DDD');
    if (join('+',@_) eq 'AAA+BBB+CCC+DDD') {
        print qq{ok - 9 split(/$MATCH/) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 9 split(/$MATCH/) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 9 split(/$MATCH/) $^X $__FILE__\n};
}

$_ = '123,456,789';
if ($_ =~ m/(,)/) {
    @_ = split(m/$MATCH/,'AAA,BBB,CCC,DDD');
    if (join('+',@_) eq 'AAA+BBB+CCC+DDD') {
        print qq{ok - 10 split(m/$MATCH/) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 10 split(m/$MATCH/) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 10 split(m/$MATCH/) $^X $__FILE__\n};
}

$_ = '123,456,789';
if ($_ =~ m/(,)/) {
    @_ = split(qr/$MATCH/,'AAA,BBB,CCC,DDD');
    if (join('+',@_) eq 'AAA+BBB+CCC+DDD') {
        print qq{ok - 11 split(qr/$MATCH/) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 11 split(qr/$MATCH/) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 11 split(qr/$MATCH/) $^X $__FILE__\n};
}

__END__

