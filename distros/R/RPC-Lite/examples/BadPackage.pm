package BadPackage;

sub new
{
  my $class = shift;
  my $self = {};
  bless $self, $class;

  $self->{scalar} = 'scalar text';
  $self->{hashref} = { a => 1, b => 2 };
  $self->{arrayref} = [1, 2, 3];
  return $self;
}

1;
