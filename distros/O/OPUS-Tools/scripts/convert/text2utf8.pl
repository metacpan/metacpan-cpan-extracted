#!/usr/bin/perl
#

use strict;

use Getopt::Std;
use Encode;
use File::BOM qw( :all );

use vars qw/$opt_l $opt_e/;

getopts('l:e:');

my $lang = $opt_l || 'unknown';
my $enc = $opt_e || LangEncoding($lang);


binmode(STDIN);
binmode(STDOUT,':encoding(utf8)');

my $line = <>;
($line, $enc) = decode_from_bom($line,$enc);
binmode(STDIN,":encoding($enc)");


do {
    # remove dos line endings
    $line=~s/\r\n$/\n/;

    print $line;
    $line = <STDIN>;
}
until (! $line);



## guess character encoding

sub LangEncoding{
    my $lang = shift;

# supported by Perl Encode:
# http://perldoc.perl.org/Encode/Supported.html

    return 'utf-8' if ($lang=~/^(utf8)$/);
    return 'iso-8859-4' if ($lang=~/^(ice)$/);
    ## what is scc?
    return 'cp1250' if ($lang=~/^(alb|bos|cze|pol|rum|scc|scr|slv|hrv)$/); 
#    return 'iso-8859-2' if ($lang=~/^(alb|bos)$/);
    return 'cp1251' if ($lang=~/^(bul|mac|rus|bel)$/);
#    return 'cp1252' if ($lang=~/^(dan|dut|epo|est|fin|fre|ger|hun|ita|nor|pob|pol|por|spa|swe)$/);
    return 'cp1253' if ($lang=~/^(ell|gre)$/);
    return 'cp1254' if ($lang=~/^(tur)$/);
    return 'cp1255' if ($lang=~/^(heb)$/);
    return 'cp1256' if ($lang=~/^(ara)$/);
    return 'cp1257' if ($lang=~/^(lat|lit)$/);  # correct?
    return 'big5-eten' if ($lang=~/^(chi|zho)$/);
#    return 'utf-8' if ($lang=~/^(jpn)$/);
    return 'shiftjis' if ($lang=~/^(jpn)$/);
#    return 'cp932' if ($lang=~/^(jpn)$/);
    return 'euc-kr' if ($lang=~/^(kor)$/);
#    return 'cp949' if ($lang=~/^(kor)$/);
    return 'cp1252';
#    return 'iso-8859-6' if ($lang=~/^(ara)$/);
#    return 'iso-8859-7' if ($lang=~/^(ell|gre)$/);
#    return 'iso-8859-1';

## unknown: haw (hawaiian), hrv (crotioan), amh (amharic) gai (borei)
##          ind (indonesian), max (North Moluccan Malay), may (Malay?)
}

