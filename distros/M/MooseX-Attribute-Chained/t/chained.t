use strict;
use warnings;
use Test::More;

use_ok('MooseX::Attribute::Chained');
use_ok('MooseX::ChainedAccessors::Accessor');
use_ok('MooseX::Traits::Attribute::Chained');

{
    package SimpleChained;
    use Moose;
        
    has 'regular_attr' => (
        is => 'rw',
        isa => 'Str',
        default => sub { 'hello'; },
    );
    
    has 'chained_attr' => (
        traits => ['Chained'],
        is => 'rw',
        isa => 'Bool',    
        lazy => 1,
        default => sub { 0; },
    );
    
    has 'writer_attr' => (
        traits => ['Chained'],
        is => 'rw',
        isa => 'Str',
        reader => 'get_writer_attr',
        writer => 'set_writer_attr',
    );
}


my $simple = SimpleChained->new();
is($simple->chained_attr(1)->regular_attr, 'hello', 'chained accessor attribute');
is($simple->chained_attr(0)->set_writer_attr('world')->get_writer_attr, 'world', 'chained writer attribute');


{
    package Debug;
    use Moose::Role;
    
    has 'debug' => (
        traits => ['Chained'],
        is => 'rw',
        isa => 'Bool',
        default => sub { 0; },
    );
}


{
    package ChainedFromRole;
    use Moose;
    
    with 'Debug';
    
    sub message 
    {
        my $self = shift;
        return 'hello' if $self->debug;
        return 'world';
    }
}

my $rolechained = ChainedFromRole->new();
is($rolechained->debug, 0, "debugging is disabled");
is($rolechained->message, 'world', 'normal access..');
is($rolechained->debug(1)->message, 'hello', 'chained write affects method call..');
is($rolechained->debug, 1, 'chained attribute reads ok.');

done_testing;