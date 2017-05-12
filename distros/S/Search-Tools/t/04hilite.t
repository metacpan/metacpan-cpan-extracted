use Test::More tests => 19;
use strict;

use Data::Dump qw( dump );

use_ok('Search::Tools::HiLiter');
use_ok('Search::Tools::Snipper');

my $text = <<EOF;
when in the course of human events
you need to create a test to prove that
your code isn't just a silly mishmash
of squiggle this and squiggle that,
type man! type! until you've reached
enough words to justify your paltry existence.
amen.
EOF

my @q = ( 'squiggle', 'type', 'course', '"human events"' );

ok( my $query = Search::Tools->parser->parse( join( ' ', @q ) ),
    "new query" );
ok( my $h = Search::Tools::HiLiter->new( query => $query ), "hiliter" );
ok( my $s = Search::Tools::Snipper->new( query => $query ), "snipper" );

#diag( dump( $re ) );

ok( my $snip = $s->snip($text), "snip" );

#diag($snip);
#diag($s->snipper_name);
#diag($s->count);

ok( my $l = $h->light($snip), "light" );

#diag($l);

# and again

$text = Search::Tools->slurp('t/docs/test.txt');

@q = qw(intramuralism maimedly sculpt);

ok( $h = Search::Tools::HiLiter->new( query => join( ' ', @q ) ),
    "new hiliter" );
ok( $s = Search::Tools::Snipper->new( query => $h->query ), "new snipper" );

ok( $snip = $s->snip($text), "new snip" );

#diag($snip);
#diag($s->snipper_name);
#diag($s->count);

ok( $l = $h->light($snip), "new light" );

#diag($l);

# now just a raw html file without snipping

ok( $h = Search::Tools::HiLiter->new(
        query =>
            q/o'reilly the quick brown fox* jumped! "jumped over the too lazy"/,

        #tty       => 1,
        #no_html   => 1,
        stopwords => 'the'
    ),
    "nosnip hiliter"
);
$text = Search::Tools->slurp('t/docs/test.html');
ok( $l = $h->light($text), "nosnip light" );

# test text_color
ok( $h = Search::Tools::HiLiter->new(
        query =>
            q/o'reilly the quick brown fox* jumped! "jumped over the too lazy"/,

        #tty       => 1,
        #debug => 1,
        stopwords  => 'the',
        text_color => '#fff',
    ),
    "nosnip hiliter text_color"
);
ok( $l = $h->light($text), "nosnip light text_color" );
like( $l, qr/color:#fff;/, "text_color used" );

#diag($l);

# test word_characters
# we test here that {`} is a "word" so the phrase
# does not match
$text = 'AirMail {`} Username]: {`} Password: {`} Remember Name';
my $q = '"airmail username"';
ok( $query = Search::Tools->parser(
        word_characters => '\w' . quotemeta("'-.`{}")
        )->parse($q),
    "word_characters"
);

ok( $h = Search::Tools->hiliter( query => $query ),
    "hiliter for word_characters regex" );

is( $h->light($text), $text, "light word_characters has no match" );
