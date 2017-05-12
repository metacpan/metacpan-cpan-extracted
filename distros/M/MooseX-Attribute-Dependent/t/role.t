use Test::Most 0.23;

package MyRole;
use Moose::Role;
use MooseX::Attribute::Dependent;

has street => ( (Moose->VERSION < 1.9900 ? (traits => ['MooseX::Attribute::Dependent::Meta::Role::Attribute']) : ()), is => 'rw', dependency => All['city', 'zip'] );
has city => ( is => 'ro' );
has zip => ( is => 'ro', clearer => 'clear_zip' );

package MyInterRole;
use Moose::Role;
with 'MyRole';

package All1;
use Moose;
MooseX::Attribute::Dependent->import if Moose->VERSION < 1.9900;
with 'MyRole';

package All2;
use Moose;
MooseX::Attribute::Dependent->import if Moose->VERSION < 1.9900;
with 'MyInterRole';

package MyEmptyRole;
use Moose::Role;

package All3;
use Moose;
MooseX::Attribute::Dependent->import if Moose->VERSION < 1.9900;
with 'MyRole', 'MyEmptyRole';

package NoLeakyTraits;
use Moose;
with 'MyRole';

has plain => (is => 'ro');

::ok(!__PACKAGE__->meta->get_attribute('plain')->does('MooseX::Attribute::Dependent::Meta::Role::Attribute'), "traits don't leak into the class");

package main;

note 'mutable';
for(0..5) 
{
    my $class = "All" . ( $_ % 3 + 1 );
    throws_ok { $class->new(street => 1) } qr/city/, 'city and zip are required';
    throws_ok { $class->new(street => 1, city => 1) } qr/city/, 'zip is required';
    lives_ok { $class->new(street => 1, city => 1, zip => 1) } 'lives ok';
    lives_ok { $class->new() } 'empty new lives ok';
    my $foo = $class->new;
    throws_ok { $foo->street("foo") } qr/city/, 'works on accessor as well';
    note "making immutable" if($_ < 3);
    $class->meta->make_immutable;
}

done_testing;
