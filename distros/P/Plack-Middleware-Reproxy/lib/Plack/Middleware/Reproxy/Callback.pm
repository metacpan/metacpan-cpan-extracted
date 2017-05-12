package Plack::Middleware::Reproxy::Callback;
use strict;
use parent qw(Plack::Middleware::Reproxy);
use Plack::Util::Accessor qw(cb);

sub reproxy_to {
    my $self = shift;
    $self->cb->($self, @_);
}

1;

__END__

=head1 NAME

Plack::Middleware::Reproxy::Callback - Use A Callback

=head1 SYNOPSIS

    builder {
        enable 'Reproxy::Callback', cb => sub {
            my ($self, $res, $env, $url) = @_;
        };
        $your_real_app;
    }

=cut
