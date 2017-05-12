
package RayApp::Request;
use strict;

sub new {
	my ($class, $r) = @_;
	if (defined $r) {
		require RayApp::Request::APR;
		return new RayApp::Request::APR($r);
	} else {
		require RayApp::Request::CGI;
		return new RayApp::Request::CGI;
	}
}

# Parameters for url:
#	base
#	absolute, relative, full
#		path_info
#		query
use URI ();
sub parse_full_uri {
	my ($self, $uri, %opts) = @_;
	for (keys %opts) {
		if (/^-(.+)$/) {
			$opts{$1} = delete $opts{$_};
		}
	}
	# print STDERR "Parsing [$uri]\n";
	my $u = new URI($uri);
	my $base = $u->scheme . '://' . $u->host;
	my $port = $u->_port;
	if (defined $port) {
		$base .= ":$port";
	}
	if ($opts{base}) {
		return $base;
	}
	my $out;
	if ($opts{full}) {
		$out = $u->as_string;
	} elsif ($opts{relative}) {
		$out = $u->rel($u->as_string);
	} else {
		$out = $u->as_string;
		if (substr($out, 0, length($base)) eq $base) {
			$out = substr($out, length($base));
		}
	}
	# print STDERR "parse_full_uri [$uri] -> [$out]\n";
	return $out;
}

1;

__END__

=head1 NAME

RayApp::Request - common object for both mod_perl and CGI requests

=head1 SYNOPSIS

	my $q = new RayApp::Request($r);
	print $q->param('name');

=head1 DESCRIPTION

The B<RayApp> module can operate both as a mod_perl handler and as
a CGI application. You can switch from one mode to another by simply
changing the Apache configuration, without any change in your .pl or
.mpl code. In fact, you can have both mod_perl and CGI handling
specified for the same directory -- the first is nice for production
speed, the second makes sure that all your module changes are reloaded
properly for each request, should you be doing some development
changes.

The B<RayApp::Request> module provides unified interface to B<CGI>.pm
and B<Apache2::Request> objects. The following method are available:

=over 4

=item new

The constructor. If you pass in an argument, it is considered to be
a B<Apache2::RequestRec> object, and the APR routines will be used.
Otherwith B<CGI>.pm is used.

=item param

A method for fetching or setting the value of parameters. For GET,
it always deals with the values from the query string, for POST it
handles only the values from the body of the HTTP request.

If run without any argument, it returns the list of parameters.

If run with one argument, it returns one (in scalar context) or all
values for the given parameter name.

If run with multiple parameters, the second to the last are set as the
new value of the parameter, whose name is the first argument.

=item delete

Deletes the value (or values) from the parameter whose name is the
first argument.

=item user, remote_user

Returns the login used for the HTTP Basic authentication, if it is an
authenticated request.

=item request_method

Returns the request method.

=item referer

The URL of the referer, provided the client sends the appropriate HTTP
header.

=item url

Returns the self url of the request. Can take arguments

=over 4

=item base

Only the base is returned.

=item absolute, relative, full

Absolute, relative and full URL of the request (the default is
relative).

=item path_info

The path info will be appended.

=item query

The query string will be returned.

=back

=item remote_addr

The IP address of the remote host (the client).

=item remote_host

The name of the remote host, provided the httpd server is set to do
the DNS lookups.

=item body

The raw body of the request. Usefull for fetching XML documents or
other inputs that are not CGI parameter values.

=item upload

Returns one or multiple B<RayApp::Request::Upload> objects that
provide access to uploaded files. The object has the following
methods: filename, size, content_type, and content.

=item cookie

Returns on or multiple values of a HTTP cookie, submitted by the
client.

=back

=head1 SEE ALSO

RayApp(3)

=head1 AUTHOR

Copyright (c) Jan Pazdziora 2001--2006

=head1 VERSION

This documentation is believed to describe accurately B<RayApp>
version 2.004.

