sub new {
  my $this = shift;
  my $self = $this->SUPER::new(@_);

  $self->const('source', 'therom.v');

  foreach my $name ('zero', 'one', 'two', 'three') {
    $self->addvar($name, 'output', 'out', '[7:0]');
  }
  
  my $romport = vars->new(name => $self->suggestname('JustSomeName'),
			  parent => $self,
			  labels => [ r0 => 'zero',
				      r1 => 'one',
				      r2 => 'two',
				      r3 => 'three']);
  
  $self->const(['user_port_names', 'wbport'], $romport);
  
  return $self;
}  
