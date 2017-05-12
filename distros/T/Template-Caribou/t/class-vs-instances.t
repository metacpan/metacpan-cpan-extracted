use strict;
use warnings;

package MyTemplate;

use Test::More tests => 4;
use Test::Exception;

use Template::Caribou;

template 'class_wide' => sub { };

my $first  = MyTemplate->new( can_add_templates => 1 );
my $second = MyTemplate->new;

ok $first->can( 'class_wide' );


subtest 'adding foo on an instance' => sub {

    ok ! $second->can('foo'), "not defined yet";

    $first->template( 'foo' => sub { } );

    ok $first->can('foo'), '$first has foo';
    ok $second->can('foo'), "it's class-wide";
}; 

throws_ok { $second->template( 'cant' => sub { } ) }
    qr/can only add templates/, "can't add templates without the flag";
    

subtest 'anon instance' => sub {
    my $third = MyTemplate->anon_instance;

    ok $third->can('foo'), "inherited";
    ok $third->can( 'class_wide' );

    lives_ok {
        $third->template( 'bar' => sub { } )
    } 'anon instances can define new templates';

    ok $third->can('bar'), "third has it";
    ok !$second->can('bar'), "but not the rest";
};


