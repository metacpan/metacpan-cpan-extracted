use strict;
use warnings;

use Test::More tests => 3;
use MooseX::Storage::Util;

my $packed = {
    __CLASS__ => 'Foo',
    number    => 10,
    string    => 'foo',
    float     => 10.5,
    array     => [ 1 .. 10 ],
    hash      => { map { $_ => undef } ( 1 .. 10 ) },
    object    => {
       __CLASS__ => 'Foo',
       number    => 2
    },
};

my $json = '{"array":[1,2,3,4,5,6,7,8,9,10],"hash":{"6":null,"3":null,"7":null,"9":null,"2":null,"8":null,"1":null,"4":null,"10":null,"5":null},"float":10.5,"object":{"number":2,"__CLASS__":"Foo"},"number":10,"__CLASS__":"Foo","string":"foo"}';
my $yaml = q{---
__CLASS__: Foo
array:
  - 1
  - 2
  - 3
  - 4
  - 5
  - 6
  - 7
  - 8
  - 9
  - 10
float: 10.5
hash:
  1: ~
  10: ~
  2: ~
  3: ~
  4: ~
  5: ~
  6: ~
  7: ~
  8: ~
  9: ~
number: 10
object:
  __CLASS__: Foo
  number: 2
string: foo
};

is('Foo', MooseX::Storage::Util->peek($packed),
   '... got the right class name from the packed item');

SKIP: {
    my $classname = eval {
        MooseX::Storage::Util->peek($json => ('format' => 'JSON'))
    };
    if ($@ =~ /^Could not load JSON module because/) {
        die 'No JSON module found' if $ENV{AUTHOR_TESTING};
        skip "No JSON module found", 1;
    }

    is('Foo', $classname,
       '... got the right class name from the json item');
}

SKIP: {
    my $classname = eval {
        MooseX::Storage::Util->peek($yaml => ('format' => 'YAML'))
    };
    if ($@ =~ /^Could not load YAML module because/) {
        die 'No YAML module found' if $ENV{AUTHOR_TESTING};
        skip "No YAML module found", 1;
    }

    is('Foo', $classname,
       '... got the right class name from the yaml item');
}
