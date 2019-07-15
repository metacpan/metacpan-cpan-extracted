package Pcore::Lib::File::UmaskGuard;

use Pcore -class;

use overload    #
  q[""] => sub {
    return $_[0]->old_umask;
  },
  fallback => undef;

has old_umask => ( required => 1 );    # Int

sub DESTROY ( $self ) {
    umask $self->{old_umask};          ## no critic qw[InputOutput::RequireCheckedSyscalls]

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Lib::File::UmaskGuard

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
