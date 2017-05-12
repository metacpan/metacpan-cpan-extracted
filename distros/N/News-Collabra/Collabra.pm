# News::Collabra
# Administrative access to iPlanet Collabra newserver's access controls.
#
# $Id: Collabra.pm,v 0.06 2002/09/19 16:00:48 nate Exp nate $

=head1 NAME

News::Collabra - Access to Collabra administrative functions

=head1 SYNOPSIS

  use News::Collabra;

  # Create an administrator object
  my $admin = new News::Collabra('username', 'password',
  	'myhost.mydomain.com', 'myhost', '1234');

  # Administrate newsgroups
  my $result = $admin->add_newsgroup('junk.test',
  	'Testing newsgroup', 'A newsgroup for testing Collabra.pm');
  my $result = $admin->remove_newsgroup('junk.test');
  my $result = $admin->delete_all_articles('junk.test');
  my $result = $admin->get_ng_acls('junk.test');
  my $result = $admin->add_ng_acl('junk.test', 'nbailey', 'manager');
  my $result = $admin->get_properties('junk.test');
  my $result = $admin->set_properties('junk.test',
  	'Post your tests here!', 'A test group for FL&T');

  # Administrate the server
  my $result = $admin->server_start;
  my $result = $admin->server_status;
  my $result = $admin->server_stop;

=head1 DESCRIPTION

This module provides an incomplete but growing implementation of a
Collabra admin interface.  Collabra administrative functions are based
on HTTP, not NNTP, so most of these functions use LWP::UserAgent,
rather than News::NNTP/News::NNTPClient.

For the uninitiated, Collabra is iPlanet's hacked over version of
inews, with LDAP-based access control.  Unfortunately, this otherwise
fairly good idea is clouded by a crufty JavaScript interface.  This
module is intended to provide direct access to the functions, to save
administrators the pain of the JavaScript interface.

=cut

package News::Collabra;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.06';      # $Date: 2002/09/19 16:00:48 $
our $DEBUG = 1;
 
use LWP::UserAgent;		# for talking to the server
use HTTP::Cookies;		# for a cookie jar
use HTTP::Request::Common;	# for 'POST'
use URI::Escape;		# for encoding
use News::NNTPClient;		# for cancelling articles
use Carp;			# for debug
use Data::Dumper;		# for debug
use URI;			# for query_form in _send_command

=over 4

=item new($username, $password, $host, $alias, $port)

Creates a C<News::Collabra> object given the necessary details.  This
method does not currently test that the username/password combination
is valid, but it may soon.  Watch this space.

=cut

sub new
{
	my ($clazz, $uid, $passwd, $host, $alias, $port, $NNTP_port) = @_;

	# We'll default to localhost and your host name:
	my $self = {
		_uid	=> $uid,
		_passwd	=> $passwd,
		_host	=> $host || 'localhost',
		_alias	=> $alias || `hostname`,
		_port	=> $port || '22000',
		_NNTP_port => $NNTP_port || '21000',
	};

	bless $self, $clazz;
	chomp $self->{_alias}; # I'm sure there is a cute way to obviate this?

	my $ua = new LWP::UserAgent;
	$ua->agent("News::Collabra/$VERSION " . $ua->agent);
        my $cookie_jar = HTTP::Cookies->new();
        $ua->cookie_jar($cookie_jar);
        #$ua->cookie_jar(HTTP::Cookies->new());
	$self->{_ua} = $ua;

	return $self;
}

sub DESTROY
{
}

# This function is for internal use -- it sends the data to the
# Collabra server, and returns what was read back.
sub _send_command($$$) {
	my ($self, $command, $method, $args) = @_;
	print "Running: '$command'\n" if $DEBUG;
	my $m = $method || 'GET';
	my $request = new HTTP::Request($m);
	$request->uri($command);
	my $url = URI->new('http:');
	$url->query_form(%$args);
	$request->content($url->query);
	$request->authorization_basic($self->{_uid},$self->{_passwd});
	$request->content_type('application/x-www-form-urlencoded');
	my $response = $self->{_ua}->simple_request($request);
	if ($response->code == '401') { # Unauthorized
		carp $response->message if $DEBUG;
	}
	return undef if ($response->is_error);
	return $response->content;
}

###########################################################################

=item add_newsgroup($ngname, $prettyname, $description)

Create a new newsgroup on a Collabra news server.

=cut

