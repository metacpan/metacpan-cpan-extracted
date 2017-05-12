# -*-perl-*-
# run with perl -d:DProf $0 ; dprofpp

use strict;
use POSIX qw(tmpnam);
use File::Path qw(rmtree);
use Template::Alloy;
#use Template::Alloy_60;

my $tt_cache_dir = tmpnam;
END { rmtree $tt_cache_dir };
mkdir $tt_cache_dir, 0755;

my $cet = Template::Alloy->new(ABSOLUTE => 1);
#use Template;
#my $cet = Template->new(ABSOLUTE => 1);

###----------------------------------------------------------------###

my $swap = {
    one   => "ONE",
    two   => "TWO",
    three => "THREE",
    a_var => "a",
    hash  => {a => 1, b => 2, c => { d => ["hmm"] }},
    array => [qw(A B C D E a A)],
    code  => sub {"($_[0])"},
    cet   => $cet,
};

my $txt = '';
$txt .= "[% one %]\n";
$txt .= ((" "x1000)."[% one %]\n")x100;
$txt .= "[%f=10; WHILE (g=f) ; f = f - 1 ; f ; END %]";
$txt .= ("[% \"".(" "x10)."\$one\" %]\n")x1000;

my $file = \$txt;

if (1) {
    $file = $tt_cache_dir .'/template.txt';
    open(my $fh, ">$file") || die "Couldn't open $file: $!";
    print $fh $txt;
    close $fh;
}

###----------------------------------------------------------------###

sub cet {
    my $out = '';
    $cet->process($file, $swap, \$out);
    return $out;
}

cet() for 1 .. 500;
