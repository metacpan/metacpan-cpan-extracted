package OAuth::Consumer;
our $VERSION = '0.03';
use strict;
use warnings;
use feature 'switch';
use Carp;
use IO::Socket::INET;
use URI::Escape;
use HTTP::Response;
use Encode;
use HTML::Entities;
use parent 'LWP::Authen::OAuth';

=encoding utf-8

=head1 NAME

OAuth::Consumer - LWP based user agent with OAuth for consumer application

=head1 SYNOPSIS

OAuth is a protocol to allow a user to authorize an application to access on its
behalf ressources on a server without giving its password to the application. To
achieve this aim OAuth have a fairly complicated 3-steps authentication mechanism
which require to user to go to a website to authenticate itself. The authentication
response is then sent-back by the user itself through a callback mechanism.

OAuth::Consumer hide away to complexity of this process, including the set-up of
a callback webserver which can be called by the user browser when its
authentication is performed.

This library is oriented toward desktop application, it could possibly be used
in a web application but I have not tried it (and the LWP setup may not be the
most appropiate in this case).

Authenticating your application with OAuth to access some user's ressources is
a matter of requesting and authorising a I<token>. This can be done with the
following steps:

  use OAuth::Consumer;
  
  my $ua = OAuth::Consumer->new(
  		oauth_consumer_key => 'key',
  		oauth_consumer_secret => 'secret'
  		oauth_request_token_url => 'http://provider/oauth/request_token',
  		oauth_authorize_url => 'http://provider/oauth/authorize',
  		oauth_access_token_url => 'http://provider/oauth/access_token'
  	);
  
  my $verifer_url = $ua->get_request_token();
  
  print "You should authentify yourself at this URL: $verifier_url\n";
  
  my ($token, $secret) = $ua->get_access_token()
  
At this point, C<$ua> is an OAuth enabled LWP user-agent that you can use to
access OAuth protected ressources. You should save the C<$token> and C<$secret>
that you got and, in a later session, you may just do the following to gain
access to the protected ressources:

  my $ua = OAuth::Consumer->new(
  		oauth_consumer_key => 'key',
  		oauth_consumer_secret => 'secret'
  		oauth_token_=> $token,
  		oauth_token_secret => $secret
  	);

=head1 DESCRIPTION

As OAuth::Consumer is a high-level library, this documentation does not describe
precisely the OAuth protocol. You may find documentation on this protocol on
these websites:

=over 4

=item L<http://markdown.io/https://raw.github.com/Dynalon/Rainy/master/docs/OAUTH.md>

=item L<http://hueniverse.com/oauth/guide/authentication/>

=item L<http://code.google.com/p/oauthconsumer/wiki/UsingOAuthConsumer>

=item L<http://tools.ietf.org/html/rfc5849>

=back


=head1 CONSTRUCTOR

  my $ua = OAuth::Consumer->new(%args);

The OAuth::Consumer constructor gives you an LWP::UserAgent object (well, strictly
speaking this is an LWP::Authen::OAuth object, but you should not use directly
the method of this module). This object is able to authenticate using the OAuth
1.0 or 1.0a protocol (but not OAuth 2.0).

You can give to the constructor any LWP::UserAgent arguments. The OAuth::Consumer
constructor expects some additionnal arguments described here:

=over 4

=item * C<oauth_consumer_key> and C<oauth_consumer_secret>

These values are specific to your application. Depending on the service you are
trying to access, you may either choose them arbitrarily, you may be given them
by the service provider (e.g. on your application page after registration for
Twitter or Google), or they may be fixed to some specific values.

If you specify nothing, the default value of C<anyone> is used for both (some
OAuth provider are known to accept this -- e.g. the Tomboy sync service -- this
may not be the case of the service you are trying to access).

=item * C<oauth_token> and C<oauth_token_secret>

The whole point of the OAuth protocol is for an application to get an access token
and an associated secret. The consumer key and secret are associated to an
application, but the token and its secret are associated to a specific user of
this application.

If you already have those (e.g. some service provider, like Twitter, will give
it to your user on there)

=item * C<oauth_request_token_url>, C<oauth_authorize_url>, and C<oauth_access_token_url>

These are the OAuth endpoints. If you already have an C<oauth_token> and
C<oauth_token_secret> then you do not need these endpoints, otherwise they should
be provided to you by the service provider.

