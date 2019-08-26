# encoding: Sjis
# This file is encoded in ShiftJIS.
die "This file is not encoded in ShiftJIS.\n" if q{あ} ne "\x82\xa0";

# Esjis::X と -X (Perlのファイルテスト演算子) の結果が一致することのテスト

my $__FILE__ = __FILE__;

use Esjis;
print "1..48\n";

if ($^O !~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    for my $tno (1..48) {
        print "ok - $tno # SKIP $^X $0\n";
    }
    exit;
}

open(FILE,'>file');
close(FILE);

open(FILE,'file');

if (((Esjis::r 'file') ne '') == ((-r 'file') ne '')) {
    print "ok - 1 Esjis::r 'file' == -r 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 1 Esjis::r 'file' == -r 'file' $^X $__FILE__\n";
}

if (((Esjis::r FILE) ne '') == ((-r FILE) ne '')) {
    print "ok - 2 Esjis::r FILE == -r FILE $^X $__FILE__\n";
}
else {
    print "not ok - 2 Esjis::r FILE == -r FILE $^X $__FILE__\n";
}

if (((Esjis::w 'file') ne '') == ((-w 'file') ne '')) {
    print "ok - 3 Esjis::w 'file' == -w 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 3 Esjis::w 'file' == -w 'file' $^X $__FILE__\n";
}

if (((Esjis::w FILE) ne '') == ((-w FILE) ne '')) {
    print "ok - 4 Esjis::w FILE == -w FILE $^X $__FILE__\n";
}
else {
    print "not ok - 4 Esjis::w FILE == -w FILE $^X $__FILE__\n";
}

if (((Esjis::x 'file') ne '') == ((-x 'file') ne '')) {
    print "ok - 5 Esjis::x 'file' == -x 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 5 Esjis::x 'file' == -x 'file' $^X $__FILE__\n";
}

if (((Esjis::x FILE) ne '') == ((-x FILE) ne '')) {
    print "ok - 6 Esjis::x FILE == -x FILE $^X $__FILE__\n";
}
else {
    print "not ok - 6 Esjis::x FILE == -x FILE $^X $__FILE__\n";
}

if (((Esjis::o 'file') ne '') == ((-o 'file') ne '')) {
    print "ok - 7 Esjis::o 'file' == -o 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 7 Esjis::o 'file' == -o 'file' $^X $__FILE__\n";
}

if (((Esjis::o FILE) ne '') == ((-o FILE) ne '')) {
    print "ok - 8 Esjis::o FILE == -o FILE $^X $__FILE__\n";
}
else {
    print "not ok - 8 Esjis::o FILE == -o FILE $^X $__FILE__\n";
}

if (((Esjis::R 'file') ne '') == ((-R 'file') ne '')) {
    print "ok - 9 Esjis::R 'file' == -R 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 9 Esjis::R 'file' == -R 'file' $^X $__FILE__\n";
}

if (((Esjis::R FILE) ne '') == ((-R FILE) ne '')) {
    print "ok - 10 Esjis::R FILE == -R FILE $^X $__FILE__\n";
}
else {
    print "not ok - 10 Esjis::R FILE == -R FILE $^X $__FILE__\n";
}

if (((Esjis::W 'file') ne '') == ((-W 'file') ne '')) {
    print "ok - 11 Esjis::W 'file' == -W 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 11 Esjis::W 'file' == -W 'file' $^X $__FILE__\n";
}

if (((Esjis::W FILE) ne '') == ((-W FILE) ne '')) {
    print "ok - 12 Esjis::W FILE == -W FILE $^X $__FILE__\n";
}
else {
    print "not ok - 12 Esjis::W FILE == -W FILE $^X $__FILE__\n";
}

if (((Esjis::X 'file') ne '') == ((-X 'file') ne '')) {
    print "ok - 13 Esjis::X 'file' == -X 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 13 Esjis::X 'file' == -X 'file' $^X $__FILE__\n";
}

if (((Esjis::X FILE) ne '') == ((-X FILE) ne '')) {
    print "ok - 14 Esjis::X FILE == -X FILE $^X $__FILE__\n";
}
else {
    print "not ok - 14 Esjis::X FILE == -X FILE $^X $__FILE__\n";
}

if (((Esjis::O 'file') ne '') == ((-O 'file') ne '')) {
    print "ok - 15 Esjis::O 'file' == -O 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 15 Esjis::O 'file' == -O 'file' $^X $__FILE__\n";
}

