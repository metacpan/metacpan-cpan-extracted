#!perl -Tw

use strict;
use warnings;
use Test::More qw(no_plan);
use Test::Exception;

require_ok('SeeAlso::Identifier::Factory');
require_ok('SeeAlso::Server');

#### fixed type (implies including the class)

my $factory = new SeeAlso::Identifier::Factory
    type => 'SeeAlso::Identifier::ISBN';

my $id = $factory->create('hello');
isa_ok($id, 'SeeAlso::Identifier::ISBN');
is( $id, '', 'not an ISBN' );

$id = $factory->create('0596527241');
is( $id->canonical, 'urn:isbn:9780596527242', 'an ISBN' );

$factory = new SeeAlso::Identifier::Factory
    type => ['SeeAlso::Identifier::ISBN'];
$id = $factory->create('urn:isbn:9780804429573');
is( $id, 'urn:isbn:9780804429573', 'type as array reference' );


#### fixed type with pre-parsing

$factory = new SeeAlso::Identifier::Factory
    type => 'SeeAlso::Identifier::ISBN',
    parse => sub { return $_[0].'2957-x'; };

$id = $factory->create('0-8044-');
isa_ok( $id, 'SeeAlso::Identifier::ISBN' );
is( $id, 'urn:isbn:9780804429573', 'pre-parsing' );


#### Multiple types

$factory = new SeeAlso::Identifier::Factory
    type => ['SeeAlso::Identifier::ISBN','SeeAlso::Identifier'];

$id = $factory->create('0596527241');
is( $id, 'urn:isbn:9780596527242', 'multiple types (1)' );

$id = $factory->create('hello');
isa_ok( $id, 'SeeAlso::Identifier', 'multiple types (2a)' );
is( $id, 'hello', 'multiple types (2b)' );

$id = $factory->create();
isa_ok( $id, 'SeeAlso::Identifier::ISBN', 'multiple types (3)' );

#### refuse unknown types
dies_ok { $factory = new SeeAlso::Identifier::Factory
    type => [qw(Foo Bar Doz)]
} 'refuse unknown types';

#### refuse non-id-type
dies_ok { $factory = new SeeAlso::Identifier::Factory
    type => "Business::ISBN"
} 'refuse non-id type';



#### Dynamically create a new type

$factory = new SeeAlso::Identifier::Factory
    parse => sub { $_[0] if length($_[0]) == 3; },
    canonical => sub { lc($_[0]); },
    hash => sub { substr($_[0],0,2); },
    type => 'ThreeChars';

$id = $factory->create('ABCD');
isa_ok( $id, 'ThreeChars');
is( $id, '', 'dynamically created identifier type: parse' );

$id = $factory->create('ABC');
isa_ok( $id, 'ThreeChars');
is( $id->value, 'ABC', 'dynamically created identifier type: value' );
is( $id, 'abc', 'dynamically created identifier type: canonical' );
is( $id->hash, 'AB', 'dynamically created identifier type: hash' );


$id = SeeAlso::Identifier::Factory->new(
    type => 'GVKPPN', 
    parse => sub { lc($_[0]) if $_[0] =~ /^(gvk:ppn:)?([0-9]*[0-9x])$/i },
    canonical => sub { 'gvk:ppn:'.$_[0] if $_[0] },
    hash => sub { substr($_[0],0,length($_[0])-1) if $_[0] } 
)->create('123');
isa_ok( $id, 'GVKPPN' );

__END__

----

my $PPNFactory = SeeAlso::Identifier::Factory
    type => 'PPN',
    parse => sub { 
        my $value = shift; 
        $value =~ /^(gvk:ppn:)?([0-9]*[0-9x])$/i ? lc($2) : '';
    },
    canonical => sub {
        my $value = shift; 
        return $value ne '' ? 'gvk:ppn:' . $value : '';
    },
    hash => sub {
        my $value = shift; 
        return $value ne '' ? substr($value,0,length($value)-1) : '';
    };

$id = SeeAlso::Identifier->new( 'valid' => sub { return 1; } );
ok( $id->value eq "" , "undefined value with handler" );

# lowercase alpha only
sub lcalpha {
   my $v = shift;
   $v =~ s/[^a-zA-Z]//g;
   return lc($v);
}
$id = SeeAlso::Identifier->new(
  'valid' => sub {
     my $v = shift;
     return $v =~ /^[a-zA-Z]+$/;
  },
  'normalized' => \&lcalpha
);
$id->value("AbC");

ok( $id->valid , "extension: valid");
ok( $id->normalized eq "abc" && $id->indexed eq "abc", "extension: normalized and indexed" );
