#! perl -I.
use t::Test::abeltje;

BEGIN {
    eval "require Moose";
    if ($@) {
        plan skip_all => "Cannot load Moose, we'll skip";
    }
}

use MooseTestBasicValidations;

{
    note("Basic testing: validating argument");
    my $t1 = MooseTestBasicValidations->new();
    my $args = $t1->validate_customer(customer => 'string');
    is_deeply(
        $args,
        { customer => 'string' },
        "Argument validated"
    ) or diag(explain($args));

    my $exception = exception { $args->{typo_in_key} };
    like(
        $exception,
        qr{^Attempt to access disallowed key 'typo_in_key' in a restricted hash},
        "Cannot access unsupported arguments"
    );

    my $args_stored = $t1->store_validate_customer(customer => 'must_be_42');
    is_deeply(
        $args_stored,
        {
            customer => 'must_be_42',
            store_customer => 'must_be_42',
        },
        "Stored argument validated"
    ) or diag(explain($args_stored));

    note("Validate positional");
    $args = $t1->validate_positional_customer('single argument');
    is_deeply(
        $args,
        { customer => 'single argument' },
        "Positional arguments standard"
    );

    $args_stored = $t1->store_validate_positional_customer('must_be_42');
    is_deeply(
        $args_stored,
        {
            customer => 'must_be_42',
            store_customer => 'must_be_42',
        },
        "Stored argument validated"
    ) or diag(explain($args_stored));
}

abeltje_done_testing();