if (((Esjis::O FILE) ne '') == ((-O FILE) ne '')) {
    print "ok - 16 Esjis::O FILE == -O FILE $^X $__FILE__\n";
}
else {
    print "not ok - 16 Esjis::O FILE == -O FILE $^X $__FILE__\n";
}

if (((Esjis::e 'file') ne '') == ((-e 'file') ne '')) {
    print "ok - 17 Esjis::e 'file' == -e 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 17 Esjis::e 'file' == -e 'file' $^X $__FILE__\n";
}

if (((Esjis::e FILE) ne '') == ((-e FILE) ne '')) {
    print "ok - 18 Esjis::e FILE == -e FILE $^X $__FILE__\n";
}
else {
    print "not ok - 18 Esjis::e FILE == -e FILE $^X $__FILE__\n";
}

if (((Esjis::z 'file') ne '') == ((-z 'file') ne '')) {
    print "ok - 19 Esjis::z 'file' == -z 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 19 Esjis::z 'file' == -z 'file' $^X $__FILE__\n";
}

if (((Esjis::z FILE) ne '') == ((-z FILE) ne '')) {
    print "ok - 20 Esjis::z FILE == -z FILE $^X $__FILE__\n";
}
else {
    print "not ok - 20 Esjis::z FILE == -z FILE $^X $__FILE__\n";
}

if (((Esjis::s 'file') ne '') == ((-s 'file') ne '')) {
    print "ok - 21 Esjis::s 'file' == -s 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 21 Esjis::s 'file' == -s 'file' $^X $__FILE__\n";
}

if (((Esjis::s FILE) ne '') == ((-s FILE) ne '')) {
    print "ok - 22 Esjis::s FILE == -s FILE $^X $__FILE__\n";
}
else {
    print "not ok - 22 Esjis::s FILE == -s FILE $^X $__FILE__\n";
}

if (((Esjis::f 'file') ne '') == ((-f 'file') ne '')) {
    print "ok - 23 Esjis::f 'file' == -f 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 23 Esjis::f 'file' == -f 'file' $^X $__FILE__\n";
}

if (((Esjis::f FILE) ne '') == ((-f FILE) ne '')) {
    print "ok - 24 Esjis::f FILE == -f FILE $^X $__FILE__\n";
}
else {
    print "not ok - 24 Esjis::f FILE == -f FILE $^X $__FILE__\n";
}

if (((Esjis::d 'file') ne '') == ((-d 'file') ne '')) {
    print "ok - 25 Esjis::d 'file' == -d 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 25 Esjis::d 'file' == -d 'file' $^X $__FILE__\n";
}

if (((Esjis::d FILE) ne '') == ((-d FILE) ne '')) {
    print "ok - 26 Esjis::d FILE == -d FILE $^X $__FILE__\n";
}
else {
    print "not ok - 26 Esjis::d FILE == -d FILE $^X $__FILE__\n";
}

if (((Esjis::p 'file') ne '') == ((-p 'file') ne '')) {
    print "ok - 27 Esjis::p 'file' == -p 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 27 Esjis::p 'file' == -p 'file' $^X $__FILE__\n";
}

if (((Esjis::p FILE) ne '') == ((-p FILE) ne '')) {
    print "ok - 28 Esjis::p FILE == -p FILE $^X $__FILE__\n";
}
else {
    print "not ok - 28 Esjis::p FILE == -p FILE $^X $__FILE__\n";
}

if (((Esjis::S 'file') ne '') == ((-S 'file') ne '')) {
    print "ok - 29 Esjis::S 'file' == -S 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 29 Esjis::S 'file' == -S 'file' $^X $__FILE__\n";
}

if (((Esjis::S FILE) ne '') == ((-S FILE) ne '')) {
    print "ok - 30 Esjis::S FILE == -S FILE $^X $__FILE__\n";
}
else {
    print "not ok - 30 Esjis::S FILE == -S FILE $^X $__FILE__\n";
}

if (((Esjis::b 'file') ne '') == ((-b 'file') ne '')) {
    print "ok - 31 Esjis::b 'file' == -b 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 31 Esjis::b 'file' == -b 'file' $^X $__FILE__\n";
}

