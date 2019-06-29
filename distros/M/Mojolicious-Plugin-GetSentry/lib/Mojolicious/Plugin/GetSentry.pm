package Mojolicious::Plugin::GetSentry;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '1.1.8';

use Data::Dump 'dump';
use Devel::StackTrace::Extract;
use Mojo::IOLoop;
use Sentry::Raven;

has [qw(
    sentry_dsn timeout
)];

has 'log_levels' => sub { ['error', 'fatal'] };
has 'processors' => sub { [] };

has 'raven' => sub {
    my $self = shift;

    foreach my $processor (@{ $self->processors }) {
        eval "require $processor; $processor->import;";

        warn $@ if $@;
    }

    return Sentry::Raven->new(
        sentry_dsn  => $self->sentry_dsn,
        timeout     => $self->timeout,
        processors  => $self->processors,
    );
};

has 'handlers' => sub {
    my $self = shift;

    return {
        capture_request     => sub { $self->capture_request(@_) },
        capture_message     => sub { $self->capture_message(@_) },
        stacktrace_context  => sub { $self->stacktrace_context(@_) },
        exception_context   => sub { $self->exception_context(@_) },
        user_context        => sub { $self->user_context(@_) },
        request_context     => sub { $self->request_context(@_) },
        tags_context        => sub { $self->tags_context(@_) },
        ignore              => sub { $self->ignore(@_) },
        on_error            => sub { $self->on_error(@_) },
    };
};

has 'custom_handlers' => sub { {} };
has 'pending' => sub { {} };

=head2 register

=cut

sub register {
    my ($self, $app, $config) = (@_);
    
    my $handlers = {};

    foreach my $name (keys(%{ $self->handlers })) {
        $handlers->{ $name } = delete($config->{ $name });
    }

    # Set custom handlers
    $self->custom_handlers($handlers);

    $config ||= {};
    $self->{ $_ } = $config->{ $_ } for keys %$config;
    
    $self->hook_after_dispatch($app);
    $self->hook_on_message($app);
}

=head2 hook_after_dispatch

=cut

sub hook_after_dispatch {
    my $self = shift;
    my $app = shift;

    $app->hook(after_dispatch => sub {
        my $controller = shift;

        if (my $exception = $controller->stash('exception')) {
            # Mark this exception as handled. We don't delete it from $pending
            # because if the same exception is logged several times within a
            # 2-second period, we want the logger to ignore it.
            $self->pending->{ $exception } = 0 if defined $self->pending->{ $exception };
            
            # Check if the exception should be ignored
            if (!$self->handle('ignore', $exception)) {
                $self->handle('capture_request', $exception, $controller);
            }
        }
    });
}

=head2 hook_on_message

=cut

sub hook_on_message {
    my $self = shift;
    my $app = shift;

    $app->log->on(message => sub {
        my ($log, $level, $exception) = @_;

        if( grep { $level eq $_ } @{ $self->log_levels } ) {
            $exception = Mojo::Exception->new($exception) unless ref $exception;

            # This exception is already pending
            return if defined $self->pending->{ $exception };
       
            $self->pending->{ $exception } = 1;

            # Check if the exception should be ignored
            if (!$self->handle('ignore', $exception)) {
                # Wait 2 seconds before we handle it; if the exception happened in
                # a request we want the after_dispatch-hook to handle it instead.
                Mojo::IOLoop->timer(2 => sub {
                    $self->handle('capture_message', $exception);
                });
            }
        }
    });
}

=head2 handle

=cut

sub handle {
    my ($self, $method) = (shift, shift);

    return $self->custom_handlers->{ $method }->($self, @_)
        if (defined($self->custom_handlers->{ $method }));
    
    return $self->handlers->{ $method }->(@_);
}

=head2 capture_request

=cut

sub capture_request {
    my ($self, $exception, $controller) = @_;

    $self->handle('stacktrace_context', $exception);
    $self->handle('exception_context', $exception);
    $self->handle('user_context', $controller);
    $self->handle('tags_context', $controller);
    
    my $request_context = $self->handle('request_context', $controller);

    my $event_id = $self->raven->capture_request($controller->url_for->to_abs, %$request_context, $self->raven->get_context);

    if (!defined($event_id)) {
        $self->handle('on_error', $exception->message, $self->raven->get_context);
    }

    return $event_id;
}

=head2 capture_message

=cut

sub capture_message {
    my ($self, $exception) = @_;

    $self->handle('exception_context', $exception);

    my $event_id = $self->raven->capture_message($exception->message, $self->raven->get_context);

    if (!defined($event_id)) {
        $self->handle('on_error', $exception->message, $self->raven->get_context);
    }

    return $event_id;
}

