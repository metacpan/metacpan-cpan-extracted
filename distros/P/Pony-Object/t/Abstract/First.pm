package Abstract::First;
use Pony::Object 'abstract';

    protected a => 11;

    sub getA : Public
        {
            my $this = shift;
            return $this->a;
        }
    
    sub setA : Abstract;

1;
