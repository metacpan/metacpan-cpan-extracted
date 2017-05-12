package Skype::Any::Command;
use strict;
use warnings;
use Carp ();
use AnyEvent;
use Skype::Any::Error;

sub new {
    my ($class, $command) = @_;

    my $cv = AE::cv();
    $cv->cb(sub { $_[0]->recv });

    return bless {
        cv      => $cv,
        command => $command,
        id      => 0,
        reply   => undef,
    }, $class;
}

sub with_id {
    my $self = shift;
    return sprintf '#%d-%d %s', $self->{id}, $$, $self->{command};
}

sub retrieve_reply {
    my $self = shift;
    return $self->{reply} ||= $self->{cv}->recv;
}

sub reply {
    my ($self, $expected) = @_;

    my $reply = $self->retrieve_reply();
    my ($obj, $params) = split /\s+/, $reply, 2;
    if ($obj eq 'ERROR') {
        my ($code, $description) = split /\s+/, $params, 2;
        my $error = Skype::Any::Error->new($code, $description);
        Carp::carp("Caught error: $error");
        return undef;
    }

    if ($expected && $reply !~ /^\Q$expected\E/) {
        Carp::croak("Unexpected reply from Skype, got [$reply], expected [$expected (...)]");
    }

    return $reply;
}

sub split_reply {
    my ($self, $limit) = @_;
    $limit ||= 4;

    my $reply = $self->reply();
    return undef unless $reply;
    return split /\s+/, $reply, $limit;
}

1;
__END__

=head1 NAME

Skype::Any::Command - Command interface for Skype::Any

=head1 METHODS

=over 4

=item C<< $command->reply([$expected]) >>

Skype API doesn't guarantee an immediate response. When this method is called, (blocking) wait for a reply.

  print $skype->api->send_command('SEARCH RECENTCHATS')->reply;

=item C<< $command->split_reply([$limit]) >>

Return a list of commands which is split. $limit is by default 4.

  my ($obj, $id, $property, $value) = $command->split_reply();

=back

=cut
