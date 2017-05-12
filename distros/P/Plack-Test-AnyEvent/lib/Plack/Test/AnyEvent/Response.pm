package
    Plack::Test::AnyEvent::Response;

use strict;
use warnings;
use parent 'HTTP::Response';

sub from_psgi {
    my $class = shift;

    my $self = HTTP::Response::from_psgi($class, @_);
    bless $self, $class;

    return $self;
}

sub send {
    my ( $self, @values ) = @_;

    $self->{'_cond'}->send(@values);
}

sub recv {
    my ( $self ) = @_;

    my $cond = $self->{'_cond'};

    local $SIG{__DIE__} = Plack::Test::AnyEvent->exception_handler($cond);

    my $ex = $cond->recv;
    if($ex) {
        die $ex;
    }
}

sub on_content_received {
    my ( $self, $cb ) = @_;

    if($cb) {
        $self->{'_on_content_received'} = $cb;
        $cb->($self->content)  if $self->{_cond}->ready;
    }
    return $self->{'_on_content_received'};
}

1;

=pod

=begin comment

=over

=item from_psgi

=item send

=item recv

=item on_content_received

=back

=end comment

=cut
