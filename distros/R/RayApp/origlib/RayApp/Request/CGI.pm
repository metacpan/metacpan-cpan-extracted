
package RayApp::Request::CGI;
use strict;
use CGI ();
use IO::ScalarArray;

sub new {
	my $class = shift;
	
	my @stdin = <>;
	tie *STDIN, "IO::ScalarArray", \@stdin;
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
	return bless $self, $class;
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

1;

