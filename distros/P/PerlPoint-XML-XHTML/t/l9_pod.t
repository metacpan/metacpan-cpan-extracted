
# = HISTORY SECTION =====================================================================

# ---------------------------------------------------------------------------------------
# version | date     | author   | changes
# ---------------------------------------------------------------------------------------
# 0.01    |09.12.2005| JSTENZEL | new.
# ---------------------------------------------------------------------------------------

# PerlPoint test script


# the following code tests the POD of all distribution files - copied from the Test::Pod manual

# load module
use Test::More;

# try to load Test::Pod
eval "use Test::Pod 1.00";

# configure test if possible
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;

# run tests
all_pod_files_ok();