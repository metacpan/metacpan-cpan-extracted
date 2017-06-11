package Mojo::WebSocketProxy::Parser;

use strict;
use warnings;

our $VERSION = '0.06';    ## VERSION

sub parse_req {
    my ($c, $req_storage) = @_;

    my $result;
    my $args = $req_storage->{args};
    if (ref $args ne 'HASH') {
        # for invalid call, eg: not json
        $req_storage->{args} = {};
        $result = $c->wsp_error('error', 'BadRequest', 'The application sent an invalid request.');
    }

    $result = _check_sanity($c, $req_storage) unless $result;

    return $result;
}

sub _check_sanity {
    my ($c, $req_storage) = @_;

    my @failed;
    my $args   = $req_storage->{args};
    my $config = $c->wsp_config->{config};

    OUTER:
    foreach my $k (keys %$args) {
        if (not ref $args->{$k}) {
            last OUTER if (@failed = _failed_key_value($k, $args->{$k}, $config->{skip_check_sanity}));
        } else {
            if (ref $args->{$k} eq 'HASH') {
                foreach my $l (keys %{$args->{$k}}) {
                    last OUTER
                        if (@failed = _failed_key_value($l, $args->{$k}->{$l}, $config->{skip_check_sanity}));
                }
            } elsif (ref $args->{$k} eq 'ARRAY') {
                foreach my $l (@{$args->{$k}}) {
                    last OUTER if (@failed = _failed_key_value($k, $l, $config->{skip_check_sanity}));
                }
            }
        }
    }

    if (@failed) {
        $c->app->log->warn("Sanity check failed: " . $failed[0] . " -> " . ($failed[1] // "undefined"));
        my $result = $c->wsp_error('sanity_check', 'SanityCheckFailed', 'Parameters sanity check failed.');
        if (    $result->{error}
            and $result->{error}->{code} eq 'SanityCheckFailed')
        {
            $req_storage->{args} = {};
        }
        return $result;
    }
    return;
}

sub _failed_key_value {
    my ($key, $value, $skip_check_sanity) = @_;

    my $key_regex = qr/^[A-Za-z0-9_-]{1,50}$/;
    if ($key !~ /$key_regex/) {
        return ($key, $value);
    }

    if ($skip_check_sanity && $key =~ /$skip_check_sanity/) {
        return;
    }

    if (
        $key !~ /$key_regex/
        # !-~ to allow a range of acceptable characters. To find what is the range, look at ascii table

        # \p{L} is to match utf-8 characters
        # \p{Script=Common} is to match double byte characters in Japanese keyboards, eg: '１−１−１'
        # refer: http://perldoc.perl.org/perlunicode.html
        # null-values are allowed
        or ($value and $value !~ /^[\p{Script=Common}\p{L}\s\w\@_:!-~]{0,300}$/))
    {
        return ($key, $value);
    }
    return;
}

1;

__END__

=head1 NAME

Mojo::WebSocketProxy::Parser

=head1 DESCRIPTION

This module using for parse JSON websocket messages.

=head1 METHODS

=head2 parse_req

=head1 SEE ALSO

L<Mojolicious::Plugin::WebSocketProxy>,
L<Mojo::WebSocketProxy>,
L<Mojo::WebSocketProxy::CallingEngine>,
L<Mojo::WebSocketProxy::Dispatcher>,
L<Mojo::WebSocketProxy::Config>
L<Mojo::WebSocketProxy::Parser>

=cut
