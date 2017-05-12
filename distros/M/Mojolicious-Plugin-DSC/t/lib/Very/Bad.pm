package    #hide
  Very::Bad;
use Mojo::Base 'Very';
use Mojo::Exception;

Mojo::Exception->throw("Does not load");

1;

