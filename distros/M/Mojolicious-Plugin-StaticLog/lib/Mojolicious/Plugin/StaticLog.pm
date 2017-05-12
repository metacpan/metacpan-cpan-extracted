package Mojolicious::Plugin::StaticLog;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.03';

sub register {
    my ($self, $app, $conf) = @_;
    my $level = $conf->{level} || 'debug';
    die "$level: unsupported log-level"
        unless $level =~ /^(debug|info|warn|error|fatal)$/;
    $app->hook(
        after_static => sub {
            my $c        = shift;
            my $log      = $c->app->log;
            return unless $log->is_level($level);
            my $path = $c->req->url->path;
            my $size = sprintf '%6s', $c->res->content->body_size;
            my $code = $c->res->code;
            $log->$level("Static $code $size $path");
        });
    return;
}

1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::StaticLog - Show Static response details in the log

=head1 SYNOPSIS

    # Mojolicious
    $app->plugin('StaticLog');
    # or
    $app->plugin( StaticLog => {level=>'info'} );

    # Mojolicious::Lite
    plugin 'StaticLog';

    # now, in a log file near you..  The lines marked "Static" are new. e.g..
    [Thu Feb 18 13:56:09 2016] [debug] GET "/dyngrp/11/pvscat"
    [Thu Feb 18 13:56:09 2016] [debug] Routing to controller "Stuff::Controller::Oauth2" and action "ok"
    [Thu Feb 18 13:56:09 2016] [debug] Routing to controller "Stuff::Controller::Pvscat" and action "page"
    [Thu Feb 18 13:56:09 2016] [debug] Rendering cached template "pvscat/page.html.ep"
    [Thu Feb 18 13:56:09 2016] [debug] Rendering cached template "layouts/default.html.ep"
    [Thu Feb 18 13:56:09 2016] [debug] 200 OK (0.011028s, 90.678/s)
    [Thu Feb 18 13:56:09 2016] [debug] Static 304      0 /css/stuff.css
    [Thu Feb 18 13:56:09 2016] [debug] Static 200  19157 /js/stuff.js
    [Thu Feb 18 13:56:09 2016] [debug] Static 304      0 /js/dyngrps.js
    [Thu Feb 18 13:56:09 2016] [debug] Static 304      0 /img/searching.gif
    [Thu Feb 18 13:56:09 2016] [debug] Static 304      0 /img/octalfutures.png
    [Thu Feb 18 13:56:09 2016] [debug] GET "/dyngrp/11/pvscat.json"

=head1 DESCRIPTION

L<Mojolicious::Plugin::StaticLog> is a L<Mojolicious> plugin which will log the http code, file name and size when rendering static files.

By default logs in debug level only.  Will respond to dynamically changed log levels and will honour "MOJO_LOG_LEVEL" if present.

=head1 REASON

L<Mojolicious> includes a static file server L<Mojolicious::Static> which does some very clever things, silently.  With this Plugin you can trace which static files your app is serving and you will also easily identify when the browser is getting a fresh version of your static resource e.g. C<Static 200 19157 /js/stuff.js> and when it's getting a zero-content "Not Modified" response e.g. C<Static 304 0 /img/searching.gif>.

=head1 METHODS

L<Mojolicious::Plugin::StaticLog> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register($app)

or

  $plugin->register($app, {level => $level}) # where $level =~ /debug|info|warn|error|fatal/

Adds an appropriate after_static hook for logging static file responses.

=head1 REPOSITORY

Open-Sourced at Github: L<https://github.com/frank-carnovale/Mojolicious-Plugin-StaticLog>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016, Frank Carnovale <frankc@cpan.org>

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Mojo::Log>, L<Mojolicious::Static>, L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=cut
