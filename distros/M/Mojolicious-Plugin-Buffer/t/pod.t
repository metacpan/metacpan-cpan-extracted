use strict;
use warnings;

use Test::More;

# Author test: every module's POD must parse cleanly
eval { require Test::Pod; Test::Pod->VERSION('1.22'); 1 }
	or plan skip_all => 'Test::Pod 1.22 is required to check the POD';

# Name lib/ explicitly: by default a stale blib/ would be checked instead
Test::Pod::all_pod_files_ok(Test::Pod::all_pod_files('lib'));
