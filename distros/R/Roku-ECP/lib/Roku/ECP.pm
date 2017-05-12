# Roku::ECP
# Package implementing Roku External Control Guide:
# http://sdkdocs.roku.com/display/sdkdoc/External+Control+Guide
package Roku::ECP;
use strict;
use warnings;
use Encode;		# To encode chars as UTF8
use URI;
use URI::Escape;	# To encode chars in URLs
use LWP::UserAgent;

our $VERSION = "1.0.0";
our $USER_AGENT = __PACKAGE__ . "/" . $VERSION;
		# User agent, for HTTP requests.

=head1 NAME

Roku::ECP - External Control Protocol for Roku

=head1 SYNOPSIS

  use Roku::ECP;

  my $r = new Roku::ECP
	hostname => "my-settop-box.dom.ain";

  my @apps = $r->apps();

  # Key and string input functions:
  $r->keydown(Roku::ECP::Home);
  $r->keyup(Roku::ECP::Down);
  $r->keypress(Roku::ECP::Info,
               Roku::ECP::Search,
               Roku::ECP::Select);
  $r->keydown_str("x");
  $r->keyup_str("x");
  $r->keydown_str("Hello world");

  $r->launch($app_id);
  $r->launch($app_id, "12345abcd");
  $r->launch($app_id, "12345abcd", "movie");

  my $icon = $r->geticonbyid("12345");
  my $icon = $r->geticonbyname("My Roku Channel");

  $r->acceleration($x, $y, $z);
  $r->orientation($x, $y, $z);
  $r->rotation($x, $y, $z);
  $r->magnetic($x, $y, $z);

=head1 DESCRIPTION

Roku::ECP implements the Roku External Control Guide, which permits
callers to query and control a Roku over the network.

=head1 KEY NAMES

The C<&key>* functions L<keypress>, L<keyup>, and L<keydown> take
symbolic key names. They are:

=over 4

=item C<KEY_Home>

=item C<KEY_Rev>

=item C<KEY_Fwd>

=item C<KEY_Play>

=item C<KEY_Select>

=item C<KEY_Left>

=item C<KEY_Right>

=item C<KEY_Down>

=item C<KEY_Up>

=item C<KEY_Back>

=item C<KEY_InstantReplay>

=item C<KEY_Info>

=item C<KEY_Backspace>

=item C<KEY_Search>

=item C<KEY_Enter>

=back

=cut

# These get fed to the /keypress (and friends) REST requests.
use constant {
	KEY_Home	=> "home",
	KEY_Rev		=> "rev",
	KEY_Fwd		=> "fwd",
	KEY_Play	=> "play",
	KEY_Select	=> "select",
	KEY_Left	=> "left",
	KEY_Right	=> "right",
	KEY_Down	=> "down",
	KEY_Up		=> "up",
	KEY_Back	=> "back",
	KEY_InstantReplay	=> "instantreplay",
	KEY_Info	=> "info",
	KEY_Backspace	=> "backspace",
	KEY_Search	=> "search",
	KEY_Enter	=> "enter",
};

=head1 METHODS

=cut

# XXX - SSDP to discover devices wolud be nice. But I think that
# requires IO::Socket::Multicast, and also me learning how to use it.
# So for now, just keep your receipts so you know how many Rokus you
# have.

=head2 C<new>

  my $r = new Roku::ECP([I<var> => I<value>, ...])
  my $r = Roku::ECP->new

Create a new object with which to communicate with a Roku. For example:

  my $r = new Roku::ECP hostname => "my-settop-box.dom.ain";
  my $r = new Roku::ECP addr => "192.168.1.10",
	port => 1234;

Possible I<var>s:

=over 4

=item hostname

Name of the Roku.

=item addr

IP(v4) address of the Roku.

=item port

TCP port on which to communicate with the Roku.

=back

Only one of C<hostname> and C<addr> needs to be specified. If both are
given, the address takes precedence.

=cut

sub new
{
	my $class = shift;
	my %args = @_;
	my $retval = {
		port => 8060,
	};

	$retval->{"hostname"} = $args{"hostname"} if defined $args{"hostname"};
	$retval->{"addr"} = $args{"addr"} if defined $args{"addr"};
	if (!defined($args{"hostname"}) &&
	    !defined($args{"addr"}))
	{
		warn __PACKAGE__ . "::new: Must specify at least one of hostname or addr.";
		return undef;
	}

	$retval->{"port"} = $args{"port"} if defined $args{"port"};

	# Construct base URL for subsequent requests.
	$retval->{"url_base"} = "http://" .
		(defined($retval->{'addr'}) ? $retval->{'addr'} : $retval->{'hostname'}) .
		":$retval->{'port'}";

	# Construct a LWP::UserAgent to use for REST calls. Might as
	# well cache it if we're going to be making multiple calls.
	# There might be some benefit in caching the connection as
	# well.
	$retval->{'ua'} = new LWP::UserAgent
		agent => $USER_AGENT;

	bless $retval, $class;
	return $retval;
}

