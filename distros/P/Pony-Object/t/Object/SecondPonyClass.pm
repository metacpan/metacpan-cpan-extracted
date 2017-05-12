package Object::SecondPonyClass;
# extends FirstPonyClass
use Pony::Object qw/Object::FirstPonyClass/;

    # test polymorphism
    has d => 'dd';

    sub b
        {
            my $this = shift;
               $this->a = 'bb';
               
            return ( @_ ? shift : 'bb' );
        }
    
    sub e {'e'};

1;

