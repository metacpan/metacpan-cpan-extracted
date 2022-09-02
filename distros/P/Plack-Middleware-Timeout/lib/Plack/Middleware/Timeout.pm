package Plack::Middleware::Timeout;

use strict;
use warnings;
use parent 'Plack::Middleware';
use Plack::Util::Accessor qw(timeout response soft_timeout on_soft_timeout);
use Plack::Request;
use Plack::Response;
use Scope::Guard ();
use Time::HiRes qw(alarm time);
use Carp qw(croak);
use HTTP::Status qw(HTTP_GATEWAY_TIMEOUT);

our $VERSION = '0.11';

sub prepare_app {
    my $self = shift;

    $self->timeout(120) unless $self->timeout;

    for my $param (qw(response on_soft_timeout)) {
        next unless defined $self->$param;
        croak "parameter $param isn't a CODE reference!"
          unless ref( $self->$param ) eq 'CODE';
    }
}

my $default_on_soft_timeout = sub {
    warn sprintf "Soft timeout reached for uri '%s' (soft timeout: %ds) request took %ds", @_;
};

sub call {
    my ( $self, $env ) = @_;

    my $alarm_msg = 'Plack::Middleware::Timeout';
    local $SIG{ALRM} = sub { die $alarm_msg };

    my $time_started = 0;
    local $@;
    eval {

        $time_started = time();
        alarm($self->timeout);

        my $guard = Scope::Guard->new(sub {
            alarm 0;
        });

        my $soft_timeout_guard;

        if ( my $soft_timeout = $self->soft_timeout ) {
            $soft_timeout_guard = Scope::Guard->new(
                sub {
                    if ( time() - $time_started > $soft_timeout ) {
                        my $on_soft_timeout =
                          $self->on_soft_timeout || $default_on_soft_timeout;

                        my $request = Plack::Request->new($env);

                        $on_soft_timeout->(
                            $request->uri,
                            $soft_timeout,
                        );
                    }
                }
            );
        }

        return $self->app->($env);

    } or do {
        my $error = $@;
        if ( $error =~ /Plack::Middleware::Timeout/ ) {

            my $request = Plack::Request->new($env);
            my $response = Plack::Response->new(HTTP_GATEWAY_TIMEOUT);
            if ( my $build_response_coderef = $self->response ) {
                $build_response_coderef->($response);
            }
            else {
                # warn by default, so there's a trace of the timeout left somewhere
                warn sprintf
                  "Terminated request for uri '%s' due to timeout (%ds)",
                  $request->uri,
                  $self->timeout;
            }

            return $response->finalize;
        } else {
            # something else blew up, so rethrow it
            die $@;
        }
    };
}

1;

__END__

=head1 NAME 

Plack::Middleware::Timeout

=head1 SYNOPSIS

    my $app = sub { ... };

    Plack::Middleware::Timeout->wrap(
        $app,
        timeout  => 120,
        # optional callback to set the custom response 
        response => sub {
            my ($response_obj) = @_;

            $response_obj->code(HTTP_REQUEST_TIMEOUT);
            $response_obj->body( encode_json({
                timeout => 1,
                other_info => {...},
            }));

            return $plack_response;
        }
    );

=head1 DESCRIPTION

Timeout any plack requests at an arbitrary time.

=head1 PARAMETERS

=over

=item timeout

Numeric value accepted by subroutine defined in Time::HiRes::alarm, default: 120 seconds.

=item response

Optional subroutine which will be exeuted when timeout is reached. The subref receives a Plack::Response object as argument. If the response subref isn't defined, we resolve to emitting a warning:

=over

'Terminated request for uri '%s' due to timeout (%ds)'

=back

and return a response code 504 (HTTP_GATEWAY_TIMEOUT).

=item soft_timeout

Same as timeout, except this value will be checked after the call to the app has completed. See also C<on_soft_timeout> below.

=item on_soft_timeout

optional coderef that'll get executed when we established, that time required to serve the response was longer than a value provided in the soft_timeout parameter. If soft_timeout is set but no on_soft_timeout coderef is provided, we're going to issue a warning as follows; the response will be returned as normal.

=over

'Soft timeout reached for uri '%s' (soft timeout: %ds) request took %ds'

=back

=back

=head1 KNOWN LIMITATIONS

The module won't correctly handle the IO operations in progress - where the signals aren't delivered until after the read/write ends.

=head1 AUTHOR

Tomasz Czepiel <tjczepiel@gmail.com>

=head1 LICENCE 

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

