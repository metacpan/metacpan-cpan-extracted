use Test::More;
use strict;
use warnings;

package MyRole;

use Moose::Role;
use DateTime;
use MooseX::Attribute::LazyInflator;
use MooseX::Attribute::Deflator::Moose;

use MooseX::Types::Moose qw(Str Int HashRef ScalarRef ArrayRef Maybe);
     
has hash => ( is => 'rw', isa => HashRef, traits => [qw(LazyInflator)] );
has scalar => ( is => 'rw', isa => 'ScalarRef[Str]' , traits => [qw(LazyInflator)] );
has lazyhash => ( is => 'rw', isa => HashRef, lazy => 1, default => sub { { key => 'value' } }, traits => [qw(LazyInflator)] );
has defaulthash => ( is => 'rw', isa => HashRef, default => sub { { key => 'value' } }, traits => [qw(LazyInflator)] );

has lazybitch => ( is => 'ro', lazy => 1, default => sub { 1 } );

package MyInterRole;
use Moose::Role;
with 'MyRole';

package Test1;
use Moose;
with 'MyRole';

package Test2;
use Moose;
with 'MyInterRole';

package MyEmptyRole;
use Moose::Role;

package Test3;
use Moose;
with 'MyRole', 'MyEmptyRole';

package main;

use JSON;

for(0..5) {
    my $class = "Test" . ( $_ % 3 + 1 );
    my $t = $class->new( hash => q({"foo":"bar"}) );
    my $meta = $t->meta;
    {
        my $attr = $meta->get_attribute('hash');

        ok($attr->has_value($t), 'Attribute has value');
        is($attr->get_raw_value($t), q({"foo":"bar"}), 'Raw value is raw');
        is_deeply($attr->get_value($t), { foo => 'bar' }, 'Value has been inflated');
        is_deeply($attr->get_value($t), { foo => 'bar' }, 'Value has not been inflated again');

        $t = $class->new( hash => q({"foo":"bar"}) );
        is_deeply($t->hash, { foo => 'bar' }, 'Value has been inflated through accessor');
    }
    
    {
        my $attr = $meta->get_attribute('lazyhash');
        ok($attr->is_lazy, 'Attribute is lazy');
        ok(!$attr->has_value($t), 'Attribute has no value');
        is($attr->get_raw_value($t), undef, 'Raw value is undef');
        is_deeply($attr->get_value($t), { key => 'value' }, 'get_value calls builder');
        
        $t = $class->new;
        is_deeply($t->lazyhash, { key => 'value' }, 'Builder works on accessor');
        
        $t = $class->new( lazyhash => q({"foo":"bar"}) );
        is_deeply($t->lazyhash, { foo => 'bar' }, 'Value has been inflated through accessor');
    }
    
    {
        my $attr = $meta->get_attribute('hash');
        $t = $class->new( hash => { foo => 'bar' }, scalar => 'foo' );
        ok($attr->is_inflated($t), 'Attribute is inflated');
        $attr = $meta->get_attribute('scalar');
        ok(!$attr->is_inflated($t), 'ScalarRef attribute is not inflated');
        
    }
    diag "making immutable" if($_ < 3);
    $class->meta->make_immutable;
}

done_testing;