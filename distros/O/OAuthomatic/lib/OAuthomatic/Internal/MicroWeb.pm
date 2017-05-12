package OAuthomatic::Internal::MicroWeb;
# ABSTRACT: temporary embedded web server used internally - management code


use namespace::sweep;
use Moose;
use MooseX::AttributeShortcuts;
use MooseX::Types::Path::Tiny qw/AbsDir AbsPath/;
use Path::Tiny qw/path/;
use threads;
use Thread::Queue;
use Const::Fast;
use OAuthomatic::Internal::MicroWebSrv;
use OAuthomatic::Error;

const my $THREAD_START_TIMEOUT => 10;
const my $FORM_FILL_WARNING_TIMEOUT => 1 * 60;


has 'config' => (
    is => 'ro', isa => 'OAuthomatic::Config', required => 1,
    handles=>[ 'app_name', 'html_dir', 'debug' ]);


has 'server' => (
    is => 'ro', isa => 'OAuthomatic::Server', required => 1,
    handles => [
        'site_name',
        'site_client_creation_page',
        'site_client_creation_desc',
        'site_client_creation_help',
       ]);


has 'port' => (
    is=>'lazy', isa=>'Int', required=>1, default => sub {
        require Net::EmptyPort;
        return Net::EmptyPort::empty_port();
    });


has 'template_dir' => (
    is=>'lazy', isa=>AbsDir, required=>1, coerce=>1, default=>sub {
        return $_[0]->html_dir->child("templates");
    });


has 'static_dir' => (
    is=>'lazy', isa=>AbsDir, required=>1, coerce=>1, default=>sub {
        return $_[0]->html_dir->child("static");
    });


has 'verbose' => (is=>'ro', isa=>'Bool');


has 'callback_path' => (is=>'ro', isa=>'Str', default=>sub {"/oauth_granted"});


has 'client_key_path' => (is=>'ro', isa=>'Str', default=>sub {"/client_key"});

has 'root_url' => (is=>'lazy', default=>sub{ "http://localhost:". $_[0]->port });
has 'callback_url' => (is=>'lazy', default=>sub{ $_[0]->root_url . $_[0]->callback_path });
has 'client_key_url' => (is=>'lazy', default=>sub{ $_[0]->root_url . $_[0]->client_key_path });

has '_oauth_queue' => (is=>'ro', builder=>sub{Thread::Queue->new()});
has '_client_key_queue' => (is=>'ro', builder=>sub{Thread::Queue->new()});

has 'is_running' => (is => 'rwp', isa => 'Bool');


sub start {
    my $self = shift;

    OAuthomatic::Error::Generic->throw(
        ident => "Server is already running")
        if $self->is_running;

    print "[OAuthomatic] Spawning embedded web server thread\n";

    $self->{thread} = threads->create(
        sub {
            my($app_name,
               $site_name,
               $site_client_creation_page,
               $site_client_creation_desc,
               $site_client_creation_help,
               $static_dir,
               $template_dir,
               $port,
               $callback_path,
               $client_key_path,
               $debug,
               $verbose,
               $oauth_queue,
               $client_key_queue) = @_;

            my $srv = OAuthomatic::Internal::MicroWebSrv->new(
               app_name => $app_name,
               site_name => $site_name,
               site_client_creation_page => $site_client_creation_page,
               site_client_creation_desc => $site_client_creation_desc,
               site_client_creation_help => $site_client_creation_help,
               static_dir => $static_dir,
               template_dir => $template_dir,
               port => $port,
               callback_path => $callback_path,
               client_key_path => $client_key_path,
               debug => $debug,
               verbose => $verbose,
               oauth_queue => $oauth_queue,
               client_key_queue => $client_key_queue,

              );
            $srv->run();
        },
        $self->app_name,
        $self->site_name,
        $self->site_client_creation_page,
        $self->site_client_creation_desc,
        $self->site_client_creation_help,
        $self->static_dir->stringify,
        $self->template_dir->stringify,
        $self->port,
        $self->callback_path || OAuthomatic::Error::Generic->throw(ident => "No callback_path"),
        $self->client_key_path || OAuthomatic::Error::Generic->throw(ident => "No client_key_path"),
        $self->debug,
        $self->verbose,
        $self->_oauth_queue,
        $self->_client_key_queue);

    # Reading start signal
    $self->_oauth_queue->dequeue_timed($THREAD_START_TIMEOUT)
      or OAuthomatic::Error::Generic->throw(
          ident => "Failed to start embedded web",
          extra => "Failed to receive completion info in $THREAD_START_TIMEOUT seconds. Is system heavily overloaded?");

    $self->_set_is_running(1);
    return 1;
}


