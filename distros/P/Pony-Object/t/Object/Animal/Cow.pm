package Object::Animal::Cow;
use Pony::Object qw(Object::Animal::Artiodactyls
                    Object::Animal::ICow );
    
    private type => 'cow';
    protected word => 'moo';
    protected yieldCount => 0;
    private milkFactor => 5;
    
    sub getLegsCount : Public
        {
            return shift->legs;
        }
    
    sub getMilk : Public
        {
            ++shift->yieldCount;
        }
    
    sub getYieldOfMilk : Public
        {
            my $this = shift;
            
            return $this->calcYield( $this->milkFactor, $this->yieldCount )
        }
    
    sub calcYield : Protected
        {
            my $this = shift;
            my ($a, $b) = @_;
            
            return $a * $b;
        }

1;
