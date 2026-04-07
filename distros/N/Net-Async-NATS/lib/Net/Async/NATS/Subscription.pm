package Net::Async::NATS::Subscription;
# ABSTRACT: Represents a NATS subscription
our $VERSION = '0.003';
use strict;
use warnings;


sub new {
    my ($class, %args) = @_;
    return bless {
        sid       => $args{sid},
        subject   => $args{subject},
        queue     => $args{queue},
        callback  => $args{callback},
        max_msgs  => $args{max_msgs},
        _received => 0,
    }, $class;
}


sub sid      { $_[0]->{sid} }
sub subject  { $_[0]->{subject} }
sub queue    { $_[0]->{queue} }
sub callback { $_[0]->{callback} }
sub max_msgs { $_[0]->{max_msgs} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::NATS::Subscription - Represents a NATS subscription

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    my $sub = await $nats->subscribe('foo.>', sub {
        my ($subject, $payload, $reply_to) = @_;
        # handle message
    });

    say $sub->sid;      # subscription ID
    say $sub->subject;  # subscribed subject

    await $nats->unsubscribe($sub);

=head1 DESCRIPTION

Lightweight object representing a single NATS subscription. Created by
L<Net::Async::NATS/subscribe> and passed to L<Net::Async::NATS/unsubscribe>.

=head2 sid

The unique subscription identifier (integer).

=head2 subject

The subject this subscription listens on.

=head2 queue

Optional queue group name for load-balanced delivery.

=head2 callback

The coderef invoked for each received message. Signature:
C<($subject, $payload, $reply_to)>.

=head2 max_msgs

If set, the subscription auto-unsubscribes after receiving this many messages.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-net-async-nats/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