# _rest_request
# Wrapper around REST calls.
# $self->_rest_request(method, path,
#	arg0 => value0,
#	arg1 => value1,
#	...
#	)
# Where:
# "method" is either "GET" or "POST'.
# "path" is a URL path, e.g., "/query/apps" or "/launch". This comes
#	after the base URL, which was defined in the constructor.
# The remaining argument pairs are passed along
sub _rest_request
{
	my $self = shift;
	my $method = shift;	# "GET" or "POST"
	my $path = shift;	# A URL path, like "/query/apps" or "/launch"

	my $result;

	# Construct the URL
	my $url = new URI $self->{'url_base'} . $path;
	$url->query_form(@_);	# Add the remaining arguments as query
				# parameters ("?a=foo&b=bar")

	# Call the right method for the request type.
	if ($method eq "GET")
	{
		$result = $self->{'ua'}->get($url);
	} elsif ($method eq "POST") {
		$result = $self->{'ua'}->post($url);
	} else {
		# XXX - Complain and die
	}
	if ($result->code !~ /^2..$/)
	{
		return {
			status	=> undef,	# Unhappy
			error	=> $result->code(),
			message	=> $result->message(),
		};
	}

	return {
		status		=> 1,		# We're happy
		"Content-Type"	=> $result->header("Content-Type"),
		data		=> $result->decoded_content(),
	};
}

=head2 C<apps>

  my @apps = $r->apps();
	# $apps[0] ==
	# {
	#	id	=> '12345',	# Can include underscores
	#	type	=> 'appl',	# 'appl'|'menu'
	#	name	=> "Channel Name",
	#	version	=> '1.2.3',
	# }

Returns a list of ref-to-hash entries listing the channels installed
on the Roku.

=cut

sub apps
{
	my $self = shift;
	my @retval = ();
	my $result = $self->_rest_request("GET", "/query/apps");
	if (!$result->{'status'})
	{
		warn "Error: query/apps got status $result->{error}: $result->{message}";
		return undef;
	}
	my $text = $result->{'data'};

	# Yeah, ideally it'd be nice to have a full-fledged XML parser
	# but I can't be bothered until it actually becomes a problem.
	# We expect lines of the form
	#	<app id="1234" type="appl" version="1.2.3b">Some Channel</app>
	while ($text =~ m{
		<app \s+
		id=\"(\w+)\" \s+
		type=\"(\w+)\" \s+
		version=\"([^\"]+)\"
		>([^<]*)</app>
		}sgx)
	{
		my $app_id = $1;
		my $app_type = $2;
		my $app_version = $3;
		my $app_name = $4;

		push @retval, {
			id	=> $app_id,
			type	=> $app_type,
			version	=> $app_version,
			name	=> $app_name,
			};
	}

	$self->{'apps'} = [@retval];	# Cache a copy
	return @retval;
}

=head2 C<launch>

    $r->launch($app_id);
    $r->launch($app_id, $contentid);
    $r->launch($app_id, $contentid, $mediatype)

Launch an app on the Roku, optionally giving it an argument saying
what to do.

The app ID can be obtained from C<L<apps>>.

The optional C<$contentid> and C<$mediatype> arguments can be used to
implement deep linking, if the channel supports it. For instance,
C<$contentid> might be the ID number of a movie that the channel will
then automatically start playing. Likewise, C<$mediatype> can be used
to tell the channel what sort of entity C<$contentid> refers to.

=cut

# Deep linking
# Channel Store - ID 11:
#	Opens the channel store to the channel whose ID is given by
#	$contentid. Note that this is an integer, not the alphanumeric
#	string code you find in listings of private channels.
# YouTube - ID 837
#	$contentid is the YouTube identifier of the video to launch,
#	the same identifier you get in
#	https://youtube.com/watch?v=VVVVVVVVVVV
#	URLs.
# Pandora - ID 28
#	$contentid is the ID of a Pandora channel to play. It can take
#	some digging to find these, but they're in Pandora URLs.

