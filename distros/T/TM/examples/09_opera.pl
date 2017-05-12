use File::Slurp;

use TM;
my $tm = new TM;
use TM::Serializable::XTM;
TM::Serializable::XTM::deserialize ($tm, join "", read_file ("maps/opera.xtm"));

__END__

use Time::HiRes qw(gettimeofday tv_interval);

use TM::Materialized::XTM;
my $t0 = [gettimeofday];
my $tm = new TM::Materialized::XTM (file => "maps/opera.xtm")->sync_in;
# NOTE: I do not bundle the opera.xtm because of its licencing restrictions

warn tv_interval ( $t0 );

use Data::Dumper;
#warn Dumper $tm;

