package Plack::Middleware::ChromeLogger;
use strict;
use warnings;
use Web::ChromeLogger;
use parent 'Plack::Middleware';
use Plack::Util;
use Plack::Util::Accessor qw/
    json_encoder
    enable_in_production
    disabled
/;

our $VERSION = '0.01';

sub prepare_app {
    my $self = shift;

    if ( $ENV{PLACK_ENV} && $ENV{PLACK_ENV} eq 'production'
            && !$self->enable_in_production ) {
        $self->disabled(1);
    }
}

sub call {
    my ($self, $env) = @_;

    unless ( $self->disabled ) {
        $env->{'psgix.chrome_logger'} = Web::ChromeLogger->new(
            json_encoder => $self->json_encoder,
        );
    }

    my $res = $self->app->($env);

    $self->response_cb($res, sub {
        return if $self->disabled;

        my $h = Plack::Util::headers($_[0]->[1]);
        $h->set('X-ChromeLogger-Data' => $env->{'psgix.chrome_logger'}->finalize);
    });
}

1;

__END__

=head1 NAME

Plack::Middleware::ChromeLogger - The Chrome Logger Middleware for Plack


=head1 SYNOPSIS

    use Plack::Builder;

    builder {
      enable "ChromeLogger";
      sub {
        $env->{"psgix.chrome_logger"}->info("foo");
        [200, [], ["OK"]];
      };
    };


=head1 DESCRIPTION

Plack::Middleware::ChromeLogger is the Chrome Logger Middleware for Plack.

See L<Web::ChromeLogger>, L<http://craig.is/writing/chrome-logger> for detail


=head1 METHODS

=over

=item prepare_app

=item call

=back


=head1 MIDDLEWARE OPTIONS

=over

=item json_encoder

pass to L<Web::ChromeLogger>. Who need to set this parameter ?

=item enable_in_production

By default this middleware is turned off in production environment.
If you set B<enable_in_production> to TRUE value, then chrome logger will be enabled in production environment.

=item disabled

turn off this middleware

=back


=head1 REPOSITORY

Plack::Middleware::ChromeLogger is hosted on github
<http://github.com/bayashi/Plack-Middleware-ChromeLogger>

Welcome your patches and issues :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<Web::ChromeLogger>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
