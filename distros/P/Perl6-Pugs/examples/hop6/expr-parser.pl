## Chapter 8 section 4

use v6-alpha;

use FindBin;
use lib $FindBin::RealDir;
use Parser;# :all;
use Lexer;# :all;
require 'it2stream.pl';

## SETUP PARSER
my $expression;
my $parser = sub { $expression.(@_) };
$expression = alternate(concatenate(lookfor('INT'),
                                    lookfor(['OP', '+']),
                                    $parser),
                        concatenate(lookfor('INT'),
                                    lookfor(['OP', '*']),
                                    $parser),
                        concatenate(lookfor(['OP', '(']),
                                    $parser,
                                    lookfor(['OP', ')'])),
                        lookfor('INT'));

my $entire_input = concatenate($parser, &End_of_Input);
my @input        = q[2 * 3 + (4 * 5)];

## SETUP LEXER
my $input = sub { return @input.shift };
my $lexer = iterator_to_stream(
               make_lexer($input,
                       ## XXX - Change these back to regexes?
                       ['TERMINATOR', ";\n*|\n+"                 ], 
                       ['INT',        '\d+'                      ],
                       ['PRINT',      '\bprint\b'                ],
                       ['IDENTIFIER', '[A-Za-z_]\w*'             ],
                       ['OP',         '\*\*|[-=+*/()]'           ],
                       ['WHITESPACE', '\s+',          sub { "" } ],
               )
             ); 

# say 'lexer looks like: ', show($lexer, 10);

my($result, $remaining_input) = $entire_input.($lexer);
if ?$result {
  say $result.perl;
} else {
  say "Didn't get anything back, must be a parse error.";
}

=pod

=head1 NAME

expr-parser.pl - A simple expression parser from Mark Jason Dominus' "Higher
Order Perl"

=head1 DESCRIPTION

This is a perl6 translation of the expression parser from HOP. It is intended as
to be a straight translation i.e it takes advantage of function signatures but
doesn't change the code unnecessarily. I have changed the code in places, but
that was mostly for my own sanity, so feel free to revert to the original code,
which can be found here:

  http://hop.perl.plover.com/Examples/

Its current state is that the lexer looks to be built fine but when it comes to
parsing the expression there are issues with the closures, which aren't too
obvious at this point, and the parsing fails. So some functional debugging
ninjas would probably do quite well at this. Introspection will definitely help.

=head1 AUTHOR

Originally from Higher-Order Perl by Mark Dominus, published by Morgan Kaufmann Publishers, Copyright 2005 by Elsevier Inc

Dan Brook (Perl 6 translator)

=cut