sub add_newsgroup($$$$) {
	my ($self, $ngname, $prettyname, $description) = @_;

	my ($parent,$group) = ($ngname =~ /^(.*)\.([^.]*)$/);

	# These uri_escapes may break one day (see below)
	my $creator = uri_escape($self->{_uid});
	$group = uri_escape($group);
	$parent = uri_escape($parent);

	# Don't uri_escape, it wants "+"s, not "%20s" for spaces...
	$prettyname =~ s/\s+/\+/g;
	$description =~ s/\s+/\+/g;
	#die "'$parent', '$group', '$prettyname', '$description'\n";

	my $ret = $self->_send_command(
		"http://$self->{_host}:$self->{_port}/news-$self->{_alias}/bin/madd",
		'POST',
		{
			grpcreat => $creator,
			group => $group,
			prefngc => $parent,
			action => 'new',
			grpprname => $prettyname,
			grpdesc => $description,
			grptype => 'discussion',
			localremote => 'remote',
			flag => 'local',
			moderator => '',
			gatewayaddr => '',
			grpalias => '',
		},
	);

	my $success = 0;
	my $error = 'Undefined error (please report this anomaly!)';
	if ($ret =~ m#\("<br><h2>Operation completed</h2>"\)#) {
		$success = 1;
	} elsif ($ret =~ m#\("Incorrect Usage:([^"]+)"\)#) {
		$success = 0;
		$error = $1;
	} elsif ($ret =~ m#401 Unauthorized#) {
		$success = 0;
		$error = 'Proper authorization is required for this area. Either your browser does not perform authorization, or your authorization has failed.';
	}

	# Return the results
	if ($success) {
		carp "Successfully created '$ngname'\n" if $DEBUG;
		return 1;
	}
	carp "Failed to created '$ngname':\n$error\n" if $DEBUG;
	return 0;
}

###########################################################################

=item remove_newsgroup($ngname)

Remove an existing newsgroup on a Collabra news server.

=cut

sub remove_newsgroup($$) {
	my ($self, $ngname) = @_;

	my $ret = $self->_send_command(
		"http://$self->{_host}:$self->{_port}/news-$self->{_alias}/bin/mrem",
		'POST',
		{
			group => $ngname,
			localremote => 'local',
		},
	);

	my $success = 0;
	my $error = 'Undefined error (please report this anomaly!)';
	if ($ret =~ m#\("<b>Discussion group removal complete.</b>"\)#) {
		$success = 1;
	} elsif ($ret =~ m#\("Incorrect Usage:([^"]+)"\)#) {
		$success = 0;
		$error = $1;
	} elsif ($ret =~ m#401 Unauthorized#) {
		$success = 0;
		$error = 'Proper authorization is required for this area. Either your browser does not perform authorization, or your authorization has failed.';
	}

	# Return the results
	if ($success) {
		carp "Successfully remove '$ngname'\n" if $DEBUG;
		return 1;
	}
	carp "Failed to remove '$ngname':\n$error\n" if $DEBUG;
	return 0;
}

###########################################################################

=item delete_all_articles($ngname)

Delete all articles in the specified newsgroup (untested as a yet).

=cut

sub delete_all_articles($$$$$)
{
	my ($self, $ng, $from, $user, $pass) = @_;

	my $nClient;
	eval {
		my $nClient = new News::NNTPClient($self->{_host}, $self->{_NNTP_port});
	};
	return 0 if ($@);

	if (!$nClient) {
		carp "Delete failed: can't connect to $self->{_host}!\n";
		return 0;
	}
	if (!$nClient->authinfo($self->{_uid}, $self->{_passwd})) {
		carp "Delete failed: bad authinfo ($self->{_uid}, $self->{_passwd})!\n";
		return 0;
	}
	$nClient->mode_reader;

	my ($first, $last) = ($nClient->group($ng));
	carp "$ng: ($first, $last)\n" if $DEBUG;

	my %msgIDH = ();

	for (; $first <= $last; $first++) {
		if ($DEBUG) {
			if ($first != $last) {
				carp "$first,";
			} else { carp "$first.\n"; }
		}
		my @article;
		if (@article = $nClient->article($first)) {
			my @IDs = grep(/^Message-ID: /,@article);
			if ($#IDs > 1) {
				carp "Multiple IDs for ", @article;
				return 0;
			}
			$IDs[0] =~ s/Message-ID: //;
			$msgIDH{$IDs[0]}++;
		}
	}

	foreach my $m (keys %msgIDH) {
		carp "Issuing cancel for $m:\n" if $DEBUG;
		my @header = (
			"Newsgroups: $ng",
			"From: $from",
			"User-Agent: News::Collabra/$VERSION",
			'Organization: My organisation',
			'Distribution: myorg-only',
			'Content-Type: text/html',
			"Subject: cancel $m",
			"References: $m",
			"Control: cancel $m"
		);
		carp join("\n", @header), "\n\n" if $DEBUG;
		my @body = (
			'This message was cancelled by '. $self->{_uid} .'.'
		);
		$nClient->post(
			@header,
			"", # neck (blank line between header and body :-)
			@body
		);
	}

	return 1;
}