Some service provider will provide already authorised tokens and as such will not
provide an C<oauth_authorize_url>. In this case, you should give C<'null'> for
this parameter and use the C<'manual'> type for C<oauth_verifier_type> (see
below).

=item * C<oauth_version>

You may specify the oauth version to use. Currently only version C<'1.0'> and
C<'1.0a'> are supported by the library. The default is C<'1.0a'>, you may need to
revert to C<'1.0'> with some server.

=item * C<oauth_consumer_signature>

Only the C<HMAC-SHA1> signature mode is supported for now (which happens to be
the default value of this option). So you should not use this argument.

=item * C<oauth_callback>

This parameter allows you to specify the where the user will be sent by the
service provider once he has authorised your application. If you do not specify
anything for this parameter, it default to C<http://localhost:port> where C<port>
is a randomly chosen port where the library will listen for the end of the
authorisation procedure.

You should not overide this value unless you are familiar with the OAuth protocol
and you know what you are doing.

Some service providers (such as Google), allow the special value C<'oob'> (out of
band) which will redirect the user to a web page which will show the verifier
value. This value may then be passed as parameter to the C<get_access_token>
method. This C<'oob'> value is the default when the C<oauth_verifier_type> is
C<manual> (see just below).

=item * C<oauth_verifier_type>

This parameter allows to specify how the verifier code is received by your
application. Currently the library support three modes. The default is
C<'blocking'>. In this mode, a call to C<get_access_token> will be blocking until
the user complete its authentication process at the url given as the result of
the C<get_request_token> call. During this time, the library will have set up a
small web server which will wait to be triggered by the user browser at the end
of this authentication.

If this setting is not working for you, you may use an C<oauth_verifier_type> of
C<'manual'>. In this case, no web server is set up by the library and you must
supply the I<verifier> code manually to the C<get_access_token> method. This
verifier may be entered by your user (some service provider will show it to your
user) or you may read eat programatically (e.g. performing the authorisation
process with WWW::Mechanize directed at the URL which is given back by the
C<get_request_token> method).

The C<manual> mode is the default if you supply an C<oauth_callback> argument to
the constructor.

Finally there is the C<thread> mode. This mode is similar in functionnalities to
the C<blocking> mode except that the small web server (which get the result of
the authentication) is run in a separate thread. This enable you more flexibilities
as you can complete the authentication process (be it by your user or with a
programatic method) before calling the C<get_access_token>. Obviously, you will
need a Perl with threads enabled to use this mode.

You should also note that in C<thread> mode the library itself is not thread-safe!
It plays with the C<ALARM> handler and as such it should be called from the main
thread of the program. Also, there may not be multiple concurently running
OAuth::Consumer object (that is in-between the C<get_request_token> and
C<get_access_token> call) if you are in C<thread> mode.

=item * C<oauth_verifier_valid_msg> and C<oauth_verifier_invalid_msg>

You can use these two options to customise the message that the user get after its
authentication in the browser. You may either pass a string of text which will
be embedded in a small web page, or you may pass a complete web page (which must
then start with the C<<'<html>'>> tag to be recognised) which will be used as-is.
In the later case the argument must be UTF-8 encoded (not in Perl internal string
representation) with all HTML entities properly escaped (but no checks at all
will be performed on the argument beyond the test for the first tag).

=item * C<oauth_verifier_timeout>

This parameter set the timeout value in the C<get_access_token> method call.
That is, the time the user have to performs its authentication on the service
provider website. This parameter is ignored when C<oauth_verifier_type> is
C<manual>.

The default value is C<180> (3 minutes). You may set it to C<undef> to
completely remove any timeout.

=back


=head1 METHODS

The methods described here allow you to get an authorised access token and its
associated secret. If you already have those (maybe from previous call to these
methods) then you do not need them.

An OAuth::Consumer object is also an LWP::UserAgent object and as such you can
use any method of the LWP::UserAgent class with an OAuth::Consumer object. If
your object is properly identified you may use it directly (e.g. with its C<get>
or C<post> method) to access OAuth protected ressources (that is, directly after
it is constructed if you provided valid C<oauth_token> and C<oauth_token_secret>
to the constructor, or after a call to C<get_request_token>/C<get_access_token>
if you need a new token).

=head2 get_request_token

  my $verifer_url = $ua->get_request_token(%args)

