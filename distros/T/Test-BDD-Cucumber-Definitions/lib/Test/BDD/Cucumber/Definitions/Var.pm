package Test::BDD::Cucumber::Definitions::Var;

use strict;
use warnings;

use DDP ( show_unicode => 1 );
use Exporter qw(import);
use Params::ValidationCompiler qw(validation_for);
use Test::BDD::Cucumber::Definitions qw(S);
use Test::BDD::Cucumber::Definitions::Types qw(:all);
use Test::More;

our $VERSION = '0.21';

our @EXPORT_OK = qw(
    var_scenario_var_set
    var_scenario_var_random
);
our %EXPORT_TAGS = (
    util => [
        qw(
            var_scenario_var_set
            var_scenario_var_random
            )
    ]
);

## no critic [Subroutines::RequireArgUnpacking]

my $validator_var_set = validation_for(
    params => [

        # var name
        { type => TbcdNonEmptyStr },

        # var value
        { type => TbcdStr }
    ]
);

sub var_scenario_var_set {
    my ( $name, $value ) = $validator_var_set->(@_);

    S->{var}->{scenario}->{vars}->{$name} = $value;

    return;
}

my $validator_var_random = validation_for(
    params => [

        # var name
        { type => TbcdNonEmptyStr },

        # var length
        { type => TbcdInt }
    ]
);

sub var_scenario_var_random {
    my ( $name, $length ) = $validator_var_random->(@_);

    my @CHARS = ( 'a' .. 'z', 'A' .. 'Z', 0 .. 9 );
    my $str = "X" x $length;
    $str =~ s/X(?=X*\z)/$CHARS[ int( rand( @CHARS ) ) ]/ge;

    S->{var}->{scenario}->{vars}->{$name} = $str;

    return;
}

1;
