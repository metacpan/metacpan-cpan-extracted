use strict;
use warnings;
use Test::More;

use Net::NicoVideo::URL;

for my $tld ( qw(ms sc) ){

    my $pairs = {
"http://nico.$tld/sm9"        => "http://www.nicovideo.jp/watch/sm9",
"http://nico.$tld/nm2522142"  => "http://www.nicovideo.jp/watch/nm2522142",
"http://nico.$tld/im826267"   => "http://seiga.nicovideo.jp/seiga/im826267?ref=nicoms",
"http://nico.$tld/sg1"        => "http://seiga.nicovideo.jp/watch/sg1?ref=nicoms",
"http://nico.$tld/mg10940"    => "http://seiga.nicovideo.jp/watch/mg10940?ref=nicoms",
"http://nico.$tld/bk1"        => "http://seiga.nicovideo.jp/watch/bk1",
"http://nico.$tld/lv10"       => "http://live.nicovideo.jp/watch/lv10",
"http://nico.$tld/l/co1"      => "http://live.nicovideo.jp/watch/co1",
"http://nico.$tld/co1"        => "http://com.nicovideo.jp/community/co1",
"http://nico.$tld/ch1"        => "http://ch.nicovideo.jp/channel/ch1",
"http://nico.$tld/ar2760"     => "http://ch.nicovideo.jp/article/ar2760",
"http://nico.$tld/nd1"        => "http://chokuhan.nicovideo.jp/products/detail/1",
"http://nico.$tld/azB000YGIP66"             => "http://ichiba.nicovideo.jp/item/azB000YGIP66",
"http://nico.$tld/ysamiami_MED-CD2-00562"   => "http://ichiba.nicovideo.jp/item/ysamiami_MED-CD2-00562",
"http://nico.$tld/ggbo-09090979"            => "http://ichiba.nicovideo.jp/item/ggbo-09090979",
"http://nico.$tld/ndsupplier_027"           => "http://ichiba.nicovideo.jp/item/ndsupplier_027",
"http://nico.$tld/dw1"                      => "http://ichiba.nicovideo.jp/item/dw1",
"http://nico.$tld/it2334005982"             => "http://ichiba.nicovideo.jp/item/it2334005982",
"http://nico.$tld/ap11"       => "http://app.nicovideo.jp/app/ap11",
"http://nico.$tld/jk1"        => "http://jk.nicovideo.jp/watch/jk1",
"http://nico.$tld/nc1"        => "http://www.niconicommons.jp/material/nc1",
"http://nico.$tld/nw1"        => "http://news.nicovideo.jp/watch/nw1",
"http://nico.$tld/dic/1"      => "http://dic.nicovideo.jp/id/1",
"http://nico.$tld/user/1"     => "http://www.nicovideo.jp/user/1",
"http://nico.$tld/mylist/26"  => "http://www.nicovideo.jp/mylist/26",
    };

    for my $s ( sort keys %$pairs ){
        my $l = $pairs->{$s};
        $s =~ s/nico\.sc/nico\.ms/g;
        is( shorten($l), $s, "shorten $l");
        is( unshorten($s), $l, "unshorten $s");
    }

}

done_testing();
1;
__END__
