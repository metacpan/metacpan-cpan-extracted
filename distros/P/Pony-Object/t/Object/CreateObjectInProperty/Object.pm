package Object::CreateObjectInProperty::Object;
use Pony::Object;
use Object::CreateObjectInProperty::Service;

  protected service => Object::CreateObjectInProperty::Service->new;
  
  sub get_service : Public
    {
      my $this = shift;
      return $this->service;
    }
  
1;
