use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;
plan tests => 6;

my @pod_files = split /\n/, <<"FILES";
Sleep
Sleep::Request
Sleep::Resource
Sleep::Response
Sleep::Routes
FILES

for (@pod_files) {
    pod_coverage_ok($_);
}


pod_coverage_ok(
    "Sleep::Handler",
    { also_private => [ qr/^[A-Z_]+$/ ], },
    "Sleep::Handler, with all-caps functions as privates",
                                );
