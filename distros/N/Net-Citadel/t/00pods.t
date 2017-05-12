use strict;
use warnings;

use Data::Dumper;

#== TESTS =====================================================================

use strict;

use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;

my @PODs = qw(
             lib/Net/Citadel.pm
             lib/Net/Citadel/ToDo.pod
             );
plan tests => scalar @PODs;

map {
    pod_file_ok ( $_, "$_ pod ok" )
    } @PODs;

__END__

use Test::Pod;
