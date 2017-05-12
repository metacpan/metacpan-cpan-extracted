use strict;
package POE::Component::Server::HTTP::Connection;

sub new {
    return bless {};
}

sub remote_host {
    return "N/A";
}

sub remote_ip {
    my $self = shift;
    return $self->{remote_ip};
}

sub local_addr {
    my $self = shift;
    return $self->{local_addr};
}

sub remote_addr {
    my $self = shift;
    return $self->{remote_addr};
}

sub remote_logname {
    my $self = shift;
    return "N/A";
}

sub user {
    my $self = shift;
    if (@_) {
        $self->{user} = shift;
    }
    return $self->{user};
}

sub authtype {
    my $self = shift;
    return $self->{authtype};
}

sub aborted {
    return 0;
}

sub fileno {
    return 0;
}

sub clone {
    my $self = shift;
    my $new = bless { %$self };
    return $new;
}

sub response {
    my $self = shift;
    return $self->{response};
}

sub request {
    my $self = shift;
    return $self->{request};
}

1;
