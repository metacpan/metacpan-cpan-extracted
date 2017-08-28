use Mojo::Base -strict;

use Test::More;

use Mojo::Date;
use Mojo::DOM;
use Mojo::JSON;
use Mojo::XMLRPC;
use Mojo::XMLRPC::Base64;

sub dom { Mojo::DOM->new(Mojo::XMLRPC::to_xmlrpc(@_)) }

# construct variables with more than one value field filled up,
# but only one valid, to check that the module doesn't mess up
# while reading internal flags
my $iv = "plonk";   $iv = 123;
my $nv = "plonk";   $nv = 2.718;
my $pv = 123456;    $pv = "plonk";

# construct variables which get upgraded from IV and NV
# to PVIV and PVNV by interpolating them in a string
my $s;
my $pviv6  = 123456;     $s = "$pviv6";
my $pviv10 = 1234567890; $s = "$pviv10";
my $pvnv   = 3.14159;    $s = "$pvnv";

# empty values
my $dom = dom(call => 'var.set');
is $dom->at('methodCall > methodName')->text, 'var.set', 'correct method name';

$dom = dom(call => 'var.set', undef);
is $dom->at('methodCall > methodName')->text, 'var.set', 'correct method name';
ok $dom->at('methodCall > params > param > value > nil'), 'correct handling of undef';

# integer values

$dom = dom(call => 'var.set', 0);
is $dom->at('methodCall > methodName')->text, 'var.set', 'correct method name';
is $dom->at('methodCall > params > param > value > int')->text, 0, 'correct handling of value';

$dom = dom(call => 'var.set', 123);
is $dom->at('methodCall > methodName')->text, 'var.set', 'correct method name';
is $dom->at('methodCall > params > param > value > int')->text, 123, 'correct handling of value';

$dom = dom(call => 'var.set', $iv);
is $dom->at('methodCall > methodName')->text, 'var.set', 'correct method name';
is $dom->at('methodCall > params > param > value > int')->text, $iv, 'correct handling of value';

$dom = dom(call => 'var.set', $pviv6);
is $dom->at('methodCall > methodName')->text, 'var.set', 'correct method name';
is $dom->at('methodCall > params > param > value > int')->text, $pviv6, 'correct handling of value';

$dom = dom(call => 'var.set', $pviv10);
is $dom->at('methodCall > methodName')->text, 'var.set', 'correct method name';
is $dom->at('methodCall > params > param > value > int')->text, $pviv10, 'correct handling of value';

# floating point values

$dom = dom(call => 'var.set', 0.);
is $dom->at('methodCall > methodName')->text, 'var.set', 'correct method name';
is $dom->at('methodCall > params > param > value > double')->text, 0, 'correct handling of value';

$dom = dom(call => 'var.set', 3.14);
is $dom->at('methodCall > methodName')->text, 'var.set', 'correct method name';
is $dom->at('methodCall > params > param > value > double')->text, 3.14, 'correct handling of value';

$dom = dom(call => 'var.set', $nv);
is $dom->at('methodCall > methodName')->text, 'var.set', 'correct method name';
is $dom->at('methodCall > params > param > value > double')->text, $nv, 'correct handling of value';

$dom = dom(call => 'var.set', $pvnv);
is $dom->at('methodCall > methodName')->text, 'var.set', 'correct method name';
is $dom->at('methodCall > params > param > value > double')->text, $pvnv, 'correct handling of value';

# string values

my @strings = (qw/
  0
  123
  12_alpha
  +33123456
  plonk
  eacute(é)
  lambda(λ)
  snowman(☃)
  hiragana_a(あ)
  thiuth(𐌸)
  pile_of_poo(💩)
  <looks_like_a_tag>
/);

for my $string (@strings) {
  $dom = dom(call => 'var.set', $string);
  is $dom->at('methodCall > methodName')->text, 'var.set', 'correct method name';
  is $dom->at('methodCall > params > param > value > string')->text, $string, 'correct handling of value';
}

$dom = dom(call => 'var.set', $pv);
is $dom->at('methodCall > methodName')->text, 'var.set', 'correct method name';
is $dom->at('methodCall > params > param > value > string')->text, $pv, 'correct handling of value';

# boolean

