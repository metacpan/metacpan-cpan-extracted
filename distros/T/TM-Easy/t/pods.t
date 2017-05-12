use strict;
use warnings;

use Data::Dumper;

#== TESTS =====================================================================

use strict;

use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;

my @PODs = qw(
	      lib/TM/Easy.pm
	      );
plan tests => scalar @PODs;

# lib/TM/Tau/Federated.pm
#	      lib/TM/QL.pm
#	      lib/TM/Tau/Filter/Analyze.pm

map {
    pod_file_ok ( $_, "$_ pod ok" )
    } @PODs;

__END__

use Test::Pod;


__END__


use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
my @poddirs = qw( blib script );
all_pod_files_ok( all_pod_files( @poddirs ) );

__END__

