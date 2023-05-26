package Net::EPP::Simple;
use Carp;
use Config;
use Digest::SHA qw(sha1_hex);
use List::Util qw(any);
use Net::EPP;
use Net::EPP::Frame;
use Net::EPP::ResponseCodes;
use Time::HiRes qw(time);
use base qw(Net::EPP::Client);
use constant {
    EPP_XMLNS	=> 'urn:ietf:params:xml:ns:epp-1.0',
    LOGINSEC_XMLNS => 'urn:ietf:params:xml:ns:epp:loginSec-1.0',
};
use vars qw($Error $Code $Message @Log);
use strict;
use warnings;

our $Error	= '';
our $Code	= OK;
our $Message	= '';
our @Log	= ();

=pod

=head1 Name

Net::EPP::Simple - a simple EPP client interface for the most common jobs.

=head1 Synopsis

	#!/usr/bin/perl
	use Net::EPP::Simple;
	use strict;

	my $epp = Net::EPP::Simple->new(
		host	=> 'epp.nic.tld',
		user	=> 'my-id',
		pass	=> 'my-password',
	);

	my $domain = 'example.tld';

	if ($epp->check_domain($domain) == 1) {
		print "Domain is available\n" ;

	} else {
		my $info = $epp->domain_info($domain);
		printf("Domain was registered on %s by %s\n", $info->{crDate}, $info->{crID});

	}

=head1 Description

This module provides a high level interface to EPP. It hides all the boilerplate
of connecting, logging in, building request frames and parsing response frames behind
a simple, Perlish interface.

It is based on the L<Net::EPP::Client> module and uses L<Net::EPP::Frame>
to build request frames.

=head1 Constructor

The constructor for C<Net::EPP::Simple> has the same general form as the
one for L<Net::EPP::Client>, but with the following exceptions:

=over

=item * Unless otherwise set, C<port> defaults to 700

=item * Unless the C<no_ssl> parameter is set, SSL is always on

=item * You can use the C<user> and C<pass> parameters to supply authentication
information.

=item * You can use the C<newPW> parameter to specify a new password.

=item * The C<login_security> parameter can be used to force the use of the
Login Security Extension (see RFC8807). C<Net::EPP::Simple> will automatically
use this extension if the server supports it, but clients may wish to force
this behaviour to prevent downgrade attacks.

=item * The C<appname> parameter can be used to specify the value of the
C<E<lt>app<gt>> element in the Login Security extension (if used). Unless
specified, the name and current version of C<Net::EPP::Simple> will be used.

=item * The C<timeout> parameter controls how long the client waits for a
response from the server before returning an error.

=item * if C<debug> is set, C<Net::EPP::Simple> will output verbose debugging
information on C<STDERR>, including all frames sent to and received from the
server.

=item * C<reconnect> can be used to disable automatic reconnection (it is
enabled by default). Before sending a frame to the server, C<Net::EPP::Simple>
will send a C<E<lt>helloE<gt>> to check that the connection is up, if not, it
will try to reconnect, aborting after the I<n>th time, where I<n> is the value
of C<reconnect> (the default is 3).

=item * C<login> can be used to disable automatic logins. If you set it
to C<0>, you can manually log in using the C<$epp-E<gt>_login()> method.

=item * C<objects> is a reference to an array of the EPP object schema
URIs that the client requires.

=item * C<stdobj> is a flag saying the client only requires the
standard EPP C<contact-1.0>, C<domain-1.0>, and C<host-1.0> schemas.

=item * If neither C<objects> nor C<stdobj> is specified then the
client will echo the server's object schema list.

=item * C<extensions> is a reference to an array of the EPP extension
schema URIs that the client requires.

=item * C<stdext> is a flag saying the client only requires the
standard EPP C<secDNS-1.1> DNSSEC extension schema.

=item * If neither C<extensions> nor C<stdext> is specified then the
client will echo the server's extension schema list.

=item * The C<lang> parameter can be used to specify the language. The
default is "C<en>".

=back

The constructor will establish a connection to the server and retrieve the
greeting (which is available via C<$epp-E<gt>{greeting}>) and then send a
C<E<lt>loginE<gt>> request.

If the login fails, the constructor will return C<undef> and set
C<$Net::EPP::Simple::Error> and C<$Net::EPP::Simple::Code>.

=head2 Client and Server SSL options

RFC 5730 requires that all EPP instances must be protected using "mutual,
strong client-server authentication". In practice, this means that both
client and server must present an SSL certificate, and that they must
both verify the certificate of their peer.

=head3 Server Certificate Verification

C<Net::EPP::Simple> will verify the certificate presented by a server if
the C<verify>, and either C<ca_file> or C<ca_path> are passed to the
constructor:

	my $epp = Net::EPP::Simple->new(
		host	=> 'epp.nic.tld',
		user	=> 'my-id',
		pass	=> 'my-password',
		verify	=> 1,
		ca_file	=> '/etc/pki/tls/certs/ca-bundle.crt',
		ca_path	=> '/etc/pki/tls/certs',
	);

C<Net::EPP::Simple> will fail to connect to the server if the
certificate is not valid.

You can disable SSL certificate verification by omitting the C<verify>
argument or setting it to C<undef>. This is strongly discouraged,
particularly in production environments.

=head3 SSL Cipher Selection

You can restrict the ciphers that you will use to connect to the server
by passing a C<ciphers> parameter to the constructor. This is a colon-
separated list of cipher names and aliases. See L<http://www.openssl.org/docs/apps/ciphers.html#CIPHER_STRINGS>
for further details. As an example, the following cipher list is
suggested for clients who wish to ensure high-security connections to
servers:

	HIGH:!ADH:!MEDIUM:!LOW:!SSLv2:!EXP

=head3 Client Certificates

If you are connecting to an EPP server which requires a client
certificate, you can configure C<Net::EPP::Simple> to use one as
follows:

    my $epp = Net::EPP::Simple->new(
        host        => 'epp.nic.tld',
        user        => 'my-id',
        pass        => 'my-password',
        key         => '/path/to/my.key',
        cert        => '/path/to/my.crt',
        passphrase  => 'foobar123',
    );

C<key> is the filename of the private key, C<cert> is the filename of
the certificate. If the private key is encrypted, the C<passphrase>
parameter will be used to decrypt it.

=head2 Configuration File

C<Net::EPP::Simple> supports the use of a simple configuration file. To
use this feature, you need to install the L<Config::Simple> module.

When starting up, C<Net::EPP::Simple> will look for
C<$HOME/.net-epp-simple-rc>. This file is an ini-style configuration
file.

=head3 Default Options

You can specify default options for all EPP servers using the C<[default]>
section:

	[default]
	default=epp.nic.tld
	debug=1

=head3 Server Specific Options

You can specify options for for specific EPP servers by giving each EPP server
its own section:

	[epp.nic.tld]
	user=abc123
	pass=foo2bar
	port=777
	ssl=0

This means that when you write a script that uses C<Net::EPP::Simple>, you can
do the following:

	# config file has a default server:
	my $epp = Net::EPP::Simple->new;

	# config file has connection options for this EPP server:
	my $epp = Net::EPP:Simple->new('host' => 'epp.nic.tld');

Any parameters provided to the constructor will override those in the config
file.

=cut

