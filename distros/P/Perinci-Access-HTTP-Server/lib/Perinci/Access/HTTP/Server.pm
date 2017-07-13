package Perinci::Access::HTTP::Server;

use 5.010001;
use strict;
use warnings;

our $VERSION = '0.61'; # VERSION

1;
# ABSTRACT: PSGI application to implement Riap::HTTP

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Access::HTTP::Server - PSGI application to implement Riap::HTTP

=head1 VERSION

This document describes version 0.61 of Perinci::Access::HTTP::Server (from Perl distribution Perinci-Access-HTTP-Server), released on 2017-07-10.

=head1 SYNOPSIS

=head1 DESCRIPTION

Perinci::Access::HTTP::I<Server> (PeriAHS for short) is a PSGI I<application> (a
set of I<middlewares> in Plack::Middleware::PeriAHS::*, really) to implement
L<Riap::HTTP> server. You compose the middlewares, configuring each one and
including only the ones you need, in your C<app.psgi>, to create an API service.

A simple command-line utility, L<peri-htserve>, is also available (distributed
separately, see L<App::PerinciUtils>). This utility runs a provided PSGI
application with the L<Gepok> or L<Starman> PSGI I<server> so you can quickly
export some Perl modules/functions as an API service with one line of command.

To get started, currently see the source code of B<peri-htserve> to see the
basic structure of the PSGI application. Also see each middleware's
documentation.

=head1 TIPS AND TRICKS

=head2 Proxying API server

Not only can you serve local modules, you can also serve remote modules
("http://" or "https://" URIs) making your API server a proxy for another.

=head2 Performance tuning

To be written.

=head1 FAQ

=head2 I don't want to have to add metadata to every function!

The point of L<Riap::HTTP> is to expose metadata over HTTP, so it's best that
you write your metadata for every API function you want to expose.

However, there are tools like L<Perinci::Gen::ForModule> (which the
B<peri-htserve> CLI uses) which can generate some (generic) metadata for your
existing modules.

=head2 How can I customize URL?

For example, instead of:

 http://localhost:5000/My/API/Adder/func

you want:

 http://localhost:5000/adder/func

or perhaps (if you only have one module to expose):

 http://localhost:5000/func

You can do this by customizing B<match_uri> when enabling the
PeriAHS::ParseRequest middleware (see B<peri-htserve> source code). You just
need to make sure that you set $env->{"riap.request"}{uri}.

=head2 I want to let user specify output format from URI (e.g. /api/j/... or /api/yaml/...).

Again, this can be achieved by customizing the PeriAHS::ParseRequest middleware.
You can do something like:

 enable "PeriAHS::ParseRequest"
     match_uri => [
         qr!^/api/(?<f>json|yaml|j|y)/
                  (?<uri>[^?/]+(?:/[^?/]+)?)!x,
         sub {
             my ($env, $m) = @_;
             $env->{"riap.request"}{fmt} = $m->{f} =~ /j/ ? 'json' : 'yaml';
         }
     ];

Another example, allowing format by sticking C<.json> or C<.yaml> at the end of
Riap URI:

 enable "PeriAHS::ParseRequest"
     match_uri => qr!^(?<uri>[^?/]+(?:/[^?/]+)?)(?:\.(?<fmt>json|yaml))!x;

=head2 I need even more custom URI syntax.

You can leave C<match_uri> empty and perform your custom URI parsing in another
middleware after PeriAHS::ParseRequest. For example:

 enable "PeriAHS::ParseRequest";

 # do more URI parsing
 enable sub {
     my $app = shift;
     sub {
         my $env     = shift;
         my $rreq    = $env->{"riap.request"};
         # parse more stuff and put it in $rreq
         my $res = $app->($env);
         return $res;
     };
 };

=head2 I want to support HTTPS.

If you use C<peri-htserve>, supply --https_ports, --ssl_key_file and
--ssl_cert_file options.

If you use B<plackup>, use L<Gepok> (-s) as the PSGI server.

If you use PSGI server other than Gepok, you will probably need to run Nginx,
L<Perlbal>, or some other external HTTPS proxy.

=head2 I don't want to run a standalone daemon.

Use other deployment mechanisms for your PSGI application, of which there are
plenty. For example, to deploy as CGI script, see L<Plack::Handler::CGI>. To
deploy as FastCGI script (allowing to run under Nginx, for example), see
L<Plack::Handler::FCGI>.

=head2 I don't want to expose my subroutines and module structure directly!

Well, isn't exposing functions the whole point of API?

If you have modules that you do not want to expose as API, simply disallow it
(e.g. using C<allowed_uris> configuration in PeriAHS::ParseRequest middleware.
Or, create a set of wrapper modules to expose only the functionalities that you
want to expose.

=head2 But I want REST-style!

Take a look at L<Serabi>.

=head2 I want to support another output format (e.g. XML, MessagePack, etc).

See L<Perinci::Result::Format>.

=head2 I want to automatically reload modules that changed on disk.

Use one of the module-reloading module on CPAN, e.g.: L<Module::Reload> or
L<Module::Reload::Conditional>.

=head2 I want to authenticate clients.

Enable L<Plack::Middleware::Auth::Basic> (or other authen middleware you prefer)
before PeriAHS::ParseRequest.

=head2 I want to add access control and/or authorize clients.

Take a look at L<Plack::Middleware::PeriAHS::ACL> (currently unfinished) which
allows access control based on various conditions. Normally this is put after
authentication and before response creation.

=head2 I want to support new actions.

Normally you'll need to extend the appropriate Riap clients (e.g.
L<Perinci::Access::Schemeless> for this. Again, note that you don't have to
resort to subclassing just to accomplish this. You can inject the
action_ACTION() method from somewhere else.

=head2 I want to serve static files.

Use the usual L<Plack::Builder>'s mount() and L<Plack::Middleware::Static> for
this.

 mount my $app = builder {
     mount "/api" => builder {
         enable "PeriAHS::ParseRequest", ...;
         ...
     },
     mount "/static" => builder {
         enable "Static", path=>..., root=>...;
     },
 };

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Access-HTTP-Server>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Access-HTTP-Server>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Access-HTTP-Server>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Perinci::Access>

L<Riap::HTTP>

L<Serabi>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2015, 2014, 2013, 2012, 2011 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
