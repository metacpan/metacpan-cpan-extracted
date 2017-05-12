package Default::Base;
use Pony::Object;

  sub sum : Public
    {
      my $this = shift;
      my $result;
      $result += $_ for @_;
      return $result;
    }

1;