package Plack::Middleware::Cerberus;
{
  $Plack::Middleware::Cerberus::VERSION = '0.04';
}

use strict;
use warnings;

use parent 'Plack::Middleware';
use Plack::Util::Accessor qw(client servers timeout log_as enforce);
use App::Cerberus::Client();

#===================================
sub prepare_app {
#===================================
    my $self   = shift;
    my $client = App::Cerberus::Client->new(
        servers => $self->servers,
        timeout => $self->timeout
    );
    $self->client($client);
    $self->log_as('warn') unless $self->log_as;
}

#===================================
sub call {
#===================================
    my ( $self, $env ) = @_;
    my $info = $env->{'plack.cerberus'} = $self->client->request(
        ip => $env->{REMOTE_ADDR}     || '',
        ua => $env->{HTTP_USER_AGENT} || ''
    );

    my $response = $self->_throttle( $env, $info->{throttle} );
    return $response if $response;
    return $self->app->($env);

}

#===================================
sub _throttle {
#===================================
    my ( $self, $env, $throttle, ) = @_;
    return unless $throttle;
    my $sleep = $throttle->{sleep} or return;
    my $range = $throttle->{range};

    my $enforce = $self->enforce;
    my $msg = ( $enforce ? "[Throttle] " : "[Throttle - Unenforced] " )
        . join( ', ',
        'Reason: ' . $throttle->{reason},
        'Range: ' . $range,
        'IP: ' . $env->{REMOTE_ADDR},
        'Sleep: ' . $sleep );

    if ( my $logger = $env->{'psgix.logger'} ) {
        $logger->( { level => $self->log_as, message => $msg } );
    }
    else {
        warn "$msg\n";
    }
    return unless $enforce;
    return [ 403, [], ['Forbidden'] ] if $sleep < 0;
    return [ 503, [ 'Retry-After' => $sleep ], ['Service unavailable'] ];
}
1;

# ABSTRACT: Include geo, time zone, user-agent and throttling from App::Cerberus


__END__
=pod

=head1 NAME

Plack::Middleware::Cerberus - Include geo, time zone, user-agent and throttling from App::Cerberus

=head1 VERSION

version 0.04

=head1 SYNOPSIS

    use Plack::Builder;

    my $app = sub {
        my $env = shift;
        my $time_zone = $env->{'plack.cerberus'}{tz}{name};
        ...
    };

    builder {
        enable 'Cerberus', servers => 'http://localhost:5001/';
        $app;
    };

=head1 DESCRIPTION

L<Plack::Middleware::Cerberus> adds metadata from an L<App::Cerberus> server to
the C<$env> as C<< $env->{'plack.cerberus'} >>.

For instance:

=over

=item *

Geo-location

=item *

Time zone

=item *

User-agent info

=item *

Are they a spider?

=item *

Are they making too many requests? Should we throttle them?

=back

It can also be configured to throttle or ban IP address ranges with
L<App::Cerberus::Plugin::Throttle>.

=head1 CONFIG

The basic configuration (C<servers> and C<timeout>) are passed to
L<App::Cerberus::Client/new()>.

    enable 'Cerberus',
        servers  => 'http://localhost:5001/',
        timeout  => 0.1;

Or

    enable 'Cerberus',
        servers  => [ 'http://host1:5001/', 'http://host2:5001/']
        timeout  => 0.1;

If you are using the L<App::Cerberus::Plugin::Throttle> plugin, then you can
also configure:

    enable 'Cerberus',
        servers => 'http://localhost:5001/',
        enforce => 1,
        log_as  => 'warn';

If C<log_as> is one of C<debug>, C<info>, C<warn>, C<error> or C<fatal>, then
Throttle messages will be logged at that level. It defaults to C<warn>. If
no logger is configured, then C<log_as> is ignored and it always warns.

If C<enforce> is true, then banned IP addresses will receive a
C<403 Forbidden> response and throttled users a C<503 Service Unavailable>
response, with a C<Retry-After: $seconds> header.

=head1 ACCESSING CERBERUS INFO

The C<$env> variable will contain a key C<'plack.cerberus'>
with any data that L<App::Cerberus> has returned, for instance:

    my $app = sub {
        my $env        = shift;
        my $geo_info   = $env->{'plack.cerberus'}{geo};
        my $time_zone  = $env->{'plack.cerberus'}{tz};
        my $user_agent = $env->{'plack.cerberus'}{ua};
        my $throttle   = $env->{'plack.cerberus'}{throttle};
    };

=head1 SEE ALSO

=over

=item *

L<App::Cerberus>

=item *

L<Dancer::Plugin::Cerberus>

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Plack::Middleware::Cerberus

You can also look for information at:

=over

=item * GitHub

L<http://github.com/clintongormley/Plack-Middleware-Cerberus>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Plack-Middleware-Cerberus>

=item * Search MetaCPAN

L<https://metacpan.org/module/Plack::Middleware::Cerberus>

=back

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Clinton Gormley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

