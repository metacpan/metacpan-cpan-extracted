# encoding: Sjis
# This file is encoded in ShiftJIS.
die "This file is not encoded in ShiftJIS.\n" if q{あ} ne "\x82\xa0";

# 関数 bytes::* のテスト

my $__FILE__ = __FILE__;

use Sjis;
print "1..12\n";

use bytes;

# bytes::chr()

my $eval = eval { bytes::chr(65); };
if (not $@) {
    print "ok - 1 eval { bytes::chr(65); } $^X $__FILE__\n";
    if (bytes::chr(65) eq 'A') {
        print "ok - 2 bytes::chr(65) eq 'A' $^X $__FILE__\n";
    }
    else {
        print "not ok - 2 bytes::chr(65) eq 'A' $^X $__FILE__\n";
    }
}
else {
    print "not ok - 1 eval { bytes::chr(65); } $^X $__FILE__\n";
    print "not ok - 2 bytes::chr(65) eq 'A' $^X $__FILE__\n";
}

# bytes::index()

$eval = eval { bytes::index('ABCDCDCDEF','CD'); };
if (not $@) {
    print "ok - 3 eval { bytes::index('ABCDCDCDEF','CD'); } $^X $__FILE__\n";
    if (bytes::index('ABCDCDCDEF','CD') == 2) {
        print "ok - 4 bytes::index('ABCDCDCDEF','CD') == 2 $^X $__FILE__\n";
    }
    else {
        print "not ok - 4 bytes::index('ABCDCDCDEF','CD') == 2 $^X $__FILE__\n";
    }
}
else {
    print "not ok - 3 eval { bytes::index('ABCDCDCDEF','CD'); } $^X $__FILE__\n";
    print "not ok - 4 bytes::index('ABCDCDCDEF','CD') == 2 $^X $__FILE__\n";
}

# bytes::length()

$eval = eval { bytes::length('AAA'); };
if (not $@) {
    print "ok - 5 eval { bytes::length('AAA'); } $^X $__FILE__\n";
    if (bytes::length('AAA') == 3) {
        print "ok - 6 bytes::length('AAA') == 3 $^X $__FILE__\n";
    }
    else {
        print "not ok - 6 bytes::length('AAA') == 3 $^X $__FILE__\n";
    }
}
else {
    print "not ok - 5 eval { bytes::length('AAA'); } $^X $__FILE__\n";
    print "not ok - 6 bytes::length('AAA') == 3 $^X $__FILE__\n";
}

# bytes::ord()

$eval = eval { bytes::ord('ABC'); };
if (not $@) {
    print "ok - 7 eval { bytes::ord('ABC'); } $^X $__FILE__\n";
    if (bytes::ord('ABC') == 65) {
        print "ok - 8 bytes::ord('ABC') == 65 $^X $__FILE__\n";
    }
    else {
        print "not ok - 8 bytes::ord('ABC') == 65 $^X $__FILE__\n";
    }
}
else {
    print "not ok - 7 eval { bytes::ord('ABC'); } $^X $__FILE__\n";
    print "not ok - 8 bytes::ord('ABC') == 65 $^X $__FILE__\n";
}

# bytes::rindex()

$eval = eval { bytes::rindex('ABCDCDCDEF','CD'); };
if (not $@) {
    print "ok - 9 eval { bytes::rindex('ABCDCDCDEF','CD'); } $^X $__FILE__\n";
    if (bytes::rindex('ABCDCDCDEF','CD') == 6) {
        print "ok - 10 bytes::rindex('ABCDCDCDEF','CD') == 6 $^X $__FILE__\n";
    }
    else {
        print "not ok - 10 bytes::rindex('ABCDCDCDEF','CD') == 6 $^X $__FILE__\n";
    }
}
else {
    print "not ok - 9 eval { bytes::rindex('ABCDCDCDEF','CD'); } $^X $__FILE__\n";
    print "not ok - 10 bytes::rindex('ABCDCDCDEF','CD') == 6 $^X $__FILE__\n";
}

# bytes::substr()

$eval = eval { bytes::substr('ABCDEF',3,2); };
if (not $@) {
    print "ok - 11 eval { bytes::substr('ABCDEF',3,2); } $^X $__FILE__\n";
    if (bytes::substr('ABCDEF',3,2) eq 'DE') {
        print "ok - 12 bytes::substr('ABCDEF',3,2) eq 'DE' $^X $__FILE__\n";
    }
    else {
        print "not ok - 12 bytes::substr('ABCDEF',3,2) eq 'DE' $^X $__FILE__\n";
    }
}
else {
    print "not ok - 11 eval { bytes::substr('ABCDEF',3,2); } $^X $__FILE__\n";
    print "not ok - 12 bytes::substr('ABCDEF',3,2) eq 'DE' $^X $__FILE__\n";
}

__END__

