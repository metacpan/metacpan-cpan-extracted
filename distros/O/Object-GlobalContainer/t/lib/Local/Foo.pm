package Local::Foo;


use Moose;

has 'name' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'abcdef',
);


sub test {
  my $this=shift;

  return '42'.$this->name;
}




1;
