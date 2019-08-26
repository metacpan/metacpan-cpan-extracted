# encoding: Sjis
# This file is encoded in ShiftJIS.
die "This file is not encoded in ShiftJIS.\n" if q{あ} ne "\x82\xa0";

# ファイルテストが真になる場合は 1 が返るテスト

my $__FILE__ = __FILE__;

use Esjis;
print "1..9\n";

if ($^O !~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    for my $tno (1..9) {
        print "ok - $tno # SKIP $^X $0\n";
    }
    exit;
}

open(FILE,'>file');
close(FILE);

open(FILE,'file');

if ((Esjis::r 'file') == 1) {
    $_ = Esjis::r 'file';
    print "ok - 1 Esjis::r 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Esjis::r 'file';
    print "not ok - 1 Esjis::r 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Esjis::w 'file') == 1) {
    $_ = Esjis::w 'file';
    print "ok - 2 Esjis::w 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Esjis::w 'file';
    print "not ok - 2 Esjis::w 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Esjis::o 'file') == 1) {
    $_ = Esjis::o 'file';
    print "ok - 3 Esjis::o 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Esjis::o 'file';
    print "not ok - 3 Esjis::o 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Esjis::R 'file') == 1) {
    $_ = Esjis::R 'file';
    print "ok - 4 Esjis::R 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Esjis::R 'file';
    print "not ok - 4 Esjis::R 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Esjis::W 'file') == 1) {
    $_ = Esjis::W 'file';
    print "ok - 5 Esjis::W 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Esjis::W 'file';
    print "not ok - 5 Esjis::W 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Esjis::O 'file') == 1) {
    $_ = Esjis::O 'file';
    print "ok - 6 Esjis::O 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Esjis::O 'file';
    print "not ok - 6 Esjis::O 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Esjis::e 'file') == 1) {
    $_ = Esjis::e 'file';
    print "ok - 7 Esjis::e 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Esjis::e 'file';
    print "not ok - 7 Esjis::e 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Esjis::z 'file') == 1) {
    $_ = Esjis::z 'file';
    print "ok - 8 Esjis::z 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Esjis::z 'file';
    print "not ok - 8 Esjis::z 'file' ($_) == 1 $^X $__FILE__\n";
}

if ((Esjis::f 'file') == 1) {
    $_ = Esjis::f 'file';
    print "ok - 9 Esjis::f 'file' ($_) == 1 $^X $__FILE__\n";
}
else {
    $_ = Esjis::f 'file';
    print "not ok - 9 Esjis::f 'file' ($_) == 1 $^X $__FILE__\n";
}

close(FILE);
unlink('file');

__END__
