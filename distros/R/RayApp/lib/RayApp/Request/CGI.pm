
package RayApp::Request::CGI;
use strict;
use CGI ();
use IO::ScalarArray ();

use base 'RayApp::Request';

my $singleton;

sub new {
	my $class = shift;
	return $singleton if defined $singleton;
	
	my @stdin = <>;
	tie *STDIN, 'IO::ScalarArray', \@stdin;
	my $q = new CGI;
	untie *STDIN;
	my $self = {
		q => $q,
		stdin => \@stdin,
	};
	if (defined $q
		and defined $q->param('POSTDATA')
		and $q->param('POSTDATA') eq join '', @stdin) {

		$q->delete('POSTDATA');
	}
	return $singleton = bless $self, $class;
}
sub user {
	return shift->remote_user;
}
sub remote_user {
	return shift->{'q'}->remote_user;
}
sub param {
	my $self = shift;
	my $name = shift;
	if (not defined $name) {
		return $self->{'q'}->param;
	}
	if (@_) {
		if (not defined $_[0]) {
			$self->{'q'}->delete($name);
			return;
		} elsif (ref $_[0] and ref $_[0] eq 'ARRAY') {
			$self->{'q'}->param($name, @{ $_[0] });
			return @{ $_[0] };
		} else {
			$self->{'q'}->param($name, @_);
			return @_;
		}
	}
	return $self->{'q'}->param($name);
}
sub delete {
	shift->{'q'}->delete(shift);
}
sub request_method {
	shift->{'q'}->request_method;
}
sub referer {
	shift->{'q'}->referer;
}
sub url {
	my $q = shift;
	my $uri = $ENV{'HTTP_X_RAYAPP_FRONTEND_URI'};
	if (not defined $uri) {
		$uri = $q->{'q'}->url('-full' => 1, -query => 0);
	}
	my %opts = @_;
	my $out = $q->parse_full_uri($uri, %opts);
	if ($opts{'query'} or $opts{'-query'}) {
		if (defined $ENV{'QUERY_STRING'}) {
			if ($ENV{'QUERY_STRING'} ne '') {
				$out .= "?$ENV{'QUERY_STRING'}";
			}
		} elsif (defined $ENV{'REDIRECT_QUERY_STRING'}) {
			if ($ENV{'REDIRECT_QUERY_STRING'} ne '') {
				$out .= "?$ENV{'REDIRECT_QUERY_STRING'}";
			}
		}
	}
	return $out;
}
sub url_orig {
	my $q = shift;
	my %opts = @_;
	for (keys %opts) {
		if (not /^-/) {
			$opts{'-' . $_} = delete $opts{$_};
		}
	}
	$q->{'q'}->url(%opts);
}
sub remote_host {
	$ENV{'REMOTE_HOST'};
}
sub remote_addr {
	$ENV{'REMOTE_ADDR'};
}
sub body {
	my $self = shift;
	if (defined $self->{stdin}
		and @{ $self->{stdin} }) {
		return join '', @{ $self->{stdin} };
	}
	return;
}

sub upload {
	my $self = shift;
	my $q = $self->{'q'};

	my @params = @_;
	if (not @params) {
		@params = grep { grep { ref $_ } $q->param($_) } $q->param;
	}
	require RayApp::Request::Upload;

	my @out;
	for my $param (@params) {
		if (defined $self->{uploads}{$param}) {
			push @out, @{ $self->{uploads}{$param} };
			next;
		}
		for my $fh ($q->upload($param)) {
			my $filename = $q->param($param);
			local $SIG{__WARN__} = sub {};
			my $info = $q->uploadInfo($param);
			my $content = join '', <$fh>;
			close $fh;
			my $u = new RayApp::Request::Upload(
				filename => $filename,
				# filehandle => $_,
				content_type => $info->{'Content-Type'},
				content => $content,
				name => $param,
			);
			push @{ $self->{uploads}{$param} }, $u;
			push @out, $u;
		}
	}
	if (wantarray) {
		@out;
	} else {
		$out[0];
	}
}

sub raw_cookie {
	my $self = shift;
	my $q = $self->{'q'};
	return $q->raw_cookie($_[0]);
}
sub cookie {
	my $self = shift;
	my $q = $self->{'q'};
	return $q->cookie($_[0]);
}

1;