sub stop {
    my $self = shift;

    print "[OAuthomatic] Shutting down embedded web server\n" if $self->debug;

    $self->{thread}->kill('HUP');
    $self->{thread}->join;

    $self->_set_is_running(0);
    return 1;
}

has '_usage_counter' => (is=>'rw', isa=>'Int', default=>0);


sub start_using {
    my $self = shift;
    $self->start unless $self->is_running;
    $self->_usage_counter($self->_usage_counter + 1);
    return 1;
}


sub finish_using {
    my $self = shift;
    my $counter = $self->_usage_counter - 1;
    $self->_usage_counter($counter);
    if($counter <= 0 && $self->is_running) {
        $self->stop;
    }
    return 1;
}



sub wait_for_oauth_grant {
    my $self = shift;
    my $reply;
    while(1) {
        $reply = $self->_oauth_queue->dequeue_timed($FORM_FILL_WARNING_TIMEOUT);
        last if $reply;
        print "Callback still not received. Please, accept the authorization in the browser (or Ctrl-C me if you changed your mind)\n";
    }

    unless($reply->{verifier}) {

        # FIXME: provide http request

        if($reply->{oauth_problem}) {
            OAuthomatic::Error::Generic->throw(
                ident => "OAuth access rejected",
                extra => "Attempt to get OAuth authorization was rejected. Error code: $reply->{oauth_problem}",
               );
        } else {
            OAuthomatic::Error::Generic->throw(
                ident => "Invalid OAuth callback",
                extra => "Failed to read verifier. Most likely this means some error/omission in OAuthomatic code.\nI am so sorry...\n");
        }
    }

    return unless %$reply;
    return OAuthomatic::Types::Verifier->new($reply);
}


sub wait_for_client_cred {
    my $self = shift;
    my $reply;
    while(1) {
        $reply = $self->_client_key_queue->dequeue_timed($FORM_FILL_WARNING_TIMEOUT);
        last if $reply;
        print "Form  still not filled. Please, fill the form shown (or Ctrl-C me if you changed your mind)\n";
    }
    return unless %$reply;
    return return OAuthomatic::Types::ClientCred->new(
        data => $reply,
        remap => {"client_key" => "key", "client_secret" => "secret"});
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OAuthomatic::Internal::MicroWeb - temporary embedded web server used internally - management code

=head1 VERSION

version 0.0201

=head1 DESCRIPTION

Utility class used internally by OAuthomatic: temporary web server
spawned in separate thread, used to receive final redirect of OAuth
sequence, and to present additional pages to the user.

This module provides methods to manage this server and communicate
with it, L<OAuthomatic::Internal::MicroWebSrv> contains it's actual
implementation.

=head1 PARAMETERS

=head2 port

Port the helper runs at. By default allocated randomly.

=head2 template_dir

Directory containing page templates. By default, use templates
provided with OAuthomatic (according to C<html_dir> param).

=head2 static_dir

Directory containing static files referenced by templates. By default,
use templates provided with OAuthomatic (according to C<html_dir>
param).

=head2 verbose

Enable console logging of web server interactions.

=head2 callback_path

URL path used in OAuth callback (/oauth_granted by default).

=head2 client_key_path

URL path used in user interactions (/client_key by default).

=head1 METHODS

=head2 start

Start embedded web server. To be called (from main thread) before any ineractions begin.

=head2 stop

Stop embedded web server. To be called (from main thread) after OAuth is properly configured.

=head2 start_using

Starts if not yet running. Increases usage counter.

=head2 finish_using

Decreass usage counter. Stops if it tropped to 0.

=head2 wait_for_oauth_grant

Wait until OAuth post-rights-grant callback arrives and return tokens it provided.
Blocks until then. Throws proper error if failed.

To be called from the main thread.

=head2 wait_for_client_cred

Wait until user entered application tokens. Blocks until then.

To be called from the main thread.

=head1 ATTRIBUTES

=head2 config

L<OAuthomatic::Config> object used to bundle various configuration params.

=head2 server

L<OAuthomatic::Server> object used to bundle server-related configuration params.

=head1 AUTHOR

Marcin Kasperski <Marcin.Kasperski@mekk.waw.pl>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Marcin Kasperski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
