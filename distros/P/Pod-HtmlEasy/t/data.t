#! /usr/bin/perl
#
#===============================================================================
#
#         FILE:  data.t
#
#  DESCRIPTION:  Test data delivered by Pod::HtmlEasy::Data for consistency
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Geoffrey Leach (), <geoff@hughes.net>
#      COMPANY:
#      VERSION:  1.1.11
#      CREATED:  02/13/08 13:22:58 PST
#     REVISION:  ---
#    COPYRIGHT:  (c) 2008-2010 Geoffrey Leach
#===============================================================================

use 5.006002;

use strict;
use warnings;

use lib qw(./t);
use Test::More tests => 24;

use Data;

BEGIN {
    use_ok(q{Pod::HtmlEasy::Data});
}

is( Pod::HtmlEasy::Data::EMPTY, Data::EMPTY, q{EMPTY} );
is( Pod::HtmlEasy::Data::FALSE, Data::FALSE, q{FALSE} );
is( Pod::HtmlEasy::Data::NL,    Data::NL,    q{NL} );
is( Pod::HtmlEasy::Data::NUL,   Data::NUL,   q{NUL} );
is( Pod::HtmlEasy::Data::SPACE, Data::SPACE, q{SPACE} );
is( Pod::HtmlEasy::Data::TRUE,  Data::TRUE,  q{TRUE} );

is_deeply( [Pod::HtmlEasy::Data::body], [Data::body], q{body default} );

is_deeply(
    [ Pod::HtmlEasy::Data::body(q{alink => '#XX0000'}) ],
    [ Data::body(q{alink => '#XX0000'}) ],
    q{body item}
);

is_deeply(
    [ Pod::HtmlEasy::Data::body( { alink => '#XX0000' } ) ],
    [ Data::body( { alink => '#XX0000' } ) ],
    q{body hashref}
);

is_deeply( [Pod::HtmlEasy::Data::css], [Data::css], q{css} );

is_deeply(
    [ Pod::HtmlEasy::Data::css(q{file.css}) ],
    [ Data::css(q{file.css}) ],
    q{css file}
);

is_deeply(
    [ Pod::HtmlEasy::Data::css(qq{this is some\nphoney css}) ],
    [ Data::css(qq{this is some\nphoney css}) ],
    q{css data}
);

is_deeply( [ Pod::HtmlEasy::Data::gen( q{V1}, q{v2} ) ],
    [ Data::gen( q{V1}, q{v2} ) ], q{gen} );

is_deeply( [Pod::HtmlEasy::Data::head], [Data::head], q{head} );

is_deeply( [Pod::HtmlEasy::Data::headend], [Data::headend], q{headend} );

is_deeply( [Pod::HtmlEasy::Data::podoff], [Data::podoff], q{podoff body} );

is_deeply(
    [ Pod::HtmlEasy::Data::podoff(1) ],
    [ Data::podoff(1) ],
    q{podoff no body}
);

is_deeply( [Pod::HtmlEasy::Data::podon], [Data::podon], q{podon} );

is_deeply( [ Pod::HtmlEasy::Data::title(q{title}) ],
    [ Data::title(q{title}) ], q{title} );

is_deeply( [Pod::HtmlEasy::Data::toc], [Data::toc], q{toc} );

is_deeply(
    [ Pod::HtmlEasy::Data::toc(q{data}) ],
    [ Data::toc(q{data}) ],
    q{toc data}
);

is_deeply(
    [ Pod::HtmlEasy::Data::toc_tag(q{tag text}) ],
    [ Data::toc_tag(q{tag text}) ],
    q{toc tag}
);

is_deeply( [Pod::HtmlEasy::Data::top], [Data::top], q{top} );
