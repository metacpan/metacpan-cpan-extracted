package Ryu::Async::Process;

use strict;
use warnings;

our $VERSION = '0.016'; # VERSION

=head1 NAME

Ryu::Async::Process - wrapper around a forked process

=head1 DESCRIPTION

This is an L<IO::Async::Notifier> subclass for interacting with L<Ryu>.

=cut

use mro;

use parent qw(IO::Async::Notifier);

use IO::Async::Process;

=head2 stdout

A L<Ryu::Source> wrapper around the process STDOUT (fd1).

=cut

sub stdout {
    my ($self) = @_;
    $self->{stdout} //= $self->ryu->from_stream(
        $self->process->fd(1)
    )
}

=head2 stderr

A L<Ryu::Source> wrapper around the process STDOUT (fd1).

=cut

sub stderr {
    my ($self) = @_;
    $self->{stderr} //= $self->ryu->from_stream(
        $self->process->fd(2)
    )
}

sub ryu {
    my ($self) = @_;
    $self->{ryu} //= do {
        require Ryu::Async;
        $self->add_child(
            my $ryu = Ryu::Async->new
        );
        $ryu
    }
}

sub configure {
    my ($self, %args) = @_;
    if(exists $args{process}) {
        my $process = delete $args{process};
        $self->{process} = $process;
        $self->add_child($process);
    }
    return $self->next::method(%args);
}

1;

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2017-2019. Licensed under the same terms as Perl itself.

