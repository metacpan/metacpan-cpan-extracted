use Test::More tests => 9;

BEGIN {
    use POSIX qw(locale_h);
    use locale;
    setlocale( LC_CTYPE, 'en_US.UTF-8' );
}

SKIP: {

    eval "require Text::Aspell";
    if ($@) {
        skip "Text::Aspell required for SpellCheck", 9;
    }

    use Data::Dump qw(dump);
    use_ok('Search::Tools::SpellCheck');

    my $query
        = 'asdfasdf the quik foo=foxx color:browwn and "lazay dogg" not jumped';

    ok( my $spellcheck = Search::Tools::SpellCheck->new(
            max_suggest => 4,
        ),
        "spellcheck object"
    );

    my $suggestions = $spellcheck->suggest($query);

    #diag(dump($suggestions));

    # if we had no suggestions, then the test is bad due to dictionaries
    # not being installed, locale or other.
    my $ok = 0;
    for my $v (@$suggestions) {
        $ok += scalar @{ $v->{suggestions} };
    }

SKIP: {

        skip "No dictionaries found for locale", 7 unless $ok;

        my %expect = (
            'the'      => 0,
            'quik'     => 4,
            'foxx'     => 3,
            'browwn'   => 4,
            'lazay'    => 4,
            'dogg'     => 4,
            'asdfasdf' => undef
        );

        for my $s (@$suggestions) {
            my $count = $expect{ $s->{word} };

            if ( !defined $count ) {
                ok( !@{ $s->{suggestions} }, $s->{word} );
            }
            elsif ( $count == 0 ) {
                ok( $s->{suggestions} == $count, $s->{word} );
            }
            else {
                ok( scalar( @{ $s->{suggestions} } ) == $count, $s->{word} );
            }
        }

    }

}
