package Text::Base;
use Pony::Object abstract => 'Text::Interface';

    protected text => '';
    
    sub getText : Public
        {
            my $this = shift;
            return $this->text;
        }

1;