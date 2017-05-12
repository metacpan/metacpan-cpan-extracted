use strict;
use warnings;

use Data::Dumper;

#== TESTS =====================================================================

use strict;

use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;

my @PODs = qw(
	      lib/TM.pm
	      lib/TM/Analysis.pm
	      lib/TM/Axes.pm
	      lib/TM/Bulk.pm
	      lib/TM/Literal.pm
	      lib/TM/Overview.pm
	      lib/TM/FAQ.pm
	      lib/TM/DM.pm
              lib/TM/Graph.pm
	      lib/TM/Tree.pm
	      lib/TM/PSI.pm
	      lib/TM/ResourceAble.pm
	      lib/TM/ResourceAble/MLDBM.pm
	      lib/TM/Synchronizable.pm
	      lib/TM/Synchronizable/MLDBM.pm
	      lib/TM/Serializable.pm
	      lib/TM/Serializable/AsTMa.pm
	      lib/TM/Serializable/LTM.pm
	      lib/TM/Serializable/CTM.pm
	      lib/TM/Serializable/XTM.pm
	      lib/TM/MapSphere.pm
	      lib/TM/Materialized/Stream.pm
	      lib/TM/Materialized/AsTMa.pm
	      lib/TM/Materialized/CTM.pm
	      lib/TM/Materialized/LTM.pm
	      lib/TM/Materialized/MLDBM.pm
	      lib/TM/Materialized/MLDBM2.pm
	      lib/TM/Materialized/XTM.pm
	      lib/TM/Tau.pm
	      lib/TM/Tau/Filter.pm
	      lib/TM/Tau/Filter/Analyze.pm
	      lib/TM/Index.pm
	      lib/TM/Index/Characteristics.pm
	      lib/TM/Index/Match.pm
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