sub launch
{
	my $self = shift;
	my $app = shift;
	my $contentid = shift;
	my $mediatype = shift;

	# XXX - Perhaps check whether $app is an ID or a name, and if
	# the latter, try to look it up? How can we identify channel
	# IDs?
	# AFAICT channel IDs are of the form
	#	^\d+(_[\da-f]{4})?$
	# That is, a decimal number, optionally followed by an
	# underscore and a four-hex-digit extension.

	my @query_args = ();
	if (defined($contentid))
	{
		push @query_args, "contentID" => $contentid;
	}
	if (defined($mediatype))
	{
		push @query_args, "mediaType" => $mediatype;
	}

	my $result = $self->_rest_request("POST", "/launch/$app", @query_args);
	if (!$result->{'status'})
	{
		# Something went wrong;
		warn "Error: launch/$app got status $result->{error}: $result->{message}";
		return undef;
	}
	return 1;		# Happy
}

=head2 C<geticonbyid>

  my $icon = $r->geticonbyid("12345_67");
  print ICONFILE $icon->{data} if $icon->{status};

Fetches an app's icon. Most users will want to use C<geticonbyname>
instead.

Takes the ID of an app (usually a number, but sometimes not).
Returns an anonymous hash describing the app's icon:

=over 4

=item status

True if the icon was successfully fetched; false otherwise.

=item error

If C<status> is false, then C<error> gives the HTTP error code (e.g.,
404).

=item message

If C<status> is false, then C<message> gives the HTTP error message
(e.g., "not found").

=item Content-Type

The MIME type of the image. Usually C<image/jpeg> or C<image/png>.

=item data

The binary data of the icon.

=back

=cut

sub geticonbyid
{
	my $self = shift;
	my $app_id = shift;
;
	my $result = $self->_rest_request("GET", "/query/icon/$app_id");
	return $result;
}

=head2 C<geticonbyname>

  my $icon = $r->geticonbyid("My Roku Channel");
  print ICONFILE $icon->{data} if $icon->{status};

Fetches an app's icon.

Takes the name of an app (a string).

Returns an anonymous hash describing the app's icon, in the same
format as C<geticonbyid>.

=cut

sub geticonbyname
{
	my $self = shift;
	my $appname = shift;

	# Call 'apps' if necessary, to get a list of apps installed on
	# the Roku.
	if (!defined($self->{'apps'}))
	{
		# Fetch list of apps, since we don't have it yet
		$self->apps;
	}

	# Look up the app name in the id table
	my $id = undef;
	foreach my $app (@{$self->{'apps'}})
	{
		next unless $app->{'name'} eq $appname;
		$id = $app->{'id'};
		last;
	}
	return undef if !defined($id);	# Name not found

	# Call geticonbyid to do the hard work.
	return $self->geticonbyid($id);
}

=head2 Keypress functions

These functions use predefined key names. See L<KEY NAMES>.

All of these functions take any number of arguments, and send all of
the keys to the Roku in sequence.

These functions all return 1 if successful, or undef otherwise. In
case of error, the return status does not say which parts of the
request were successful; the undef just means that something went
wrong.

=cut

# _key
# This is an internal helper function for the keydown/keyup/keypress
# functions. It takes key names (from the KEY_* constants, above) and
# issues a series of REST requests to send each key in turn to the
# Roku.
#
# Returns 1 on success, or undef on failure. If it fails, the return
# status doesn't say which keys succeeded; it just means that not all
# of them succeeded.
sub _key
{
	my $self = shift;
	my $url = shift;	# The REST URL

	foreach my $key (@_)
	{
		my $result = $self->_rest_request("POST", "$url/$key");

		if (!$result->{'status'})
		{
			warn "Error: $url/$key got status $result->{error}: $result->{message}";
			return undef;
		}
	}
	return 1;			# Happy
}

# _key_str
# This is an internal helper function similar to _key, but for letters
# and such, rather than the buttons on the remote.
#
# It takes each string argument in turn, breaks it up into individual
# characters, and uses _key to send each letter in turn. For instance,
# the string "xyz" gets broken down into three requests: "Lit_x",
# "Lit_y", and "Lit_z".
#
# And yes, you may pronounce it "keister" if you want.
sub _key_str
{
	my $self = shift;
	my $url = shift;	# The REST URL

	my $result;
	foreach my $str (@_)
	{
		# Break this string up into individual characters
		foreach my $c ($str =~ m{.}sg)
		{
			# Send the character as a /key*/Lit_* REST
			# request.
			# Assume that the string is UTF-8, coded, so
			# $c might be several non-ASCII bytes. We use
			# uri_escape_utf8 to escape this properly, so
			# that a Euro symbol gets sent as
			# "Lit_%E2%82%AC"
			$result = $self->_key($url,
					      "Lit_" .
						uri_escape_utf8($c));
			return undef if !$result;
		}
	}
	return 1;
}

