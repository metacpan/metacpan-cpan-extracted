#! perl -I.
use t::Test::abeltje;

use TestBasicValidations;

my $file = $INC{"TestBasicValidations.pm"};

{
    note("Basic validation error (named parameters)");
    my $t1 = TestBasicValidations->new();

    my $exception = exception { $t1->validate_customer(customer => "") };
    like(
        $exception,
        qr{^Error in TestBasicValidations::validate_customer \($file:11\):},
        "Validation error reference (named)"
    );
}

{ # Trigger cache
    note("Basic validation error (named parameters)");
    my $t1 = TestBasicValidations->new();

    my $exception = exception { $t1->validate_customer(customer => [ ]) };
    like(
        $exception,
        qr{^Error in TestBasicValidations::validate_customer \($file:11\):},
        "Validation error reference (named)"
    );
}

{
    note("Basic validation error (positional parameters)");
    my $t2 = TestBasicValidations->new();

    my $exception = exception { $t2->validate_positional_customer("") };
    like(
        $exception,
        qr{^Error in TestBasicValidations::validate_positional_customer \($file:36\):},
        "Validation error reference (positional)"
    );
}

{ # Trigger cache
    note("Basic validation error (positional parameters)");
    my $t2 = TestBasicValidations->new();

    my $exception = exception { $t2->validate_positional_customer([ ]) };
    like(
        $exception,
        qr{^Error in TestBasicValidations::validate_positional_customer \($file:36\):},
        "Validation error reference (positional)"
    );
}

abeltje_done_testing();
