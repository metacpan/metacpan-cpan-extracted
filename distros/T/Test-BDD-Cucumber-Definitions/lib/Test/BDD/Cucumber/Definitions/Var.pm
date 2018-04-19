package Test::BDD::Cucumber::Definitions::Var;

use strict;
use warnings;

use DDP ( show_unicode => 1 );
use Exporter qw(import);
use Test::BDD::Cucumber::Definitions qw(S);
use Test::BDD::Cucumber::Definitions::Validator qw(:all);
use Test::More;

our $VERSION = '0.35';

our @EXPORT_OK = qw(Var);

## no critic [Subroutines::RequireArgUnpacking]

sub Var {
    return __PACKAGE__;
}

sub scenario_var_set {
    my $self = shift;
    my ( $name, $value ) = validator_ns->(@_);

    S->{Var} = __PACKAGE__;

    S->{_Var}->{scenario}->{vars}->{$name} = $value;

    return 1;
}

sub scenario_var_random {
    my $self = shift;
    my ( $name, $length ) = validator_ni->(@_);

    S->{Var} = __PACKAGE__;

    my @CHARS = ( 'a' .. 'z', 'A' .. 'Z', 0 .. 9 );
    my $str = "X" x $length;
    $str =~ s/X(?=X*\z)/$CHARS[ int( rand( @CHARS ) ) ]/gex;

    S->{_Var}->{scenario}->{vars}->{$name} = $str;

    return 1;
}

sub scenario {
    my $self = shift;
    my ($name) = validator_n->(@_);

    return S->{_Var}->{scenario}->{vars}->{$name};
}

1;
