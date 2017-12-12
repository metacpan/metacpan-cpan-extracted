use Mojo::Base -strict;
use Test::Mojo;
use Test::More;
use Test::Mock::Guard qw(mock_guard);

#============================================================================
package MyApp;
use Mojo::Base 'Mojolicious';
use Sentry::Raven;

sub startup {
    my $app = shift;
    $app->plugin("ErrorTracking::Sentry",
        sentry_dsn => 'http://<publickey>:<secretkey>@app.getsentry.com/<projectid>',
        on_error => sub {
            my $c = shift;
            my %user_context = Sentry::Raven->user_context(
                id => $c->stash->{user}->{id},
                username => $c->stash->{user}->{name},
                email => $c->stash->{user}->{email},
            );
            return \%user_context;
        },
    );

    $app->routes->get('/ok')->to('controller-dummy#ok');
    $app->routes->get('/error')->to('controller-dummy#error');
}

package MyApp::Controller::Dummy;
use Mojo::Base 'Mojolicious::Controller';

sub ok {
    my $self = shift;
    $self->render(status => 200, text => "hello");
}

sub error {
    my $self = shift;
    $self->stash->{user} = { id => 10, name => "John Doe" };
    die "fatal error";
    $self->render(status => 500, text => "error");
}

#============================================================================
package main;
my $t = Test::Mojo->new('MyApp');

subtest 'App dies, the event will be sent' => sub {
    my $guard = mock_guard('Sentry::Raven', {
        capture_message => sub {
            my ($self, $message, %context) = @_;
            is ref $self, 'Sentry::Raven', "event will be sent";
            like $message, qr/fatal error/;
            is_deeply [ sort keys %context ], [
                'culprit',
                'sentry.interfaces.Exception',
                'sentry.interfaces.Stacktrace',
                'sentry.interfaces.User'
            ], "can use sevral context";
            is_deeply $context{"sentry.interfaces.User"}, {
                ip_address => undef,
                email => undef,
                username => 'John Doe',
                id => '10'
            }, "can use extra user context";
        },
    });

    $t->get_ok('/error')->status_is(500);
    $guard->call_count('Sentry::Raven', 'capture_message'), 1, 'event is sent';
};

subtest 'When there is no error, the event is not sent' => sub {
    my $guard = mock_guard('Sentry::Raven', { capture_message => sub {} });

    $t->get_ok('/ok')->status_is(200);
    $guard->call_count('Sentry::Raven', 'capture_message'), 0, 'event not sent';
};

done_testing;
