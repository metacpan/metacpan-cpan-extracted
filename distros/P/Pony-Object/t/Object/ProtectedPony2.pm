package Object::ProtectedPony2;
use Pony::Object;

    has __a => 'a';
    has _b  => 'b';
    has __c => 'c';
    
    sub getA : Public
        {
            my $this = shift;
            return $this->_getA();
        }
    
    sub setA : Public
        {
            my $this = shift;
            $this->__setA(shift);
        }
    
    sub _getA : Protected
        {
            my $this = shift;
            return $this->_a;
        }
    
    sub __setA : Private
        {
            my $this = shift;
            $this->_a = shift;
        }
    
1;