This call initiates a new authorisation procedure. It does not expect any
arguments but you can provide any additionnal OAuth argument required by your
service provider. Example of such argument are C<xoauth_displayname>, C<scope>,
or C<realm>. You should look at the documentation of your service provider to
know which arguments it expects. These arguments will be added as POST arguments
in the OAuth query. If you need to pass them as GET arguments (in the url of the
query), then you should modify yourself the C<oauth_request_token_url> that you
give to the constructor of the class.

On success, this method returns a string containing an URL to which the
application user should be directed to authorise your application to access to
the service provider on behalf of this user. At the end of its authorisation the
user's browser will be automatically redirected to a small web server set up by
the library. This web server will automatically read the C<verifier> code that
is given by the service provider.

You may also use this C<verifer_url> to programatically authorise your request
(e.g. with WWW::Mechanize).

Finally, if your service provider does not need you to authenticate your token
then the return value may be ignored and you may directly call the
C<get_access_token> method. In that case you must set the C<oauth_verifier_type>
to C<manual> to prevent the application from blocking.

The method will C<croak> in case of error.

=head2 get_access_token

  my ($token, $secret) = $ua->get_access_token(%args)

Once you have redirected your user to the verifier url, you can call this method.
It will block until the user finishes authenticating itself on the service
provider's website. If this process takes more time than the value of the
C<oauth_verifier_timeout> parameter (in the constructor) then the method will
croak with the following message: C<'Timeout error while waiting for a callback connection'>.
You can trap this error (with C<eval>) and, optionnaly, restart the call to
C<get_access_token> (which will wait for the same duration) if the C<oauth_verifier_type>
is C<blocking> (you may not call this function more than once per call to
C<get_request_token> in C<thread> mode).

If the C<oauth_verifier_type> parameter is C<'blocking'> you must call this
function as soon as you have instructed your user to authenticate at the
I<verifier> URL.

If the C<oauth_verifier_type> parameter is C<'manual'> then this function will
not block. But then you I<must> specify an C<oauth_verifier> named argument to
this function with its value being the value of the verifier that you got (your
user may have entered it in your application if your using out-of-bound
verification).

If your service provider does not require you to verify the request token (and
as such did not give you an C<oauth_authorize_url>). You must use C<'manual'>
mode with a dummy C<oauth_authorize_url> in the constructor and you should pass
an empty value to the C<oauth_verifier> argument of this method.

All other arguments in the C<%args> hash will be passed with the I<access token>
query. To the author knowledge, no service providers require any arguments with
this query (as opposed to the I<request token> query).

Finally, this function plays with the C<alarm> function and associated handler.
So you should not rely on alarm handler set accross this function call.

=cut


my @internal_opts = qw(
	oauth_request_token_url oauth_authorize_url	oauth_access_token_url
	oauth_version oauth_callback oauth_verifier_type oauth_verifier_valid_msg
	oauth_verifier_invalid_msg oauth_verifier_timeout);

my $max_content_len_for_error = 60;

sub new {
	my ($class, %args) = @_;

	my %opts;
	for my $o (@internal_opts)
	{
		$opts{$o} = delete $args{$o};
	}
	
	$args{oauth_consumer_key} ||= 'anyone';
	$args{oauth_consumer_secret} ||= 'anyone';

	$opts{oauth_version} ||= '1.0a';
	$opts{oauth_verifier_type} ||= $opts{oauth_callback} ? 'manual' : 'blocking';
	$opts{oauth_verifier_valid_msg} ||= 'Authentication accepted you can go back to the application';
	$opts{oauth_verifier_invalid_msg} ||= 'There have been a problem with your authentication';
	$opts{oauth_verifier_timeout} //= 180; # /
	
	given($opts{oauth_verifier_type}) {
		when(/^(manual|blocking)$/) { }
		when('thread') {
			if (not eval 'use threads; 1') {
				croak "You need a thread enabled Perl to a use oauth_verifier_type of 'thread'";
			} elsif (not eval 'use Thread::Queue; 1') {
				croak "You need 'Thread::Queue' to use a oauth_verifier_type of 'thread'";
			}
		}
		default {
			croak "Unknown value for the oauth_verifier_type parameter: ".$opts{oauth_verifier_type};
		}
	}

	my $self = $class->SUPER::new(%args);

	for(keys %opts)
	{
		$self->{$_} = $opts{$_};
	}

	return $self;
}


