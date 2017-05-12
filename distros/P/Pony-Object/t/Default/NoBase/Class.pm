package Default::NoBase::Class;
use Pony::Object;

  sub try_do : Public
    {
      my $this = shift;
      
      my $result = try {
        die;
      } catch {
        return 12;
      };
      
      return $result;
    }

1;