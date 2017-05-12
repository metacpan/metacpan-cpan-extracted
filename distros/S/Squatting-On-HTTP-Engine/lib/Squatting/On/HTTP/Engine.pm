package Squatting::On::HTTP::Engine;
use strict;
no  strict 'refs';
use warnings;

use HTTP::Engine;

our $VERSION = '0.05';
our %p;

$p{e} = sub {
  my ($req) = @_;
  my %env = (
    QUERY_STRING   => $req->uri->query || '',
    REQUEST_METHOD => $req->method,
    REQUEST_PATH   => $req->path,
    REQUEST_URI    => $req->uri.''
  );
  my $h = $req->headers;
  $h->scan(sub{
    my ($header, $value) = @_;
    my $key = uc $header;
    $key =~ s/-/_/g;
    $key = "HTTP_$key";
    $env{$key} = $value;
  });
  \%env;
};

$p{init_cc} = sub {
  my ($c, $req) = @_;
  my $cc = $c->clone;
  $cc->env     = $p{e}($req);
  $cc->cookies = $req->cookies;
  $cc->input   = $req->parameters;
  $cc->headers = { 'Content-Type' => 'text/html' };
  $cc->v       = {};
  $cc->status  = 200;
  $cc;
};

sub http_engine {
  my ($app, %options) = @_;
  $options{interface}{request_handler} = sub {
    my ($req)   = @_;
    my $path    = $req->uri->path;
    my ($c, $p) = &{ $app . "::D" }($path);
    my $cc      = $p{init_cc}($c, $req);
    my $content = $app->service($cc, @$p);
    HTTP::Engine::Response->new(
      status  => $cc->status,
      headers => $cc->headers,
      cookies => $cc->cookies,
      body    => $content,
    );
  };
  HTTP::Engine->new(%options);
}

1;

__END__

=head1 NAME

Squatting::On::HTTP::Engine - run Squatting apps on top of HTTP::Engine

=head1 SYNOPSIS

Squatting on top of HTTP::Engine::Interface::ServerSimple

  # app_server_simple.pl

  #!/usr/bin/perl
  use strict;
  use warnings;
  use App 'On::HTTP::Engine';
  App->init;
  App->http_engine(
    interface => {
      module => 'ServerSimple',
      args   => {
        host => 'localhost',
        port => 2222,
      },
    },
  )->run;

Squatting on top of HTTP::Engine::Interface::FCGI

  # app_fastcgi.pl

  #!/usr/bin/perl
  use strict;
  use warnings;
  use App 'On::HTTP::Engine';

  App->init;
  App->http_engine(
    interface => {
      module => 'FCGI',
      args   => {
        leave_umask => 0,
        keep_stderr => 1,
        nointr      => 0,
        detach      => 0,
        manager     => 'FCGI::ProcManager',
        nproc       => 4,
        pidfile     => 'app.pid',
        listen      => 'localhost:8000',
      },
  )->run;

Squatting on top of HTTP::Engine::Interface::ModPerl

  # App/ModPerl.pm
  package App::ModPerl;
  use Moose;
  extends 'HTTP::Engine::Interface::ModPerl';
  use App 'On::HTTP::Engine';

  App->init;

  sub create_engine {
    my ($class, $r, $context_key) = @_;
    App->http_engine(interface => { module => 'ModPerl' });
  }

  1;

=head1 DESCRIPTION

This module makes it possible to run Squatting apps on top of L<HTTP::Engine>.

=head1 API

=head2 An HTTP Abstraction Layer for Perl

=head3 App->http_engine(%options)

This method creates an HTTP::Engine object based on the C<%options> that are
given to it.  The C<%options> are passed directly to HTTP::Engine's C<new()>
method and Squatting-based C<request_handler> is provided.  After you get
an HTTP::Engine object back, you can call C<run()> on it to start up an
HTTP server in most cases.  The only time you don't do this is when you're
using the ModPerl interface.  See the L</SYNOPSIS> for some examples.

=head1 SEE ALSO

L<Squatting>, L<HTTP::Engine>, L<Mojo>

=head1 AUTHOR

John BEPPU E<lt>beppu@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2008 John BEPPU E<lt>beppu@cpan.orgE<gt>.

=head2 The "MIT" License

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=cut

# Local Variables: ***
# mode: cperl ***
# indent-tabs-mode: nil ***
# cperl-close-paren-offset: -2 ***
# cperl-continued-statement-offset: 2 ***
# cperl-indent-level: 2 ***
# cperl-indent-parens-as-block: t ***
# cperl-tab-always-indent: nil ***
# End: ***
# vim:tabstop=8 softtabstop=2 shiftwidth=2 shiftround expandtab
