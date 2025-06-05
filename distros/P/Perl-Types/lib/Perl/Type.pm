# [[[ HEADER ]]]
package Perl::Type;
use strict;
use warnings;
use Perl::Config;  # don't use Perl::Types inside itself, in order to avoid circular includes
our $VERSION = 0.002_000;

# [[[ OO INHERITANCE ]]]
use parent qw(Perl::Class);
use Perl::Class;

# [[[ INCLUDES ]]]
# include modifiers here to be utilized by individual data types
use Perl::Type::Modifier::Reference;

1;  # end of package
