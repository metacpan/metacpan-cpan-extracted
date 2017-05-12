  {
    package Local::Person;
    use Moose;
    has name => (
      is    => 'ro',
      isa   => 'Str',
    );
    __PACKAGE__->meta->make_immutable;
  }
  
  {
    package Local::Marriage;
    use MooseX::ArrayRef;
    has husband => (
      is    => 'ro',
      isa   => 'Local::Person',
    );
    has wife => (
      is    => 'ro',
      isa   => 'Local::Person',
    );
    __PACKAGE__->meta->make_immutable;
  }
  
  my $marriage = Local::Marriage->new(
    wife      => Local::Person->new(name => 'Alex'),
    husband   => Local::Person->new(name => 'Sam'),
  );
  
  use Data::Dumper;
  use Scalar::Util qw(reftype);
  print reftype($marriage), "\n";   # 'ARRAY'
  print Dumper($marriage);

