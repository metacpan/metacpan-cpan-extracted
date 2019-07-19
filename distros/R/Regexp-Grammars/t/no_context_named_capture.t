use 5.010;

use Test::More;
plan tests => 1;

use Regexp::Grammars;

my $parser = qr/

     <name>

     <token: name>
         <nocontext:>
         <word=(\w+)>

/x;

"alex" =~ $parser;

is_deeply \%/, { '' => 'alex', 'name' => { 'word' => 'alex' } }  => 'Nocontext with named capture';