sub new {
	my ($package, %params) = @_;
	$params{dom}		= 1;

	my $load_config = (defined($params{load_config}) ? $params{load_config} : 1);
	$package->_load_config(\%params) if ($load_config);

	$params{port}		= (defined($params{port}) && int($params{port}) > 0 ? $params{port} : 700);
	$params{ssl}		= ($params{no_ssl} ? undef : 1);

	my $self = $package->SUPER::new(%params);

	$self->{user}			= $params{user};
	$self->{pass}			= $params{pass};
	$self->{newPW}			= $params{newPW};
	$self->{debug} 			= (defined($params{debug}) ? int($params{debug}) : undef);
	$self->{timeout}		= (defined($params{timeout}) && int($params{timeout}) > 0 ? $params{timeout} : 5);
	$self->{reconnect}		= (defined($params{reconnect}) ? int($params{reconnect}) : 3);
	$self->{'connected'}		= undef;
	$self->{'authenticated'}	= undef;
	$self->{connect}		= (exists($params{connect}) ? $params{connect} : 1);
	$self->{login}			= (exists($params{login}) ? $params{login} : 1);
	$self->{key}			= $params{key};
	$self->{cert}			= $params{cert};
	$self->{passphrase}		= $params{passphrase};
	$self->{verify}			= $params{verify};
	$self->{ca_file}		= $params{ca_file};
	$self->{ca_path}		= $params{ca_path};
	$self->{ciphers}		= $params{ciphers};
	$self->{objects}		= $params{objects};
	$self->{stdobj}			= $params{stdobj};
	$self->{extensions}		= $params{extensions};
	$self->{stdext}			= $params{stdext};
	$self->{lang}			= $params{lang} || 'en';
	$self->{login_security}	= $params{login_security};
	$self->{appname}	    = $params{appname};

	bless($self, $package);

	if ($self->{connect}) {
		return ($self->_connect($self->{login}) ? $self : undef);

	} else {
		return $self;

	}
}

sub _load_config {
	my ($package, $params_ref) = @_;

	eval 'use Config::Simple';
	if (!$@) {
		# we have Config::Simple, so let's try to parse the RC file:
		my $rcfile = $ENV{'HOME'}.'/.net-epp-simple-rc';
		if (-e $rcfile) {
			my $config = Config::Simple->new($rcfile);

			# if no host was defined in the constructor, use the default (if specified):
			if (!defined($params_ref->{'host'}) && $config->param('default.default')) {
				$params_ref->{'host'} = $config->param('default.default');
			}

			# if no debug level was defined in the constructor, use the default (if specified):
			if (!defined($params_ref->{'debug'}) && $config->param('default.debug')) {
				$params_ref->{'debug'} = $config->param('default.debug');
			}

			# grep through the file's values for settings for the selected host:
			my %vars = $config->vars;
			foreach my $key (grep { /^$params_ref->{'host'}\./ } keys(%vars)) {
				my $value = $vars{$key};
				$key =~ s/^$params_ref->{'host'}\.//;
				$params_ref->{$key} = $value unless (defined($params_ref->{$key}));
			}
		}
	}
}

sub _connect {
	my ($self, $login) = @_;

	my %params;

	$params{SSL_cipher_list} = $self->{ciphers} if (defined($self->{ssl}) && defined($self->{ciphers}));

	if (defined($self->{key}) && defined($self->{cert}) && defined($self->{ssl})) {
		$self->debug('configuring client certificate parameters');
		$params{SSL_key_file}	= $self->{key};
		$params{SSL_cert_file}	= $self->{cert};
		$params{SSL_passwd_cb}	= sub { $self->{passphrase} };
	}

	if (defined($self->{ssl}) && defined($self->{verify})) {
		$self->debug('configuring server verification');
		$params{SSL_verify_mode}	= 1;
		$params{SSL_ca_file}		= $self->{ca_file};
		$params{SSL_ca_path}		= $self->{ca_path};

	} elsif (defined($self->{ssl})) {
		$params{SSL_verify_mode} = 0;

	}

	$self->debug(sprintf('Attempting to connect to %s:%d', $self->{host}, $self->{port}));
	eval {
		$params{no_greeting} = 1;
		$self->connect(%params);
	};
	if ($@ ne '') {
		chomp($@);
		$@ =~ s/ at .+ line .+$//;
		$self->debug($@);
		$Code = COMMAND_FAILED;
		$Error = $Message = "Error connecting: ".$@;
		return undef;

	} else {
		$self->{'connected'} = 1;

		$self->debug('Connected OK, retrieving greeting frame');
		$self->{greeting} = $self->get_frame;
		if (ref($self->{greeting}) ne 'Net::EPP::Frame::Response') {
			$Code = COMMAND_FAILED;
			$Error = $Message = "Error retrieving greeting: ".$@;
			return undef;

		} else {
			$self->debug('greeting frame retrieved OK');

		}
	}

	map { $self->debug('S: '.$_) } split(/\n/, $self->{greeting}->toString(1));

	if ($login) {
		$self->debug('attempting login');
		return $self->_login;

	} else {
		return 1;

	}
}

sub _login {
	my $self = shift;

	$self->debug(sprintf("Attempting to login as client ID '%s'", $self->{user}));
	my $response = $self->request($self->_prepare_login_frame());

	if (!$response) {
		$Error = $Message = "Error getting response to login request: ".$Error;
		return undef;

	} else {
		$Code = $self->_get_response_code($response);
		$Message = $self->_get_message($response);

		$self->debug(sprintf('%04d: %s', $Code, $Message));

		if ($Code > 1999) {
			$Error = "Error logging in (response code $Code, message $Message)";
			return undef;

		} else {
			$self->{'authenticated'} = 1;
			return 1;

		}
	}
}

sub _get_option_uri_list {
	my $self = shift;
	my $tag = shift;
	my $list = [];
	my $elems = $self->{greeting}->getElementsByTagNameNS(EPP_XMLNS, $tag);
	while (my $elem = $elems->shift) {
		push @$list, $elem->firstChild->data;
	}
	return $list;
}

sub _prepare_login_frame {
	my $self = shift;

	$self->debug('preparing login frame');
	my $login = Net::EPP::Frame::Command::Login->new;

    my @extensions;
    if ($self->{'stdext'}) {
        push(@extensions, (Net::EPP::Frame::ObjectSpec->spec('secDNS'))[1]);

    } elsif ($self->{'extensions'}) {
        @extensions = @{$self->{'extensions'}};

    } else {
        @extensions = @{$self->_get_option_uri_list('extURI')};

    }

	$login->clID->appendText($self->{'user'});

    if ($self->{'login_security'} || any { LOGINSEC_XMLNS eq $_ } @extensions) {
        push(@extensions, LOGINSEC_XMLNS) unless (any { LOGINSEC_XMLNS eq $_ } @extensions);

    	$login->pw->appendText('[LOGIN-SECURITY]');

        my $loginSec = $login->createElementNS(LOGINSEC_XMLNS, 'loginSec');

        my $userAgent = $login->createElement('userAgent');
        $loginSec->appendChild($userAgent);

        my $app = $login->createElement('app');
        $app->appendText($self->{'appname'} || sprintf('%s %s', __PACKAGE__, $Net::EPP::VERSION));
        $userAgent->appendChild($app);

        my $tech = $login->createElement('tech');
        $tech->appendText(sprintf('Perl %s', $Config{'version'}));
        $userAgent->appendChild($tech);

        my $os = $login->createElement('os');
        $os->appendText(sprintf('%s %s', ucfirst($Config{'osname'}), $Config{'osvers'}));
        $userAgent->appendChild($os);

        my $pw = $login->createElement('pw');
        $pw->appendText($self->{'pass'});
        $loginSec->appendChild($pw);

    	if ($self->{'newPW'}) {
    		my $newPW = $login->createElement('newPW');
    		$newPW->appendText('[LOGIN-SECURITY]');
    		$login->getNode('login')->insertAfter($newPW, $login->pw);

            $newPW = $login->createElement('newPW');
            $newPW->appendText($self->{'newPW'});
            $loginSec->appendChild($newPW);
        }

        my $extension = $login->createElement('extension');
        $extension->appendChild($loginSec);

        $login->getCommandNode()->parentNode()->insertAfter($extension, $login->getCommandNode());

    } else {
    	$login->pw->appendText($self->{pass});

    	if ($self->{newPW}) {
    		my $newPW = $login->createElement('newPW');
    		$newPW->appendText($self->{newPW});
    		$login->getNode('login')->insertAfter($newPW, $login->pw);
    	}
    }

	$login->version->appendText($self->{greeting}->getElementsByTagNameNS(EPP_XMLNS, 'version')->shift->firstChild->data);
	$login->lang->appendText($self->{lang});

	my $objects = $self->{objects};
	$objects = [map { (Net::EPP::Frame::ObjectSpec->spec($_))[1] }
		    qw(contact domain host)] if $self->{stdobj};
	$objects = _get_option_uri_list($self,'objURI') if not $objects;
	$login->svcs->appendTextChild('objURI', $_) for @$objects;

	if (scalar(@extensions) > 0) {
		my $svcext = $login->createElement('svcExtension');
		$login->svcs->appendChild($svcext);
		$svcext->appendTextChild('extURI', $_) for @extensions;

	}

	return $login;
}

