use strict;
use Test;
BEGIN { plan tests => 11 }
use Syntax::Highlight::Shell;

# check that the following functions are available
ok( exists &Syntax::Highlight::Shell::new              ); #01
ok( exists &Syntax::Highlight::Shell::parse            ); #02
ok( exists &Syntax::Highlight::Shell::_generic_highlight ); #03

# create an object
my $highlighter = undef;
eval { $highlighter = new Syntax::Highlight::Shell };
ok( $@, ''                                             ); #04
ok( defined $highlighter                               ); #05
ok( $highlighter->isa('Syntax::Highlight::Shell' )     ); #06
ok( ref $highlighter, 'Syntax::Highlight::Shell'       ); #07

# check that the following object methods are available
ok( ref $highlighter->can('can')              , 'CODE' ); #08
ok( ref $highlighter->can('new')              , 'CODE' ); #09
ok( ref $highlighter->can('parse')            , 'CODE' ); #10
ok( ref $highlighter->can('_generic_highlight'),'CODE' ); #11