###########################################################################
# The following three functions are for internal use only.  HTML::Parser
# probably does this better, but it doesn't work on Netscape's broken
# HTML...
#
# parseTag: an internal function to get name/values out of HTML
sub parseTag {
	my $tag = shift;
	# We don't know what order name/value are in:
	my ($name) = $tag =~ m#name\s*=\s*"([^"]*)"#si;
	my ($value) = $tag =~ m#value\s*=\s*"([^"]*)"#si;
	return ($name,$value);
}

# parseSelect: an internal function to get name/values out of HTML
sub parseSelect {
	my $tag = shift;
	# selected may not exist, or may be more than we want
	my ($name,$selected) = $tag =~ m#name\s*=\s*"([^"]*)".*?<\s*option selected\s*>([^<]+)#si;
	return ($name,$selected);
}

# parseRadio: an internal function to get name/values out of HTML
sub parseRadio {
	my $tag = shift;
	# checked may not exist, or may be more than we want
	my ($name,$checked) = $tag =~ m#name\s*=\s*"([^"]*)".*?<\s*option checked\s*>([^<]+)#si;
	return ($name,$checked);
}

###########################################################################

=item get_ng_acls($ngname)

Get the ACLs for the specified newsgroup.

=cut

# This hasn't been tested thoroughly against non-existant ngs, etc.  OTOH,
# non-existant groups seem to return the default ACL set, so... *shrug*
sub get_ng_acls($$) {
	my ($self, $ngname) = @_;
	return undef if !defined $ngname;
	my (%acl,%role);

	my $ret = $self->_send_command(
		"http://$self->{_host}:$self->{_port}/news-$self->{_alias}/bin/maci?nothing=0&group=$ngname",
		'GET');
	
	# Read the results
	my $success = 0;
	my $error = 'Undefined error (please report this anomaly!)';
	my $content = $ret;
	# ACLs set from higher in the hierarchy
	while($content =~ m#(.*)(<input\s+[^>]*"(u|g)list\d+"\s*[^>]*>)(.*)#si) {
		$content = $1.$4;
		my ($key,$value) = parseTag($2);
		my ($name,$count) = $key =~ /(\w+?)(\d+)$/;
		$acl{$count}->{$name} = $value;
	}
	# Editable at this level
	while($content =~ m#(.*)(<input\s+[^>]*"(users|groups|hosts|auth|abs)\d+"\s*[^>]*>)(.*)#si) {
		$content = $1.$4;
		my ($key,$value) = parseTag($2);
		my ($name,$count) = $key =~ /(\w+?)(\d+)$/;
		$acl{$count}->{$name} = $value;
	}
	# Auth settings for editable at this level
	while($content =~ m#(.*)(<select\s+.*?name="role\d+".*?/select>)(.*)#si) {
		$content = $1.$3;
		my ($key,$value) = parseSelect($2);
		my ($name,$count) = $key =~ /(\w+?)(\d+)$/;
		$acl{$count}->{$name} = $value;
	}

	# Return the results
	if (%acl) {
		if ($DEBUG) {
			print "Successfully found " . scalar(keys %acl). " ACLs for '$ngname'\n";
			#print Dumper \%acl if $VERBOSE;
		}
		return \%acl;
	}
	print "Failed find ACLs for '$ngname':\n$error\n" if $DEBUG;
	return 0;
}

###########################################################################

=item add_ng_acl($ngname,$users,$groups,$role)

Add a new ACL to the specified newsgroup.

=cut

my %_acl_defaults = (
	users => 'all',
	groups => '',
	hosts => '*',
	auth => 'default',
	abs => 'on',
	role => 'reader',
);

sub add_ng_acl($$$$$) {
	my ($self,$ngname,$users,$groups,$role) = @_;

	my $existing = $self->get_ng_acls($ngname);
	my $ACL_count = scalar(keys %$existing);
	my %new_acl = (
		move_rule => 'none',
		delete_rule => 'none',
		group => $ngname,
		cACI => $ACL_count,
# These lines seem to be superflous (or worse)
#		add0 => ' New Rule ',
#		role0 => 'manager',
#		hosts0 => '*',
#		users0 => 'collabra',
#		abs0 => 'on',
#		auth0 => 'default',
	);
	foreach my $e (keys %$existing) {
		foreach my $k (keys %_acl_defaults) {
			$new_acl{$k.$e} = $existing->{$e}{$k} || $_acl_defaults{$k};
		}
	}
	$new_acl{"users$ACL_count"} = $users;
	$new_acl{"groups$ACL_count"} = $groups || '';
	$new_acl{"hosts$ACL_count"} = '*';
	$new_acl{"auth$ACL_count"} = 'default';
	$new_acl{"abs$ACL_count"} = 'on';
	$new_acl{"role$ACL_count"} = 'reader'; #$role || 'reader';
	
	my $ret = $self->_send_command(
		"http://$self->{_host}:$self->{_port}/news-$self->{_alias}/bin/maci",
		'POST',
		\%new_acl,
	);
}