=pod

=head1 Availability Checks

You can do a simple C<E<lt>checkE<gt>> request for an object like so:

	my $result = $epp->check_domain($domain);

	my $result = $epp->check_host($host);

	my $result = $epp->check_contact($contact);

Each of these methods has the same profile. They will return one of the
following:

=over

=item * C<undef> in the case of an error (check C<$Net::EPP::Simple::Error> and C<$Net::EPP::Simple::Code>).

=item * C<0> if the object is already provisioned.

=item * C<1> if the object is available.

=back

=cut

sub check_domain {
	my ($self, $domain) = @_;
	return $self->_check('domain', $domain);
}

sub check_host {
	my ($self, $host) = @_;
	return $self->_check('host', $host);
}

sub check_contact {
	my ($self, $contact) = @_;
	return $self->_check('contact', $contact);
}

sub _check {
	my ($self, $type, $identifier) = @_;
	my $frame;
	if ($type eq 'domain') {
		$frame = Net::EPP::Frame::Command::Check::Domain->new;
		$frame->addDomain($identifier);

	} elsif ($type eq 'contact') {
		$frame = Net::EPP::Frame::Command::Check::Contact->new;
		$frame->addContact($identifier);

	} elsif ($type eq 'host') {
		$frame = Net::EPP::Frame::Command::Check::Host->new;
		$frame->addHost($identifier);

	} else {
		$Error = "Unknown object type '$type'";
		return undef;
	}

	my $response = $self->_request($frame);

	if (!$response) {
		return undef;

	} else {
		$Code = $self->_get_response_code($response);
		$Message = $self->_get_message($response);

		if ($Code > 1999) {
			$Error = $self->_get_error_message($response);
			return undef;

		} else {
			my $xmlns = (Net::EPP::Frame::ObjectSpec->spec($type))[1];
			my $key;
			if ($type eq 'domain' || $type eq 'host') {
				$key = 'name';

			} elsif ($type eq 'contact') {
				$key = 'id';

			}
			return $response->getNode($xmlns, $key)->getAttribute('avail');

		}
	}
}

=pod

=head1 Retrieving Object Information

=head2 Domain Objects

	my $info = $epp->domain_info($domain, $authInfo, $follow);

This method constructs an C<E<lt>infoE<gt>> frame and sends
it to the server, then parses the response into a simple hash ref. If
there is an error, this method will return C<undef>, and you can then
check C<$Net::EPP::Simple::Error> and C<$Net::EPP::Simple::Code>.

If C<$authInfo> is defined, it will be sent to the server as per RFC
5731, Section 3.1.2.

If the C<$follow> parameter is true, then C<Net::EPP::Simple> will also
retrieve the relevant host and contact details for a domain: instead of
returning an object name or ID for the domain's registrant, contact
associations, DNS servers or subordinate hosts, the values will be
replaced with the return value from the appropriate C<host_info()> or
C<contact_info()> command (unless there was an error, in which case the
original object ID will be used instead).

=cut

sub domain_info {
	my ($self, $domain, $authInfo, $follow, $hosts) = @_;
	$hosts = $hosts || 'all';

	my $result = $self->_info('domain', $domain, $authInfo, $hosts);
	return $result if (ref($result) ne 'HASH' || !$follow);

	if (defined($result->{'ns'}) && ref($result->{'ns'}) eq 'ARRAY') {
		for (my $i = 0 ; $i < scalar(@{$result->{'ns'}}) ; $i++) {
			my $info = $self->host_info($result->{'ns'}->[$i]);
			$result->{'ns'}->[$i] = $info if (ref($info) eq 'HASH');
		}
	}

	if (defined($result->{'hosts'}) && ref($result->{'hosts'}) eq 'ARRAY') {
		for (my $i = 0 ; $i < scalar(@{$result->{'hosts'}}) ; $i++) {
			my $info = $self->host_info($result->{'hosts'}->[$i]);
			$result->{'hosts'}->[$i] = $info if (ref($info) eq 'HASH');
		}
	}

	my $info = $self->contact_info($result->{'registrant'});
	$result->{'registrant'} = $info if (ref($info) eq 'HASH');

	foreach my $type (keys(%{$result->{'contacts'}})) {
		my $info = $self->contact_info($result->{'contacts'}->{$type});
		$result->{'contacts'}->{$type} = $info if (ref($info) eq 'HASH');
	}

	return $result;
}

=pod

=head2 Host Objects

	my $info = $epp->host_info($host);

This method constructs an C<E<lt>infoE<gt>> frame and sends
it to the server, then parses the response into a simple hash ref. If
there is an error, this method will return C<undef>, and you can then
check C<$Net::EPP::Simple::Error> and C<$Net::EPP::Simple::Code>.

=cut

sub host_info {
	my ($self, $host) = @_;
	return $self->_info('host', $host);
}

=pod

=head2 Contact Objects

	my $info = $epp->contact_info($contact, $authInfo, $roid);

This method constructs an C<E<lt>infoE<gt>> frame and sends
it to the server, then parses the response into a simple hash ref. If
there is an error, this method will return C<undef>, and you can then
check C<$Net::EPP::Simple::Error> and C<$Net::EPP::Simple::Code>.

If C<$authInfo> is defined, it will be sent to the server as per RFC
RFC 5733, Section 3.1.2.

If the C<$roid> parameter to C<host_info()> is set, then the C<roid>
attribute will be set on the C<E<lt>authInfoE<gt>> element.

=cut

sub contact_info {
	my ($self, $contact, $authInfo, $roid) = @_;
	return $self->_info('contact', $contact, $authInfo, $roid);
}

sub _info {
	# $opt is the "hosts" attribute value for domains or the "roid"
	# attribute for contacts
	my ($self, $type, $identifier, $authInfo, $opt) = @_;
	my $frame;
	if ($type eq 'domain') {
		$frame = Net::EPP::Frame::Command::Info::Domain->new;
		$frame->setDomain($identifier, $opt || 'all');

	} elsif ($type eq 'contact') {
		$frame = Net::EPP::Frame::Command::Info::Contact->new;
		$frame->setContact($identifier);

	} elsif ($type eq 'host') {
		$frame = Net::EPP::Frame::Command::Info::Host->new;
		$frame->setHost($identifier);

	} else {
		$Error = "Unknown object type '$type'";
		return undef;

	}

	if (defined($authInfo) && $authInfo ne '') {
		$self->debug('adding authInfo element to request frame');
		my $el = $frame->createElement((Net::EPP::Frame::ObjectSpec->spec($type))[0].':authInfo');
		my $pw = $frame->createElement((Net::EPP::Frame::ObjectSpec->spec($type))[0].':pw');
		$pw->appendChild($frame->createTextNode($authInfo));
		$pw->setAttribute('roid', $opt) if ($type eq 'contact' && $opt);
		$el->appendChild($pw);
		$frame->getNode((Net::EPP::Frame::ObjectSpec->spec($type))[1], 'info')->appendChild($el);
	}

	my $response = $self->_request($frame);

	if (!$response) {
		return undef;

	} else {
		$Code = $self->_get_response_code($response);
		$Message = $self->_get_message($response);

		if ($Code > 1999) {
			$Error = $self->_get_error_message($response);
			return undef;

		} else {
			return $self->parse_object_info($type, $response);
		}
	}
}

# An easy-to-subclass method for parsing object info
sub parse_object_info {
	my ($self, $type, $response) = @_;

	my $infData = $response->getNode((Net::EPP::Frame::ObjectSpec->spec($type))[1], 'infData');

	if ($type eq 'domain') {
		# secDNS extension only applies to domain objects
		my $secinfo = $response->getNode((Net::EPP::Frame::ObjectSpec->spec('secDNS'))[1], 'infData');
		return $self->_domain_infData_to_hash($infData, $secinfo);

	} elsif ($type eq 'contact') {
		return $self->_contact_infData_to_hash($infData);

	} elsif ($type eq 'host') {
		return $self->_host_infData_to_hash($infData);

	} else {
		$Error = "Unknown object type '$type'";
		return undef;

	}
}

