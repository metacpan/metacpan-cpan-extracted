use Test::More tests => 2;

BEGIN {
    use POSIX qw(locale_h);
    use locale;
    setlocale( LC_CTYPE, 'en_US.UTF-8' );
}

use Search::Tools;

{

    package MyResult;
    sub summary { $_[0]->{summary} }
}

my @search_results
    = ( bless( { summary => 'my brown fox is quick' }, 'MyResult' ) );

my $string  = 'the quik brown fox';
my $qparser = Search::Tools->parser();
my $query   = $qparser->parse($string);
my $snipper = Search::Tools->snipper( query => $query );
my $hiliter = Search::Tools->hiliter( query => $query );

for my $result (@search_results) {
    ok( $hiliter->light( $snipper->snip( $result->summary ) ),
        "hilite snipped summary" );
}

SKIP: {

    eval "require Text::Aspell";
    if ($@) {
        skip "Text::Aspell required for SpellCheck", 1;
    }

    my $spellcheck = Search::Tools->spellcheck( query_parser => $qparser );
    my $suggestions = $spellcheck->suggest($string);

    my $ok;
    for my $v (@$suggestions) {
        $ok += scalar @{ $v->{suggestions} };
    }

SKIP: {

        skip "No valid suggestions found. Missing dictionary?", 1 unless $ok;

        for my $s (@$suggestions) {
            if ( !$s->{suggestions} ) {

                # $s->{word} was spelled correctly
            }
            elsif ( @{ $s->{suggestions} } ) {
                my $str = join( ' or ', @{ $s->{suggestions} } );
                ok( "Did you mean: $str\n", "suggestion $str" );
            }
        }

    }

}
