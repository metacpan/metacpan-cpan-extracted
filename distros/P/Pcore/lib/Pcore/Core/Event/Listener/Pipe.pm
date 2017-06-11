package Pcore::Core::Event::Listener::Pipe;

use Pcore -role;
use overload    #
  q[&{}] => sub ( $self, @ ) {
    return sub { return $self->sendlog(@_) };
  },
  fallback => undef;

requires qw[sendlog];

has uri => ( is => 'ro', isa => InstanceOf ['Pcore::Util::URI'], required => 1 );

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Core::Event::Listener::Pipe

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
