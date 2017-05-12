package MyWriter; 

# custom handler for testing that we can use a class name as Handler
# in t/76.writer.t

use base qw( XML::SAX::Base );
use open IO => ':encoding(utf8)';

use XML::SAX::Writer;

sub new {
  my $x = "";
  return XML::SAX::Writer->new(Output => \$x);
}

1;

