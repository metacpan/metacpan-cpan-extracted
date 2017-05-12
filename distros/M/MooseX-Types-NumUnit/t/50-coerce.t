package MyTest;

use Moose;
use MooseX::Types::NumUnit qw/NumUnit/;

has 'num_unit' => ( isa => NumUnit, is => 'rw', default => 1 );
has 'num' => ( isa => 'Num', is => 'rw', default => 1 );

sub does_attr_coerce {
  my $self = shift;
  my $meta = $self->meta;

  my $attr = shift;

  return $meta->get_attribute( $attr )->should_coerce;
}

no Moose;
__PACKAGE__->meta->make_immutable;


package main;

use Test::More;

my $test = MyTest->new;

is( $test->does_attr_coerce('num'), 0, "A standard attribute does not coerce");
is( $test->does_attr_coerce('num_unit'), 1, "A NumUnit attribute does coerce");

done_testing;

