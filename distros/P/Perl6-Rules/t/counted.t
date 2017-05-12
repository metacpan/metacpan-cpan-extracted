use Perl6::Rules;
use Test::Simple 'no_plan';

my $data = "f fo foo fooo foooo fooooo foooooo";
my $sub1 = "f bar foo fooo foooo fooooo foooooo";
my $sub2 = "f fo bar fooo foooo fooooo foooooo";
my $sub3 = "f fo foo bar foooo fooooo foooooo";
my $sub4 = "f fo foo fooo bar fooooo foooooo";
my $sub5 = "f fo foo fooo foooo bar foooooo";
my $sub6 = "f fo foo fooo foooo fooooo bar";

# :nth(N)...

ok( $data !~ m:nth(0)/fo+/, "No match nth(0)" );

ok( $data =~ m:nth(1)/fo+/, "Match nth(1)" );
ok( $0 eq 'fo', "Matched value for nth(1)" );

ok( $data =~ m:nth(2)/fo+/, "Match nth(2)" );
ok( $0 eq 'foo', "Matched value for nth(2)" );

ok( $data =~ m:nth(3)/fo+/, "Match nth(3)" );
ok( $0 eq 'fooo', "Matched value for nth(3)" );

ok( $data =~ m:nth(4)/fo+/, "Match nth(4)" );
ok( $0 eq 'foooo', "Matched value for nth(4)" );

ok( $data =~ m:nth(5)/fo+/, "Match nth(5)" );
ok( $0 eq 'fooooo', "Matched value for nth(5)" );

ok( $data =~ m:nth(6)/fo+/, "Match nth(6)" );
ok( $0 eq 'foooooo', "Matched value for nth(6)" );

ok( $data !~ m:nth(7)/fo+/, "No match nth(7)" );


# :nth($N)...

for $N (1..6) {
	ok( $data =~ m:nth($N)/fo+/, "Match nth(\$N) for \$N == $N" );
	ok( $0 eq 'f'.'o'x$N, "Matched value for $N" );
}


# :Nst...

ok( $data =~ m:1st/fo+/, "Match 1st" );
ok( $0 eq 'fo', "Matched value for 1st" );

ok( $data =~ m:2st/fo+/, "Match 2st" );
ok( $0 eq 'foo', "Matched value for 2st" );

ok( $data =~ m:3st/fo+/, "Match 3st" );
ok( $0 eq 'fooo', "Matched value for 3st" );

ok( $data =~ m:4st/fo+/, "Match 4st" );
ok( $0 eq 'foooo', "Matched value for 4st" );

ok( $data =~ m:5st/fo+/, "Match 5st" );
ok( $0 eq 'fooooo', "Matched value for 5st" );

ok( $data =~ m:6st/fo+/, "Match 6st" );
ok( $0 eq 'foooooo', "Matched value for 6st" );

ok( $data !~ m:7st/fo+/, "No match 7st" );


# :Nnd...

ok( $data =~ m:1nd/fo+/, "Match 1nd" );
ok( $0 eq 'fo', "Matched value for 1nd" );

ok( $data =~ m:2nd/fo+/, "Match 2nd" );
ok( $0 eq 'foo', "Matched value for 2nd" );

ok( $data =~ m:3nd/fo+/, "Match 3nd" );
ok( $0 eq 'fooo', "Matched value for 3nd" );

ok( $data =~ m:4nd/fo+/, "Match 4nd" );
ok( $0 eq 'foooo', "Matched value for 4nd" );

ok( $data =~ m:5nd/fo+/, "Match 5nd" );
ok( $0 eq 'fooooo', "Matched value for 5nd" );

ok( $data =~ m:6nd/fo+/, "Match 6nd" );
ok( $0 eq 'foooooo', "Matched value for 6nd" );

ok( $data !~ m:7nd/fo+/, "No match 7nd" );


# :Nrd...

ok( $data =~ m:1rd/fo+/, "Match 1rd" );
ok( $0 eq 'fo', "Matched value for 1rd" );

ok( $data =~ m:2rd/fo+/, "Match 2rd" );
ok( $0 eq 'foo', "Matched value for 2rd" );

ok( $data =~ m:3rd/fo+/, "Match 3rd" );
ok( $0 eq 'fooo', "Matched value for 3rd" );

ok( $data =~ m:4rd/fo+/, "Match 4rd" );
ok( $0 eq 'foooo', "Matched value for 4rd" );

ok( $data =~ m:5rd/fo+/, "Match 5rd" );
ok( $0 eq 'fooooo', "Matched value for 5rd" );

