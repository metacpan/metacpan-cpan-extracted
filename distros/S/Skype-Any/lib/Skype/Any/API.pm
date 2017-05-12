package Skype::Any::API;
use strict;
use warnings;
use Carp ();
use Encode ();
use Skype::Any::Command;
use Skype::Any::Error;

our @OBJECT = qw/USER CALL MESSAGE CHAT CHATMEMBER CHATMESSAGE VOICEMAIL SMS APPLICATION GROUP FILETRANSFER/;

sub new {
    my ($class, %args) = @_;

    my $self = bless {
        %args,
        commands => {},
    }, $class;

    $self->handler->register(Notification => sub {
        my $notification = shift;
        my ($obj, $params) = split /\s+/, $notification, 2;
        if ($obj eq 'ERROR') {
            my ($code, $description) = split /\s+/, $params, 2;
            my $error = Skype::Any::Error->new($code, $description);
            $self->handler->call('Error', _ => $error);
        } elsif (grep { $obj eq $_ } @OBJECT) {
            my ($id, $property, $value) = split /\s+/, $params, 3;
            my $object = $self->{skype}->object($obj => $id);
            $self->handler->call($obj, _ => $object, $value);
            $self->handler->call($obj, $property => $object, $value);
        }
    });

    return $self;
}

sub handler { $_[0]->{skype}->handler }

sub run;
sub attach;
sub is_running;
sub send;

sub send_command {
    my ($self, $cmd) = @_;

    my $command = Skype::Any::Command->new($cmd);
    if (my $reply = $self->send(Encode::encode_utf8($command->with_id))) {
        $reply = Encode::decode_utf8($reply);
        $reply =~ s/^#(\d+-\d+)\s+//;
        $command->{cv}->send($reply);
        $self->_reply_received($reply);
    } else {
        $self->_push_command($command);
    }

    $self->handler->call('Command', _ => $command);

    return $command;
}

sub _push_command {
    my ($self, $command) = @_;
    my $id = $command->{id};
    if ($id < 1) {
        while (exists $self->{commands}{"$id-$$"}) {
            $id++;
        }
        $command->{id} = $id;
    } elsif (exists $self->{commands}{"$id-$$"}) {
        Carp::croak('Command id conflict');
    }
    $self->{commands}{"$id-$$"} = $command;
}

sub _pop_command {
    my ($self, $id) = @_;
    return delete $self->{commands}{$id};
}

sub _notification_handler {
    my $self = shift;
    return sub {
        my ($notification) = @_;
        $notification = Encode::decode_utf8($notification);

        $self->handler->call('Receive', _ => $notification);

        if ($notification =~ s/^#(\d+-\d+)\s+//) {
            if (my $command = $self->_pop_command($1)) {
                $command->{cv}->send($notification);
                $self->_reply_received($notification);
            }
        } else {
            $self->_notification_received($notification);
        }
    };
}

sub _reply_received {
    my ($self, $reply) = @_;
    $self->handler->call('Reply', _ => $reply);
}

sub _notification_received {
    my ($self, $notification) = @_;
    $self->handler->call('Notification', _ => $notification);
}

1;
__END__

=head1 NAME

Skype::Any::API - API interface for Skype::Any

=head1 METHODS

=over 4

=item C<< $api->is_running() >>

Return 1 when Skype is running and 0 otherwise.

=item C<< $api->send_command($cmd, $expected) >>

Send Skype API string. This method returns new instance of L<Skype::Any::Commond>. If you want reply command sent:

  $api->send_command($cmd)->reply();

=back

=head1 ATTRIBUTES

=over 4

=item C<< $api->handler >>

=back

=cut
