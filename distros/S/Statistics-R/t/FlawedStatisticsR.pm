package t::FlawedStatisticsR;

use Statistics::R;
use base qw(Statistics::R);
my $eos = 'Statistics::R::EOS';

# Override the wrap_cmd() method of Statistics::R with a faulty one
sub wrap_cmd {
   my ($self, $cmd) = @_;
   $cmd = qq`zzzzzzzzzzzzzzz; write("$eos",stdout())\n`;
   return $cmd;
}

1;

__END__