sub m__start_server {
	my ($self) = @_;

	my $sock = IO::Socket::INET->new(
			Listen => 1,
			LocalAddr => 'localhost',
			LocalPort => 0,
			Proto => 'tcp',
			Timeout => $self->{oauth_verifier_timeout}
		);

	return unless $sock;

	$self->{oauth_consumer_server_sock} = $sock;
	$self->{oauth_consumer_server_port} = $sock->sockport();
	carp "ignored oauth_callback parameter" if $self->{oauth_callback};
	$self->{oauth_callback} = "http://localhost:".$sock->sockport().'/oauth_callback';

	return $self->{oauth_callback};
}

sub __forge_response {
	my ($ok, $txt) = @_;
	
	my $code = $ok ? 200 : 500;
	my $msg = $ok ? 'OK' : 'Server Error';
	my $content;
	if ($txt =~ m/^\s*<html>/) {
		$content = $txt;
	} else {
		$content = encode('UTF-8', '<html><body><h1>'.encode_entities($txt).'</h1></body></html>');
	}
	
	my $m = HTTP::Response->new($code, $msg, [
			'Content-Type' => 'text/html;charset=UTF-8',
			'Content-Length' => length($content)
		], $content);
	$m->protocol("HTTP/1.0");

	return $m->as_string();
}

sub m__get_verifier {
	my ($self) = @_;

	my $sock = $self->{oauth_consumer_server_sock}->accept();
	return 'OAUTH::CONSUMER::ERR:Timeout error while waiting for a callback connection' unless $sock;
	$self->{oauth_consumer_server_sock}->close();

	my $get_line;
	eval {
		local $SIG{ALRM} = sub { die "Timeout error while reading the callback data\n" };
		alarm 5;
		$get_line = $sock->getline();
		alarm 0;
	};
	return "OAUTH::CONSUMER::ERR:$@" if $@;

	if ($get_line =~ m{^GET\s+/oauth_callback.*oauth_verifier=([-0-9a-z_]+)}i) {
		$self->{oauth_verifier} = $1;
		$sock->print(__forge_response(1, $self->{oauth_verifier_valid_msg}));
		$sock->close();
		return $self->{oauth_verifier};
	} else {
		$sock->print(__forge_response(0, $self->{oauth_verifier_invalid_msg}));	
		$sock->close();
		return "OAUTH::CONSUMER::ERR:no match in GET line '$get_line'";
	}
}

sub m__get_thread_verifier {
	my ($self) = @_;

	$self->{thread}->join();
	delete $self->{thread};
	$SIG{ALRM} = $self->{previous_alrm_handler};
	# On n'utilise pas la valeur de retour du thread pour faire quelquechose de
	# plus facilement extensible.
	return $self->{thread_queue}->dequeue();
}

sub DESTROY {
	my ($self) = @_;

	if ($self->{thread}) {
		if ($self->{thread}->is_joinable()) {
			$self->{thread}->join();
		} else {
			$self->{thread}->detach();		
		}
	}
}

sub m__start_thread_server {
	my ($self) = @_;

	$self->{thread_queue} = Thread::Queue->new();

	$self->{thread} = threads->create(sub {
			$self->{thread_queue}->enqueue($self->m__start_server());
			$self->{thread_queue}->enqueue($self->m__get_verifier());
		});

	$self->{previous_alrm_handler} = $SIG{ALRM};
	$SIG{ALRM} = sub {
			$self->{thread}->is_running();
			$self->{thread}->kill('ALRM');
		};

	return $self->{thread_queue}->dequeue();	
}

