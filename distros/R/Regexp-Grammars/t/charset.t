use 5.010;
use warnings;

use Test::More;
plan 'no_plan';

use Regexp::Grammars;

# This checks for a bug where [^\]] was not interpreted as a charset.
my $bracket_bug = qr{
    <Bracketed>

    <token: Bracketed>
        \[ <text=( [^!\]]+ )> \]
}xms;

my $escaped_bs = qr{
    <Bracketed>

    <token: Bracketed>
        \[ <text=( [^!\\]+ )> \]
}xms;

my $old_bracket = qr{
    <Bracketed>

    <token: Bracketed>
        \[ <text=( [^]!]+ )> \]
}xms;

no Regexp::Grammars;

while (my $input = <DATA>) {
    chomp $input;
    my ( $text, $to_match ) = split /:/, $input;

    if ( $to_match =~ $bracket_bug ) {
        ok( 'matched bracketed text with [^\]]+' );
        is( $/{Bracketed}{text}, $text );
    }
    else {
        fail( 'did not match bracketed text with [^\]]+' );
    }

    if ( $to_match =~ $escaped_bs ) {
        ok( 'matched bracketed text with [^\\]+' );
        is( $/{Bracketed}{text}, $text );
    }
    else {
        fail( 'did not match bracketed text with [^\\]+' );
    }

    if ( $to_match =~ /$old_bracket/ ) {
        ok( 'matched bracketed text with [^]]+' );
        is( $/{Bracketed}{text}, $text );
    }
    else {
        fail( 'did not match bracketed text with [^]]+' );
    }
}


__DATA__
some text:[some text]
 and more text :[ and more text ]
