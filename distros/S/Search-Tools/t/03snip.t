#!/usr/bin/env perl
use strict;
use Test::More tests => 20;
use Data::Dump qw( dump );


BEGIN { use_ok('Search::Tools::Snipper') }

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

ok( my $s = Search::Tools::Snipper->new(
        query     => join( ' ', @q ),
        max_chars => length($text) - 1,
    ),
    "snipper"
);

ok( my $snip = $s->snip($text), "snip" );

#diag($snip);
#diag( $s->type_used );

ok( length($snip) < $s->max_chars, "max_chars" );

#diag($s->type_used);

$text = Search::Tools->slurp('t/docs/test.txt');

@q = qw(intramuralism maimedly sculpt);

ok( $s = Search::Tools::Snipper->new(
        query     => join( ' ', @q ),
        max_chars => length($text) - 1,
    ),
    "new snipper"
);

ok( $snip = $s->snip($text), "new snip" );

#diag($snip);
#diag( $s->type_used );

ok( length($snip) < $s->max_chars, "more snip" );

# test context
my $text2 = <<EOF;
when in the course of human events
you need to create a test to prove that
your code isn't just a silly mishmash
of squiggle this and squiggle that,
type man! type! until you've reached
enough words to justify your paltry existence.
amen.
consider the lilies. do they toil or spin?
yet they do not speak either, nor write. which
means that they do not generate text worth snipping.
EOF

my $excerpt
    = qq{type man! type! until you've reached enough words to justify your paltry existence. amen. consider the lilies. do they toil or spin?};

my $query        = Search::Tools->parser->parse('amen');
my $snip_excerpt = Search::Tools::Snipper->new(
    query   => $query,
    occur   => 1,
    context => 26,
);
my $snip_title = Search::Tools::Snipper->new(
    query   => $query,
    occur   => 1,
    context => 8,
);
my $snip_pp = Search::Tools::Snipper->new(
    query   => $query,
    occur   => 1,
    context => 26,
    use_pp  => 1,
);

like( $snip_excerpt->snip($text2), qr/$excerpt/, "excerpt context" );
ok( $snip_excerpt->type('re'), "set re type" );
like( $snip_excerpt->snip($text2), qr/$excerpt/,
    "re matches loop algorithm" );

#diag( $snip_excerpt->type_used );

is( $snip_title->snip($text2),
    qq{ ... justify your paltry existence. amen. consider the lilies. do ... },
    "8 context"
);

#diag( $snip_title->type_used );

like( $snip_pp->snip($text2), qr/$excerpt/, "excerpt context" );

############
# phrases
my $phrased = '"reached heaven" perjury';
ok( my $strict_phrase_snipper = Search::Tools::Snipper->new(
        query                    => $phrased,
        treat_phrases_as_singles => 0,
        show                     => 0,
    ),
    "strict_phrase_snipper"
);
ok( !$strict_phrase_snipper->snip($text2), "snip text2 with strict phrase" );

ok( my $loose_phrase_snipper = Search::Tools::Snipper->new(
        query => $phrased,
        show  => 0,
    ),
    "loose_phrase_snipper"
);
ok( my $phrased_snip = $loose_phrase_snipper->snip($text2),
    "snip text2 with loose phrase" );

is( $phrased_snip,
    qq/ ... man! type! until you've reached enough words to justify ... /,
    "phrased_snip" );

##############
## markup
my $text_with_markup
    = '<a href="link">this text is cheap</a> and filler and otherwise unimpressive but <b>this</b> is important!';
ok( my $no_markup_snipper = Search::Tools::Snipper->new(
        strip_markup  => 1,
        query         => 'this',
        show          => 1,
        ignore_length => 1,
    ),
    "new no_markup_snipper"
);
ok( my $stripped = $no_markup_snipper->snip($text_with_markup),
    "snip marked up text" );
is( $stripped,
    ' ... this text is cheap and ... and otherwise unimpressive but this is important ... ',
    "got markedup text stripped and snipped"
);