sub _get_common_properties_from_infData {
	my ($self, $infData, @extra) = @_;
	my $hash = {};

	my @default = qw(roid clID crID crDate upID upDate trDate);

	foreach my $name (@default, @extra) {
		my $els = $infData->getElementsByLocalName($name);
		$hash->{$name} = $els->shift->textContent if ($els->size > 0);
	}

	my $codes = $infData->getElementsByLocalName('status');
	while (my $code = $codes->shift) {
		push(@{$hash->{status}}, $code->getAttribute('s'));
	}

	return $hash;
}

=pod

=head2 Domain Information

The hash ref returned by C<domain_info()> will usually look something
like this:

	$info = {
	  'contacts' => {
	    'admin' => 'contact-id'
	    'tech' => 'contact-id'
	    'billing' => 'contact-id'
	  },
	  'registrant' => 'contact-id',
	  'clID' => 'registrar-id',
	  'roid' => 'tld-12345',
	  'status' => [
	    'ok'
	  ],
	  'authInfo' => 'abc-12345',
	  'name' => 'example.tld',
	  'trDate' => '2011-01-18T11:08:03.0Z',
	  'ns' => [
	    'ns0.example.com',
	    'ns1.example.com',
	  ],
	  'crDate' => '2011-02-16T12:06:31.0Z',
	  'exDate' => '2011-02-16T12:06:31.0Z',
	  'crID' => 'registrar-id',
	  'upDate' => '2011-08-29T04:02:12.0Z',
	  hosts => [
	    'ns0.example.tld',
	    'ns1.example.tld',
	  ],
	};

Members of the C<contacts> hash ref may be strings or, if there are
multiple associations of the same type, an anonymous array of strings.
If the server uses the Host Attribute model instead of the Host Object
model, then the C<ns> member will look like this:

	$info->{ns} = [
	  {
	    name => 'ns0.example.com',
	    addrs => [
	      version => 'v4',
	      addr => '10.0.0.1',
	    ],
	  },
	  {
	    name => 'ns1.example.com',
	    addrs => [
	      version => 'v4',
	      addr => '10.0.0.2',
	    ],
	  },
	];

Note that there may be multiple members in the C<addrs> section and that
the C<version> attribute is optional.

=cut

sub _domain_infData_to_hash {
	my ($self, $infData, $secinfo) = @_;

	my $hash = $self->_get_common_properties_from_infData($infData, 'registrant', 'name', 'exDate');

	my $contacts = $infData->getElementsByLocalName('contact');
	while (my $contact = $contacts->shift) {
		my $type	= $contact->getAttribute('type');
		my $id		= $contact->textContent;

		if (ref($hash->{contacts}->{$type}) eq 'STRING') {
			$hash->{contacts}->{$type} = [ $hash->{contacts}->{$type}, $id ];

		} elsif (ref($hash->{contacts}->{$type}) eq 'ARRAY') {
			push(@{$hash->{contacts}->{$type}}, $id);

		} else {
			$hash->{contacts}->{$type} = $id;

		}

	}

	my $ns = $infData->getElementsByLocalName('ns');
	if ($ns->size == 1) {
		my $el = $ns->shift;
		my $hostObjs = $el->getElementsByLocalName('hostObj');
		while (my $hostObj = $hostObjs->shift) {
			push(@{$hash->{ns}}, $hostObj->textContent);
		}

		my $hostAttrs = $el->getElementsByLocalName('hostAttr');
		while (my $hostAttr = $hostAttrs->shift) {
			my $host = {};
			$host->{name} = $hostAttr->getElementsByLocalName('hostName')->shift->textContent;
			my $addrs = $hostAttr->getElementsByLocalName('hostAddr');
			while (my $addr = $addrs->shift) {
				push(@{$host->{addrs}}, { version => $addr->getAttribute('ip'), addr => $addr->textContent });
			}
			push(@{$hash->{ns}}, $host);
		}
	}

	my $hosts = $infData->getElementsByLocalName('host');
	while (my $host = $hosts->shift) {
		push(@{$hash->{hosts}}, $host->textContent);
	}

	my $auths = $infData->getElementsByLocalName('authInfo');
	if ($auths->size == 1) {
		my $authInfo = $auths->shift;
		my $pw = $authInfo->getElementsByLocalName('pw');
		$hash->{authInfo} = $pw->shift->textContent if ($pw->size == 1);
	}

	if (defined $secinfo) {
		if (my $maxSigLife = $secinfo->getElementsByLocalName('maxSigLife')) {
			$hash->{maxSigLife} = $maxSigLife->shift->textContent;
		}
		my $dslist = $secinfo->getElementsByTagName('secDNS:dsData');
		while (my $ds = $dslist->shift) {
			my @ds = map { $ds->getElementsByLocalName($_)->string_value() }
			    qw(keyTag alg digestType digest);
			push @{ $hash->{DS} }, "@ds";
		}
		my $keylist = $secinfo->getElementsByLocalName('keyData');
		while (my $key = $keylist->shift) {
			my @key = map { $key->getElementsByLocalName($_)->string_value() }
			    qw(flags protocol alg pubKey);
			push @{ $hash->{DNSKEY} }, "@key";
		}
	}

	return $hash;
}


=pod

=head2 Host Information

The hash ref returned by C<host_info()> will usually look something like
this:

	$info = {
	  'crDate' => '2011-09-17T15:38:56.0Z',
	  'clID' => 'registrar-id',
	  'crID' => 'registrar-id',
	  'roid' => 'tld-12345',
	  'status' => [
	    'linked',
	    'serverDeleteProhibited',
	  ],
	  'name' => 'ns0.example.tld',
	  'addrs' => [
	    {
	      'version' => 'v4',
	      'addr' => '10.0.0.1'
	    }
	  ]
	};

Note that hosts may have multiple addresses, and that C<version> is
optional.

=cut

sub _host_infData_to_hash {
	my ($self, $infData) = @_;

	my $hash = $self->_get_common_properties_from_infData($infData, 'name');

	my $addrs = $infData->getElementsByLocalName('addr');
	while (my $addr = $addrs->shift) {
		push(@{$hash->{addrs}}, { version => $addr->getAttribute('ip'), addr => $addr->textContent });
	}

	return $hash;
}

=pod

=head2 Contact Information

The hash ref returned by C<contact_info()> will usually look something
like this:

	$VAR1 = {
	  'id' => 'contact-id',
	  'postalInfo' => {
	    'int' => {
	      'name' => 'John Doe',
	      'org' => 'Example Inc.',
	      'addr' => {
	        'street' => [
	          '123 Example Dr.'
	          'Suite 100'
	        ],
	        'city' => 'Dulles',
	        'sp' => 'VA',
	        'pc' => '20116-6503'
	        'cc' => 'US',
	      }
	    }
	  },
	  'clID' => 'registrar-id',
	  'roid' => 'CNIC-HA321983',
	  'status' => [
	    'linked',
	    'serverDeleteProhibited'
	  ],
	  'voice' => '+1.7035555555x1234',
	  'fax' => '+1.7035555556',
	  'email' => 'jdoe@example.com',
	  'crDate' => '2011-09-23T03:51:29.0Z',
	  'upDate' => '1999-11-30T00:00:00.0Z'
	};

There may be up to two members of the C<postalInfo> hash, corresponding
to the C<int> and C<loc> internationalised and localised types.

=cut

sub _contact_infData_to_hash {
	my ($self, $infData) = @_;

	my $hash = $self->_get_common_properties_from_infData($infData, 'email', 'id');

	# remove this as it gets in the way:
	my $els = $infData->getElementsByLocalName('disclose');
	if ($els->size > 0) {
		while (my $el = $els->shift) {
			$el->parentNode->removeChild($el);
		}
	}

	foreach my $name ('voice', 'fax') {
		my $els = $infData->getElementsByLocalName($name);
		if (defined($els) && $els->size == 1) {
			my $el = $els->shift;
			if (defined($el)) {
				$hash->{$name} = $el->textContent;
				$hash->{$name} .= 'x'.$el->getAttribute('x') if (defined($el->getAttribute('x')) && $el->getAttribute('x') ne '');
			}
		}
	}

	my $postalInfo = $infData->getElementsByLocalName('postalInfo');
	while (my $info = $postalInfo->shift) {
		my $ref = {};

		foreach my $name (qw(name org)) {
			my $els = $info->getElementsByLocalName($name);
			$ref->{$name} = $els->shift->textContent if ($els->size == 1);
		}

		my $addrs = $info->getElementsByLocalName('addr');
		if ($addrs->size == 1) {
			my $addr = $addrs->shift;
			foreach my $child ($addr->childNodes) {
				next if (XML::LibXML::XML_ELEMENT_NODE != $child->nodeType);
				if ($child->localName eq 'street') {
					push(@{$ref->{addr}->{$child->localName}}, $child->textContent);

				} else {
					$ref->{addr}->{$child->localName} = $child->textContent;

				}
			}
		}

		$hash->{postalInfo}->{$info->getAttribute('type')} = $ref;
	}

	my $auths = $infData->getElementsByLocalName('authInfo');
	if ($auths->size == 1) {
		my $authInfo = $auths->shift;
		my $pw = $authInfo->getElementsByLocalName('pw');
		$hash->{authInfo} = $pw->shift->textContent if ($pw->size == 1);
	}

	return $hash;
}

=pod

=head1 Object Transfers

The EPP C<E<lt>transferE<gt>> command suppots five different operations:
query, request, cancel, approve, and reject. C<Net::EPP::Simple> makes
these available using the following methods:

	# For domain objects:

	$epp->domain_transfer_query($domain);
	$epp->domain_transfer_cancel($domain);
	$epp->domain_transfer_request($domain, $authInfo, $period);
	$epp->domain_transfer_approve($domain);
	$epp->domain_transfer_reject($domain);

	# For contact objects:

	$epp->contact_transfer_query($contact);
	$epp->contact_transfer_cancel($contact);
	$epp->contact_transfer_request($contact, $authInfo);
	$epp->contact_transfer_approve($contact);
	$epp->contact_transfer_reject($contact);

Most of these methods will just set the value of C<$Net::EPP::Simple::Code>
and return either true or false. However, the C<domain_transfer_request()>,
C<domain_transfer_query()>, C<contact_transfer_request()> and C<contact_transfer_query()>
methods will return a hash ref that looks like this:

	my $trnData = {
	  'name' => 'example.tld',
	  'reID' => 'losing-registrar',
	  'acDate' => '2011-12-04T12:24:53.0Z',
	  'acID' => 'gaining-registrar',
	  'reDate' => '2011-11-29T12:24:53.0Z',
	  'trStatus' => 'pending'
	};

=cut

sub _transfer_request {
	my ($self, $op, $type, $identifier, $authInfo, $period) = @_;

	my $class = sprintf('Net::EPP::Frame::Command::Transfer::%s', ucfirst(lc($type)));

	my $frame;
	eval("\$frame = $class->new");
	if ($@ || ref($frame) ne $class) {
		$Error = "Error building request frame: $@";
		$Code = COMMAND_FAILED;
		return undef;

	} else {
		$frame->setOp($op);
		if ($type eq 'domain') {
			$frame->setDomain($identifier);
			$frame->setPeriod(int($period)) if ($op eq 'request');

		} elsif ($type eq 'contact') {
			$frame->setContact($identifier);

		}

		if ($op eq 'request' || $op eq 'query') {
			$frame->setAuthInfo($authInfo) if ($authInfo ne '');
		}

	}

	my $response = $self->_request($frame);


	if (!$response) {
		return undef;

	} else {
		$Code = $self->_get_response_code($response);
		$Message = $self->_get_message($response);

		if ($Code > 1999) {
			$Error = $response->msg;
			return undef;

		} elsif ($op eq 'query' || $op eq 'request') {
			my $trnData = $response->getElementsByLocalName('trnData')->shift;
			my $hash = {};
			foreach my $child ($trnData->childNodes) {
				$hash->{$child->localName} = $child->textContent;
			}

			return $hash;

		} else {
			return 1;

		}
	}
}

sub domain_transfer_query {
	return $_[0]->_transfer_request('query', 'domain', $_[1]);
}

sub domain_transfer_cancel {
	return $_[0]->_transfer_request('cancel', 'domain', $_[1]);
}

sub domain_transfer_request {
	return $_[0]->_transfer_request('request', 'domain', $_[1], $_[2], $_[3]);
}

sub domain_transfer_approve {
	return $_[0]->_transfer_request('approve', 'domain', $_[1]);
}

sub domain_transfer_reject {
	return $_[0]->_transfer_request('reject', 'domain', $_[1]);
}

sub contact_transfer_query {
	return $_[0]->_transfer_request('query', 'contact', $_[1]);
}

sub contact_transfer_cancel {
	return $_[0]->_transfer_request('cancel', 'contact', $_[1]);
}

sub contact_transfer_request {
	return $_[0]->_transfer_request('request', 'contact', $_[1], $_[2]);
}

sub contact_transfer_approve {
	return $_[0]->_transfer_request('approve', 'contact', $_[1]);
}

sub contact_transfer_reject {
	return $_[0]->_transfer_request('reject', 'contact', $_[1]);
}

=pod

=head1 Creating Objects

The following methods can be used to create a new object at the server:

	$epp->create_domain($domain);
	$epp->create_host($host);
	$epp->create_contact($contact);

The argument for these methods is a hash ref of the same format as that
returned by the info methods above. As a result, cloning an existing
object is as simple as the following:

	my $info = $epp->contact_info($contact);

	# set a new contact ID to avoid clashing with the existing object
	$info->{id} = $new_contact;

	# randomize authInfo:
	$info->{authInfo} = $random_string;

	$epp->create_contact($info);

C<Net::EPP::Simple> will ignore object properties that it does not recognise,
and those properties (such as server-managed status codes) that clients are
not permitted to set.

=head2 Creating New Domains

When creating a new domain object, you may also specify a C<period> key, like so:

	my $domain = {
	  'name' => 'example.tld',
	  'period' => 2,
	  'registrant' => 'contact-id',
	  'contacts' => {
	    'tech' => 'contact-id',
	    'admin' => 'contact-id',
	    'billing' => 'contact-id',
	  },
	  'status' => [
	    'clientTransferProhibited',
	  ],
	  'ns' => {
	    'ns0.example.com',
	    'ns1.example.com',
	  },
	};

	$epp->create_domain($domain);

The C<period> key is assumed to be in years rather than months. C<Net::EPP::Simple>
assumes the registry uses the host object model rather than the host attribute model.

=cut

sub create_domain {
	my ($self, $domain) = @_;

	return $self->_get_response_result(
		$self->_request(
			$self->_prepare_create_domain_frame($domain)
		)
	);
}

sub _prepare_create_domain_frame {
	my ($self, $domain) = @_;

	my $frame = Net::EPP::Frame::Command::Create::Domain->new;
	$frame->setDomain($domain->{'name'});
	$frame->setPeriod($domain->{'period'}) if (defined($domain->{period}) && $domain->{period} > 0);
	$frame->setNS(@{$domain->{'ns'}}) if $domain->{'ns'} and @{$domain->{'ns'}};
	$frame->setRegistrant($domain->{'registrant'}) if (defined($domain->{registrant}) && $domain->{registrant} ne '');
	$frame->setContacts($domain->{'contacts'});
	$frame->setAuthInfo($domain->{authInfo}) if (defined($domain->{authInfo}) && $domain->{authInfo} ne '');
	return $frame;
}

=head2 Creating Hosts

    my $host = {
        name  => 'ns1.example.tld',
        addrs => [
            { ip => '123.45.67.89', version => 'v4' },
            { ip => '98.76.54.32',  version => 'v4' },
        ],
    };
    $epp->create_host($host);

=cut

sub create_host {
	my ($self, $host) = @_;

	return $self->_get_response_result(
		$self->_request(
			$self->_prepare_create_host_frame($host)
		)
	);
}

