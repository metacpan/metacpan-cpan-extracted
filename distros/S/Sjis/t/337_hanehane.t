# encoding: Sjis
# This file is encoded in ShiftJIS.
die "This file is not encoded in ShiftJIS.\n" if q{あ} ne "\x82\xa0";

use Sjis;
print "1..1\n";

my $__FILE__ = __FILE__;

# [96 FB] [92 4A]
$_ = "油谷";

# [FB 92] [89 48]
if ($_ =~ s/羽/羽/g) {
    print qq{not ok - 1 \$_ !~ s/羽/羽/ --> ($_) $^X $__FILE__\n};
}
else {
    if ($_ eq "油谷") {
        print qq{ok - 1 \$_ !~ s/羽/羽/ --> ($_) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 \$_ !~ s/羽/羽/ --> ($_) $^X $__FILE__\n};
    }
}

__END__

kog*2*20 さん

perlでsjisの文字置換。半角、全角の1バイト目2バイト目に的確に正規表現をヒットさせる術
http://blogs.yahoo.co.jp/koga2020/40579992.html

より
