#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 14;

my $foo_re_plain = qr/
(
\A|(?i-xsm:[\Q'\E\-]*)(?si-xm:(?:[\s\x20]|[^\w\Q'\E\-])+)(?i-xsm:[\Q'\E\-]?)
)
(
foo
)
(
\Z|(?i-xsm:[\Q'\E\-]*)(?si-xm:(?:[\s\x20]|[^\w\Q'\E\-])+)(?i-xsm:[\Q'\E\-]?)
)
/xis;

use_ok('Search::Tools::QueryParser');
ok( my $qp    = Search::Tools::QueryParser->new(), "new queryparser" );
ok( my $query = $qp->parse('foo bar'),             "parse 'foo bar'" );
ok( $query->regex_for('foo')->isa('Search::Tools::RegEx'),
    "regex isa RegEx" );

# perl >= 5.14 will fail here.
#is( $query->regex_for('foo')->plain, $foo_re_plain, "foo_re_plain" );

like( 'foo', $query->regex_for('foo')->plain, "match foo plain" );
like( 'foo', $query->regex_for('foo')->html,  "match foo html" );

#diag('-' x 80);
#diag($foo_re_plain);

my $foo_re_plain_no_hyphen = qr/
(
\A|(?i-xsm:[\Q'\E\-]*)(?si-xm:(?:[\s\x20]|[^\w\Q'\E\.])+)(?i-xsm:[\Q'\E\-]?)
)
(
foo
)
(
\Z|(?i-xsm:[\Q'\E\-]*)(?si-xm:(?:[\s\x20]|[^\w\Q'\E\.])+)(?i-xsm:[\Q'\E\-]?)
)
/xis;

ok( my $qp_no_hyphen = Search::Tools::QueryParser->new(
        word_characters => '\w' . quotemeta("'.")
    ),
    "new qp with no hyphen in word_characters"
);
ok( my $query_no_hyphen = $qp_no_hyphen->parse('foo-bar'),
    "parse 'foo-bar'" );
ok( $query_no_hyphen->regex_for('foo')->isa('Search::Tools::RegEx'),
    "regex isa RegEx" );

# perl >= 5.14 will fail here -- see 21...t for explanation.
#is( $query_no_hyphen->regex_for('foo')->plain,
#    $foo_re_plain_no_hyphen, "foo_re_plain" );


like( 'foo', $query_no_hyphen->regex_for('foo')->plain, "match foo plain" );
like( 'foo', $query_no_hyphen->regex_for('foo')->html,  "match foo html" );

ok( my $qp_wonly
        = Search::Tools::QueryParser->new( word_characters => '\w', ),
    "qp_wonly"
);
ok( my $wonly_query = $qp_wonly->parse('garden*'), "parse wonly" );
like( 'LIFE--GARDENING', $wonly_query->regex_for('garden*')->plain,
    "match garden" );
