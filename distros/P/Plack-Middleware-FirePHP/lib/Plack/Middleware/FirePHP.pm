package Plack::Middleware::FirePHP;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.01';

use Plack::Response;
use Plack::Util;
use FirePHP::Dispatcher;
use Plack::Util::Accessor qw/disabled/;

use base 'Plack::Middleware';

sub call {
    my $self = shift;
    my $env = shift;

    if (defined $self->disabled && $self->disabled) {
        require Class::Null;
        $env->{'plack.fire_php'} = Class::Null->new;
    } else {
        require FirePHP::Dispatcher;
        $env->{'plack.fire_php'} = 
            FirePHP::Dispatcher->new(Plack::Response->new->headers);
    }

    my $res = $self->app->($env);
    $env->{'plack.fire_php'}->finalize;

    $self->response_cb($res, sub {
        my $res = Plack::Response->new(@{$_[0]});
        $res->headers->push_header(
            %{$env->{'plack.fire_php'}->{http_headers}}
        );
        @{$_[0]} = @{$res->finalize};
    });
}

1;

__END__
 
=pod
 
=head1 NAME
 
Plack::Middleware::FirePHP - Middleware for FirePHP::Dispatcher
 
=head1 SYNOPSIS
 
    # app.psgi
    use Plack::Builder;
 
    my $app = sub {
        my $env      = shift;
        my $fire_php = $env->{'plack.fire_php'};

        $fire_php->log('Hello from FirePHP');
        $fire_php->start_group('Levels:');
        $fire_php->info('Log informational message');
        $fire_php->warn('Log warning message');
        $fire_php->error('Log error message');
        $fire_php->end_group;

        $fire_php->start_group('Propably emtpy:');
        $fire_php->dismiss_group;

        return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello Foo' ] ];
    };
 
    builder {
        enable 'FirePHP';
        $app;
    };
 
=head1 DESCRIPTION

This is a Plack middleware component which enables FirePHP in your app using
L<FirePHP::Dispatcher>. Currently only the basic interface of supported. See
The L<FirePHP::Dispatcher> documentation for a list of supported methods.

Please B<do not> call C<finalize> on the FirePHP object yourself. The middleware 
takes care of that for you.

To enable the middleware, just use L<Plack::Builder> in your C<.psgi> file:

    use Plack::Builder;

    my $app = sub { ... };

    builder {
        enable 'FirePHP';
        $app;
    };

If you want to disable the FirePHP message (eg. for production usage) just
set C<disabled> to C<1>. In this case the middleware will use L<Class::Null>
instead of L<FirePHP::Dispatcher>, which will silently dispatch all your calls:

    use Plack::Builder;

    my $app = sub { ... };

    builder {
        enable 'FirePHP', disabled => 1;
        $app;
    };
 
=head1 BUGS
 
All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<http://www.firephp.org>, L<FirePHP::Dispatcher>, L<Class::Null>
 
=head1 AUTHOR
 
Florian Helmberger E<lt>fh@25th-floor.comE<gt>

Tatsuhiko Miyagawa
 
=head1 COPYRIGHT AND LICENSE
 
Copyright 2009 25th-floor - de Pretis & Helmberger KG
 
L<http://www.25th-floor.com>
 
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
 
=cut
