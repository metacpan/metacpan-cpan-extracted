package Pcore::Core::Dump;

use Pcore -export;
use Pcore::Core::Dump::Dumper;

our $EXPORT = {
    CORE    => [qw[dump]],
    DEFAULT => [qw[dump]],
};

sub dump {    ## no critic qw[Subroutines::ProhibitBuiltinHomonyms]
    my %args = (
        color  => 1,
        tags   => 1,
        indent => 4,
        @_[ 1 .. $#_ ],
    );

    return '$VAR = ' . bless( \%args, 'Pcore::Core::Dump::Dumper' )->run( $_[0] );
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    1 | 19                   | ValuesAndExpressions::RequireInterpolationOfMetachars - String *may* require interpolation                     |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Core::Dump

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