sub get_request_token {
	my ($self, %args) = @_;
	
	my $ver_type = $self->{oauth_verifier_type};
	croak "oauth_request_token_url must be set" unless $self->{oauth_request_token_url};
	croak "oauth_authorize_url must be set" unless $self->{oauth_authorize_url};
	croak "Invalid oauth_verifier_type: $ver_type" unless $ver_type =~ m/^(manual|blocking|thread)$/;

	given($ver_type) {
		when('blocking') {
			$self->{oauth_callback} = $self->m__start_server();
			croak "Cannot open the verifier callback: $!" unless $self->{oauth_callback};
		}
		when('thread') {
			$self->{oauth_callback} = $self->m__start_thread_server();
			croak "Cannot open the verifier callback: $!" unless $self->{oauth_callback};			
		}
		when('manual') {
			if (not $self->{oauth_callback}) {
				# we must supply a callback
				# carp "You should provide a value for the 'oauth_callback' parameter";
				$self->{oauth_callback} = 'oob';
			}
		}
		default {
			croak "Unknown value for the oauth_verifier_type parameter: $ver_type";
		}
	}
	my $cback = uri_escape($self->{oauth_callback});

	# request a 'request' token
	my $r = $self->post($self->{oauth_request_token_url}, Authorization => "OAuth oauth_callback=\"$cback\"", %args);
	if ($r->is_error) {
		my $str = length $r->content > $max_content_len_for_error ?
				substr($r->content, 0, $max_content_len_for_error - 3).'...'
				: $r->content;
		croak "error during the GetRequestToken call: ".$r->message." ($str)";
	}

	$self->oauth_update_from_response($r);
	my $token = $self->oauth_token();
	my $auth_url = $self->{oauth_authorize_url}."?oauth_token=$token";
	if ($self->{oauth_version} eq '1.0') {
		$auth_url .= '&oauth_callback='.$cback;
	}

	return $auth_url;
}



sub get_access_token {
	my ($self, %args) = @_;

	croak "oauth_access_token_url must be set" unless $self->{oauth_access_token_url};

	given($self->{oauth_verifier_type}) {
		when('blocking') {
			$self->{oauth_verifier} = $self->m__get_verifier();
		}
		when('thread') {
			$self->{oauth_verifier} = $self->m__get_thread_verifier();
		}
		when('manual') {
			croak 'You must supply a oauth_verifier' unless exists $args{oauth_verifier};
			$self->{oauth_verifier} = delete $args{oauth_verifier};
		}
		default {
			croak "Unknown value for the oauth_verifier_type parameter: ".$self->{oauth_verifier_type};
		}
	}
	if ($self->{oauth_verifier} =~ m/^OAUTH::CONSUMER::ERR:(.*?)$/m) {
		croak $1;
	}

	my $verif_header = 'OAuth oauth_verifier="'.uri_escape($self->{oauth_verifier}).'"';
	my $r = $self->post($self->{oauth_access_token_url}, Authorization => $verif_header, %args);
	if ($r->is_error) {
		my $str = length $r->content > $max_content_len_for_error ?
				substr($r->content, 0, $max_content_len_for_error - 3).'...'
				: $r->content;
		croak "error during the GetAccessToken call: ".$r->message." ($str)";
	}
	$self->oauth_update_from_response($r);
	
	my $token = $self->oauth_token();
	my $secret = $self->oauth_token_secret();

	return ($token, $secret);
}




1;




=head1 EXAMPLES

=head2 Getting an access token and secret

Here are the steps to follow to request an access token from a ressource
provider. To achieve this, you need the 3 endpoints URL that should be described
in the documentation of the API of the provider. You also need a consumer key and
secret. Depending on the provider and the service, these value may be fixed to
a specific value or you may need to register your application at the provider
website to get them.

Some providers require extra arguments for the C<get_request_token> call. These
arguments are not mendatory in the OAuth specification but you should check the
API documentation of your service provider to know what it expects.

  my $ua = OAuth::Consumer->new(
  	oauth_consumer_key      => 'my-consumer-key',
  	oauth_consumer_secret   => 'my-consumer-secret',
  	oauth_request_token_url => 'http://oauth-provider.example.com/request_token',
  	oauth_access_token_url  => 'http://oauth-provider.example.com/access_token',
  	oauth_authorize_url     => 'http://oauth-provider.example.com/authorize',
  );
  
  my $verifier_url = $ua->get_request_token(
  	scope              => 'http://oauth-provider.example.com/scope1',
  	xoauth_displayname => 'My Application Name'
  );
  
  # Send your user to $verifier_url to authenticate or use a WWW::Mechanize
  # robot to performs the authentication programatically. In this later case,
  # you should use the "oauth_verifier_type => thread" argument in the call to
  # new to ensure that the authentication can terminate before the call to
  # get_access_token.
  
  my ($token, $secret) = $ua->get_access_token();
  
  $r = $ua->get('http://oauth-provider.example.com/protected_ressource');

At the end of this procedure you should store the C<$token> and C<$secret> values
as they should remains valid (usually service providers do not expire those).
You can then use them directly in a future session.

