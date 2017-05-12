package Skype::Any::Object;
use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    return bless \%args, $class;
}

sub api     { $_[0]->{skype}->api }
sub handler { $_[0]->{skype}->handler }

sub object {
    my $self = shift;
    $self->{skype}->object(@_);
}

sub property {
    my ($self, $obj, $property, $value) = @_;
    $property = uc $property;
    if (defined $value) {
        return $self->_set_property($obj, $property, $value);
    } else {
        return $self->_get_property($obj, $property);
    }
}

sub _get_property {
    my ($self, $obj, $property) = @_;

    my $id = $self->{id};
    my $cmd = do {
        if ($id) {
            sprintf 'GET %s %s %s', $obj, $id, $property;
        } else {
            sprintf 'GET %s %s', $obj, $property;
        }
    };
    my $command = $self->api->send_command($cmd);
    my @reply = $command->split_reply($id ? 4 : 3);
    return $reply[$id ? 3 : 2];
}

sub _set_property {
    my ($self, $obj, $property, $value) = @_;

    my $id = $self->{id};
    my $cmd = do {
        if ($id) {
            sprintf 'SET %s %s %s %s', $obj, $id, $property, $value;
        } else {
            sprintf 'SET %s %s %s', $obj, $property, $value;
        }
    };
    my $command = $self->api->send_command($cmd);
    my @reply = $command->split_reply($id ? 4 : 3);
    return $reply[$id ? 3 : 2];
}

sub alter {
    my ($self, $obj, $action, $value) = @_;
    $action = uc $action;

    my $id = $self->{id};
    my $cmd = "ALTER $obj $id $action";
    my $command;
    if (defined $value) {
        $command = $self->api->send_command("$cmd $value");
    } else {
        $command = $self->api->send_command($cmd);
    }

    return $command->reply;
}

sub _mk_bool_property {
    my ($class, @property) = @_;
    {
        no strict 'refs';
        for my $property (@property) {
            *{$property} = sub {
                my $self = shift;
                return $self->property($property) eq 'TRUE';
            };
        }
    }
}

sub AUTOLOAD {
    my $property = our $AUTOLOAD;
    $property =~ s/.*:://;
    {
        no strict 'refs';
        *{$property} = sub {
            my $self = shift;
            return $self->property($property, @_);
        };
    }
    goto &$property;
}

sub DESTROY {}

1;
__END__

=head1 NAME

Skype::Any::Object - General object class for Skype::Any::Object::*

=head1 METHODS

=over 4

=item C<< $object->object($obj, @args) >>

Create new instance of Skype::Any::Object::*.

  my $user = $object->object(user => 'echo123');

=item C<< $object->property($property[, $value]) >>

Get $property.

  $object->property($obj, $property);

Set $property to $value.

  $object->property($obj, $property, $value);

=item C<< $object->alter($obj, $action[, $value]) >>

=back

=head1 ATTRIBUTES

=over 4

=item C<< $object->api >>

=item C<< $object->handler >>

=back

=cut
