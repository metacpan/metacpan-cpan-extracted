# $Id: pod.t,v 1.1 2009/01/10 17:15:38 drhyde Exp $
use strict;

$^W=1;

use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();
