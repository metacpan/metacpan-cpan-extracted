BEGIN { chdir 't' if -d 't' };

use strict;
use lib '../lib';
use Test::More 'no_plan';
use Data::Dumper;

my $Class   = 'Object::Accessor::XS';
my $MyClass = 'My::Class';
my $Acc     = 'foo';

use_ok($Class);

### establish another package that subclasses our own
{   package My::Class;
    use base 'Object::Accessor::XS';
}    

my $Object  = $MyClass->new;

### check the object
{   ok( $Object,                "Object created" );
    isa_ok( $Object,            $MyClass );
    isa_ok( $Object,            $Class );
}    

### create an accessor 
{   ok( $Object->mk_accessors( $Acc ),
                                "Accessor '$Acc' created" );
    ok( $Object->can( $Acc ),   "   Object can '$Acc'" );
    ok( $Object->$Acc(1),       "   Objects '$Acc' set" );
    ok( $Object->$Acc(),        "   Objects '$Acc' retrieved" );
}    
    
