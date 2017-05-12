# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 7;
BEGIN { use_ok('Music::ABC::Archive') };

use File::Compare ;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

makedatafiles() ;

my $abcfile = "test.abc" ;
my $songnum = 1 ;

$abcfile = "test.abc" ;
$songnum = 1 ;

my $abc_obj = Music::ABC::Archive->new($abcfile) ;

ok($abc_obj->openabc($abcfile), "open $abcfile") ;

my @lines = $abc_obj->print_song_summary($songnum) ;

open(F, ">a1_tst.txt") ;

foreach (@lines) {
    print F "$_\n" ;
}

close(F) ;

ok(compare("a1.txt", "a1_tst.txt") == 0, "print song summary") ;

@lines = $abc_obj->print_song_summary($songnum,1) ;

open(F, ">a2_tst.txt") ;

foreach (@lines) {
    print F "$_\n" ;
}

close(F) ;

ok(compare("a2.txt", "a2_tst.txt") == 0, "print song summary with html") ;

@lines = $abc_obj->get_song($songnum) ;

open(F, ">a3_tst.txt") ;

foreach (@lines) {
    print F "$_\n" ;
}

close(F) ;

ok(compare("a3.txt", "a3_tst.txt") == 0, "get song text") ;

my @files = $abc_obj->list_by_title() ;

open(F, ">a4_tst.txt") ;
foreach (@files) {
    my ($display_name, $sn, $type, $meter, $key, $titles_aref) = @{$_} ;
    my $name = "$display_name - $type - Key of $key" ;
    foreach(@$titles_aref) {
	print F "$_ : $display_name : $sn : $type : $meter : Key of $key\n" ;
    }
}
close(F) ;

ok(compare("a4.txt", "a4_tst.txt") == 0, "list_by_title") ;

@lines = $abc_obj->get_archive_header_lines() ;

open(F, ">a5_tst.txt") ;

foreach (@lines) {
    print F "$_\n" ;
}

close(F) ;

ok(compare("a5.txt", "a5_tst.txt") == 0, "get archive header") ;

#unlink glob('a*.txt') ;
#unlink "test.abc" ;

sub makedatafiles
{

open(F, ">a1.txt");
print F <<EOF;
Song Number 1 in test.abc
TITLES 
        Top of the Cork Road, The
        Father O'Flynn
RHYTHM jig
KEY D
METER 6/8
NOTES 
        This is note number 1
        This is note number 2
HISTORY 
DISCOGRAPHY 
INFORMATION 
TRANSCRIPTION 
        Another very widely known tune.
        Song #16 in 'JohnWalsh/sessionTunes.abc'
EOF
close(F);

open(F, ">a2.txt");
print F <<EOF;
<h3><center>Song Number 1 in test.abc</h3>
<dl>
TITLES 
        <dd><pre>Top of the Cork Road, The</pre></dd>
        <dd><pre>Father O'Flynn</pre></dd>
</dl>
<dl>RHYTHM<dd><pre> jig</pre></dd></dl>
<dl>KEY<dd><pre> D</pre></dd></dl>
<dl>METER<dd><pre> 6/8</pre></dd></dl>
<dl>
NOTES 
        <dd><pre>This is note number 1</pre></dd>
        <dd><pre>This is note number 2</pre></dd>
</dl>
<dl>
HISTORY 
</dl>
<dl>
DISCOGRAPHY 
</dl>
<dl>
INFORMATION 
</dl>
<dl>
TRANSCRIPTION 
        <dd><pre>Another very widely known tune.</pre></dd>
        <dd><pre>Song #16 in 'JohnWalsh/sessionTunes.abc'</pre></dd>
</dl>
EOF
close(F);

open(F, ">a3.txt");
print F <<EOF;
X:1
T:Top of the Cork Road, The
T:Father O'Flynn
Z:Another very widely known tune.
M:6/8
R:jig
K:D
Z:Song #16 in 'JohnWalsh/sessionTunes.abc'
N:This is note number 1
N:This is note number 2
A|dAF DFA|ded cBA|dcd efg|fdf ecA|
dAF DFA|ded cBA|dcd efg|fdc d2:|
g|fdf fga|ecA ABc|dcd Bed|cAA A2c|
BGB Bcd|AFD DFA|dcd efg|fdc d2:|

EOF
close(F);

open(F, ">a4.txt");
print F <<EOF;
Top of the Cork Road, The : Father O'Flynn : 1 : jig : 6/8 : Key of D
Father O'Flynn : Father O'Flynn : 1 : jig : 6/8 : Key of D
Father Tom's Wager : Father Tom's Wager : 2 : jig : 6/8 : Key of G
EOF
close(F);

open(F, ">a5.txt") or die ;
print F "% header line 1\n" ;
print F "% header line 2\n" ;
close(F);

open(F, ">test.abc");
print F "% header line 1\n" ;
print F "% header line 2\n" ;
print F <<EOF;
X:1
T:Top of the Cork Road, The
T:Father O'Flynn
Z:Another very widely known tune.
M:6/8
R:jig
K:D
Z:Song #16 in 'JohnWalsh/sessionTunes.abc'
N:This is note number 1
N:This is note number 2
A|dAF DFA|ded cBA|dcd efg|fdf ecA|
dAF DFA|ded cBA|dcd efg|fdc d2:|
g|fdf fga|ecA ABc|dcd Bed|cAA A2c|
BGB Bcd|AFD DFA|dcd efg|fdc d2:|

X:2
T:Father Tom's Wager
R:jig
B:O'Neill's 1005, Krassen O'Neill p 52
M:6/8
L:1/8
K:G
Z:Song #130 in 'warnock/alfjigs.abc'
B/c/|dge dBG|AEF GDB,|G,B,D GBd|{d}cBc ABc|
dge dBG|AEF GDB,|G,B,D GAc|BEF G2:|
d/c/|Bdg bag|fed cAF|DGG FAA|GBB ABc|
Bdg bag|gfe dBG|cec dBG|AEF G2:|
EOF
close(F);
}