$dom = dom(call => 'var.set', Mojo::JSON::true);
is $dom->at('methodCall > methodName')->text, 'var.set', 'correct method name';
is $dom->at('methodCall > params > param > value > boolean')->text, 1, 'correct handling of value';

$dom = dom(call => 'var.set', Mojo::JSON::false);
is $dom->at('methodCall > methodName')->text, 'var.set', 'correct method name';
is $dom->at('methodCall > params > param > value > boolean')->text, 0, 'correct handling of value';

$dom = dom(call => 'var.set', \1);
is $dom->at('methodCall > methodName')->text, 'var.set', 'correct method name';
is $dom->at('methodCall > params > param > value > boolean')->text, 1, 'correct handling of value';

$dom = dom(call => 'var.set', \0);
is $dom->at('methodCall > methodName')->text, 'var.set', 'correct method name';
is $dom->at('methodCall > params > param > value > boolean')->text, 0, 'correct handling of value';

# datetime

$dom = dom(call => 'var.set', Mojo::Date->new(900684535));
is $dom->at('methodCall > methodName')->text, 'var.set', 'correct method name';
is $dom->at('methodCall > params > param > value > dateTime\.iso8601')->text, '1998-07-17T14:08:55Z', 'correct handling of value';

# base64

$dom = dom(call => 'var.set', Mojo::XMLRPC::Base64->new(encoded => 'eW91IGNhbid0IHJlYWQgdGhpcyE='));
is $dom->at('methodCall > methodName')->text, 'var.set', 'correct method name';
is $dom->at('methodCall > params > param > value > base64')->text, 'eW91IGNhbid0IHJlYWQgdGhpcyE=', 'correct handling of value';

$dom = dom(call => 'var.set', Mojo::XMLRPC::Base64->new->decoded(q[you can't read this!]));
is $dom->at('methodCall > methodName')->text, 'var.set', 'correct method name';
is $dom->at('methodCall > params > param > value > base64')->text, 'eW91IGNhbid0IHJlYWQgdGhpcyE=', 'correct handling of value';

# hash references

{
  my %input = (yo => 'dawg', hi => 'bye');
  $dom = dom(call => 'var.set', \%input);
  is $dom->at('methodCall > methodName')->text, 'var.set', 'correct method name';
  my $struct = $dom->at('methodCall > params > param > value > struct');
  ok $struct, 'got a struct';
  my %got;
  $struct->children('member')->each(sub{
    my $name = $_->children('name')->first->text;
    $got{$name} = $_->children('value')->first->children('string')->first->text;
  });
  is_deeply \%got, \%input, 'correct struct';
}

# array references

{
  my @input = (qw/the quick dog/);
  $dom = dom(call => 'var.set', \@input);
  is $dom->at('methodCall > methodName')->text, 'var.set', 'correct method name';
  my $array = $dom->at('methodCall > params > param > value > array > data');
  ok $array, 'got array';
  my $got = $array->children('value')->map(sub{ $_->children('string')->first->text })->to_array;
  is_deeply $got, \@input, 'correct array';
}

# multiple parameters

$dom = dom(call => 'var.set', 1, 'hello');
is $dom->at('methodCall > methodName')->text, 'var.set', 'correct method name';
is $dom->at('methodCall > params > param:nth-of-type(1) > value > int')->text, 1, 'correct handling of value';
is $dom->at('methodCall > params > param:nth-of-type(2) > value > string')->text, 'hello', 'correct handling of value';

# object invocation

$dom = dom(Mojo::XMLRPC::Message::Call->new(method_name => 'mycall', parameters => ['hi']));
is $dom->at('methodCall > methodName')->text, 'mycall', 'correct method name';
is $dom->at('methodCall > params > param > value > string')->text, 'hi', 'correct parameter';

$dom = dom(Mojo::XMLRPC::Message::Response->new(parameters => ['hi']));
is $dom->at('methodResponse > params > param > value > string')->text, 'hi', 'correct parameter';

{
  $dom = dom(Mojo::XMLRPC::Message::Response->new(fault => {faultCode => 400, faultString => 'error'}));
  my %got;
  $dom->find('methodResponse > fault > value > struct > member')->each(sub {
    $got{ $_->at('name')->text } = $_->at('value')->all_text;
  });
  is_deeply \%got, { faultCode => 400, faultString => 'error'}, 'correct fault values';
}

done_testing;


