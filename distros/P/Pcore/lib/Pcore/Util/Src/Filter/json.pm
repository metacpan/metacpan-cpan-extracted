package Pcore::Util::Src::Filter::json;

use Pcore -class, -res;
use Pcore::Util::Src qw[:FILTER_STATUS];

with qw[Pcore::Util::Src::Filter];

sub decompress ($self) {
    eval {
        my $data = P->data->from_json( $self->{data} );

        $self->{data} = P->data->to_json( $data, readable => 1 );
    };

    return $@ ? $SRC_FATAL : $SRC_OK;
}

sub compress ($self) {
    eval {
        my $data = P->data->from_json( $self->{data} );

        $self->{data} = P->data->to_json( $data, readable => 0 );
    };

    return $@ ? $SRC_FATAL : $SRC_OK;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 9, 19                | ErrorHandling::RequireCheckingReturnValueOfEval - Return value of eval not tested                              |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Src::Filter::json

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
