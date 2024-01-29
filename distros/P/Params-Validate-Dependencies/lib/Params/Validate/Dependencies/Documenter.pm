package Params::Validate::Dependencies::Documenter;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '2.00';

use Scalar::Util qw(blessed);

# sets a magic flag in P::V::D that the code-refs use to tell
# whether they should document themselves or validate, then
# calls the code-ref
sub _document {
  my $sub = shift();
  local $Params::Validate::Dependencies::DOC = $sub;
  $sub->({});
}

# gets passed the list of options for this validator, and spits
# out doco, recursing as necessary
sub _doc_me {
  my $sub = shift;
  my $list = {@_}->{list};
  (my $name = $sub->name()) =~ s/_/ /g;

  my @list = (
    (map { (my $t = $_) =~ s/'/\\'/g; "'$t'" } grep { !ref($_) } @{$list}), # scalars first, quoted
    (grep { ref($_) } @{$list})                                             # then code-refs
  );
  
  return
    $name.' ('.
      (
        $#list > 0
          ? join(', ', map { _doc_element($_) } @list[0 .. $#list - 1]).
            " ".$sub->join_with().' '._doc_element($list[-1])
          : _doc_element($list[0])
      ).
    ')';
} 

# passed an option, returning it if it's scalar, otherwise
# calling its ->_document() method
sub _doc_element {
  my $element = shift;
  if(!ref($element)) { return $element }
   elsif(blessed($element)) { return $element->_document(); }
   else { return '[coderef does not support autodoc]' }
}

1;