=head3 C<keypress>

  my $status = $r->keypress(key, [key,...]);

Sends a keypress event to the Roku. This is equivalent to releasing a key
on the remote, then releasing it.

=cut

sub keypress
{
	my $self = shift;

	return $self->_key("/keypress", @_);
}

=head3 C<keypress_str>

  my $status = $r->keypress_str($string, [$string...]);

Takes a string, breaks it up into individual characters, and sends
each one in turn to the Roku.

=cut

sub keypress_str
{
	my $self = shift;

	return $self->_key_str("/keypress", @_);
}

=head3 C<keydown>

  my $status = $r->keydown(key, [key...]);

Sends a keydown event to the Roku. This is equivalent to pressing a
key on the remote. Most people will want to use C<L<keypress>>
instead.

=cut

sub keydown
{
	my $self = shift;

	return $self->_key("/keydown", @_);
}

=head3 C<keydown_str>

  my $status = $r->keydown_str($string, [$string...]);

Takes a string, breaks it up into individual characters, and sends
each one in turn to the Roku. Most people will want to use
C<L<keypress_str>> instead.

=cut

sub keydown_str
{
	my $self = shift;

print "inside keydown_str(@_)\n";
	return $self->_key_str("/keydown", @_);
}

=head3 C<keyup>

  my $status = $r->keyup(key, [key,...]);

Sends a keyup event to the Roku. This is equivalent to releasing a key
on the remote. Most people will want to use C<L<keypress>> instead.

=cut

sub keyup
{
	my $self = shift;

	return $self->_key("/keyup", @_);
}

=head3 C<keyup_str>

  my $status = $r->keyup_str($string, [$string...]);

Takes a string, breaks it up into individual characters, and sends
each one in turn to the Roku. Most people will want to use
C<L<keypress_str>> instead.

=cut

sub keyup_str
{
	my $self = shift;

	return $self->_key_str("/keyup", @_);
}

=head2 Vector input methods

The following methods send three-dimensional vectors to the
currently-running application. They each take three arguments: C<$x>,
C<$y>, C<$z>.

These functions use one of two coordinate systems: relative to the
remote, or relative to the Earth. See the L<External Control Guide> in
the Roku documentation for details.

These functions all return 1 if successful, or undef if not.

=cut

# _input
# Internal helper function for the user-visible input functions. Those
# are just implemented with _input.
sub _input
{
	my $self = shift;
	my $type = shift;	# Input type
	my $x = shift;
	my $y = shift;
	my $z = shift;

	my $result = $self->_rest_request("POST", "/input",
		"$type.x" => $x,
		"$type.x" => $y,
		"$type.x" => $z);
	if (!$result->{'status'})
	{
		# Something went wrong;
		warn "Error: input/$type got status $result->{error}: $result->{message}";
		return undef;
	}
	return 1;		# Happy
}

=head3 C<acceleration>

  my $status = $r->acceleration($x, $y, $z);

Send an acceleration event to the currently-running application,
indicating motion in space.

=cut

sub acceleration
{
	my $self = shift;
	my $x = shift;
	my $y = shift;
	my $z = shift;

	return $self->_input("acceleration", $x, $y, $z);
}

=head3 C<orientation>

  my $status = $r->orientation($x, $y, $z);

Send an orientation event to the currently-running application,
indicating tilting or displacement from lying flat.

=cut

sub orientation
{
	my $self = shift;
	my $x = shift;
	my $y = shift;
	my $z = shift;

	return $self->_input("orientation", $x,  $y, $z);
}

=head3 C<rotation>

  my $status = $r->rotation($x, $y, $z);

Send a rotation event to the currently-running application, indicating
rotation around an axis.

=cut

sub rotation
{
	my $self = shift;
	my $x = shift;
	my $y = shift;
	my $z = shift;

	return $self->_input("rotation", $x,  $y, $z);
}

=head3 C<magnetic>

  my $status = $r->magnetic($x, $y, $z);

Send a magnetometer event to the currently-running application,
indicating the strength of the local magnetic field.

=cut

sub magnetic
{
	my $self = shift;
	my $x = shift;
	my $y = shift;
	my $z = shift;

	return $self->_input("magnetic", $x,  $y, $z);
}

# XXX - /input allegedly also supports touch and multi-touch, but I
# can't tell from the documentation how to send those.

=head1 SEE ALSO

=over 4

=item External Control Guide

http://sdkdocs.roku.com/display/sdkdoc/External+Control+Guide

=back

=head1 AUTHOR

Andrew Arensburger, E<lt>arensb+pause@ooblick.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Andrew Arensburger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
