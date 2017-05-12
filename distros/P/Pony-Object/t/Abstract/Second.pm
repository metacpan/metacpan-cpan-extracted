package Abstract::Second;
use Pony::Object 'Abstract::First';

    sub setA : Public
        {
            my $this = shift;
            $this->a = shift;
        }

1;
