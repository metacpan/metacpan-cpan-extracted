package Pcore::Util::File::ChdirGuard;

use Pcore -class;

has dir => ( isa => 'Str', required => 1 );

sub DESTROY ( $self ) {
    chdir $self->{dir} or die;

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    1 | 25                   | Documentation::RequirePackageMatchesPodName - Pod NAME on line 29 does not match the package declaration       |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