ok( $data =~ m:6rd/fo+/, "Match 6rd" );
ok( $0 eq 'foooooo', "Matched value for 6rd" );

ok( $data !~ m:7rd/fo+/, "No match 7rd" );


# :Nth...

ok( $data =~ m:1th/fo+/, "Match 1th" );
ok( $0 eq 'fo', "Matched value for 1th" );

ok( $data =~ m:2th/fo+/, "Match 2th" );
ok( $0 eq 'foo', "Matched value for 2th" );

ok( $data =~ m:3th/fo+/, "Match 3th" );
ok( $0 eq 'fooo', "Matched value for 3th" );

ok( $data =~ m:4th/fo+/, "Match 4th" );
ok( $0 eq 'foooo', "Matched value for 4th" );

ok( $data =~ m:5th/fo+/, "Match 5th" );
ok( $0 eq 'fooooo', "Matched value for 5th" );

ok( $data =~ m:6th/fo+/, "Match 6th" );
ok( $0 eq 'foooooo', "Matched value for 6th" );

ok( $data !~ m:7th/fo+/, "No match 7th" );


# Substitutions...

my $try = $data;
ok( $try !~ s:0th{fo+}{bar}, "Can't substitute 0th" );
ok( $try eq $data, 'No change to data for 0th' );

my $try = $data;
ok( $try =~ s:1st{fo+}{bar}, 'substitute 1st' );
ok( $try eq $sub1, 'substituted 1st correctly' );

my $try = $data;
ok( $try =~ s:2nd{fo+}{bar}, 'substitute 2nd' );
ok( $try eq $sub2, 'substituted 2nd correctly' );

my $try = $data;
ok( $try =~ s:3rd{fo+}{bar}, 'substitute 3rd' );
ok( $try eq $sub3, 'substituted 3rd correctly' );

my $try = $data;
ok( $try =~ s:4th{fo+}{bar}, 'substitute 4th' );
ok( $try eq $sub4, 'substituted 4th correctly' );

my $try = $data;
ok( $try =~ s:5th{fo+}{bar}, 'substitute 5th' );
ok( $try eq $sub5, 'substituted 5th correctly' );

my $try = $data;
ok( $try =~ s:6th{fo+}{bar}, 'substitute 6th' );
ok( $try eq $sub6, 'substituted 6th correctly' );

my $try = $data;
ok( $try !~ s:7th{fo+}{bar}, "Can't substitute 7th" );
ok( $try eq $data, 'No change to data for 7th' );


# Other patterns...

ok( $data =~ m:3rd/ f [\d|\w+]/, 'Match 3rd f[\d|\w+]' );
ok( $0 eq 'fooo', 'Matched value for 3rd f[\d|\w+]' );

ok( $data =~ m:3rd/ <ident> /, 'Match 3rd <ident>' );
ok( $0 eq 'o', 'Matched value for 3th <ident>' );

ok( $data =~ m:3rd/ \b <ident> /, 'Match 3rd \b <ident>' );
ok( $0 eq 'foo', 'Matched value for 3th \b <ident>' );


$data = "f fo foo fooo foooo fooooo foooooo";
$sub1 = "f bar foo fooo foooo fooooo foooooo";
$sub2 = "f bar bar fooo foooo fooooo foooooo";
$sub3 = "f bar bar bar foooo fooooo foooooo";
$sub4 = "f bar bar bar bar fooooo foooooo";
$sub5 = "f bar bar bar bar bar foooooo";
$sub6 = "f bar bar bar bar bar bar";

# :x(N)...

ok( $data =~ m:x(0)/fo+/, "No match x(0)" );
ok( $0 eq '', "Matched value for x(0)" );

ok( $data =~ m:x(1)/fo+/, "Match x(1)" );
ok( $0 eq 'fo', "Matched value for x(1)" );

ok( $data =~ m:x(2)/fo+/, "Match x(2)" );
ok( $0 eq 'foo', "Matched value for x(2)" );

ok( $data =~ m:x(2)/fo+ <ws>/, "Match x(2) with <ws>" );
ok( $0 eq 'foo ', "Matched value for x(2) with <ws>" );

ok( $data =~ m:x(3)/fo+/, "Match x(3)" );
ok( $0 eq 'fooo', "Matched value for x(3)" );

ok( $data =~ m:x(4)/fo+/, "Match x(4)" );
ok( $0 eq 'foooo', "Matched value for x(4)" );

