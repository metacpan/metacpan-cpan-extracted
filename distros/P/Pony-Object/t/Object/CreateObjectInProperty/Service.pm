package Object::CreateObjectInProperty::Service;
use Pony::Object;

  protected list => [];

  sub add : Public
    {
      my $this = shift;
      push @{ $this->list }, @_;
    }
  
  sub flush : Public
    {
      my $this = shift;
      $this->list = clone $this->ALL->{list};
    }
  
  sub get_list : Public
    {
      my $this = shift;
      return $this->list;
    }

1;