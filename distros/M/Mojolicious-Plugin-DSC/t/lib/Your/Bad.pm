package    #hide
  Your::Bad;
use Mojo::Base 'Your';
use Mojo::Exception;

Mojo::Exception->throw("Does not compute");

1;
