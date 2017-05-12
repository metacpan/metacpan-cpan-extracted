# trivial XML parser written to create testable trees
package ToyXML;

require Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw(parse);

use strict;
use warnings;
use Element;
use Carp;

our ( $root, @attributes, @stack, $b1, $b2 );
our $parsing_re = qr!

^ \s*+ (?&element) \s*+ $

(?(DEFINE)
   (?<element> (?&single) | (?&paired))
   (?<single> 
      < 
      ((?&tag)) 
      (?{ 
         local $b1 = $^N;
         local @attributes;
       })
      (?&attributes)
      \s*+ />
      (?{ construct() })
   )
   (?<paired> 
      < 
      (?<t>(?&tag)) 
      (?{
         local $b1 = $^N;
         local @attributes;
      })
      (?&attributes)
      \s*+ >
      (?{ push @stack, construct() })
      (?: \s*+ (?&element) )*+ \s*+
      </ \k<t> >
      (?{ pop @stack })
   )
   (?<tag> [^"<>=/\s]++ )
   (?<attributes> (?: \s++ (?&attribute) )*+ )
   (?<attribute>
      ((?&tag)) 
      (?{ local $b1 = $^N })
      = (?: "((?&att_val))" | '((?&att_val))' )
      (?{
         local $b2 = $^N;
         push @attributes, [ $b1, $b2 ];
      })
   )
   (?<att_val> [^"']*+ )
)
!x;

# build AST
sub construct {
    local $b1 = {
        tag        => $b1,
        children   => [],
        attributes => { map { $_->[0] => $_->[1] } @attributes }
    };
    if ( $stack[-1] ) {
        push @{ $stack[-1]->{children} }, $b1;
    }
    else {
        $root = $b1;
    }
    return $b1;
}

# convert AST into an XML tree
sub deconstruct {
    my ( $ref, $parent ) = @_;
    my $e = Element->new( tag => $ref->{tag}, parent => $parent );
    while ( my ( $k, $v ) = each %{ $ref->{attributes} } ) {
        $e->attribute( $k, $v );
    }
    for my $child ( @{ $ref->{children} } ) {
        push @{ $e->children }, deconstruct( $child, $e );
    }
    return $e;
}

# convert string into XML tree
sub parse {
    my $str = shift;
    local ( $root, @stack );
    if ( $str =~ $parsing_re ) {
        return deconstruct($root);
    }
    else {
        confess "cannot parse as XML: $str";
    }
}

1;
