package Private::Ancestor;
use Pony::Object;
  
  sub _some_private : Private
    {
      my $me = shift;
      return 'private';
    }
  
  sub some_public : Public
    {
      my $me = shift;
      return 'public calls ' . $me->_some_private;
    }
  
1;