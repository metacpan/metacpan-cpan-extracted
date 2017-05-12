use Test::Most 0.23;

package All;
use Moose;
use MooseX::Attribute::Dependent;

has street => ( dependency => All['city', 'zip'], is => 'rw' );
has city => ( is => 'ro' );
has zip => ( is => 'ro', clearer => 'clear_zip' );

package Any;
use Moose;
use MooseX::Attribute::Dependent;

has street => ( is => 'rw', dependency => Any['city', 'zip'] );
has city => ( is => 'ro' );
has zip => ( is => 'ro', clearer => 'clear_zip' );

package main;

note 'mutable';
for(1..2) 
{
    throws_ok { All->new(street => 1) } qr/city/, 'city and zip are required';
    throws_ok { All->new(street => 1, city => 1) } qr/city/, 'zip is required';
    lives_ok { All->new(street => 1, city => 1, zip => 1) } 'lives ok';
    lives_ok { All->new() } 'empty new lives ok';
    my $foo = All->new;
    throws_ok { $foo->street("foo") } qr/city/, 'works on accessor as well';
    note "making immutable" if($_ == 1);
    All->meta->make_immutable;
}

note 'mutable';
for(1..2) 
{
    throws_ok { Any->new(street => 1) } qr/city/, 'city or zip are required';
    lives_ok { Any->new(street => 1, city => 1) } 'lives with city';
    lives_ok { Any->new(street => 1, zip => 1) } 'lives with zip';
    lives_ok { Any->new(street => 1, zip => 1, city => 1) } 'lives with both';
    lives_ok { Any->new() } 'empty new lives ok';
    my $foo = Any->new;
    throws_ok { $foo->street("foo") } qr/city/, 'works on accessor as well';
    note "making immutable" if($_ == 1);
    Any->meta->make_immutable;
}

done_testing;