sub _prepare_create_host_frame {
	my ($self, $host) = @_;

	my $frame = Net::EPP::Frame::Command::Create::Host->new;
	$frame->setHost($host->{name});
	$frame->setAddr(@{$host->{addrs}});
	return $frame;
}

sub create_contact {
	my ($self, $contact) = @_;

	return $self->_get_response_result(
		$self->_request(
			$self->_prepare_create_contact_frame($contact)
		)
	);
}


sub _prepare_create_contact_frame {
	my ($self, $contact) = @_;

	my $frame = Net::EPP::Frame::Command::Create::Contact->new;

	$frame->setContact($contact->{id});

	if (ref($contact->{postalInfo}) eq 'HASH') {
		foreach my $type (keys(%{$contact->{postalInfo}})) {
			$frame->addPostalInfo(
				$type,
				$contact->{postalInfo}->{$type}->{name},
				$contact->{postalInfo}->{$type}->{org},
				$contact->{postalInfo}->{$type}->{addr}
			);
		}
	}

	$frame->setVoice($contact->{voice}) if (defined($contact->{voice}) && $contact->{voice} ne '');
	$frame->setFax($contact->{fax}) if (defined($contact->{fax}) && $contact->{fax} ne '');
	$frame->setEmail($contact->{email});
	$frame->setAuthInfo($contact->{authInfo}) if (defined($contact->{authInfo}) && $contact->{authInfo} ne '');

	if (ref($contact->{status}) eq 'ARRAY') {
		foreach my $status (grep { /^client/ } @{$contact->{status}}) {
			$frame->appendStatus($status);
		}
	}
	return $frame;
}


# Process response code and return result
sub _get_response_result {
	my ($self, $response) = @_;

	return undef if !$response;

	# If there was a response...
	$Code    = $self->_get_response_code($response);
	$Message = $self->_get_message($response);
	if ($Code > 1999) {
		$Error = $response->msg;
		return undef;
	}
	return 1;
}


=head1 Updating Objects

The following methods can be used to update an object at the server:

	$epp->update_domain($domain);
	$epp->update_host($host);
	$epp->update_contact($contact);

Each of these methods has the same profile. They will return one of the following:

=over

=item * undef in the case of an error (check C<$Net::EPP::Simple::Error> and C<$Net::EPP::Simple::Code>).

=item * 1 if the update request was accepted.

=back

You may wish to check the value of $Net::EPP::Simple::Code to determine whether the response code was 1000 (OK) or 1001 (action pending).

=cut


=head2 Updating Domains

Use update_domain() method to update domains' data.

The update info parameter may look like:
$update_info = {
    name => $domain,
    chg  => {
        registrant => $new_registrant_id,
        authInfo   => $new_domain_password,
    },
    add => {
        # DNS info with "hostObj" or "hostAttr" model, see create_domain()
        ns       => [ ns1.example.com ns2.example.com ],
        contacts => {
            tech    => 'contact-id',
            billing => 'contact-id',
            admin   => 'contact-id',
        },

        # Status info, simple form:
        status => [ qw/ clientUpdateProhibited clientHold / ],

        # Status info may be in more detailed form:
        # status => {
        #    clientUpdateProbhibited  => 'Avoid accidental change',
        #    clientHold               => 'This domain is not delegated',
        # },
    },
    rem => {
        ns       => [ ... ],
        contacts => {
            tech    => 'old_tech_id',
            billing => 'old_billing_id',
            admin   => 'old_admin_id',
        },
        status => [ qw/ clientTransferProhibited ... / ],
    },
}

All fields except 'name' in $update_info hash are optional.

=cut

sub update_domain {
	my ($self, $domain) = @_;
	return $self->_update('domain', $domain);
}

=head2 Updating Contacts

Use update_contact() method to update contact's data.

The $update_info for contacts may look like this:

$update_info = {
    id  => $contact_id,
    add => {
        status => [ qw/ clientDeleteProhibited / ],
        # OR
        # status => {
        #    clientDeleteProhibited  => 'Avoid accidental removal',
        # },
    },
    rem => {
        status => [ qw/ clientUpdateProhibited / ],
    },
    chg => {
        postalInfo => {
            int => {
                  name => 'John Doe',
                  org => 'Example Inc.',
                  addr => {
                    street => [
                      '123 Example Dr.'
                      'Suite 100'
                    ],
                    city => 'Dulles',
                    sp => 'VA',
                    pc => '20116-6503'
                    cc => 'US',
              },
            },
        },
        voice => '+1.7035555555x1234',
        fax   => '+1.7035555556',
        email => 'jdoe@example.com',
        authInfo => 'new-contact-password',
    },
}

All fields except 'id' in $update_info hash are optional.

=cut

sub update_contact {
	my ($self, $contact) = @_;
	return $self->_update('contact', $contact);
}

=head2 Updating Hosts

Use update_host() method to update EPP hosts.

The $update_info for hosts may look like this:

$update_info = {
    name => 'ns1.example.com',
    add  => {
        status => [ qw/ clientDeleteProhibited / ],
        # OR
        # status => {
        #    clientDeleteProhibited  => 'Avoid accidental removal',
        # },

        addrs  => [
            { ip => '123.45.67.89', version => 'v4' },
            { ip => '98.76.54.32',  version => 'v4' },
        ],
    },
    rem => {
        status => [ qw/ clientUpdateProhibited / ],
        addrs  => [
            { ip => '1.2.3.4', version => 'v4' },
            { ip => '5.6.7.8', version => 'v4' },
        ],
    },
    chg => {
        name => 'ns2.example.com',
    },
}

All fields except first 'name' in $update_info hash are optional.

=cut

sub update_host {
	my ($self, $host) = @_;
	return $self->_update('host', $host);
}


# Update domain/contact/host information
sub _update {
	my ($self, $type, $info) = @_;

	my %frame_generator = (
		'domain'  => \&_generate_update_domain_frame,
		'contact' => \&_generate_update_contact_frame,
		'host'	  => \&_generate_update_host_frame,
	);

	if ( !exists $frame_generator{$type} ) {
		$Error = "Unknown object type: '$type'";
		return undef;
	}

	my $generator = $frame_generator{$type};
	my $frame     = $self->$generator($info);
	return $self->_get_response_result( $self->request($frame) );
}


sub _generate_update_domain_frame {
	my ($self, $info) = @_;

	my $frame = Net::EPP::Frame::Command::Update::Domain->new;
	$frame->setDomain( $info->{name} );

	# 'add' element
	if ( exists $info->{add} && ref $info->{add} eq 'HASH' ) {

		my $add = $info->{add};

		# Add DNS
		if ( exists $add->{ns} && ref $add->{ns} eq 'ARRAY' ) {
			$frame->addNS( @{ $add->{ns} } );
		}

		# Add contacts
		if ( exists $add->{contacts} && ref $add->{contacts} eq 'HASH' ) {

			my $contacts = $add->{contacts};
			foreach my $type ( keys %{ $contacts } ) {
				$frame->addContact( $type, $contacts->{$type} );
			}
		}

		# Add status info
		if ( exists $add->{status} && ref $add->{status} ) {
			if ( ref $add->{status} eq 'HASH' ) {
				while ( my ($type, $info) = each %{ $add->{status} } ) {
					$frame->addStatus($type, $info);
				}
			}
			elsif ( ref $add->{status} eq 'ARRAY' ) {
				$frame->addStatus($_) for @{ $add->{status} };
			}
		}
	}

	# 'rem' element
	if ( exists $info->{rem} && ref $info->{rem} eq 'HASH' ) {

		my $rem = $info->{rem};

		# DNS
		if ( exists $rem->{ns} && ref $rem->{ns} eq 'ARRAY' ) {
			$frame->remNS( @{ $rem->{ns} } );
		}

		# Contacts
		if ( exists $rem->{contacts} && ref $rem->{contacts} eq 'HASH' ) {
			my $contacts = $rem->{contacts};

			foreach my $type ( keys %{ $contacts } ) {
				$frame->remContact( $type, $contacts->{$type} );
			}
		}

		# Status info
		if ( exists $rem->{status} && ref $rem->{status} eq 'ARRAY' ) {
			$frame->remStatus($_) for @{ $rem->{status} };
		}
	}

	# 'chg' element
	if ( exists $info->{chg} && ref $info->{chg} eq 'HASH' ) {

		my $chg	= $info->{chg};

		if ( defined $chg->{registrant} ) {
			$frame->chgRegistrant( $chg->{registrant} );
		}

		if ( defined $chg->{authInfo} ) {
			$frame->chgAuthInfo( $chg->{authInfo} );
		}
	}

	return $frame;
}


