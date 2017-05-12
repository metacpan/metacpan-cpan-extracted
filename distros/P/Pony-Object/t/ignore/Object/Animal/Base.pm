package Object::Animal::Base;
use Pony::Object -abstract;

    protected format => '%s says %s';
    private __format => '%s says %s again';
    public big => '';
    
    sub getType : Public
        {
            my $this = shift;
            return $this->type;
        }
    
    sub say : Public
        {
            my $this = shift;
            return sprintf( $this->format, $this->type, $this->word );
        }

    sub sayAgain : Public
        {
            my $this = shift;
            return sprintf( $this->__format, $this->type, $this->word );
        }
    
    sub inc : Abstract;

1;
