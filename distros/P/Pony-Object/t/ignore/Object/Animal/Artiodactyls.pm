package Object::Animal::Artiodactyls;
use Pony::Object qw(Object::Animal::Base);

    protected legs => 4;
    private counter => 0;
    
    sub inc : Private
        {
            shift->counter++
        }

1;
