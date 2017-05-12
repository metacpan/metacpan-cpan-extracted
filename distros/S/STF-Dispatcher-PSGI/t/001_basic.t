use strict;
use Test::More;

BEGIN {
    use_ok "STF::Dispatcher::Test";
    use_ok "STF::Dispatcher::PSGI";
    use_ok "STF::Dispatcher::Impl::File";
    use_ok "STF::Dispatcher::Impl::Hash";
}

my @impls = (
    STF::Dispatcher::Impl::File->new(),
    STF::Dispatcher::Impl::Hash->new(),
);

foreach my $impl (@impls) {
    subtest "Test against $impl" => sub {
        test_stf_impl $impl
    }
}

done_testing;