###########################################################################

=item get_properties($ngname)

Get the display properties for the specified newsgroup.

=cut

# Doesn't get inherited properties yet.
sub get_properties($$) {
	my ($self, $ngname) = @_;
	my %properties;

	my $ret = $self->_send_command(
		"http://$self->{_host}:$self->{_port}/news-$self->{_alias}/bin/madd?action=edit&group=$ngname",
		'GET',
	);

	# Singular properties
	while($ret =~ m#(.*)(<input\s+[^>]*"(group|grpcreat|group|grpprname|grpdesc|moderator|gatewayaddr|grpalias)"\s*[^>]*>)(.*)#si) {
		$ret = $1.$4;
		my ($key,$value) = parseTag($2);
		$properties{$key} = $value;
	}
	# Multiple properties
	while($ret =~ m#(.*)(<radio\s+.*?name="(localremote|flag|grptype)".*?>)(.*)#si) {
		$ret = $1.$3;
		my ($key,$value) = parseRadio($2);
		$properties{$key} = $value;
	}
   return \%properties;
}

###########################################################################

=item set_properties($ngname,$pretty_name,$description)

Set the display properties for the specified newsgroup.

=cut

sub set_properties($$$$) {
	my ($self, $ngname, $pretty_name, $description) = @_;

	my $ret = $self->_send_command(
		"http://$self->{_host}:$self->{_port}/news-$self->{_alias}/bin/madd",
		'POST',
		{
			group => $ngname,
			localremote => 'local',
			grpcreat => '',
			group => $ngname,
			action => 'edit',
			grpprname => $pretty_name,
			grpdesc => $description,
			grptype => 'discussion',
			flag => 'local',
			moderator => '',
			gatewayaddr => '',
			grpalias => '',
		},
	);
	return undef;
}

=item _is_server_port_listening

A fundamental check for the server, used by server_status -- if we
can't run a command, is the server listening at all?  If this fails,
manual action is required to start the admin server (i.e. the command
line scripts to start the HTTP admin server -- look for a file called
'start-admin' in your server installation directory).

=cut

sub _is_server_port_listening() {
	my $self = shift;

	use IO::Socket;
	if (my $socket = IO::Socket::INET->new(PeerAddr => $self->{_host},
					PeerPort => $self->{_port},
					Proto => "tcp",
					Type => SOCK_STREAM)) {
		shutdown($socket, 2);
		return 1;
	}
	warn "Admin server not running: couldn't connect to $self->{_host}:$self->{_port} : $@\n";
	return 0;
}

###########################################################################

=item server_start

Start the Collabra newsserver instance.  Returns 1 on success, 0 if
the server was already running (no other error states have been
observed).

=cut

sub server_start() {
	my $self = shift;

	my $ret = $self->_send_command("http://$self->{_host}:$self->{_port}/news-$self->{_alias}/bin/start");
	return 0 if !defined $ret || $ret =~ m#'Server already running'#si;
	return 1;
}

###########################################################################

=item server_status

Returns status information about the Collabra newsserver instance (in
HTML -- grep for '<b>not</b>' if you want an off/on indicator).

=cut

sub server_status() {
	my $self = shift;

	my $ret = $self->_send_command("http://$self->{_host}:$self->{_port}/news-$self->{_alias}/bin/pcontrol");
	if (!defined $ret) {
		# Failed -- we should warn in DEBUG mode
		# Is the admin server running?
		if (!$self->_is_server_port_listening()) {
			# Admin server not running -- should warn in DEBUG mode
			return undef;
		}
		return $ret;
	}
	$ret =~ s#.*(<h2>[^<]+</h2>\s*<pre>)#$1#si;
	$ret =~ s#(</pre>).*#$1#si;
	return $ret;
}

###########################################################################

=item server_stop

Start the Collabra newsserver instance.  Returns 1 on success, 0 if
the server was already stopped (no other error states have been
observed).

=cut

sub server_stop($) {
	my $self = shift;

	my $ret = $self->_send_command("http://$self->{_host}:$self->{_port}/news-$self->{_alias}/bin/shutdown");
	return 0 if !defined $ret || $ret =~ m#'Server already down'#si;
	return 1;
}

=back

=head1 BUGS

This module has only been tested on a newsserver with the local (ie.
supplied with Collabra) directory.  Reports on servers with full
directory servers would be appreciated!  Also, the test server only had
one newsserver instance.  Tests with multiple newsservers on the one
admin server or multiple newsservers on different servers would also be
appreciated.

Some return values aren't particularly meaningful at the moment.

=head1 AUTHOR

Nathan Bailey, E<lt>nate@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 1999-2002 Nathan Bailey.  All rights reserved.  This module
is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option) any later
version.

=cut

1;
__END__
