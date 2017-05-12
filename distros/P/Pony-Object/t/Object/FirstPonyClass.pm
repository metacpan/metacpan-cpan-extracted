package Object::FirstPonyClass;
use Pony::Object;

  # properties
  has a => 'a';
  has d => 'd';
  
  # method
  sub b
    {
      my $this = shift;
        $this->a = 'b';
      
      return ( @_ ? shift : 'b' );
    }

  # one more perl method
  sub c { 'c' }

1;