package Human::Base;
use Pony::Object;
  
  has name   => '';
  has height => undef;
  has weight => undef;
  
  sub init
    {
      my $this = shift;
      $this->name = shift;
    }
  
1;