=head2 stacktrace_context

$app->sentry->stacktrace_context($exception)

Build the stacktrace context from current exception.
See also L<Sentry::Raven->stacktrace_context|https://metacpan.org/pod/Sentry::Raven#Sentry::Raven-%3Estacktrace_context(-$frames-)>

=cut

sub stacktrace_context {
    my ($self, $exception) = @_;

    my $stacktrace = Devel::StackTrace::Extract::extract_stack_trace($exception);

    $self->raven->add_context(
        $self->raven->stacktrace_context($self->raven->_get_frames_from_devel_stacktrace($stacktrace))
    );
}

=head2 exception_context

$app->sentry->exception_context($exception)

Build the exception context from current exception.
See also L<Sentry::Raven->exception_context|https://metacpan.org/pod/Sentry::Raven#Sentry::Raven-%3Eexception_context(-$value,-%25exception_context-)>

=cut

sub exception_context {
    my ($self, $exception) = @_;

    $self->raven->add_context(
        $self->raven->exception_context($exception->message, type => ref($exception))
    );
}

=head2 user_context

$app->sentry->user_context($controller)

Build the user context from current controller.
See also L<Sentry::Raven->user_context|https://metacpan.org/pod/Sentry::Raven#Sentry::Raven-%3Euser_context(-%25user_context-)>

=cut

sub user_context {
    my ($self, $controller) = @_;

    if (defined($controller->user)) {
        $self->raven->add_context(
            $self->raven->user_context(
                id          => $controller->user->id,
                ip_address  => $controller->tx && $controller->tx->remote_address,
            )
        );
    }
}

=head2 request_context

$app->sentry->request_context($controller)

Build the request context from current controller.
See also L<Sentry::Raven->request_context|https://metacpan.org/pod/Sentry::Raven#Sentry::Raven-%3Erequest_context(-$url,-%25request_context-)>

=cut

sub request_context {
    my ($self, $controller) = @_;

    if (defined($controller->req)) {
        my $request_context = {
            method  => $controller->req->method,
            headers => $controller->req->headers->to_hash,
        };

        $self->raven->add_context(
            $self->raven->request_context($controller->url_for->to_abs, %$request_context)
        );

        return $request_context;
    }

    return {};
}

=head2 tags_context
    
$app->sentry->tags_context($controller)

Add some tags to the context.
See also L<Sentry::Raven->3Emerge_tags|https://metacpan.org/pod/Sentry::Raven#$raven-%3Emerge_tags(-%25tags-)>

=cut

sub tags_context {
    my ($self, $c) = @_;

    $self->raven->merge_tags(
        getsentry => $VERSION,
    );
}

=head2 ignore
    
$app->sentry->ignore($exception)

Check if the exception should be ignored.

=cut

sub ignore {
    my ($self, $exception) = @_;

    return 0;
}

=head2 on_error
    
$app->sentry->on_error($message, %context)

Handle reporting to Sentry error.

=cut

sub on_error {
    my ($self, $message) = (shift, shift);

    die "failed to submit event to sentry service:\n" . dump($self->raven->_construct_message_event($message, @_));
}

1;

__END__

=pod

=head1 NAME

Mojolicious::Plugin::GetSentry - Sentry client for Mojolicious

=head1 VERSION

version 1.0

