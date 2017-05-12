package Human::Base;
use Pony::Object;

    public name   => '';
    public height => undef;
    public weight => undef;
    
    sub init : Public
        {
            my $this = shift;
               $this->name = shift;
        }

1;
