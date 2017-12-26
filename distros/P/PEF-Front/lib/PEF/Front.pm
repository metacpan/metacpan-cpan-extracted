package PEF::Front;

our $VERSION = "0.25";

1;

__END__

=encoding utf8
 
=head1 NAME
 
PEF::Front - B<P>erl B<E>ffective Web B<F>ramework
 
=head1 SYNOPSIS
 
  # startup.pl
  use MyApp::AppFrontConfig;
  use PEF::Front::Preload qw(no_db_connect);
  use PEF::Front::Route ('/' => '/appIndex');
  
  PEF::Front::Route->to_app();
 
  # MyApp::AppFrontConfig.pm
  package MyApp::AppFrontConfig;
  sub cfg_no_nls { 1 }
  sub cfg_no_multilang_support { 1 }
  
  1;
  
  # $project_dir/templates/index.html
  some Template-Toolkit style template.

=head1 DESCRIPTION

PEF::Front is a Perl web framework with following features.

=over

=item B<Easy in development>

You just write API of your application and it's automatically exposed as AJAX
or data retrieving methods in your templates. HTML templates can be programmed
separately.

=item B<Fast and versatile template engine>

HTML templates can be programmed by other people who know nothing about Perl.

=item B<Explicit model methods description>

Your API calls are described in YAML files. There're can be set default 
values, complex parameter checks, input parameter filters, output filters
and other things.

HTML/AJAX developer can look into these YAML files to understand backend API.

=item B<Safe>

Thanks very comprehensive parameter checks, passed into handler request is
already checked and filtered, you don't need to make additional validation.

=item B<Flexible rules>

Different output filters can be applied to the same data to get different 
data representation. Input data can be obtained automatically from session,
headers, cookies, form and other sources. Results from handlers can set or 
unset headers or cookies. All this is described in YAML and all these 
rules are compiled into native Perl code.

=item B<Routing>

Request routing is very powerful and effective. Your routing rules are 
compiled into native Perl code.

=item B<Highly configurable>

There're many configurable parameters and functions. They have some sensible
defaults that you have to configure only small part of them. It's very easy
to configure them in your own *::AppFrontConfig module. 

=item B<PSGI>

PSGI is very effective protocol for passing incoming requests into 
application. You can use PEF::Front with any PSGI-server. 
I use L<uwsgi|https://uwsgi-docs.readthedocs.io/en/latest/PSGIquickstart.html>. 
It is also very wise to have some reverse-proxy server in front of 
PSGI-server for static content. I use L<Nginx|https://www.nginx.com/>.

=item B<More productive out of the box>

PEF::Front has many components that a really useful for typical web 
applications:

=over

=item Sessions

Session data can be automatically loaded during request validation.

=item Oauth2

There're components to easily make authorization on your site for B<Facebook>, 
B<GitHub>, B<Google>, B<LinkedIn>, B<MSN>, B<PayPal>, B<Vkontakte> 
and B<Yandex> users.

=item Localization support

There's a message translation support in templates and handlers and 
automatic language detection based on URL, HTTP headers and Geo IP.

=item Captcha

Captcha check during request validation. Simple captcha component. Custom
captcha image generation is possible.

=back

=item B<Websockets and Server Sent Events>

Basically these technologies require some event loop architecture to 
reduce overhead on every connection. But it requires non-trivial callback
code for series of complex queries to DB. 
It is possible to make in quite "usual" code using L<Coro> + L<AnyEvent> 
environment with L<DBIx::Connection::Pool> for pool of asynchronous 
L<DBIx::Connector>s. Thre's even L<DBIx::Struct> ORM that supports 
such a pool of connectors. 

B<Websockets and Server Sent Events> are available as external modules.

=back

=head1 Your Application

=head2 Project structure

Typical directory structure of Your application is alike:

    + $project_dir/
      + $app/
        + $Project/
          - AppFrontConfig.pm
          + InFilter/
          + OutFilter/
          + Local/
      + bin/
        - startup.pl
      + model/
      + templates/
      + var/
        + cache/
        + captcha-db/
        + tt_cache/
        + upload/
      + www-static/
        + captchas/
        + images/
        + jss/
        + styles/

You can redefine almost everything here except B<InFilter>, B<OutFilter> 
and B<Local> directories.

=head3 What is what

=over

=item bin 

Different executables. startup.pl is one of them. Actually this file can have
any name that is known to PSGI-server.

=item $app

Directory of main application code and AppFrontConfig.pm module. Framework 
determines it automatically from path to loaded AppFrontConfig.pm module.

=item $Project

Directory structure of application modules.

=item InFilter

Optional modules for input data validation.

=item OutFilter

Optional modules for transformation of output data.

=item Local

Incoming request handlers. 

=item model

YAML-files with descriptions of model methods. Every file describes one method.

=item templates

Directory of templates. Currently only Template-Toolkit style is supported.

=item var/cache

Session data and cached responses of handlers. 
 
=item var/captcha-db

Database for generated captchas.

=item var/tt_cache

Cache of compiled templates.

=item var/upload

Root directory for uploaded files.

=item www-static

Directory of static content. This is typically served by some fast web-server 
like L<Nginx|https://www.nginx.com/>.

=item www-static/captchas

Directory of generated captcha images. This is typically served by the same 
web-server for static content.

=back

=head2 Minimal application

Minimal application can consist of only two files: B<AppFrontConfig.pm>
and B<setup.pl>. 

It would look like this:

  # MyApp::AppFrontConfig.pm
  package MyApp::AppFrontConfig;
  sub cfg_no_nls { 1 }
  sub cfg_no_multilang_support { 1 }
  
  1;

  # startup.pl
  use MyApp::AppFrontConfig;
  use PEF::Front::Response;
  use PEF::Front::Route;
  
  PEF::Front::Route::add_route(
   get '/' => sub {
      PEF::Front::Response->new(headers => ['Content-Type' => 'text/plain'], body => 'Hello World!');
    }
  );
  
  PEF::Front::Route->to_app();
 
You have to define minimal config and routes. Routes can return HTTP response directly. 

=head1 More information

There're guides and demos. 

=over

=item L<Quick-Start guide|PEF::Front::Guide::QuickStart>

=item L<Configuration parameters|PEF::Front::Config>

=item L<Model methods description|PEF::Front::Model>

=item L<Routing of incoming requests|PEF::Front::Route>

=item L<Template processing|PEF::Front::RenderTT>

=back

=head1 AUTHOR
 
This module was written and is maintained by Anton Petrusevich.

=head1 Copyright and License
 
Copyright (c) 2016 Anton Petrusevich. Some Rights Reserved.
 
This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
