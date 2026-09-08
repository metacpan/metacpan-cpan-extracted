use v5.36;

# Syntax check only. Pod::Coverage is deliberately not used: the module's
# functions are internal to the pplquery command and are documented in source
# comments, not POD, so a coverage test would report intentional omissions as
# failures. User documentation lives in PPLQuery.pod.

use Test::More;

plan skip_all => 'Test::Pod 1.41 required' unless eval { require Test::Pod; Test::Pod->VERSION(1.41); 1 };
Test::Pod->import;

# PPLQuery.pod is the source the shipped POD is injected from. It is pruned
# from the built distribution, so it is only present when testing the checkout.
my @files = (Test::Pod::all_pod_files('lib', 'bin'), -f 'PPLQuery.pod' ? 'PPLQuery.pod' : ());

plan tests => scalar @files;
pod_file_ok($_) for @files;
