package Object::ProtectedPony;
use Pony::Object;

    protected a => 'a';
    public    b => 'b';
    protected c => undef;
    private   d => 0xDEAD;
    
    sub getA : Public
        {
            my $this = shift;
            return $this->_getA();
        }
    
    sub setA : Public
        {
            my $this = shift;
            $this->a = shift;
        }
    
    sub _getA : Protected
        {
            my $this = shift;
            return $this->a;
        }
    
    sub sum : Public
        {
            my $this = shift;
            $this->c = $this->a + $this->b;
        }
    
    sub getC : Public
        {
            my $this = shift;
            return $this->c;
        }
    
    sub magic : Public
        {
            my $this = shift;
            return ( $this->d ^ $this->c );
        }
    
    sub __doNothing : Private
        {
            1 + 1 == 2
        }
    
1;

