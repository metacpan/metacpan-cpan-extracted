use strict;
use warnings;
use Test::More tests => 1;
use MooseX::Adopt::Class::Accessor::Fast;

{
  package MyClass::Accessor::Chained::Fast;
  use strict;
  use base 'Class::Accessor::Fast';

  sub make_accessor {
    my($class, $field) = @_;

    return sub {
      my $self = shift;
      if(@_) {
        $self->{$field} = (@_ == 1 ? $_[0] : [@_]);
        return $self;
      }
      return $self->{$field};
    };
  }
}

{
   package TestPackage;
   use base qw/MyClass::Accessor::Chained::Fast/;
   __PACKAGE__->mk_accessors('foo');
}

my $i = bless {}, 'TestPackage';
my $other_i = $i->foo('bar');
TODO: {
  local $TODO = 'ENOWORKEY';
  is($other_i, $i, 'Accessor returns instance as opposed to value.');
}
