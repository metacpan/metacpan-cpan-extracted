use Test::More;
use Try::Tiny;
use Module::Build;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
try {
plan skip_all => "Not calling from build process" unless Module::Build->current;
all_pod_files_ok();
} catch {
    plan skip_all => "Author tests";
};