sub _generate_update_contact_frame {
	my ($self, $info) = @_;

	my $frame = Net::EPP::Frame::Command::Update::Contact->new;
	$frame->setContact( $info->{id} );

	# Add
	if ( exists $info->{add} && ref $info->{add} eq 'HASH' ) {
		my $add = $info->{add};

		if ( exists $add->{status} && ref $add->{status} ) {
			if ( ref $add->{status} eq 'HASH' ) {
				while ( my ($type, $info) = each %{ $add->{status} } ) {
					$frame->addStatus($type, $info);
				}
			}
			elsif ( ref $add->{status} eq 'ARRAY' ) {
				$frame->addStatus($_) for @{ $add->{status} };
			}
		}
	}

	# Remove
	if ( exists $info->{rem} && ref $info->{rem} eq 'HASH' ) {

		my $rem = $info->{rem};

		if ( exists $rem->{status} && ref $rem->{status} eq 'ARRAY' ) {
			$frame->remStatus($_) for @{ $rem->{status} };
		}
	}

	# Change
	if ( exists $info->{chg} && ref $info->{chg} eq 'HASH' ) {

		my $chg	= $info->{chg};

		# Change postal info
		if ( ref $chg->{postalInfo} eq 'HASH' ) {
			foreach my $type ( keys %{ $chg->{postalInfo} } ) {
				$frame->chgPostalInfo(
					$type,
					$chg->{postalInfo}->{$type}->{name},
					$chg->{postalInfo}->{$type}->{org},
					$chg->{postalInfo}->{$type}->{addr}
				);
			}
		}

		# Change voice / fax / email
		for my $contact_type ( qw/ voice fax email / ) {
			if ( defined $chg->{$contact_type} ) {
				my $el = $frame->createElement("contact:$contact_type");
				$el->appendText( $chg->{$contact_type} );
				$frame->chg->appendChild($el);
			}
		}

		# Change auth info
		if ( $chg->{authInfo} ) {
			$frame->chgAuthInfo( $chg->{authInfo} );
		}

		# 'disclose' option is still unimplemented
	}

	return $frame;
}

sub _generate_update_host_frame {
	my ($self, $info) = @_;

	my $frame = Net::EPP::Frame::Command::Update::Host->new;
	$frame->setHost($info->{name});

	if ( exists $info->{add} && ref $info->{add} eq 'HASH' ) {
		my $add = $info->{add};
		# Process addresses
		if ( exists $add->{addrs} && ref $add->{addrs} eq 'ARRAY' ) {
			$frame->addAddr( @{ $add->{addrs} } );
		}
		# Process statuses
		if ( exists $add->{status} && ref $add->{status} ) {
			if ( ref $add->{status} eq 'HASH' ) {
				while ( my ($type, $info) = each %{ $add->{status} } ) {
					$frame->addStatus($type, $info);
				}
			}
			elsif ( ref $add->{status} eq 'ARRAY' ) {
				$frame->addStatus($_) for @{ $add->{status} };
			}
		}
	}

	if ( exists $info->{rem} && ref $info->{rem} eq 'HASH' ) {
		my $rem = $info->{rem};
		# Process addresses
		if ( exists $rem->{addrs} && ref $rem->{addrs} eq 'ARRAY' ) {
			$frame->remAddr( @{ $rem->{addrs} } );
		}
		# Process statuses
		if ( exists $rem->{status} && ref $rem->{status} ) {
			if ( ref $rem->{status} eq 'HASH' ) {
				while ( my ($type, $info) = each %{ $rem->{status} } ) {
					$frame->remStatus($type, $info);
				}
			}
			elsif ( ref $rem->{status} eq 'ARRAY' ) {
				$frame->remStatus($_) for @{ $rem->{status} };
			}
		}
	}

	if ( exists $info->{chg} && ref $info->{chg} eq 'HASH' ) {
		if ( $info->{chg}->{name} ) {
			$frame->chgName( $info->{chg}->{name} );
		}
	}

	return $frame;
}


=pod

=head1 Deleting Objects

The following methods can be used to delete an object at the server:

	$epp->delete_domain($domain);
	$epp->delete_host($host);
	$epp->delete_contact($contact);

Each of these methods has the same profile. They will return one of the following:

=over

=item * undef in the case of an error (check C<$Net::EPP::Simple::Error> and C<$Net::EPP::Simple::Code>).

=item * 1 if the deletion request was accepted.

=back

You may wish to check the value of $Net::EPP::Simple::Code to determine whether the response code was 1000 (OK) or 1001 (action pending).

=cut

sub delete_domain {
	my ($self, $domain) = @_;
	return $self->_delete('domain', $domain);
}

sub delete_host {
	my ($self, $host) = @_;
	return $self->_delete('host', $host);
}

sub delete_contact {
	my ($self, $contact) = @_;
	return $self->_delete('contact', $contact);
}

sub _delete {
	my ($self, $type, $identifier) = @_;
	my $frame;
	if ($type eq 'domain') {
		$frame = Net::EPP::Frame::Command::Delete::Domain->new;
		$frame->setDomain($identifier);

	} elsif ($type eq 'contact') {
		$frame = Net::EPP::Frame::Command::Delete::Contact->new;
		$frame->setContact($identifier);

	} elsif ($type eq 'host') {
		$frame = Net::EPP::Frame::Command::Delete::Host->new;
		$frame->setHost($identifier);

	} else {
		$Error = "Unknown object type '$type'";
		return undef;

	}

	my $response = $self->_request($frame);


	if (!$response) {
		return undef;

	} else {
		$Code = $self->_get_response_code($response);
		$Message = $self->_get_message($response);

		if ($Code > 1999) {
			$Error = $self->_get_error_message($response);
			return undef;

		} else {
			return 1;

		}
	}
}

=head1 Domain Renewal

You can extend the validity period of the domain object by issuing a
renew_domain() command.

 my $result = $epp->renew_domain({
     name         => 'example.com',
     cur_exp_date => '2011-02-05',  # current expiration date
     period       => 2,             # prolongation period in years
 });

Return value is C<1> on success and C<undef> on error.
In the case of error C<$Net::EPP::Simple::Error> contains the appropriate
error message.

=cut

sub renew_domain {
	my ($self, $info) = @_;

	return $self->_get_response_result(
		$self->request(
			$self->_generate_renew_domain_frame($info)
		)
	);
}

sub _generate_renew_domain_frame {
	my ($self, $info) = @_;

	my $frame = Net::EPP::Frame::Command::Renew::Domain->new;
	$frame->setDomain( $info->{name} );
	$frame->setCurExpDate( $info->{cur_exp_date} );
	$frame->setPeriod( $info->{period} ) if $info->{period};

	return $frame;
}

=pod

=head1 Miscellaneous Methods

=cut

sub error { $Error }

sub code { $Code }

sub message { $Message }

=pod

	my $greeting = $epp->greeting;

Returns the a L<Net::EPP::Frame::Greeting> object representing the greeting returned by the server.

=cut

sub greeting { $_[0]->{greeting} }

=pod

	$epp->ping;

Checks that the connection is up by sending a C<E<lt>helloE<gt>> to the server. Returns false if no
response is received.

=cut

sub ping {
	my $self = shift;
	my $hello = Net::EPP::Frame::Hello->new;
	my $response = $self->request($hello);

	if (UNIVERSAL::isa($response, 'XML::LibXML::Document')) {
		$Code    = 1000;
		$Message = 'Command completed successfully.';
		return 1;

	} else {
		$Code    = 2400;
		$Message = 'Error getting greeting from server.';
		return undef;
	}
}

