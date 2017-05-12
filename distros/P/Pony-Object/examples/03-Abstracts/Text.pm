package Text;
use Pony::Object 'Text::Base';
  
  sub setText : Public
    {
      my $this = shift;
      $this->text = shift;
    }
  
1;