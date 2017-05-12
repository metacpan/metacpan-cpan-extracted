package Pcore::Util::File::ChdirGuard;

use Pcore -class;

with qw[Pcore::Core::Guard];

has dir => ( is => 'ro', isa => Str, required => 1 );

sub ON_DESTROY {
    my $self = shift;

    chdir $self->dir or die;

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    1 | 29                   | Documentation::RequirePackageMatchesPodName - Pod NAME on line 33 does not match the package declaration       |
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