sub _request {
	my ($self, $frame) = @_;

	if ($self->{reconnect} > 0) {
		$self->debug("reconnect is $self->{reconnect}, pinging");
		if (!$self->ping) {
			$self->debug('connection seems dead, trying to reconnect');
			for (1..$self->{reconnect}) {
				$self->debug("attempt #$_");
				if ($self->_connect) {
					$self->debug("attempt #$_ succeeded");
					return $self->request($frame);

				} else {
					$self->debug("attempt #$_ failed, sleeping");
					sleep($self->{timeout});

				}
			}
			$self->debug('unable to reconnect!');
			return undef;

		} else {
			$self->debug("Connection is up, sending frame");
			return $self->request($frame);

		}

	} else {
		return $self->request($frame);

	}
}

=pod

=head1 Overridden Methods From L<Net::EPP::Client>

C<Net::EPP::Simple> overrides some methods inherited from
L<Net::EPP::Client>. These are described below:

=head2 The C<request()> Method

C<Net::EPP::Simple> overrides this method so it can automatically populate
the C<E<lt>clTRIDE<gt>> element with a unique string. It then passes the
frame back up to L<Net::EPP::Client>.

=cut

sub request {
	my ($self, $frame) = @_;
	# Make sure we start with blank variables
	$Code		= undef;
	$Error		= '';
	$Message	= '';

	if (!$self->connected) {
		$Code = COMMAND_FAILED;
		$Error = $Message = 'Not connected';
		$self->debug('cannot send frame if not connected');
		return undef;

	} elsif (!$frame) {
		$Code = COMMAND_FAILED;
		$Error = $Message = 'Invalid frame';
		$self->debug($Message);
		return undef;

	} else {
		$frame->clTRID->appendText(sha1_hex(ref($self).time().$$)) if (UNIVERSAL::isa($frame, 'Net::EPP::Frame::Command'));

		my $type = ref($frame);
		if ($frame =~ /^\//) {
			$type = 'file';

		} else {
			$type = 'string';

		}
		$self->debug(sprintf('sending a %s to the server', $type));
		if (UNIVERSAL::isa($frame, 'XML::LibXML::Document')) {
			map { $self->debug('C: '.$_) } split(/\n/, $frame->toString(2));

		} else {
			map { $self->debug('C: '.$_) } split(/\n/, $frame);

		}

		my $response = $self->SUPER::request($frame);

		map { $self->debug('S: '.$_) } split(/\n/, $response->toString(2)) if (UNIVERSAL::isa($response, 'XML::LibXML::Document'));

		return $response;
	}
}

=pod

=head2 The C<get_frame()> Method

C<Net::EPP::Simple> overrides this method so it can catch timeouts and
network errors. If such an error occurs it will return C<undef>.

=cut

sub get_frame {
	my $self = shift;
	if (!$self->connected) {
		$self->debug('cannot send frame if not connected');
		$Code = COMMAND_FAILED;
		$Error = $Message = 'Not connected';
		return undef;

	} else {
		my $frame;
		$self->debug(sprintf('reading frame, waiting %d seconds before timeout', $self->{timeout}));
		eval {
			local $SIG{ALRM} = sub { die 'timeout' };
			$self->debug('setting timeout alarm for receiving frame');
			alarm($self->{timeout});
			$frame = $self->SUPER::get_frame();
			$self->debug('unsetting timeout alarm after successful receive');
			alarm(0);
		};
		if ($@ ne '') {
			chomp($@);
			$@ =~ s/ at .+ line .+$//;
			$self->debug("unsetting timeout alarm after alarm was triggered ($@)");
			alarm(0);
			$Code = COMMAND_FAILED;
			if ($@ =~ /^timeout/) {
				$Error = $Message = "get_frame() timed out after $self->{timeout} seconds";

			} else {
				$Error = $Message = "get_frame() received an error: $@";

			}
			return undef;

		} else {
			return bless($frame, 'Net::EPP::Frame::Response');

		}
	}
}

sub send_frame {
	my ($self, $frame, $wfcheck) = @_;
	if (!$self->connected) {
		$self->debug('cannot get frame if not connected');
		$Code = 2400;
		$Message = 'Not connected';
		return undef;

	} else {
		return $self->SUPER::send_frame($frame, $wfcheck);

	}
}

# Get details error description including code, message and reason
sub _get_error_message {
	my ($self, $doc) = @_;

	my $code    = $self->_get_response_code($doc);
	my $error   = "Error $code";

	my $message = $self->_get_message($doc);
	if ( $message ) {
		$error .= ": $message";
	}

	my $reason  = $self->_get_reason($doc);
	if ( $reason ) {
		$error .= " ($reason)";
	}

	return $error;
}

sub _get_response_code {
	my ($self, $doc) = @_;
	if ($doc->isa('XML::DOM::Document') || $doc->isa('Net::EPP::Frame::Response')) {
		my $els = $doc->getElementsByTagNameNS(EPP_XMLNS, 'result');
		if (defined($els)) {
			my $el = $els->shift;
			return $el->getAttribute('code') if (defined($el));
		}
	}
	return 2400;
}

sub _get_message {
	my ($self, $doc) = @_;
	if ($doc->isa('XML::DOM::Document') || $doc->isa('Net::EPP::Frame::Response')) {
		my $msgs = $doc->getElementsByTagNameNS(EPP_XMLNS, 'msg');
		if (defined($msgs)) {
			my $msg = $msgs->shift;
			return $msg->textContent if (defined($msg));
		}
	}
	return '';
}

sub _get_reason {
	my ($self, $doc) = @_;
	if ($doc->isa('XML::DOM::Document') || $doc->isa('Net::EPP::Frame::Response')) {
		my $reasons = $doc->getElementsByTagNameNS(EPP_XMLNS, 'reason');
		if (defined($reasons)) {
			my $reason = $reasons->shift;
			if (defined($reason)) {
				return $reason->textContent;
			}
		}
	}
        return '';
}

sub logout {
	my $self = shift;
	if ($self->authenticated) {
		$self->debug('logging out');
		my $response = $self->request(Net::EPP::Frame::Command::Logout->new);
		undef($self->{'authenticated'});
		if (!$response) {
			$Code = COMMAND_FAILED;
			$Message = $Error = 'unknown error';
			return undef

		} else {
			$Code = $self->_get_response_code($response);
			$Message = $self->_get_message($response);

		}
	}
	$self->debug('disconnecting from server');
	$self->disconnect;
	undef($self->{'connected'});
	return 1;
}

sub DESTROY {
	my $self = shift;
	$self->debug('DESTROY() method called');
	$self->logout if ($self->connected);
}

sub debug {
	my ($self, $msg) = @_;
	my $log = sprintf("%s (%d): %s", scalar(localtime()), $$, $msg);
	push(@Log, $log);
	print STDERR $log."\n" if (defined($self->{debug}) && $self->{debug} == 1);
}

=pod

	$connected = $epp->connected;

Returns a boolean if C<Net::EPP::Simple> has a connection to the server. Note that this
connection might have dropped, use C<ping()> to test it.

=cut

sub connected {
	my $self = shift;
	return defined($self->{'connected'});
}

=pod

	$authenticated = $epp->authenticated;

Returns a boolean if C<Net::EPP::Simple> has successfully authenticated with the server.

=cut

sub authenticated {
	my $self = shift;
	return defined($self->{'authenticated'});
}

=pod

=head1 Package Variables

=head2 $Net::EPP::Simple::Error

This variable contains an english text message explaining the last error
to occur. This is may be due to invalid parameters being passed to a
method, a network error, or an error response being returned by the
server.

=head2 $Net::EPP::Simple::Message

This variable contains the contains the text content of the
C<E<lt>msgE<gt>> element in the response frame for the last transaction.

=head2 $Net::EPP::Simple::Code

This variable contains the integer result code returned by the server
for the last transaction. A successful transaction will always return an
error code of 1999 or lower, for an unsuccessful transaction it will be
2011 or more. If there is an internal client error (due to invalid
parameters being passed to a method, or a network error) then this will
be set to 2400 (C<COMMAND_FAILED>). See L<Net::EPP::ResponseCodes> for
more information about thes codes.

=cut

1;
