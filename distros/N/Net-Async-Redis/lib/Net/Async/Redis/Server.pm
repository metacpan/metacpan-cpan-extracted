package Net::Async::Redis::Server;

use strict;
use warnings;

use parent qw(IO::Async::Notifier);

our $VERSION = '3.021'; # VERSION

=head1 NAME

Net::Async::Redis::Server - basic server implementation

=head1 DESCRIPTION

Best to wait until the 2.000 release for this one.

=cut

sub _add_to_loop {
    my ($self, $loop) = @_;
    $self->add_child(
        my $listener = IO::Async::Listener->new(
            on_stream => sub {
                my ($server, $stream) = @_;

            }
        )
    );
}

1;

__END__

=head1 AUTHOR

Tom Molesworth C<< <TEAM@cpan.org> >> plus contributors as mentioned in
L<Net::Async::Redis/CONTRIBUTORS>.

=head1 LICENSE

Copyright Tom Molesworth 2015-2022. Licensed under the same terms as Perl itself.

