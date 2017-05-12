package Pcore::Util::File::UmaskGuard;

use Pcore -class;

use overload    #
  q[""] => sub {
    return $_[0]->old_umask;
  },
  fallback => undef;

has old_umask => ( is => 'ro', isa => Int, required => 1 );

sub DEMOLISH ( $self, $global ) {
    umask $self->old_umask;    ## no critic qw[InputOutput::RequireCheckedSyscalls]

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::File::UmaskGuard

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
