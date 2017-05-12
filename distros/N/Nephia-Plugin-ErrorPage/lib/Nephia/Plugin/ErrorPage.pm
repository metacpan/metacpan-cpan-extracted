package Nephia::Plugin::ErrorPage;
use 5.008005;
use strict;
use warnings;
use parent 'Nephia::Plugin';
use Nephia::Response;
use HTTP::Status;

our $VERSION = "0.01";

sub new {
    my ($class, %opts) = @_;
    my $self = $class->SUPER::new(%opts);
    return $self;
}

sub exports { qw/ res_error res_404 / }

sub res_error {
    my ($self, $context) = @_;
    sub {
        my ($code, $message) = @_;
        $message ||= HTTP::Status::status_message($code);
        my $template = $self->app->{config}{ErrorPage}{template};
        my $content  = $template && $self->app->dsl('render') ? 
            $self->app->dsl('render')->($template, {code => $code, message => $message}) : 
            "<h1>$code $message</h1>"
        ;
        my $res = Nephia::Response->new($code, ['Content-Type' => 'text/html; charset=UTF-8'], [$content]);
        $context->set(res => $res);
    };
}

sub res_404 {
    my ($self, $context) = @_;
    sub {
        my $template = $self->app->{config}{ErrorPage}{template};
        my $content  = $template && $self->app->dsl('render') ? 
            $self->app->dsl('render')->($template, {code => 404, message => 'Not Found'}) : 
            '<h1>404 Not Found</h1>'
        ;
        my $res = Nephia::Response->new(404, ['Content-Type' => 'text/html; charset=UTF-8'], [$content]);
        $context->set(res => $res);
    };
}

1;
__END__

=encoding utf-8

=head1 NAME

Nephia::Plugin::ErrorPage - Error Page DSL for Nephia

=head1 SYNOPSIS

    package MyApp;
    use Nephia plugins => [
        'ErrorPage',
        'View::MicroTemplate' => {...},
    ];
    
    app {
        return res_404() unless param('id');
        ...;
    };


=head1 DESCRIPTION

Nephia::Plugin::ErrorPage provides error page response DSLs.

=head1 CONFIGURE

In this plugin, default design for error page is so cheapy.

You can customize it with config.

For example. Look at following.

    use Plack::Builder;
    use MyApp;
    
    my $app = MyApp->run(
        ErrorPage => {
            template => 'error.html',
        },
    );
    
    builder {
        ...
        $app;
    };


=head1 DSL

=head2 res_error($code, $message)

Returns L<Nephia::Response> object that contains specified response-code and response-message.

You may omission response-message.

    app {
        res_error(403);
    };
    # or 
    app {
        res_error(403, 'some error message');
    };

=head2 res_404()

Returns L<Nephia::Response> object that is 404 response.

    app {
        res_404();
    };

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut

