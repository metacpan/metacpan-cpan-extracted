package Human::Movable;
use Pony::Object qw/Human::Base/;
  
  has 'x' => 0;
  has 'y' => 0;
  
  sub moveLeft
    {
      --shift->x;
    }
  
  sub moveRight
    {
      ++shift->x;
    }
  
  sub moveTop
    {
      ++shift->y;
    }
  
  sub moveDown
    {
      --shift->y;
    }
  
  sub getResultWay
    {
      my $this = shift;
      return ( $this->x**2 + $this->y**2 )**0.5;
    }
  
1;
