package Plack::Middleware::Auth::Negotiate;
$Plack::Middleware::Auth::Negotiate::VERSION = '0.172130';
# ABSTRACT: Negotiate authentication middleware (SPNEGO)

use 5.006;
use strict;
use warnings;

use parent 'Plack::Middleware';
use Plack::Util::Accessor 'keytab';
use Scalar::Util;
use MIME::Base64;
use GSSAPI;

sub prepare_app {
	my $self = shift;
}

sub call {
	my($self, $env) = @_;

	my $auth = $env->{HTTP_AUTHORIZATION}
		or return $self->unauthorized;

	if ($auth =~ /^Negotiate (.*)$/) {
		my $data = MIME::Base64::decode($1);
		$ENV{KRB5_KTNAME} = $self->keytab if $self->keytab;
		my $user = gssapi_verify($data);
		if ($user) {
			$env->{REMOTE_USER} = $user;
			return $self->app->($env);
		}
	}

	return $self->unauthorized;
}

my $UNAUTH_MSG = q{<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html><head>
<title>401 Authorization Required</title>
</head><body>
<h1>Authorization Required</h1>
<p>This server could not verify that you
are authorized to access the document
requested.  Either you supplied the wrong
credentials (e.g., bad password), or your
browser doesn't understand how to supply
the credentials required.</p>
</body></html>
};

sub unauthorized {
	my $self = shift;
	return [
		401,
		[ 'Content-Type' => 'text/html',
			'Content-Length' => length $UNAUTH_MSG,
			'WWW-Authenticate' => 'Negotiate' ],
		[ $UNAUTH_MSG ],
	];
}

sub gssapi_verify {
	my $gss_input_token = shift;
	my $server_context;
	my $status = GSSAPI::Context::accept(
		$server_context,
		GSS_C_NO_CREDENTIAL,
		$gss_input_token,
		GSS_C_NO_CHANNEL_BINDINGS,
		my $gss_client_name,
		undef,
		my $gss_output_token,
		my $out_flags,
		my $out_time,
		my $gss_delegated_cred);

	$status or return gss_exit("Unable to accept security context", $status);
	my $client_name;
	$status = $gss_client_name->display($client_name);
	$status or return gss_exit("Unable to display client name", $status);
	return $client_name;
}

sub gss_exit {
	my $errmsg = shift;
	my $status = shift;

	my @major_errors = $status->generic_message();
	my @minor_errors = $status->specific_message();

	print STDERR "$errmsg:\n";
	foreach my $s (@major_errors) {
		print STDERR "  MAJOR::$s\n";
	}
	foreach my $s (@minor_errors) {
		print STDERR "  MINOR::$s\n";
	}
	return;
}


1; # End of Plack::Middleware::Auth::Negotiate

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::Auth::Negotiate - Negotiate authentication middleware (SPNEGO)

=head1 VERSION

version 0.172130

=head1 SYNOPSIS

    use Plack::Builder;
    my $app = sub { ... };

    builder {
        enable 'Auth::Negotiate', keytab => 'FILE:www.keytab';
        $app;
    };

=head1 DESCRIPTION

Plack::Middleware::Auth::Negotiate provides Negotiate (SPNEGO) authentication
for your Plack application (for use with Kerberos).

This is a very alpha module, and I am still testing some of the security corner
cases. Help wanted.

=head1 CONFIGURATION

=over 4

=item * keytab: path to the keytab to use. This value is set as
C<$ENV{KRB5_KTNAME}> if provided.

=back

Note that there is no option for matching URLs. You can do this yourself with
L<Plack::Middleware::Conditional>'s C<enable_if> syntax (for L<Plack::Builder>).

=head1 TODO

=over 4

=item * More security testing.

=item * Ability to specify a list of valid realms. If REALM.EXAMPLE.COM trusts
REALM.FOOBAR.COM, and we don't want to allow REALM.FOOBAR.COM users, we have to
check after accepting the ticket.

=item * Option to automatically trim the @REALM.EXAMPLE.COM portion of the user
value.

=item * Method to also provide Basic auth if Negotiate fails.

=item * Some way to cooperate with other Auth middleware. C<enable_if> is your
best bet right now (with different URLs for each type of authentication, and
writing a session).

=item * Better interaction with L<Plack::Middleware::Session>, since this
authentication is slow in my experience.

=item * Better implementation of the actual RFC.

=item * Custom "Authorization Required" message

=back

=head1 SEE ALSO

L<Plack>, L<Plack::Builder>, L<Plack::Middleware::Auth::Basic>

L<GSSAPI>, mod_auth_kerb

=head1 ACKNOWLEDGEMENTS

This code is based off of L<Plack::Middleware::Auth::Basic> and a sample script
provided with L<GSSAPI>.

=head1 AUTHOR

Adrian Kreher <avuserow@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Adrian Kreher <avuserow@cpan.org>.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