if (((Esjis::b FILE) ne '') == ((-b FILE) ne '')) {
    print "ok - 32 Esjis::b FILE == -b FILE $^X $__FILE__\n";
}
else {
    print "not ok - 32 Esjis::b FILE == -b FILE $^X $__FILE__\n";
}

if (((Esjis::c 'file') ne '') == ((-c 'file') ne '')) {
    print "ok - 33 Esjis::c 'file' == -c 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 33 Esjis::c 'file' == -c 'file' $^X $__FILE__\n";
}

if (((Esjis::c FILE) ne '') == ((-c FILE) ne '')) {
    print "ok - 34 Esjis::c FILE == -c FILE $^X $__FILE__\n";
}
else {
    print "not ok - 34 Esjis::c FILE == -c FILE $^X $__FILE__\n";
}

if (((Esjis::u 'file') ne '') == ((-u 'file') ne '')) {
    print "ok - 35 Esjis::u 'file' == -u 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 35 Esjis::u 'file' == -u 'file' $^X $__FILE__\n";
}

if (((Esjis::u FILE) ne '') == ((-u FILE) ne '')) {
    print "ok - 36 Esjis::u FILE == -u FILE $^X $__FILE__\n";
}
else {
    print "not ok - 36 Esjis::u FILE == -u FILE $^X $__FILE__\n";
}

if (((Esjis::g 'file') ne '') == ((-g 'file') ne '')) {
    print "ok - 37 Esjis::g 'file' == -g 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 37 Esjis::g 'file' == -g 'file' $^X $__FILE__\n";
}

if (((Esjis::g FILE) ne '') == ((-g FILE) ne '')) {
    print "ok - 38 Esjis::g FILE == -g FILE $^X $__FILE__\n";
}
else {
    print "not ok - 38 Esjis::g FILE == -g FILE $^X $__FILE__\n";
}

if (((Esjis::T 'file') ne '') == ((-T 'file') ne '')) {
    print "ok - 39 Esjis::T 'file' == -T 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 39 Esjis::T 'file' == -T 'file' $^X $__FILE__\n";
}

if (((Esjis::T FILE) ne '') == ((-T FILE) ne '')) {
    print "ok - 40 Esjis::T FILE == -T FILE $^X $__FILE__\n";
}
else {
    print "not ok - 40 Esjis::T FILE == -T FILE $^X $__FILE__\n";
}

if (((Esjis::B 'file') ne '') == ((-B 'file') ne '')) {
    print "ok - 41 Esjis::B 'file' == -B 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 41 Esjis::B 'file' == -B 'file' $^X $__FILE__\n";
}

if (((Esjis::B FILE) ne '') == ((-B FILE) ne '')) {
    print "ok - 42 Esjis::B FILE == -B FILE $^X $__FILE__\n";
}
else {
    print "not ok - 42 Esjis::B FILE == -B FILE $^X $__FILE__\n";
}

if (((Esjis::M 'file') ne '') == ((-M 'file') ne '')) {
    print "ok - 43 Esjis::M 'file' == -M 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 43 Esjis::M 'file' == -M 'file' $^X $__FILE__\n";
}

if (((Esjis::M FILE) ne '') == ((-M FILE) ne '')) {
    print "ok - 44 Esjis::M FILE == -M FILE $^X $__FILE__\n";
}
else {
    print "not ok - 44 Esjis::M FILE == -M FILE $^X $__FILE__\n";
}

if (((Esjis::A 'file') ne '') == ((-A 'file') ne '')) {
    print "ok - 45 Esjis::A 'file' == -A 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 45 Esjis::A 'file' == -A 'file' $^X $__FILE__\n";
}

if (((Esjis::A FILE) ne '') == ((-A FILE) ne '')) {
    print "ok - 46 Esjis::A FILE == -A FILE $^X $__FILE__\n";
}
else {
    print "not ok - 46 Esjis::A FILE == -A FILE $^X $__FILE__\n";
}

if (((Esjis::C 'file') ne '') == ((-C 'file') ne '')) {
    print "ok - 47 Esjis::C 'file' == -C 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 47 Esjis::C 'file' == -C 'file' $^X $__FILE__\n";
}

if (((Esjis::C FILE) ne '') == ((-C FILE) ne '')) {
    print "ok - 48 Esjis::C FILE == -C FILE $^X $__FILE__\n";
}
else {
    print "not ok - 48 Esjis::C FILE == -C FILE $^X $__FILE__\n";
}

close(FILE);
unlink('file');

__END__
