package Object::CreateObjectInProperty::ObjectWithFactory;
use Pony::Object;
use Object::CreateObjectInProperty::Service;

  protected service => sub { Object::CreateObjectInProperty::Service->new };
  
  sub get_service : Public
    {
      my $this = shift;
      return $this->service;
    }
  
1;
