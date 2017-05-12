package Human::Movable;
use Pony::Object qw/Human::Base/;

    protected 'x' => 0;
    protected 'y' => 0;
    
    sub moveLeft : Public
        {
            --shift->x;
        }

    sub moveRight : Public
        {
            --shift->x;
        }
    
    sub moveTop : Public
        {
            --shift->y;
        }

    sub moveDown : Public
        {
            --shift->y;
        }
    
    sub getResultWay : Public
        {
            my $this = shift;
            return ( $this->x**2 + $this->y**2 )**0.5;
        }
    
1;
