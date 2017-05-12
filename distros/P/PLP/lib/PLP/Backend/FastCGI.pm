package PLP::Backend::FastCGI;

use strict;
use warnings;

use PLP::Backend::CGI ();
use FCGI;
use base 'PLP::Backend::CGI';

our $VERSION = '1.01';

sub import {
	my $self = shift;
	$PLP::interface = $self;
	my $request = FCGI::Request();
	$SIG{TERM} = sub {
		$request->LastCall();
	};
	$SIG{PIPE} = 'IGNORE';
	while ($request->Accept() >= 0) {
		$PLP::use_cache = !defined $ENV{PLP_CACHE} || $ENV{PLP_CACHE}; # before it's clean()ed
		delete $ENV{PATH_TRANSLATED};
		$self->everything();
	}
}

1;

=head1 NAME

PLP::Backend::FastCGI - FastCGI interface for PLP

=head1 SYNOPSIS

=head2 Lighttpd

Add this to your configuration file (usually F</etc/lighttpd/lighttpd.conf>):

    server.modules += ("mod_fastcgi")
    fastcgi.server += (".plp" => ((
        "bin-path" => "/usr/bin/perl -MPLP::Backend::FastCGI",
        "socket"   => "/tmp/fcgi-plp.socket",
    )))
    server.indexfiles += ("index.plp")
    static-file.exclude-extensions += (".plp")

=head2 Apache

You'll need a dispatch script (F<plp.fcgi> is included with PLP).
Example F</foo/bar/plp.fcgi>:

    #!/usr/bin/perl
    use PLP::Backend::FastCGI;

Then enable either I<mod_fcgid> (recommended) or I<mod_fastcgi>, and
setup F<httpd.conf> (in new installs just create F</etc/apache/conf.d/plp>) with:

    <IfModule mod_fastcgi.c>
        AddHandler fastcgi-script plp
        FastCgiWrapper /foo/bar/plp.fcgi
    </IfModule>

    <IfModule mod_fcgid.c>
        AddHandler fcgid-script plp
        FCGIWrapper /foo/bar/plp.fcgi .plp
    </IfModule>

=head1 DESCRIPTION

This is usually the preferred backend, providing persistent processes
for speeds comparable to L<mod_perl|PLP::Backend::Apache> and
reliability closer to L<CGI|PLP::Backend::CGI>.

Servers often feature auto-adjusting number of daemons, script timeouts,
and occasional restarts.

=head2 Configuration directives

PLP behaviour can be configured by setting environment variables.

=over 16

=item PLP_CACHE

Sets caching off if false (0 or empty), on otherwise (true or undefined).
When caching, PLP saves your script in memory and doesn't re-read
and re-parse it if it hasn't changed. PLP will use more memory,
but will also run 50% faster.

=back

=head1 AUTHOR

Mischa POSLAWSKY <perl@shiar.org>

=head1 SEE ALSO

L<PLP>, L<PLP::Backend::CGI>, L<FCGI>

