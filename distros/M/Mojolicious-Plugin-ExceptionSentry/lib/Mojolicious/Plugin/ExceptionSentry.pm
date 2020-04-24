package Mojolicious::Plugin::ExceptionSentry;
use Mojo::Base 'Mojolicious::Plugin';
use Sentry::Raven;

our $VERSION = 0.02;

has 'sentry_raven';

sub register {
    my ($self, $app, $config) = @_;

    $self->sentry_raven(
        Sentry::Raven->new(%$config)
    ) if $config->{sentry_dsn}; 

    $app->hook(before_render => sub {
        my ($c, $args) = @_;

        # check if variable $raven
        return unless $self->sentry_raven;

        # check if template is exception
        return unless defined $args->{template} 
                           && $args->{template} eq 'exception';

        $self->_exception($c, $args);    
    });
}

sub _exception {
    my ($self, $c, $args) = @_;

    my ($file_name) = $c->stash('exception') =~ /at\s+(.*)\s+line/;

    $self->sentry_raven->capture_message(
        $c->stash('exception'),
        Sentry::Raven->request_context(
            $c->req->url->to_string,
            method       => $c->req->method,
            data         => $c->req->body_params->to_string,
            query_string => $c->req->query_params->to_string,
            headers      => { 
                map { $_ => $c->req->headers->header($_) } @{$c->req->headers->names} 
            }
        ),
        Sentry::Raven->stacktrace_context(
            [
                {
                    filename     => $file_name,
                    function     => $c->stash('action'),
                    lineno       => int($c->stash('exception')->line->[0]),
                    context_line => $c->stash('exception')->line->[1],
                    pre_context  => [
                        map { $_->[1] } @{$c->stash('exception')->lines_before}
                    ],
                    post_context => [
                        map { $_->[1] } @{$c->stash('exception')->lines_after}
                    ]
                }
            ]
        )
    );
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::ExceptionSentry - Sentry Plugin for Mojolicious

=head1 SYNOPSIS

    # Mojolicious::Lite
    plugin 'ExceptionSentry' => {
        sentry_dsn => 'https://<publickey>:<secretkey>@sentry.io/<projectid>'
    };
    
    # Mojolicious
    $self->plugin('ExceptionSentry' => {
        sentry_dsn => 'https://<publickey>:<secretkey>@sentry.io/<projectid>'                          
    });     
    
=head1 DESCRIPTION

L<Mojolicious::Plugin::ExceptionSentry> is a plugin for L<Mojolicious>, 
This module auto-send all exceptions from L<Mojolicious> for Sentry.

=head1 OPTIONS

L<Mojolicious::Plugin::ExceptionSentry> supports the following options.

=head2 sentry_dsn 

    plugin 'ExceptionSentry' => {
        sentry_dsn => 'DSN'
    };
    
The DSN for your sentry service. Get this from the client configuration page for your project.

=head2 timeout  

    plugin 'ExceptionSentry' => {
        sentry_dsn => 'DSN',
        timeout    => 5
    };

Do not wait longer than this number of seconds when attempting to send an event.

=head1 SEE ALSO

L<Sentry::Raven>, L<Mojolicious>, L<https://mojolicious.org>.

=head1 AUTHOR
  
Lucas Tiago de Moraes C<lucastiagodemoraes@gmail.com>
  
=head1 COPYRIGHT AND LICENSE
  
This software is copyright (c) 2020 by Lucas Tiago de Moraes.
  
This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
  
=cut
