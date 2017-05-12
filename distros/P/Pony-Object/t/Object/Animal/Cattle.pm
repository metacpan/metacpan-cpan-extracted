package Object::Animal::Cattle;
use Pony::Object qw(Object::Animal::Cow
                    Object::Animal::Artiodactyls
                    Object::Animal::ICow
                    Object::Animal::ICattle);

    has horns => 2;
    private type => 'cattle';
    private milkFactor => 10;
    protected hurtCount => 0;
    
    sub gore : Protected
        {
            my $this = shift;
            $this->hurtCount++;
            return $this->hurtCount;
        }

1;
