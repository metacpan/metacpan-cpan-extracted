use strict;
use Test;
BEGIN { plan tests => 15 }
require Shell::Parser;

# check that the following functions are available
ok( exists &Shell::Parser::new                                ); #01
ok( exists &Shell::Parser::parse                              ); #02
ok( exists &Shell::Parser::eof                                ); #03
ok( exists &Shell::Parser::handlers                           ); #04
ok( exists &Shell::Parser::syntax                             ); #05

# create an object
my $parser = undef;
eval { $parser = new Shell::Parser };
ok( $@, ''                                                    ); #06
ok( defined $parser                                           ); #07
ok( $parser->isa('Shell::Parser')                             ); #08
ok( ref $parser, 'Shell::Parser'                              ); #09

# check that the following object methods are available
ok( ref $parser->can('can'), 'CODE'                           ); #10
ok( ref $parser->can('new'), 'CODE'                           ); #11
ok( ref $parser->can('parse'), 'CODE'                         ); #12
ok( ref $parser->can('eof'), 'CODE'                           ); #13
ok( ref $parser->can('handlers'), 'CODE'                      ); #14
ok( ref $parser->can('syntax'), 'CODE'                        ); #15
