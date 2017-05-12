package Human::WithCache;
use Pony::Object qw/Human::Base/;

    protected money => 0;
    protected inCount => 0;
    protected outCount => 0;
    protected in => 0;
    protected out => 0;
    
    sub deposit : Public
        {
            my $this = shift;
            my $in   = shift;
            
            $this->money += $in;
            $this->in += $in;
            $this->inCount++;
        }
    
    sub withdraw : Public
        {
            my $this = shift;
            my $out  = shift;
            
            die "Not enough money" if $this->money - $out < 0;
            
            $this->money -= $out;
            $this->out += $out;
            $this->outCount++;
        }
    
    sub avgIn : Public
        {
            my $this = shift;
            
            return 0 if $this->inCount == 0;
            return sprintf( '%.2f', $this->in / $this->inCount );
        }

    sub avgOut : Public
        {
            my $this = shift;
            
            return 0 if $this->outCount == 0;
            return sprintf( '%.2f', $this->out / $this->outCount );
        }
    
1;
