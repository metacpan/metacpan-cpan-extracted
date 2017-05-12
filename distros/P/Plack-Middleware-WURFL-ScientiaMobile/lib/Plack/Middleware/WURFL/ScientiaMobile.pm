package Plack::Middleware::WURFL::ScientiaMobile;

use Moo;
use Net::WURFL::ScientiaMobile;
use Plack::Util;
use Try::Tiny;
use URI::Escape qw(uri_escape);
use 5.008008;

extends 'Plack::Middleware';

our $VERSION = '0.01';
sub PSGI_KEY     () { q{plack.middleware.wurfl.scientiamobile} }
sub CLIENT_CLASS () { q{Net::WURFL::ScientiaMobile} }

has 'config' => (
    is => 'ro',
    required => 1,
    isa => sub { die "config must be a hashref!" unless ref $_[0] eq 'HASH' },
);

has 'client' => (
    is => 'rw',
);

sub BUILD {
    my $self = shift;
    $self->client(CLIENT_CLASS->new($self->config));
}

sub call {
    my $self = shift;
    my ($env) = @_;
    
    # if we're using a cookie-based cache provider, pass env to it
    my $cookie_cache = $self->client->cache->isa('Net::WURFL::ScientiaMobile::Cache::Cookie');
    $self->client->cache->env($env) if $cookie_cache;
    
    # query the ScientiaMobile webservice
    try {
        $self->client->detectDevice($env);
        $env->{+PSGI_KEY} = $self->client;
    } catch {
        $env->{+PSGI_KEY} = $_;
    };
    
    my $res = $self->app->($env);
    if ($cookie_cache) {
        $self->response_cb($res, sub {
            my $res = shift;
            foreach my $cookie_name (%{ $self->client->cache->cookies }) {
                push @{$res->[1]}, 'Set-Cookie' => sprintf '%s=%s',
                    uri_escape($cookie_name),
                    uri_escape($self->client->cache->cookies->{$cookie_name});
            }
        });
    } else {
        return $res;
    }
}

sub get_from_env {
    my $self_or_class = shift;
    my ($env) = @_;
    
    my $obj = $env->{+PSGI_KEY};
    return (ref $obj eq CLIENT_CLASS) ? $obj : undef;
}

sub get_error_from_env {
    my $self_or_class = shift;
    my ($env) = @_;
    
    my $obj = $env->{+PSGI_KEY};
    return (ref $obj eq CLIENT_CLASS) ? undef : $obj;
}

=head1 NAME

Plack::Middleware::WURFL::ScientiaMobile - Query the ScientiaMobile webservice in middleware

=head1 SYNOPSIS

    use Plack::Builder;
    builder {
        enable 'WURFL::ScientiaMobile', config => {
            api_key => '...',
        };
        $app;
    };

=head1 DESCRIPTION

This middleware is intended to act as a bridge between the WURFL ScientiaMobile webservice
and PSGI-based web applications. It does two things: it processes each incoming HTTP request
through the C<detectDevice()> method of L<Net::WURFL::ScientiaMobile> and it places the
pre-populated ScientiaMobile object inside the C<$env> structure that is passed to your web 
application.
You can easily access it from your web framework of choice and apply your device-specific logic.

If you configure the ScientiaMobile object with a C<Cache> cache provider, the middleware
will be smart enough to interact with it for reading and writing cookies.

    use Plack::Builder;
    builder {
        enable 'WURFL::ScientiaMobile', config => {
            api_key => '...',
            cache   => Net::WURFL::ScientiaMobile::Cache::Cookie->new,
        };
        $app;
    };

=head1 ARGUMENTS

This middleware accepts the following arguments.

=head2 config

This argument is required. It must be a hashref containing the configuration options for the
L<Net::WURFL::ScientiaMobile> client object. The only required option is C<api_key>, but check
the documentation for L<Net::WURFL::ScientiaMobile> to learn about all possible options.

=head1 SUBROUTINES

=head2 PSGI_KEY

Returns the PSGI C<$env> key under which you'd expect to find either an instance of
L<Net::WURFL::ScientiaMobile> (pre-populated with the device capabilities) or an exception
object.

=head2 get_from_env

Given a L<Plack> C<$env>, returns the L<Net::WURFL::ScientiaMobile> object containing the device
capabilities. If the call to C<detectDevice()> threw an exception instead of succeeding, this method
returns undef.

For example, in your web application:

    use Plack::Middleware::WURFL::ScientiaMobile;
    
    sub my_handler {
        ...
        my $env = ...;   # your web framework provides this
        my $scientiamobile = Plack::Middleware::WURFL::ScientiaMobile->get_from_env($env);
        if (!$scientiamobile) {
            my $error = Plack::Middleware::WURFL::ScientiaMobile->get_error_from_env($env);
            ....
        }
        ....
    }

Refer to the documentation of your web framework to learn how to access C<$env>. For example,
L<Catalyst> provides it in C<$ctx-E<gt>request-E<gt>env>, Dancer provides it in C<request-E<gt>env>, 
L<Mojo> provides it in C<$tx-E<gt>req-E<gt>env>.

=head2 get_error_from_env

Given a L<Plack> C<$env>, returns the L<Exception::Class> object representing the failure. If
no exception was caught, undef is returned.

Refer to the documentation of L<Net::WURFL::ScientiaMobile> for an explanation of possible 
exceptions.

=head1 SEE ALSO

L<Plack>, L<Plack::Middleware>, L<Net::WURFL::ScientiaMobile>

=head1 AUTHOR

Alessandro Ranellucci C<< <aar@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2012, ScientiaMobile, Inc.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
