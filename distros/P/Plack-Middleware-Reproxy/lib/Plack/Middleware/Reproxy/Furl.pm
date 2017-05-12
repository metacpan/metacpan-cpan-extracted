package Plack::Middleware::Reproxy::Furl;
use strict;
use parent qw(Plack::Middleware::Reproxy);
use Plack::Util::Accessor qw(furl);
use Furl::HTTP;

sub prepare_app {
    my $self = shift;
    if (! $self->furl) {
        my $furl = Furl::HTTP->new;
        $self->furl($furl);
    }
}

sub reproxy_to {
    my ($self, $res, $env, $url) = @_;

    # Now recreate headers
    my @hdrs = $self->extract_headers($env);

    my $input = $env->{'psgi.input'};
    $input->seek(0, 0);
    my @args = (
        method  => $env->{HTTP_METHOD},
        url     => $url,
        headers => \@hdrs,
        content => $input,
    );
    my (undef, $code, undef, $hdrs, $body) = $self->furl->request(@args);

    @$res = ( $code, $hdrs, [ $body ] );
}

1;

__END__

=head1 NAME

Plack::Middleware::Reproxy::Furl - Use Furl To Reproxy

=head1 SYNOPSIS

    # in your app.psgi
    use Plack::Builder;

    builder {
        enable 'Reproxy::Furl';
        $your_real_app;
    }

    builder {
        enable 'Reproxy::Furl', furl => Furl::HTTP->new(agent => "Blah");
        $your_real_app;
    }

=cut