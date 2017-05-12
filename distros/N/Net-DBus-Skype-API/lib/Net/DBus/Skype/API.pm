package Net::DBus::Skype::API;
use strict;
use warnings;
use parent qw/Net::DBus::Object/;
use 5.008001;
use Carp ();
use Net::DBus;

our $VERSION = '0.01';

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;

    my $name = $args{name}
        || __PACKAGE__ . '/' . $Net::DBus::Skype::API::VERSION;

    my $bus = Net::DBus->session;
    my $service = $bus->export_service('com.Skype.API');
    my $self = $class->SUPER::new($service, '/com/Skype/Client');
    $self->{name}     = $name;
    $self->{protocol} = $args{protocol} || 8;
    $self->{notify}   = $args{notify} || sub {};

    Carp::croak("Skype is not running.") unless $self->is_running;

    $self;
}

sub attach {
    my $self = shift;

    my $bus = Net::DBus->session;
    my $service = $bus->get_service('com.Skype.API');
    my $object = $service->get_object('/com/Skype');
    $self->{out} = $object;

    $self->send_command("NAME $self->{name}");
    $self->send_command("PROTOCOL $self->{protocol}");
}

sub is_running {
    my $self = shift;
    eval {
        my $bus = Net::DBus->session;
        $bus->get_service('com.Skype.API')->get_object('/com/Skype');
    };
    return 0 if $@;
    return 1;
}

sub send_command {
    my ($self, $command) = @_;
    unless ($self->{out}) {
        $self->attach;
    }
    $self->{out}->Invoke($command);
}

sub Notify {
    my ($self, $notification) = @_;
    $self->{notify}->($notification);
}

1;
__END__

=head1 NAME

Net::DBus::Skype::API - Skype API for Linux

=head1 SYNOPSIS

    use AnyEvent;
    use AnyEvent::DBus;
    use Net::DBus::Skype::API;

    my $cv = AE::cv;

    my $skype = Net::DBus::Skype::API->new(
        notify => sub {
            my ($notification) = @_;
            print $notification;
        },
    );
    $skype->attach;

    $cv->recv;

=head1 DESCRIPTION

This module is uselessly without L<Skype::Any>.

=head1 METHODS

=over 4

=item my $skype = Net::DBus::Skype::API->new([\%args])

Create new instance of Net::DBus::Skype::API.

=over 4

=item name

If you use spaces in the name, the name is truncated to the space.

=item protocol => 8 : Num

By default is 8.

=item notify => sub { my ($notification) = @_; ... }

This callback receives Skype-to-client commands and responses.

=back

=item $skype->attach()

Prepare to connect to Skype.

=item $skype->is_running()

Return 1 if Skype is running.

=item $skype->send_command($command)

Send client-to-Skype command.

=back

=head1 FAQ

=over 4

=item What's the reason why this module was written?

Because L<Net::DBus::Skype> doesn't provide Notify method for DBus. Without it, can't receive responses.

=back

=head1 SEE ALSO

L<Public API Reference|https://developer.skype.com/public-api-reference>

=head1 AUTHOR

Takumi Akiyama E<lt>t.akiym at gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
