use Perlmazing qw(is_number);
use POSIX 'ceil';
our @ISA = qw(Perlmazing::Listable);

sub main {
  $_[0] = ceil $_[0] if is_number $_[0];
}

1;