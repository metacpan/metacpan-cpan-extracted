package Counter;
use Pony::Object;
  
  protected static 'counter' => 0;
  
  sub get_count : Public
    {
      my $this = shift;
      return $this->counter;
    }
  
  sub inc : Public
    {
      my $this = shift;
      ++$this->counter;
    }
  
1;