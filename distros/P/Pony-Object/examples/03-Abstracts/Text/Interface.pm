package Text::Interface;
use Pony::Object -abstract; # Use 'abstract' or '-abstract'
                            # params to define abstract class.
  
  sub getText : Abstract; # Use 'Abstract' attribute to
  sub setText : Abstract; # define abstract method.
  
1;