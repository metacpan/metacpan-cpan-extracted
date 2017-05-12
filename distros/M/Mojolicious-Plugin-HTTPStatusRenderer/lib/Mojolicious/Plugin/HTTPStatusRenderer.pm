package Mojolicious::Plugin::HTTPStatusRenderer;
use strict;
use warnings;
use utf8;
our $VERSION = '0.01';

use Mojo::Base 'Mojolicious::Plugin';
# taken from https://metacpan.org/source/GAAS/HTTP-Message-6.06/lib/HTTP/Status.pm
my %StatusCode = (
    100 => 'Continue',
    101 => 'Switching Protocols',
    102 => 'Processing',                      # RFC 2518 (WebDAV)
    200 => 'OK',
    201 => 'Created',
    202 => 'Accepted',
    203 => 'Non-Authoritative Information',
    204 => 'No Content',
    205 => 'Reset Content',
    206 => 'Partial Content',
    207 => 'Multi-Status',                    # RFC 2518 (WebDAV)
    208 => 'Already Reported',             # RFC 5842
    300 => 'Multiple Choices',
    301 => 'Moved Permanently',
    302 => 'Found',
    303 => 'See Other',
    304 => 'Not Modified',
    305 => 'Use Proxy',
    307 => 'Temporary Redirect',
    400 => 'Bad Request',
    401 => 'Unauthorized',
    402 => 'Payment Required',
    403 => 'Forbidden',
    404 => 'Not Found',
    405 => 'Method Not Allowed',
    406 => 'Not Acceptable',
    407 => 'Proxy Authentication Required',
    408 => 'Request Timeout',
    409 => 'Conflict',
    410 => 'Gone',
    411 => 'Length Required',
    412 => 'Precondition Failed',
    413 => 'Request Entity Too Large',
    414 => 'Request-URI Too Large',
    415 => 'Unsupported Media Type',
    416 => 'Request Range Not Satisfiable',
    417 => 'Expectation Failed',
    418 => 'I\'m a teapot',            # RFC 2324
    422 => 'Unprocessable Entity',            # RFC 2518 (WebDAV)
    423 => 'Locked',                          # RFC 2518 (WebDAV)
    424 => 'Failed Dependency',               # RFC 2518 (WebDAV)
    425 => 'No code',                         # WebDAV Advanced Collections
    426 => 'Upgrade Required',                # RFC 2817
    428 => 'Precondition Required',
    429 => 'Too Many Requests',
    431 => 'Request Header Fields Too Large',
    449 => 'Retry with',                      # unofficial Microsoft
    500 => 'Internal Server Error',
    501 => 'Not Implemented',
    502 => 'Bad Gateway',
    503 => 'Service Unavailable',
    504 => 'Gateway Timeout',
    505 => 'HTTP Version Not Supported',
    506 => 'Variant Also Negotiates',         # RFC 2295
    507 => 'Insufficient Storage',            # RFC 2518 (WebDAV)
    509 => 'Bandwidth Limit Exceeded',        # unofficial
    510 => 'Not Extended',                    # RFC 2774
    511 => 'Network Authentication Required',
);
my $template = do {local $/; <DATA>};
sub register {
  my ($self, $app, $conf) = @_;

  return $app->routes->any(
    '/httpstatus/*code' => {code => ''} => \&_httpstatus);
}

sub _httpstatus {
  my $self = shift;
  my $code = $self->param('code')||$self->req->param('code');
  if ( defined $code ) {
    $code =~ s/[^a-zA-Z0-9]+//g;
  }

  $self->stash(sc => \%StatusCode);
  $self->stash(pcode => $code // '');

  $self->render(inline => $template, handler => 'ep');
}
1;

=pod

=head1 NAME

Mojolicious::Plugin::HTTPStatusRenderer - HTTP status renderer plugin

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('HTTPStatusRenderer');
  
  #Mojolicious::Lite
  plugin 'HTTPStatusRenderer';
  
  # start daemon, and
  # access http://<host>:<port>/httpstatus/

=head1 DESCRIPTION

L<Mojolicious::Plugin::HTTPStatusRenderer> is a renderer for novice Web Programmer, rawr!

=head1 OPTIONS

L<Mojolicious::Plugin::HTTPStatusRenderer> supports no options

=head1 METHODS


L<Mojolicious::Plugin::HTTPStatusRenderer> inherits all methods from L<Mojolicious::Plugin> and implements the following new ones

=head2 register

  my $route = $plugin->register(Mojolicious->new);

=head1 SEE ALSO

L<Mojoilcious>, L<Mojolicious::Guides>, L<http://mojolicio.us>, L<Mojolicious::Plugin::PODRenderer>, L<App::httpstatus>, L<http://blog.64p.org/entry/2013/02/21/121830>

=head1 AUTHOR

turugina E<lt>turugina@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__DATA__
<!DOCTYPE html>
<html>
<head>
<meta http_equiv='Content-Type' content='text/html; charset=utf8-8' />
<script>
function f(code) {
  if ( typeof(code) === 'string' && /^\d+$/.test(code) ) {
    try { code = parseInt(code); }
    catch (e) { code = null; }
  }
  var r = new RegExp(
    typeof(code) === 'number' && !isNaN(code) ? ('^'+code)
    : typeof(code) === 'string' ? code.replace(/[\-\[\]{}()*+?.,\\\^$|#\s]/g, "\\$&")
    : '.*', 'i')
  , trs = document.getElementsByTagName('tr');
  for (var i=0; i<trs.length; ++i) {
    var tr=trs[i], chld = tr.childNodes
      , t1 = txt(chld[0])
      , t2 = txt(chld[1]);
    tr.style.display = (r.test(t1)||r.test(t2))?'block':'none';
  }
}
function g() { f(ft().value); }
function h() { g(); if (ft().value !== '') {ft().style.display='none';}}
function ft() { return document.getElementById('code'); }
function txt(e) {
  return ('textContent' in e) ? e.textContent
    : ('innerText' in e) ? e.innerText
    : '';
}
</script>
</head>
<body onload='h();'>
<form method='get'>
<input type='text' name='code' id='code' onkeyup='g();' 
value='<%= $pcode %>'
/>
</form>
<table>
<tbody>
% my $sc = stash('sc');
% for my $code ( sort keys %$sc ) {
%    my $text = $sc->{$code};
<tr><td><%= $code %></td><td><%= $text %></td></tr>
%  }
</tbody>
</table>
</body>
</html>
