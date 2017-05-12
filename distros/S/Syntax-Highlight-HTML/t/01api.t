use strict;
use Test;
BEGIN { plan tests => 13 }
use Syntax::Highlight::HTML;

# check that the following functions are available
ok( exists &Syntax::Highlight::HTML::new               ); #01
ok( exists &Syntax::Highlight::HTML::parse             ); #02
ok( exists &Syntax::Highlight::HTML::_highlight_tag    ); #03
ok( exists &Syntax::Highlight::HTML::_highlight_text   ); #04

# create an object
my $highlighter = undef;
eval { $highlighter = new Syntax::Highlight::HTML };
ok( $@, ''                                             ); #05
ok( defined $highlighter                               ); #06
ok( $highlighter->isa('Syntax::Highlight::HTML' )      ); #07
ok( ref $highlighter, 'Syntax::Highlight::HTML'        ); #08

# check that the following object methods are available
ok( ref $highlighter->can('can')              , 'CODE' ); #09
ok( ref $highlighter->can('new')              , 'CODE' ); #10
ok( ref $highlighter->can('parse')            , 'CODE' ); #11
ok( ref $highlighter->can('_highlight_tag')   , 'CODE' ); #12
ok( ref $highlighter->can('_highlight_text')  , 'CODE' ); #13
