# encoding: Sjis
# This file is encoded in ShiftJIS.
die "This file is not encoded in ShiftJIS.\n" if q{あ} ne "\x82\xa0";

my $__FILE__ = __FILE__;

use Sjis;
print "1..1\n";

if ($^O !~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    print "ok - 1 # SKIP $^X $0\n";
    exit;
}

if (($ENV{'PERL5SHELL'}||$ENV{'COMSPEC'}) =~ / \\COMMAND\.COM \z/oxmsi) {
    system('rmdir D2機能');
}
else {
    system('rmdir D2機能 2>NUL');
}

# mkdir
if (mkdir('D2機能',0777)) {
    print "ok - 1 mkdir $^X $__FILE__\n";
}
else {
    print "not ok - 1 mkdir: $! $^X $__FILE__\n";
}

if (($ENV{'PERL5SHELL'}||$ENV{'COMSPEC'}) =~ / \\COMMAND\.COM \z/oxmsi) {
    system('rmdir D2機能');
}
else {
    system('rmdir D2機能 2>NUL');
}

__END__