=head2 Getting an access token and secret with out-of-bound (OOB) verifier

If your service provider will not redirect your user to OAuth::Consumer
validation page, or if it is not feasible to ask the user to use his browser on
the same machine as where the program is running, you may use out-of-bound
verification where the user will be shown the verification code and can then
enter it in your application.

Not all service provider support the C<oob> callback scheme, so the example below
may not work correctly. An alternative is to redirect the user to a web page that
you control and that will show the user the verification code. Some practice about
this are discussed on this web page: L<https://sites.google.com/site/oauthgoog/oauth-practices/auto-detecting-approval>.

  my $ua = OAuth::Consumer->new(
  	oauth_consumer_key      => 'my-consumer-key',
  	oauth_consumer_secret   => 'my-consumer-secret',
  	oauth_verifier_type     => 'manual',
  	oauth_request_token_url => 'http://oauth-provider.example.com/request_token',
  	oauth_access_token_url  => 'http://oauth-provider.example.com/access_token',
  	oauth_authorize_url     => 'http://oauth-provider.example.com/authorize',
  );
  
  my $verifier_url = $ua->get_request_token();
  
  print "Please, authenticate yourself at: $verifier_url\n";
  print "Type in the verification code that you got: ";
  my $verifier = <STDIN>;
  
  my ($token, $secret) = $ua->get_access_token(oauth_verifier => $verifier);
  
  $r = $ua->get('http://oauth-provider.example.com/protected_ressource');

Be carefull that a verifier URL may not remain valid for a long time (usual
expiration time is around an hour).

=head2 Using an access token and secret

If you saved your user specific access token and secret from a previous session
or if your service provider does not allow for the authentication procedure and,
instead, gives directly the token and its secret to your user on some web page
(e.g. this is what Twitter does), then you can directly use these value in the
constructor of the OAuth::Consumer object and completely skip the authentication
procedure.

  my $ua = OAuth::Consumer->new(
  	oauth_consumer_key      => 'my-consumer-key',
  	oauth_consumer_secret   => 'my-consumer-secret',
  	oauth_token             => $token,
  	oauth_token_secret      => $secret
  );
  
  $r = $ua->get('http://oauth-provider.example.com/protected_ressource');

However, you should check your response code in case the token has been revoked
or has expired (in which cases you will probably get a status code of C<401> or
C<403>, but some servers return a C<500> status code).

=head2 Two-legged request (tokenless or consumer mode)

Some service provider only require a your consumer key to authorise the access
to some protected ressource. This is called two-legged request (as opposed to
the normal three-legged mode) or tokenless mode.

In this case, once you got your consumer key and secret (probably from your
application page on the service provider website) you can just use those to
access protected ressource.

  my $ua = OAuth::Consumer->new(
  	oauth_consumer_key      => 'my-consumer-key',
  	oauth_consumer_secret   => 'my-consumer-secret',
  );
  
  $r = $ua->get('http://oauth-provider.example.com/two-legged_ressource');

=head1 CAVEATS

=over 4

=item * Currently only the OAuth 1.0 and 1.0a are supported. The OAuth 2.0 protocol
is quiet different from the 1.0 version (and varies greatly from one service
provider to an other) so there is no plan currently to upgrade thise library to
it.

=item * Only the C<HMAC-SHA1> signature mode is supported in the OAuth message. This
is partly due to the fact that this is the only mode supported by the LWP::Authen::OAuth
library from which OAuth::Consumer is inheriting and also to the fact that this
mode is supported by all major OAuth enabled service provider. Let me know if you
need another signature mode.

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-oauth-consumer@rt.cpan.org>, or
through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=OAuth-Consumer>.

However note that the tests for this distribution all depend on external service
which may be unavailable or broken at some point. I have removed from the
distribution the test depending on unreliable provider but some errors may still
happen.

=head1 SEE ALSO

LWP::Authen::OAuth, LWP::UserAgent, OAuth::Simple, Net::OAuth, OAuth::Lite,
Net::OAuth::Simple, OAuth::Lite::Consumer

=head1 AUTHOR

Mathias Kende (mathias@cpan.org)

=head1 VERSION

Version 0.03 (March 2013)

=head1 COPYRIGHT & LICENSE

Copyright 2013 © Mathias Kende. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut



