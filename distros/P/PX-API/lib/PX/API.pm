package PX::API;
use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.3');

use base qw/Class::Accessor::Fast/;
__PACKAGE__->mk_accessors( qw/api_key secret method args do_sign api_sig ua/ );

use LWP::UserAgent;
use PX::API::Request;
use PX::API::Response;
use Digest::MD5 qw(md5_hex);

sub new {
	my $class = shift;
	my $args  = shift;

	$class = ref($class) || $class;
	my $self = bless {}, $class;

	my $ua = LWP::UserAgent->new(agent => $self->_agent, timeout => 60);
	$self->ua($ua);
	$self->api_key($args->{'api_key'});
	$self->secret($args->{'secret'});
	warn "No API key present!!" unless ($self->api_key);

	return $self;
	}

sub call {
	my $self = shift;
	my $meth = shift;
	my $args = shift;

	$self->args($args);
	my $req = PX::API::Request->new({
				method  => $meth,
				args	=> $args,
				});
	$self->execute_request($req);
	}

sub execute_request {
	my $self = shift;
	my $req  = shift;

	$req->{'args'}->{'api_key'} = $self->api_key;
	$req->{'args'}->{'api_sig'} = $self->_sign_args($req->{'args'}) if $self->do_sign;

	my $uri = $req->uri;
	$uri .= "?" . $self->_query_string($req->{'args'});
	$req->uri($uri);
	my $resp = $self->ua->request($req);
	bless $resp, 'PX::API::Response';
	$resp->_init({format => $req->{'args'}->{'format'}});

	if ($resp->{'_rc'} != 200) {
		$resp->fault(0,"API returned status code ($resp->{_rc})");
		return $resp;
		}

	my $parser = $resp->{'parser'};
	my $ref = $parser->parse($resp->{'_content'});
	$resp->fault(0,"Error parsing server response") if (!defined $ref->{response});

	my $stat = $ref->{response}->{status} if defined $ref->{response}->{status};
	if ($stat eq "error") {
		my $error = $ref->{response}->{content}->{error};
		$resp->fault(0,"($error->{err_code}) $error->{err_string}");
		return $resp;
		}

	if ($ref->{response}->{status} eq "ok") {
		$resp->success($ref->{response});
		return $resp;
		}

	$resp->fault(0,"API returned an invalid status code");
	return $resp;
	}

sub auth_url {
	my $self = shift;
	my $perms = shift;
	return undef unless defined $self->secret;

	my $args = {
		api_key => $self->api_key,
		perms	=> $perms,
		};

	my $sig = $self->_sign_args($args);
	$args->{api_sig} = $sig;

	my $q = $self->_query_string($args);
	my $uri = "http://services.peekshows.com/auth?" . $q;
	return $uri;
	}

sub _sign_args {
	my $self = shift;
	my $args = shift;

	my $sig = $self->secret;
	foreach my $k(sort {$a cmp $b} keys %{$args}) {
		$sig .= $k . $args->{$k};
		}
	return md5_hex($sig);
	}

sub _query_string {
	my $self = shift;
	my $args = shift;

	my @pairs;
        foreach my $k(keys %{$args}) {
                my $kv = $k . "=" . $args->{$k};
                push(@pairs,$kv);
                }
        my $q = join("&",@pairs);
	return $q;
	}

sub _agent { __PACKAGE__ . "/" . $VERSION }


1;
__END__

=head1 NAME

PX::API - Perl interface to the Peekshows Web Services API.


=head1 SYNOPSIS

    use PX::API;

    my $px = PX::API->new({
			api_key => '13243432434',  #Your api key
			secret  => 's33cr3tttt',   #Your api secret
			});
    my $response = $px->call('px.test.echo', {
					arg1 => 'val1',
					arg2 => 'val2',
					});


=head1 DESCRIPTION

A quick and simple perl interface to the Peekshows Web Services API.
C<PX::API> uses L<LWP::UserAgent> for communication via the Peekshows
Web Services rest interface.  Response formats are made available
'plugin' style to allow for an extensible method of adding response
types as they become available through the API.

=head1 METHODS/SUBROUTINES

=over 4

=item C<new($args)>

Constructs a new C<PX::API> object storing your C<api_key> and C<secret>.

=item C<call($method,$args)>

Calls the specified C<$method> passing along all C<$args> allong with the
request.  A C<PX::API::Response> object is returned based on the requested
format, rest by default.  When making authenticated calls, C<PX::API::do_sign(1)>
must be called to create a valid C<api_sig>.  Will return an error if no
secret is present when requiring an C<api_sig>.

=item C<execute_request($request)>

Executes a method call to the API.  The C<$request> argument must be a
C<PX::API::Request> object.

=item C<auth_url($perms)>

Constructs a url that can be used to send users to the Peekshows auth page.
This method will create an C<api_sig> automagically, there is no need to
set C<PX::API::do_sign(1)>, though a C<secret> is required.


=back


=head1 CONFIGURATION AND ENVIRONMENT

C<PX::API> uses L<Class::Accessor::Fast> as a base, making most
parameters available through its simple get/set interface. ie:

    my $api_key = $px->api_key

    $px->api_key('41234314344')


=over 4

=item C<api_key>

The key you received for your application.

=item C<secret>

The secret string you received for your application.

=item C<method>

Then name of the method you wish to call.  ie: C<px.test.echo>

=item C<args>

The list of arguments to be sent with the call to the API.

=item C<do_sign>

This works as a switch, setting to 0 or 1 will disable or enable
call signing respectively.

=item C<api_sig>

The signature for the last signed API call that was made.

=item C<ua>

This is the L<LWP::UserAgent> object created during construction.
By default the object is created with:

    {
    agent => "PX::API/$VERSION"
    timeout => 60
    }


=back


=head1 DEPENDENCIES

L<Class::Accessor>
L<LWP::UserAgent>
L<Digest::MD5>

=head1 SEE ALSO

L<PX::API::Request>
L<PX::API::Response>
L<http://www.peekshows.com>
L<http://services.peekshows.com>

=head1 AUTHOR

Anthony Decena  C<< <anthony@1bci.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Anthony Decena C<< <anthony@1bci.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
