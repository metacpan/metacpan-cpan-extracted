use Test::More tests => 2;

BEGIN {
    use POSIX qw(locale_h);
    use locale;
    setlocale( LC_ALL, 'en_US.UTF-8' );
}

use Search::Tools::QueryParser;

ok( my $qp = Search::Tools::QueryParser->new(), "new QueryParser" );

#diag( 'queryparser locale: ' . $qp->locale );

SKIP: {

    my $locale_ctype = setlocale(LC_CTYPE);
    #diag("setlocale(LC_CTYPE) = $locale_ctype");
    my $locale_all = setlocale(LC_ALL);
    #diag("setlocale(LC_ALL) = $locale_all");

    skip "UTF-8 charset not supported", 1 if $locale_ctype ne 'en_US.UTF-8';

    like( uc($qp->charset), qr/UTF-?8/, "UTF-8 charset" );
}

