package Mojolicious::Plugin::ErrorTracking::Sentry;
use 5.008001;
use strict;
use warnings;

our $VERSION = '1.0.0';

use Mojo::Base 'Mojolicious::Plugin';

use English '-no_match_vars';
use Data::Dump 'dump';
use Devel::StackTrace;
use Sentry::Raven;

sub register {
    my ($self, $app, $conf) = @_;
    my $raven = Sentry::Raven->new(
        sentry_dsn => $conf->{sentry_dsn},
        timeout => $conf->{timeout},
    );

    $app->hook(
        around_dispatch => sub {
            my ($next, $c) = @_;

            my $stacktrace;
            eval {
                local $SIG{__DIE__} = sub { $stacktrace = Devel::StackTrace->new(skip_frames => 1) };
                $next->();
                1;
            };

            my $eval_error = $EVAL_ERROR;
            if ($eval_error) {
                my $message = $eval_error;
                chomp($message);

                my $custom_context = _build_custom_context($conf, $c);
                my $context = _make_context($raven, $message, $stacktrace, $custom_context);

                my $event_id = $raven->capture_message($message, %$context);
                if (!defined($event_id)) {
                    die "failed to submit event to sentry service:\n"
                        . CORE::dump($raven->_construct_message_event($message, %$context));
                }

                # Raise error for Mojolicious
                return ref $eval_error ? CORE::die($eval_error) : Mojo::Exception->throw($eval_error);
            }
        }
    );
}

sub _build_custom_context {
    my ($conf, $c) = @_;
    return $conf->{on_error}->($c) if ($conf->{on_error} && ref($conf->{on_error}) eq 'CODE');
    return {};
}

sub _make_context {
    my ($raven, $message, $stacktrace, $custom_context) = @_;
    my %stacktrace_context
        = $stacktrace
        ? $raven->stacktrace_context($raven->_get_frames_from_devel_stacktrace($stacktrace))
        : ();

    my $context = {
        culprit => $PROGRAM_NAME,
        %$custom_context,
        $raven->exception_context($message),
        %stacktrace_context,
    };
    return $context;
}

1;
__END__

=encoding utf-8

=head1 NAME

Mojolicious::Plugin::ErrorTracking::Sentry - error traking plugin for Mojolicious with Sentry

=head1 SYNOPSIS

    # Mojolicious
    $self->plugin('ErrorTracking::Sentry', sentry_dsn => 'http://<publickey>:<secretkey>@app.getsentry.com/<projectid>');

    # Custom error context handling
    use Sentry::Raven;

    $self->plugin('ErrorTracking::Sentry',
        sentry_dsn => 'http://<publickey>:<secretkey>@app.getsentry.com/<projectid>',
        on_error => sub {
            my $c = shift;
            # Make context you want.
            my %user_context = Sentry::Raven->user_context(
                id => $c->stash->{user}->{id},
            );
            return \%user_context; # Must return HashRef.
        },
    );

=head1 DESCRIPTION

Mojolicious::Plugin::ErrorTracking::Sentry is a Mojolicious plugin to send error report at Sentry.

=head1 CONFIG

=head2 C<< sentry_dsn => 'http://<publickey>:<secretkey>@app.getsentry.com/<projectid>' >>

The DSN for your sentry service.  Get this from the client configuration page for your project.

=head2 C<< timeout => 5 >>

Do not wait longer than this number of seconds when attempting to send an event.

=head2 C<on_error>

You can pass custom error context. For example

    $self->plugin('ErrorTracking::Sentry', on_error => sub {
        my $c = shift;
        return +{
            Sentry::Raven->user_context(id => $c->stash->{id}) ,
        };
    });

=head1 SEE ALSO

=over 4

=item L<Sentry::Raven>

This plugin use Sentry::Raven.

=back

=head1 LICENSE

Copyright (C) Akira Osada.

Released under the MIT license
http://opensource.org/licenses/mit-license.php

=head1 AUTHOR

Akira Osada E<lt>osd.akira@gmail.comE<gt>

=cut
