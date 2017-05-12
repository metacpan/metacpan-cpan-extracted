
use Test::More tests => 15;

sub BEGIN {
    use_ok('Regexp::DeferredExecution');
};

use Regexp::DeferredExecution;
my ($f, $b) = (0, 0);
"foobar" =~ qr/foo(?{$f = 1})d|bar(?{$b = 1})/x;

is($f, 0, '$f was not set ...');
is($b, 1, '... but $b was set');


{
    use Regexp::DeferredExecution;
    my ($f, $b, $c) = ("") x 3;
    "foobaz" =~ qr/(?:(foo) (?{$f = $^N})) d | 
       	           (?:(ba)  (?{$b = $^N})) $ |
	           (?:(baz) (?{$c = $^N}))/x;
    
    is($f, "",    '$f is not foo ...');
    is($b, "",    '$b is not ba ...');
    is($c, "baz", '... but $c is baz');
}

{
    no Regexp::DeferredExecution;
    my ($f, $b, $c) = ("") x 3;
    "foobaz" =~ qr/(?:(foo) (?{$f = $^N})) d | 
       	           (?:(ba)  (?{$b = $^N})) $ |
	           (?:(baz) (?{$c = $^N}))/x;
    
    is($f, "foo",    '$f is foo ...');
    is($b, "ba",    '$b is ba ...');
    is($c, "baz", '... and $c is still baz');
}

{
  no Regexp::DeferredExecution;
  my ($color, $verb, $adj) = ("") x 3;
  "The quick brown fox jumped over the lazy doggie" =~
    m/^
      The\ quick\ (\S+) (?{ $color = $^N })
      \ fox\ (\S+) (?{ $verb = $^N })
      \ over\ the\ (\S+) (?{ $adj = $^N })
      \ dog
      $/x;
  is($color, "brown");
  is($verb, "jumped");
  is($adj, "lazy");
}

{
  use Regexp::DeferredExecution;
  my ($color, $verb, $adj) = ("") x 3;
  "The quick brown fox jumped over the lazy doggie" =~
    m/^
      The\ quick\ (\S+) (?{ $color = $^N })
      \ fox\ (\S+) (?{ $verb = $^N })
      \ over\ the\ (\S+) (?{ $adj = $^N })
      \ dog
      $/x;
  is($color, "");
  is($verb, "");
  is($adj, "");
}
