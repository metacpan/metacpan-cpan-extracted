# encoding: Sjis
# This file is encoded in ShiftJIS.
die "This file is not encoded in ShiftJIS.\n" if q{あ} ne "\x82\xa0";

# 引数が省略された場合のテスト

my $__FILE__ = __FILE__;

use Esjis;
print "1..24\n";

if ($^O !~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    for my $tno (1..24) {
        print "ok - $tno # SKIP $^X $0\n";
    }
    exit;
}

open(FILE,'>file');
close(FILE);

open(FILE,'file');

$_ = 'file';
if ((Esjis::r_ ne '') == (-r ne '')) {
    print "ok - 1 Esjis::r_ == -r  $^X $__FILE__\n";
}
else {
    print "not ok - 1 Esjis::r_ == -r  $^X $__FILE__\n";
}

$_ = 'file';
if ((Esjis::w_ ne '') == (-w ne '')) {
    print "ok - 2 Esjis::w_ == -w  $^X $__FILE__\n";
}
else {
    print "not ok - 2 Esjis::w_ == -w  $^X $__FILE__\n";
}

$_ = 'file';
if ((Esjis::x_ ne '') == (-x ne '')) {
    print "ok - 3 Esjis::x_ == -x  $^X $__FILE__\n";
}
else {
    print "not ok - 3 Esjis::x_ == -x  $^X $__FILE__\n";
}

$_ = 'file';
if ((Esjis::o_ ne '') == (-o ne '')) {
    print "ok - 4 Esjis::o_ == -o  $^X $__FILE__\n";
}
else {
    print "not ok - 4 Esjis::o_ == -o  $^X $__FILE__\n";
}

$_ = 'file';
if ((Esjis::R_ ne '') == (-R ne '')) {
    print "ok - 5 Esjis::R_ == -R  $^X $__FILE__\n";
}
else {
    print "not ok - 5 Esjis::R_ == -R  $^X $__FILE__\n";
}

$_ = 'file';
if ((Esjis::W_ ne '') == (-W ne '')) {
    print "ok - 6 Esjis::W_ == -W  $^X $__FILE__\n";
}
else {
    print "not ok - 6 Esjis::W_ == -W  $^X $__FILE__\n";
}

$_ = 'file';
if ((Esjis::X_ ne '') == (-X ne '')) {
    print "ok - 7 Esjis::X_ == -X  $^X $__FILE__\n";
}
else {
    print "not ok - 7 Esjis::X_ == -X  $^X $__FILE__\n";
}

$_ = 'file';
if ((Esjis::O_ ne '') == (-O ne '')) {
    print "ok - 8 Esjis::O_ == -O  $^X $__FILE__\n";
}
else {
    print "not ok - 8 Esjis::O_ == -O  $^X $__FILE__\n";
}

$_ = 'file';
if ((Esjis::e_ ne '') == (-e ne '')) {
    print "ok - 9 Esjis::e_ == -e  $^X $__FILE__\n";
}
else {
    print "not ok - 9 Esjis::e_ == -e  $^X $__FILE__\n";
}

$_ = 'file';
if ((Esjis::z_ ne '') == (-z ne '')) {
    print "ok - 10 Esjis::z_ == -z  $^X $__FILE__\n";
}
else {
    print "not ok - 10 Esjis::z_ == -z  $^X $__FILE__\n";
}

$_ = 'file';
if ((Esjis::s_ ne '') == (-s ne '')) {
    print "ok - 11 Esjis::s_ == -s  $^X $__FILE__\n";
}
else {
    print "not ok - 11 Esjis::s_ == -s  $^X $__FILE__\n";
}

$_ = 'file';
if ((Esjis::f_ ne '') == (-f ne '')) {
    print "ok - 12 Esjis::f_ == -f  $^X $__FILE__\n";
}
else {
    print "not ok - 12 Esjis::f_ == -f  $^X $__FILE__\n";
}

$_ = 'file';
if ((Esjis::d_ ne '') == (-d ne '')) {
    print "ok - 13 Esjis::d_ == -d  $^X $__FILE__\n";
}
else {
    print "not ok - 13 Esjis::d_ == -d  $^X $__FILE__\n";
}

$_ = 'file';
if ((Esjis::p_ ne '') == (-p ne '')) {
    print "ok - 14 Esjis::p_ == -p  $^X $__FILE__\n";
}
else {
    print "not ok - 14 Esjis::p_ == -p  $^X $__FILE__\n";
}

$_ = 'file';
if ((Esjis::S_ ne '') == (-S ne '')) {
    print "ok - 15 Esjis::S_ == -S  $^X $__FILE__\n";
}
else {
    print "not ok - 15 Esjis::S_ == -S  $^X $__FILE__\n";
}

$_ = 'file';
if ((Esjis::b_ ne '') == (-b ne '')) {
    print "ok - 16 Esjis::b_ == -b  $^X $__FILE__\n";
}
else {
    print "not ok - 16 Esjis::b_ == -b  $^X $__FILE__\n";
}

$_ = 'file';
if ((Esjis::c_ ne '') == (-c ne '')) {
    print "ok - 17 Esjis::c_ == -c  $^X $__FILE__\n";
}
else {
    print "not ok - 17 Esjis::c_ == -c  $^X $__FILE__\n";
}

$_ = 'file';
if ((Esjis::u_ ne '') == (-u ne '')) {
    print "ok - 18 Esjis::u_ == -u  $^X $__FILE__\n";
}
else {
    print "not ok - 18 Esjis::u_ == -u  $^X $__FILE__\n";
}

$_ = 'file';
if ((Esjis::g_ ne '') == (-g ne '')) {
    print "ok - 19 Esjis::g_ == -g  $^X $__FILE__\n";
}
else {
    print "not ok - 19 Esjis::g_ == -g  $^X $__FILE__\n";
}

$_ = 'file';
if ((Esjis::T_ ne '') == (-T ne '')) {
    print "ok - 20 Esjis::T_ == -T  $^X $__FILE__\n";
}
else {
    print "not ok - 20 Esjis::T_ == -T  $^X $__FILE__\n";
}

$_ = 'file';
if ((Esjis::B_ ne '') == (-B ne '')) {
    print "ok - 21 Esjis::B_ == -B  $^X $__FILE__\n";
}
else {
    print "not ok - 21 Esjis::B_ == -B  $^X $__FILE__\n";
}

$_ = 'file';
if ((Esjis::M_ ne '') == (-M ne '')) {
    print "ok - 22 Esjis::M_ == -M  $^X $__FILE__\n";
}
else {
    print "not ok - 22 Esjis::M_ == -M  $^X $__FILE__\n";
}

$_ = 'file';
if ((Esjis::A_ ne '') == (-A ne '')) {
    print "ok - 23 Esjis::A_ == -A  $^X $__FILE__\n";
}
else {
    print "not ok - 23 Esjis::A_ == -A  $^X $__FILE__\n";
}

$_ = 'file';
if ((Esjis::C_ ne '') == (-C ne '')) {
    print "ok - 24 Esjis::C_ == -C  $^X $__FILE__\n";
}
else {
    print "not ok - 24 Esjis::C_ == -C  $^X $__FILE__\n";
}

close(FILE);
unlink('file');

__END__
