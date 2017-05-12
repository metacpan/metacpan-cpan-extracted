package Plack::App::GitHub::WebHook;
use strict;
use warnings;
use v5.10;

use parent 'Plack::Component';
use Plack::Util::Accessor qw(hook events secret access safe logger);
use Plack::Request;
use Plack::Middleware::HTTPExceptions;
use Plack::Middleware::Access;
use Carp qw(croak);
use JSON qw(decode_json);
use Scalar::Util qw(blessed);

our $VERSION = '0.9';

our @GITHUB_IPS = (
    allow => "204.232.175.64/27",
    allow => "192.30.252.0/22",
);

sub github_webhook {
    my $hook = shift;
    if ( !ref $hook ) {
        my $class = Plack::Util::load_class($hook, 'GitHub::WebHook');
        $class = $class->new;
        return sub { $class->call(@_) };
    } elsif ( ref $hook eq 'HASH' ) {
        my ($class, $args) = each %$hook;
        $class = Plack::Util::load_class($class, 'GitHub::WebHook');
        $class = $class->new( ref $args eq 'HASH' ? %$args : @$args );
        return sub { $class->call(@_) };
    } elsif ( blessed $hook and $hook->can('call') ) {
        return sub { $hook->call(@_) };
    } elsif ( (ref $hook // '') ne 'CODE') {
        croak "hook must be a CODE or ARRAY of CODEs";
    }
    $hook;
}

sub to_app {
    my $self = shift;

    my $hook = (ref $self->hook // '') eq 'ARRAY' 
             ? $self->hook : [ $self->hook // () ];
    $self->hook([ map { github_webhook($_) } @$hook ]);

    my $app = Plack::Middleware::HTTPExceptions->wrap(
        sub { $self->call_granted($_[0]) }
    );

    if ($self->secret) {
        require Plack::Middleware::HubSignature;
        $app = Plack::Middleware::HubSignature->wrap($app,
            secret => $self->secret
        );
    }

    $self->access('github') unless $self->access;
    $self->access([]) if $self->access eq 'all';
    my @rules = (@GITHUB_IPS, 'deny' => 'all');
    if ( $self->access !~ /^github$/i ) {
        @rules = ();
        foreach (@{$self->access}) {
            if (@rules and $rules[0] eq 'allow' and $_ =~ /^github$/i) {
                push @rules, @GITHUB_IPS[1 .. $#GITHUB_IPS];
            } else {
                push @rules, $_;
            }
        }
    }
    $app = Plack::Middleware::Access->wrap( $app, rules => \@rules );

    $app;
}

sub call_granted {
    my ($self, $env) = @_;

    if ( $env->{REQUEST_METHOD} ne 'POST' ) {
        return [405,['Content-Type'=>'text/plain','Content-Length'=>18],['Method Not Allowed']];
    }

    my $req = Plack::Request->new($env);
    my $event = $env->{'HTTP_X_GITHUB_EVENT'} // '';
    my $delivery = $env->{'HTTP_X_GITHUB_DELIVERY'} // '';
    my $payload;
    my ($status, $message);
    
    if ( !$self->events or grep { $event eq $_ } @{$self->events} ) {
        $payload = $req->param('payload') || $req->content;
        $payload = eval { decode_json $payload };
    }

    if (!$payload) {
        return [400,['Content-Type'=>'text/plain','Content-Length'=>11],['Bad Request']];
    }
    
    my $logger = Plack::App::GitHub::WebHook::Logger->new(
        $self->logger || $env->{'psgix.logger'} || sub { }
    );

    if ( $self->receive( [ $payload, $event, $delivery, $logger ], $env->{'psgi.errors'} ) ) {
        ($status, $message) = (200,"OK");
    } else {
        ($status, $message) = (202,"Accepted");
    }

    $message = ucfirst($event)." $message" if $self->events;

    return [ 
        $status,
        [ 'Content-Type' => 'text/plain', 'Content-Length' => length $message ],
        [ $message ] 
    ];
}

sub receive {
    my ($self, $args, $error) = @_;

    foreach my $hook (@{$self->{hook}}) {
        if ( !eval { $hook->(@$args) } || $@ ) {
            if ( $@ ) {
                if ($self->safe) {
                    $error->print($@);
                } else {
                    die Plack::App::GitHub::WebHook::Exception->new( 500, $@ );
                }
            }
            return;
        }
    } 

    return scalar @{$self->{hook}};
}

{
    package Plack::App::GitHub::WebHook::Logger;
    use Scalar::Util qw(blessed);
    sub new {
        my $self = bless { logger => $_[1] }, $_[0];
        foreach my $level (qw(debug info warn error fatal)) {
            $self->{$level} = sub { $self->log( $level => $_[0] ) }
        }
        $self;
    }
    sub log {
        my ($self, $level, $message) = @_;
        chomp $message;
        if (blessed $self->{logger}) {
            $self->{logger}->log( level => $level, message => $message );
        } else {
            $self->{logger}->({ level => $level, message => $message });
        }
        1;
    }
    sub debug { $_[0]->log(debug => $_[1]) }
    sub info  { $_[0]->log(info  => $_[1]) }
    sub warn  { $_[0]->log(warn  => $_[1]) }
    sub error { $_[0]->log(error => $_[1]) }
    sub fatal { $_[0]->log(fatal => $_[1]) }
}

{
    package Plack::App::GitHub::WebHook::Exception;
    use overload  '""' => sub { $_[0]->{message} };
    sub new { bless { code => $_[1], message => $_[2] }, $_[0]; }
    sub code { $_[0]->{code} }
}

1;
__END__

=head1 NAME

Plack::App::GitHub::WebHook - GitHub WebHook receiver as Plack application

=begin markdown

# STATUS

[![Build Status](https://travis-ci.org/nichtich/Plack-App-GitHub-WebHook.png)](https://travis-ci.org/nichtich/Plack-App-GitHub-WebHook)
[![Coverage Status](https://coveralls.io/repos/nichtich/Plack-App-GitHub-WebHook/badge.png?branch=master)](https://coveralls.io/r/nichtich/Plack-App-GitHub-WebHook?branch=master)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/Plack-App-GitHub-WebHook.png)](http://cpants.cpanauthors.org/dist/Plack-App-GitHub-WebHook)

=end markdown

=head1 SYNOPSIS

    use Plack::App::GitHub::WebHook;

    # Basic Usage
    Plack::App::GitHub::WebHook->new(
        hook => sub {
            my $payload = shift;
            ...
        },
        events => ['pull'],  # optional
        secret => $secret,   # optional
        access => 'github',  # default
    )->to_app;

    # Multiple hooks
    use IPC::Run3;
    Plack::App::GitHub::WebHook->new(
        hook => [
            sub { $_[0]->{repository}{name} eq 'foo' },
            sub {
                my ($payload, $event, $delivery, $logger) = @_;
                run3 \@cmd, undef, $logger->{info}, $logger->{error}; 
            },
            sub { ...  }, # some more action
        ]
    )->to_app;

=head1 DESCRIPTION

This L<PSGI> application receives HTTP POST requests with body parameter
C<payload> set to a JSON object. The default use case is to receive 
L<GitHub WebHooks|http://developer.github.com/webhooks/>, for instance
L<PushEvents|http://developer.github.com/v3/activity/events/types/#pushevent>.

The response of a HTTP request to this application is one of:

=over 4

=item HTTP 403 Forbidden

If access was not granted (for instance because it did not origin from GitHub).

=item HTTP 405 Method Not Allowed

If the request was no HTTP POST.

=item HTTP 400 Bad Request

If the payload was no well-formed JSON or the C<X-GitHub-Event> header did not
match configured events.

=item HTTP 200 OK

Otherwise, if the hook was called and returned a true value.

=item HTTP 202 Accepted

Otherwise, if the hook was called and returned a false value.

=item HTTP 500 Internal Server Error

If a hook died with an exception, the error is returned as content body. Use
configuration parameter C<safe> to disable HTTP 500 errors. 

=back

This module requires at least Perl 5.10.

=head1 CONFIGURATION

=over

=item hook

A hook can be any of a code reference, an object instance with method C<code>,
a class name, or a class name mapped to parameters. You can also pass a list of
hooks as array reference. Class names are prepended by L<GitHub::WebHook>
unless prepended by C<+>.
    
    hook => sub {
        my ($payload, $event, $delivery, $logger) = @_;
        ...
    }

    hook => 'Foo'
    hook => '+GitHub::WebHook::Foo'
    hook => GitHub::WebHook::Foo->new

    hook => { Bar => [ doz => 'baz' ] }
    hook => GitHub::WebHook::Bar->new( doz => 'baz' )
    
Each hook gets passed the encoded payload, the type of webhook
L<event|https://developer.github.com/webhooks/#events>, a unique delivery ID,
and a L<logger object|/LOGGING>.  If the hook returns a true value, the next
the hook is called or HTTP status code 200 is returned.  If a hook returns a
false value (or if no hook was given), HTTP status code 202 is returned
immediately.  Information can be passed from one hook to the next by modifying
the payload. 

=item events

A list of L<event types|http://developer.github.com/v3/activity/events/types/>
expected to be send with the C<X-GitHub-Event> header (e.g. C<['pull']>).

=item logger

Object or function reference to hande L<logging events|/LOGGING>.  An object
must implement method C<log> that is called with named arguments:

    $logger->log( level => $level, message => $message );

For instance L<Log::Dispatch> can be used as logger this way.
A function reference is called with hash reference arguments:

    $logger->({ level => $level, message => $message });

By default L<PSGI::Extensions|psgix.logger> is used as logger (if set).

=item secret

Secret token set at GitHub Webhook setting to validate payload.  See
L<https://developer.github.com/webhooks/securing/> for details. Requires
L<Plack::Middleware::HubSignature>.

=item access

Access restrictions, as passed to L<Plack::Middleware::Access>. A recent list
of official GitHub WebHook IPs is vailable at L<https://api.github.com/meta>.
The default value

    access => 'github'

is a shortcut for these official IP ranges

    access => [
        allow => "204.232.175.64/27",
        allow => "192.30.252.0/22",
        deny  => 'all'
    ]

and

    access => [
        allow => 'github',
        ...
    ]

is a shortcut for

    access => [
        allow => "204.232.175.64/27",
        allow => "192.30.252.0/22",
        ...
    ]

To disable access control via IP ranges use any of

    access => 'all'
    access => []

=item safe

Wrap all hooks in C<< eval { ... } >> blocks to catch exceptions.  Error
messages are send to the PSGI error stream C<psgi.errors>.  A dying hook in
safe mode is equivalent to a hook that returns a false value, so it will result
in a HTTP 202 response.

If you want errors to result in a HTTP 500 response, don't use this option but
wrap the application in an eval block such as this:

    sub {
        eval { $app->(@_) } || do {
            my $msg = $@ || 'Server Error';
            [ 500, [ 'Content-Length' => length $msg ], [ $msg ] ];
        };
    };


=back

=head1 LOGGING

Each hook is passed a logger object to facilitate logging to
L<PSGI::Extensions|psgix.logger>. The logger provides logging methods for each
log level and a general log method:

    sub sample_hook {
        my ($payload, $event, $delivery, $log) = @_;

        $log->debug('message');  $log->{debug}->('message');
        $log->info('message');   $log->{info}->('message');
        $log->warn('message');   $log->{warn}->('message');
        $log->error('message');  $log->{error}->('message');
        $log->fatal('message');  $log->{fatal}->('message');

        $log->log( warn => 'message' );

        run3 \@system_command, undef,
            $log->{info},   # STDOUT to log level info
            $log->{error};  # STDERR to log level error
    }

Trailing newlines on log messages are trimmed.

=head1 EXAMPLES

=head2 Synchronize with a GitHub repository

The following application automatically pulls the master branch of a GitHub
repository into a local working directory.

    use Plack::App::GitHub::WebHook;
    use IPC::Run3;

    my $branch = "master";
    my $work_tree = "/some/path";

    Plack::App::GitHub::WebHook->new(
        events => ['push','ping'],
        hook => [
            sub { 
                my ($payload, $event, $delivery, $log) = @_;
                $log->info("$event $delivery");
                $event eq 'ping' or $payload->{ref} eq "refs/heads/$branch";
            },
            sub {
                my ($payload, $event, $delivery, $log) = @_;
                my $origin = $payload->{repository}->{clone_url} 
                           or die "missing clone_url\n";
                my $cmd;
                if ( -d "$work_tree/.git") {
                    chdir $work_tree;
                    $cmd = ['git','pull',$origin,$branch];
                } else {
                    $cmd = ['git','clone',$origin,'-b',$branch,$work_tree];
                }
                $log->info(join ' ', '$', @$cmd);
                run3 $cmd, undef, $log->{debug}, $log->{warn};
                1;
            },
            # sub { ...optional action after each pull... } 
        ],
    )->to_app;

See L<GitHub::WebHook::Clone> for before copy and pasting this code.

=head1 DEPLOYMENT

Many deployment methods exist. An easy option might be to use Apache webserver
with mod_cgi and L<Plack::Handler::CGI>. First install Apache, Plack and
Plack::App::GitHub::WebHook:

    sudo apt-get install apache2
    sudo apt-get install cpanminus libplack-perl
    sudo cpanm Plack::App::GitHub::WebHook

Then add this section to C</etc/apache2/sites-enabled/default> (or another host
configuration) and restart Apache.

    <Directory /var/www/webhooks>
       Options +ExecCGI -Indexes +SymLinksIfOwnerMatch
       AddHandler cgi-script .cgi
    </Directory>

You can now put webhook applications in directory C</var/www/webhooks> as long
as they are executable, have file extension C<.cgi> and shebang line
C<#!/usr/bin/env plackup>. You might further want to run webhooks scripts as
another user instead of C<www-data> by using Apache module SuExec.

=head1 SEE ALSO

=over

=item

GitHub WebHooks are documented at L<http://developer.github.com/webhooks/>.

=item

See L<GitHub::WebHook> for a collection of handlers for typical tasks.

=item

L<WWW::GitHub::PostReceiveHook> uses L<Web::Simple> to receive GitHub web
hooks. A listener as exemplified by the module can also be created like this:

    use Plack::App::GitHub::WebHook;
    use Plack::Builder;
    build {
        mount '/myProject' => 
            Plack::App::GitHub::WebHook->new(
                hook => sub { my $payload = shift; }
            );
        mount '/myOtherProject' => 
            Plack::App::GitHub::WebHook->new(
                hook => sub { run3 \@cmd ... }
            );
    };

=item

L<Net::GitHub> and L<Pithub> provide access to GitHub APIs.

=item

L<Github::Hooks::Receiver> and L<App::GitHubWebhooks2Ikachan> are alternative
application that receive GitHub WebHooks.

=back

=head1 COPYRIGHT AND LICENSE

Copyright Jakob Voss, 2014-

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
