package Test;

use Moose;
use DateTime;

use MooseX::Attribute::Deflator;

deflate 'DateTime', via { $_->epoch };
inflate 'DateTime', via { DateTime->from_epoch( epoch => $_ ) };

no MooseX::Attribute::Deflator;

use MooseX::Attribute::Deflator::Moose;

has now => (
    is      => 'rw',
    isa     => 'DateTime',
    default => sub { DateTime->now },
    traits  => ['Deflator']
);

has hash => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { { foo => 'bar' } },
    traits  => ['Deflator']
);

sub deflate {
   my $self = shift;
   
   # you probably want to deflate only those that are required or have a value
   my @attributes = grep { $_->has_value($self) || $_->is_required }
                    $self->meta->get_all_attributes;
   
   # works only if all attributes have the 'Deflator' trait applied
   return { map { $_->name => $_->deflate($self) } @attributes };
}

package main;

use Test::More;

my $obj = Test->new;

{
    my $attr     = $obj->meta->get_attribute('now');
    my $deflated = $attr->deflate($obj);
    like( $deflated, qr/^\d+$/ );

    my $inflated = $attr->inflate( $obj, $deflated );
    isa_ok( $inflated, 'DateTime' );
}

{
    my $attr     = $obj->meta->get_attribute('hash');
    my $deflated = $attr->deflate($obj);
    is( $deflated, '{"foo":"bar"}' );

    my $inflated = $attr->inflate( $obj, $deflated );
    is_deeply( $inflated, { foo => 'bar' } )
}

is_deeply(
    $obj->deflate,
    {   hash => $obj->meta->get_attribute('hash')->deflate($obj),
        now  => $obj->meta->get_attribute('now')->deflate($obj),
    },
    'deflate object method works as well'
);

package LazyInflator;

use Moose;
use MooseX::Attribute::LazyInflator;
use MooseX::Attribute::Deflator::Moose;

has hash => (
    is     => 'rw',
    isa    => 'HashRef',
    traits => ['LazyInflator']
);

package main;

for ( 1 .. 2 ) {
    $obj = LazyInflator->new( hash => '{"foo":"bar"}' );

    # Attribute 'hash' is being inflated on access
    is_deeply( $obj->hash, { foo => 'bar' } );

    $obj = LazyInflator->new( hash => '[1,2,3]' );
    eval { $obj->hash };
    like($@, qr/constraint/, 'throws on wrong type');

    LazyInflator->meta->make_immutable;
}
done_testing;
