package Plack::Middleware::ServerTiming;
use strict;
use warnings;
use parent qw/Plack::Middleware/;
use Plack::Util;

our $VERSION = "0.04";

sub call {
    my ($self, $env) = @_;

    my $res = $self->app->($env);
    $self->response_cb($res, sub {
        my $res = shift;

        return unless exists $env->{'psgix.server-timing'};

        my @header;
        for my $metric (@{$env->{'psgix.server-timing'}}) {
            my $name  = $metric->[0];
            my %field = %{$metric->[1] || {}};
            my @opt = map { "$_=" . _escape($field{$_}) } grep { defined $field{$_} } qw/dur desc/;
            push @header, join ';', $name, @opt;
        }
        Plack::Util::header_set($res->[1], 'Server-Timing', join(', ', @header));
    });
}

sub _escape {
    my $v = shift;
    if ($v =~ /[\x00-\x20()<>@,;:\\\"\/\[\]?={}\x7F-\xFF]/ || !length($v)) {
        $v =~ s/([\"\\])/\\$1/g;
        return qq{"$v"};
    } else {
        return $v;
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Plack::Middleware::ServerTiming - Performance metrics in Server-Timing header

=head1 SYNOPSIS

    use Plack::Builder;

    builder {
        enable 'ServerTiming';
        sub {
            my $env = shift;
            sleep 1;
            push @{$env->{'psgix.server-timing'}}, ['miss'];
            push @{$env->{'psgix.server-timing'}}, ['sleep', {dur => 1000, desc => 'Sleep one second...'}];
            [200, ['Content-Type','text/html'], ["OK"]];
        };
    };

=head1 DESCRIPTION

Plack::Middleware::ServerTiming is middleware to add C<Server-Timing> header on your response.
You may set C<psgix.server-timing> environment value to specify name, duration and description as metrics.

=head1 ENVIRONMENT VALUE

=over 4

=item psgix.server-timing

    $env->{'psgix.server-timing'} = [
        [$name],
        [$name, {dur => $duration}],
        [$name, {desc => $description}],
        [$name, {dur => $duration, desc => $description}],
    ];

=back

=head1 SEE ALSO

L<https://www.w3.org/TR/server-timing/>

=head1 LICENSE

Copyright (C) Takumi Akiyama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Takumi Akiyama E<lt>t.akiym@gmail.comE<gt>

=cut

