package Test::BDD::Cucumber::Definitions::Validator;

use strict;
use warnings;

use Exporter qw(import);
use Params::ValidationCompiler qw(validation_for);
use Test::BDD::Cucumber::Definitions::Types qw(:all);

our $VERSION = '0.29';

our @EXPORT_OK = qw(
    validator_i
    validator_n
    validator_s
    validator_r
    validator_ni
    validator_ns
    validator_nn
    validator_nr
);

our %EXPORT_TAGS = (
    all => [
        qw(
            validator_i
            validator_n
            validator_s
            validator_r
            validator_ni
            validator_ns
            validator_nn
            validator_nr
            )
    ]
);

my $validator_i = validation_for(
    params => [

        # value integer
        { type => TbcdInt },
    ]
);

sub validator_i {
    return $validator_i;
}

my $validator_n = validation_for(
    params => [

        # name
        { type => TbcdNonEmptyStr },
    ]
);

sub validator_n {
    return $validator_n;
}

my $validator_s = validation_for(
    params => [

        # value string
        { type => TbcdStr },
    ]
);

sub validator_s {
    return $validator_s;
}

my $validator_r = validation_for(
    params => [

        # value regexp
        { type => TbcdRegexpRef }
    ]
);

sub validator_r {
    return $validator_r;
}

my $validator_ni = validation_for(
    params => [

        # name
        { type => TbcdNonEmptyStr },

        # value int
        { type => TbcdInt },
    ]
);

sub validator_ni {
    return $validator_ni;
}

my $validator_ns = validation_for(
    params => [

        # name
        { type => TbcdNonEmptyStr },

        # value string
        { type => TbcdStr }
    ]
);

sub validator_ns {
    return $validator_ns;
}

my $validator_nn = validation_for(
    params => [

        # value non empty string
        { type => TbcdNonEmptyStr },

        # value non empty string
        { type => TbcdNonEmptyStr },
    ]
);

sub validator_nn {
    return $validator_nn;
}

my $validator_nr = validation_for(
    params => [

        # name
        { type => TbcdNonEmptyStr },

        # value regexp
        { type => TbcdRegexpRef }
    ]
);

sub validator_nr {
    return $validator_nr;
}

1;
