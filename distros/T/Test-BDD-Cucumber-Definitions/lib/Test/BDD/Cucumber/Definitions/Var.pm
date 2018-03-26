package Test::BDD::Cucumber::Definitions::Var;

use strict;
use warnings;

use DDP ( show_unicode => 1 );
use Exporter qw(import);
use Test::BDD::Cucumber::Definitions qw(S);
use Test::BDD::Cucumber::Definitions::Validator qw(:all);
use Test::More;

our $VERSION = '0.29';

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

sub var_scenario_var_set {
    my ( $name, $value ) = validator_ns->(@_);

    S->{var}->{scenario}->{vars}->{$name} = $value;

    return;
}

sub var_scenario_var_random {
    my ( $name, $length ) = validator_ni->(@_);

    my @CHARS = ( 'a' .. 'z', 'A' .. 'Z', 0 .. 9 );
    my $str = "X" x $length;
    $str =~ s/X(?=X*\z)/$CHARS[ int( rand( @CHARS ) ) ]/gex;

    S->{var}->{scenario}->{vars}->{$name} = $str;

    return;
}

1;
