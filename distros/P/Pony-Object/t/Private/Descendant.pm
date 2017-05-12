package Private::Descendant;
use Pony::Object 'Private::Ancestor';

  sub ok_public : Public
    {
      my $me = shift;
      return 'public calls ' . $me->some_public;
    }

  sub mine_public : Public
    {
      my $me = shift;
      return 'public calls ' . $me->some_public . $me->_some_private;
    }
  
1;