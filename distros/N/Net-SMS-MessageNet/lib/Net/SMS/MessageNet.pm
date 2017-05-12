package Net::SMS::MessageNet;

use LWP();
use HTTP::Cookies();
use URI::Escape();
use warnings;
use strict;
our ($VERSION) = '0.65';
our (@ISA) = qw(Exporter);
our (@EXPORT) = qw(send_sms);

sub new {
	my ($class, $user_name, $password, $params) = @_;
	my ($self) = {};
	my ($timeout) = 60;
	unless ($user_name) {
		die("The user_name must be supplied\n");
	}
	if (ref $user_name) {
		die("The user_name must be a scalar\n");
	}
	$self->{user_name} = $user_name;
	unless ($password) {
		die("The password must be supplied\n");
	}
	if (ref $password) {
		die("The password must be a scalar\n");
	}
	$self->{password} = $password;
	if (exists $params->{timeout}) {
		if (($params->{timeout}) && ($params->{timeout} =~ /^\d+$/)) {
			$timeout = $params->{timeout};
		} else {
			die("The 'timeout' parameter must be a number\n");
		}
	}
	my ($name) = "Net::SMS::MessageNet $VERSION "; # a space causes the default LWP User Agent to be appended.
	if (exists $params->{user_agent}) {
		if (($params->{user_agent}) && ($params->{user_agent} =~ /\S/)) {
			$name = $params->{user_agent};
		}
	}
	my ($ua) = new LWP::UserAgent( timeout => $timeout,
					keep_alive => 1 );
	$ua->agent($name);
	my ($cookieJar) = new HTTP::Cookies( hide_cookie2 => 1 );
	$ua->cookie_jar($cookieJar);
	$ua->requests_redirectable([ 'GET' ]);
	$self->{_ua} = $ua;
	bless $self, $class;
	return ($self);
}

sub send {
	my ($self, $phone_number, $message) = @_;
	if ((length ($message)) > 160) {
		die("Message greater than 160 characters\n");
	}
	unless ($phone_number =~ /^\d+$/) {
		die("Phone number must be all numbers.  The country code should be included\n");
	}
	my ($url);
	eval { require Net::HTTPS; };
	if ($@) {
		if ($^W) {
			warn("Using insecure means to send sms to messagenet.com.au\n");
		}
		$url = 'http://www.messagenet.com.au/dotnet/Lodge.asmx/LodgeSMSMessage';
	} else {
		unless (defined $ENV{HTTPS_VERSION}) {
			$ENV{HTTPS_VERSION} = '3';
		}
		unless (defined $ENV{HTTPS_CA_DIR}) {
			$ENV{HTTPS_CA_DIR} = 'certs';
		}
		$url = 'https://www.messagenet.com.au/dotnet/Lodge.asmx/LodgeSMSMessage';
	}
	my ($request) = new HTTP::Request('POST' => $url);
	$request->content_type('application/x-www-form-urlencoded');
	my ($ua) = $self->{_ua};
	my ($username) = $self->{user_name};
	my ($password) = $self->{password};
	$request->content("Username=" . URI::Escape::uri_escape($username) . '&Pwd=' . URI::Escape::uri_escape($password) . '&PhoneNumber=' . URI::Escape::uri_escape($phone_number) . '&PhoneMessage=' . URI::Escape::uri_escape($message));
	my ($response);
	eval {
		local $SIG{'ALRM'} = sub { die("Timeout\n"); };
		alarm $ua->timeout();
		$response = $ua->request($request);
		alarm 0;
	};
	if ($@) {
		die("Failed to get a response from '$url':$@\n");
	}
	unless ($response->is_success()) {
		die("Failed to get a successful response from sms attempt\n");
	}
	my ($response_as_string) = $response->as_string();
	if ($response_as_string =~ /<string[^>]+>([^<]+)<\/string>/) {
		my ($actual_message) = $1;
		if ($actual_message eq 'Message sent successfully.') {
		} else {
			die("Failed to send sms:$actual_message\n");
		}
	} else {
		die("Unrecognisable response\n");
	}
}

sub send_sms {
	my ($user_name, $password, $phone_number, $message) = @_;
	__PACKAGE__->new($user_name, $password)->send($phone_number, $message);
}
