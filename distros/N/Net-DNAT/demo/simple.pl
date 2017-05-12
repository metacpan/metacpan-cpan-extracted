#!/usr/bin/perl -w -T

use strict;
use Net::DNAT;

run Net::DNAT
  port => 80,
  pools => "127.0.0.1:8000",
  user => "nobody",
  group => "nobody",
  ;

=pod

=head1 PORT REDIRECTION

Simple Port Redirecting Configuration

Forwards incoming connections on the privileged
low port 80 to an unprivleged high port 8000.

=head1 SECURITY

This is great for security because

1) The process switches to nobody after binding
to the privileged low port.

2) The entire web server can run and even start
as an unprivileged user on a high port.

=head1 DEVELOPMENT

This is also helpful for development and testing
because you don't have to be root to restart the
web server, yet you still get to use "pretty"
URLs, i.e.:

   http://box/cgi-bin/test.cgi

instead of the uglier:

   http://localhost:8000/cgi-bin/test.cgi

so development appears closer to what production
would look like.

=cut
