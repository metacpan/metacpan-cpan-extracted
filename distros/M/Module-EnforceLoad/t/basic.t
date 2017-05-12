use Module::EnforceLoad qw/^Test2::Tools::/;
use Test2::Bundle::Extended;

enforce();

package XYZ;

eval { Test2::Tools::Basic::ok(0, "Should not see"); 1 } and die "eval should not succeed, but it did";
my $ex = $@;

require Test2::Bundle::Extended;

Test2::Tools::Compare::like(
    $ex,
    qr{^Tried to use Test2::Tools::Basic::ok without loading Test2::Tools::Basic},
    "Got exception before we re-required Test2::Bundle::Extended"
);

Test2::Tools::Basic::ok(1, "Can call it now that we required the module");

Test2::Tools::Basic::plan(2);