ok( $data =~ m:x(5)/fo+/, "Match x(5)" );
ok( $0 eq 'fooooo', "Matched value for x(5)" );

ok( $data =~ m:x(6)/fo+/, "Match x(6)" );
ok( $0 eq 'foooooo', "Matched value for x(6)" );

ok( $data !~ m:x(7)/fo+/, "no match x(7)" );

# :x($N)...

for $N (1..6) {
	ok( $data =~ m:x($N)/fo+/, "Match x(\$N) for \$N == $N" );
	ok( $0 eq 'f'.'o'x$N, "Matched value for $N" );
}

# :Nx...

ok( $data =~ m:1x/fo+/, "Match 1x" );
ok( $0 eq 'fo', "Matched value for 1x" );

ok( $data =~ m:2x/fo+/, "Match 2x" );
ok( $0 eq 'foo', "Matched value for 2x" );

ok( $data =~ m:3x/fo+/, "Match 3x" );
ok( $0 eq 'fooo', "Matched value for 3x" );

ok( $data =~ m:4x/fo+/, "Match 4x" );
ok( $0 eq 'foooo', "Matched value for 4x" );

ok( $data =~ m:5x/fo+/, "Match 5x" );
ok( $0 eq 'fooooo', "Matched value for 5x" );

ok( $data =~ m:6x/fo+/, "Match 6x" );
ok( $0 eq 'foooooo', "Matched value for 6x" );

ok( $data !~ m:7x/fo+/, "No match 7x" );

# Substitutions...

my $try = $data;
ok( $try !~ s:0x{fo+}{bar}, "Can't substitute 0x" );
ok( $try eq $data, 'No change to data for 0x' );

my $try = $data;
ok( $try =~ s:1x{fo+}{bar}, 'substitute 1x' );
ok( $try eq $sub1, 'substituted 1x correctly' );

my $try = $data;
ok( $try =~ s:2x{fo+}{bar}, 'substitute 2x' );
ok( $try eq $sub2, 'substituted 2x correctly' );

my $try = $data;
ok( $try =~ s:3x{fo+}{bar}, 'substitute 3x' );
ok( $try eq $sub3, 'substituted 3x correctly' );

my $try = $data;
ok( $try =~ s:4x{fo+}{bar}, 'substitute 4x' );
ok( $try eq $sub4, 'substituted 4x correctly' );

my $try = $data;
ok( $try =~ s:5x{fo+}{bar}, 'substitute 5x' );
ok( $try eq $sub5, 'substituted 5x correctly' );

my $try = $data;
ok( $try =~ s:6x{fo+}{bar}, 'substitute 6x' );
ok( $try eq $sub6, 'substituted 6x correctly' );

my $try = $data;
ok( $try =~ s:7x{fo+}{bar}, "substitute 7x" );
ok( $try eq $sub6, 'substituted 7x correctly' );


# Global Nth

$data  = "f fo foo fooo foooo fooooo foooooo";
$gsub1 = "f bar bar bar bar bar bar";
$gsub2 = "f fo bar fooo bar fooooo bar";
$gsub3 = "f fo foo bar foooo fooooo bar";
$gsub4 = "f fo foo fooo bar fooooo foooooo";
$gsub5 = "f fo foo fooo foooo bar foooooo";
$gsub6 = "f fo foo fooo foooo fooooo bar";

my $try = $data;
ok( $try =~ s:g:1st{fo+}{bar}, "Global :1st match" );
ok( $try eq $gsub1, 'substituted :g:1st correctly' );

my $try = $data;
ok( $try =~ s:g:2nd{fo+}{bar}, "Global :2nd match" );
ok( $try eq $gsub2, 'substituted :g:2nd correctly' );

my $try = $data;
ok( $try =~ s:g:3rd{fo+}{bar}, "Global :3rd match" );
ok( $try eq $gsub3, 'substituted :g:3rd correctly' );

my $try = $data;
ok( $try =~ s:g:4th{fo+}{bar}, "Global :4th match" );
ok( $try eq $gsub4, 'substituted :g:4th correctly' );

my $try = $data;
ok( $try =~ s:g:5th{fo+}{bar}, "Global :5th match" );
ok( $try eq $gsub5, 'substituted :g:5th correctly' );

my $try = $data;
ok( $try =~ s:g:6th{fo+}{bar}, "Global :6th match" );
ok( $try eq $gsub6, 'substituted :g:6th correctly' );

my $try = $data;
ok( $try !~ s:g:7th{fo+}{bar}, "Global :7th match" );
ok( $try eq $data, 'substituted :g:7th correctly' );