=head1 SYNOPSIS
    
    # Mojolicious with config
    #
    $self->plugin('sentry' => {
        # Required field
        sentry_dsn  => 'DSN',

        # Not required
        log_levels => ['error', 'fatal'],
        timeout     => 3,
        logger      => 'root',
        platform    => 'perl',

        # And if you want to use custom handles
        # this is how you do it
        stacktrace_context => sub {
            my ($sentry, $exception) = @_;

            my $stacktrace = Devel::StackTrace::Extract::extract_stack_trace($exception);

            $sentry->raven->add_context(
                $sentry->raven->stacktrace_context($sentry->raven->_get_frames_from_devel_stacktrace($stacktrace))
            );
        },

        exception_context => sub {
            my ($sentry, $exception) = @_;

            $sentry->raven->add_context(
                $sentry->raven->exception_context($exception->message, type => ref($exception))
            );
        },

        user_context => {
            my ($sentry, $controller) = @_;

            $sentry->raven->add_context(
                $sentry->raven->user_context(
                    id          => 1,
                    ip_address  => '10.10.10.1',
                )
            );
        },

        request_context => sub {
            my ($sentry, $controller) = @_;

            if (defined($controller->req)) {
                my $request_context = {
                    method  => $controller->req->method,
                    headers => $controller->req->headers->to_hash,
                };

                $sentry->raven->add_context(
                    $sentry->raven->request_context($controller->url_for->to_abs, %$request_context)
                );

                return $request_context;
            }

            return {};
        },

        tags_context => sub {
            my ($sentry, $controller) = @_;

            $sentry->raven->merge_tags(
                account => $controller->current_user->account_id,
            );
        },

        ignore => sub {
            my ($sentry, $exception) = @_;

            return 1 if ($expection->message =~ /Do not log this error/);
        },

        on_error => sub {
            my ($self, $message) = (shift, shift);

            die "failed to submit event to sentry service:\n" . dump($sentry->raven->_construct_message_event($message, @_));
        }
    });

    # Mojolicious::Lite
    #
    plugin 'sentry' => {
        # Required field
        sentry_dsn  => 'DSN',

        # Not required
        log_levels => ['error', 'fatal'],
        timeout     => 3,
        logger      => 'root',
        platform    => 'perl',

        # And if you want to use custom handles
        # this is how you do it
        stacktrace_context => sub {
            my ($sentry, $exception) = @_;

            my $stacktrace = Devel::StackTrace::Extract::extract_stack_trace($exception);

            $sentry->raven->add_context(
                $sentry->raven->stacktrace_context($sentry->raven->_get_frames_from_devel_stacktrace($stacktrace))
            );
        },

        exception_context => sub {
            my ($sentry, $exception) = @_;

            $sentry->raven->add_context(
                $sentry->raven->exception_context($exception->message, type => ref($exception))
            );
        },

        user_context => {
            my ($sentry, $controller) = @_;

            $sentry->raven->add_context(
                $sentry->raven->user_context(
                    id          => 1,
                    ip_address  => '10.10.10.1',
                )
            );
        },

        request_context => sub {
            my ($sentry, $controller) = @_;

            if (defined($controller->req)) {
                my $request_context = {
                    method  => $controller->req->method,
                    headers => $controller->req->headers->to_hash,
                };

                $sentry->raven->add_context(
                    $sentry->raven->request_context($controller->url_for->to_abs, %$request_context)
                );

                return $request_context;
            }

            return {};
        },

        tags_context => sub {
            my ($sentry, $controller) = @_;

            $sentry->raven->merge_tags(
                account => $controller->current_user->account_id,
            );
        },

        ignore => sub {
            my ($sentry, $exception) = @_;

            return 1 if ($expection->message =~ /Do not log this error/);
        },

        on_error {
            my ($sentry, $method) = (shift, shift);

            die "failed to submit event to sentry service:\n" . dump($sentry->raven->_construct_message_event($message, @_));
        }
    };

=head1 DESCRIPTION

Mojolicious::Plugin::GetSentry is a plugin for the Mojolicious web framework which allow you use Sentry L<https://getsentry.com>.
See also L<Sentry::Raven|https://metacpan.org/pod/Sentry::Raven>

=head1 ATTRIBUTES

L<Mojolicious::Plugin::GetSentry> implements the following attributes.

=head2 sentry_dsn

    Sentry DSN url

=head2 timeout

    Timeout specified in seconds

=head2 log_levels

    Which log levels needs to be sent to Sentry
    e.g.: ['error', 'fatal']

=head2 processors

    A list of processors to filter down Sentry event
    See also L<Sentry::Raven->processors|https://metacpan.org/pod/Sentry::Raven#$raven-%3Eadd_processors(-%5B-Sentry::Raven::Processor::RemoveStackVariables,-...-%5D-)>

=head2 raven

    Sentry::Raven instance

    See also L<Sentry::Raven|https://metacpan.org/pod/Sentry::Raven>

=head1 METHODS

L<Mojolicious::Plugin::GetSentry> inherits all methods from L<Mojolicious::Plugin> and implements the
following new ones.

=head1 SOURCE REPOSITORY

L<https://github.com/crlcu/Mojolicious-Plugin-GetSentry>

=head1 AUTHOR

Adrian Crisan, E<lt>adrian.crisan88@gmail.comE<gt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mojolicious-plugin-getsentry at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mojolicious-Plugin-GetSentry>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mojolicious::Plugin::GetSentry


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mojolicious-Plugin-GetSentry>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mojolicious-Plugin-GetSentry>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mojolicious-Plugin-GetSentry>

=item * Search CPAN

L<http://search.cpan.org/dist/Mojolicious-Plugin-GetSentry/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2018 Adrian Crisan.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut
