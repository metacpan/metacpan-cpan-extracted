package Rapid7::NeXpose::API;

use warnings;
use strict;

use XML::Simple;
use LWP::UserAgent;
use HTTP::Request::Common;

=head1 NAME

Rapid7::NeXpose::API - Communicate with NeXpose via XML NeXpose API v1.1

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

This is Perl interface for communication with NeXpose scanner over API v1.1.
You can start, stop, pause and resume scan. Watch progress and status of
scan, download report, etc.

Currently you can only start scan, list sites and delete site.

    use Rapid7::NeXpose::API;

    my $n = Rapid7::NeXpose::API->new(
                    url=>'https://localhost:3780',password=>'test');
    my $sl = $n->sitelist();
    print "Starting scan for first site found: ";
    printf "%s with ID: %s\n", $sl->[0]->{'name'}, $sl->[0]->{'id'};
    $n->sitescan($sl->[0]->{'id'});

=head1 NOTICE

This CPAN module uses LWP for communicating with NeXpose over its API via https.
Therefore, make sure that you have Net::SSL (provided by Crypt::SSLeay):
http://search.cpan.org/perldoc?Crypt::SSLeay
or IO::Socket::SSL:
http://search.cpan.org/perldoc?IO::Socket::SSL

If you think you have login problems, check this first!

=head1 METHODS

=head2 new ( [key=>value, key2=>value2, ...] )

creates new object Rapid7::NeXpose::API

    my $n = Rapid7::NeXpose::API->new(
                    url=>'https://localhost:3780', debug=>1, 
                    user=>'user', password=>'test', nologin=>1
            );

=cut
sub new {
	# Check for common user mistake - taken from LWP
	Carp::croak("Options to Rapid7::NeXpose::API constructor should be key/value pairs, not hash reference")
	if ref($_[1]) eq 'HASH';

	my($class, %cnf) = @_;
	my $self;

	$self->{_url} = delete $cnf{url}; 
	if (!defined($self->{_url}) or $self->{_url} eq '') {
		$self->{_url}='https://localhost:3780/';
	} elsif (substr($self->{_url},-1,1) ne '/') {
		$self->{_url}= $self->{_url}.'/';
	}

	$self->{_urlapi} = delete $cnf{urlapi}; 
	if (!defined($self->{_urlapi})) {
		$self->{_urlapi}=$self->{_url}."api/1.1/xml";
	}

	$self->{_user} = delete $cnf{user}; 
	$self->{_user} = "nxadmin" unless defined $self->{_user};

	$self->{_password} = delete $cnf{password}; 

	$self->{'_debug'} = 0 unless defined $cnf{'debug'};

	$self->{_ua} = LWP::UserAgent->new;
	if ($self->{'_debug'}) {
		$self->lwpdebug();
	}

	bless $self, $class;
	unless ($cnf{nologin} and !defined($self->{_password})) {
		$self->login();
	}
	return $self;
}

=head2 url ( [$nexpose_url] )

get/set NeXpose base URL
=cut
sub url {
	my ( $self, $url ) = @_;
	$self->{_url} = $url if defined($url);
	return ( $self->{_url} );
}

=head2 urlapi ( [$nexpose_url_api] )

get/set NeXpose API URL
=cut
sub urlapi {
	my ( $self, $urlapi ) = @_;
	$self->{_urlapi} = $urlapi if defined($urlapi);
	return ( $self->{_urlapi} );
}

=head2 user ( [$user] )

set NeXpose credentials, returns $user
=cut
sub user {
	my ( $self, $user ) = @_;
	$self->{_user} = $user if defined($user);
	return ( $self->{_user} );
}

=head2 password ( [$password])

set NeXpose credentials, returns $password
=cut
sub password {
	my ( $self, $password ) = @_;
	$self->{_password} = $password if defined($password);
	return ( $self->{_password} );
}

=head2 session ( [$session])

set NeXpose session-id, returns $session
=cut
sub session {
	my ( $self, $session ) = @_;
	$self->{_session} = $session if defined($session);
	return ( $self->{_session} );
}

=head2 syncid ( [$syncid])

set NeXpose sync-id, returns $id
=cut
sub syncid {
	my ( $self, $syncid ) = @_;
	my $sid;
	if (defined($syncid)) {
		$sid = $syncid;
	} else {
		$sid=int(rand(65535));
	}
	return ( $sid );
}

=head2 lwpdebug 

get/set LWP debugging
=cut
sub lwpdebug {
	my ( $self ) = @_;
	my $ua = $self->{_ua};
	$ua->add_handler("request_send",  sub { shift->dump; return });
	$ua->add_handler("response_done", sub { shift->dump; return });
}

=head2 xml_request ( <$req> )

perform XML request to nexpose 
=cut
sub xml_request {
	my ( $self, $req ) = @_;

	my $xml = XMLout($req, RootName => '', XMLDecl => '<?xml version="1.0" encoding="UTF-8"?>');
	
	if ($self->{'_debug'}>2) {
		print STDERR $xml."\n";
	} 
	my $cont = $self->http_api ($xml);
	my $xmls;
	eval {
	$xmls=XMLin($cont, KeepRoot => 1, ForceArray => 1, KeyAttr => '', SuppressEmpty => '' );
	} or return '';
	return ($xmls);
}

=head2 http_api <$post_data> )

perform api request to nexpose and return content
=cut
sub http_api {
	my ( $self, $post_data ) = @_;

	my $ua = $self->{_ua};
	my $r = POST $self->urlapi(), 'Content-Type'=>'text/xml', Content=>$post_data;
	my $result = $ua->request($r);
	if ($result->is_success) {
		return $result->content;
	} else {
		return '';
	}
}

=head2 login ()

login to NeXpose 
=cut
sub login {
	my ( $self ) = @_;
	my $hashref = { 'LoginRequest' => {
	'sync-id' => $self->syncid(),
	'user-id' => $self->user(),
	'password' => $self->password()
	} };
	my $xmlh = $self->xml_request($hashref);
	if ($xmlh->{'LoginResponse'}->[0]->{'success'}==1) {
		$self->session($xmlh->{'LoginResponse'}->[0]->{'session-id'});
		return $xmlh; 
	} else { 
		return ''
	}
}

=head2 logout ()

sends logout request, returns 1 on success, 0 on failure
=cut

sub logout {
	my ( $self ) = @_;

	my $sid=int(rand(65535));
	my $hashref = { 'LogoutRequest' => {
	'sync-id' => $self->syncid(),
	'session-id' => $self->session()
	} };
	
	my $xmlh = $self->xml_request($hashref);
	if ($xmlh->{'LogoutResponse'}->[0]->{'success'}==1) {
		return 1; 
	} else {
		return 0;
	}
}

=head2 sitelist ()

list sites, returns list of sites
=cut
sub sitelist {
	my ( $self ) = @_;
	my $hashref = { 'SiteListingRequest' => {
	'sync-id' => $self->syncid(),
	'session-id' => $self->session()
	} };
	my $xmlh = $self->xml_request($hashref);
	if ($xmlh->{'SiteListingResponse'}->[0]->{'success'}==1) {
		return $xmlh->{'SiteListingResponse'}->[0]->{'SiteSummary'};
	} else { 
		return ''
	}
}

=head2 sitescan ( $siteid )

scan site specified by ID
=cut
sub sitescan {
	my ( $self, $siteid ) = @_;
	my $hashref = { 'SiteScanRequest' => {
	'sync-id' => $self->syncid(),
	'session-id' => $self->session(),
	'site-id' => $siteid
	} };
	my $xmlh = $self->xml_request($hashref);
	if ($xmlh->{'SiteScanResponse'}->[0]->{'success'}==1) {
		my $hashref={
		'scan-id' => $xmlh->{'Scan'}->[0]->{'scan-id'},
		'engine-id' => $xmlh->{'Scan'}->[0]->{'engine-id'}
		};
		return $hashref;
	} else { 
		return ''
	}
}

=head2 sitedelete ( $siteid ) 

delete site specified by ID
=cut
sub sitedelete {
	my ( $self, $siteid ) = @_;
	my $hashref = { 'SiteDeleteRequest' => {
	'sync-id' => $self->syncid(),
	'session-id' => $self->session(),
	'site-id' => $siteid
	} };
	my $xmlh = $self->xml_request($hashref);
	if ($xmlh->{'SiteDeleteResponse'}->[0]->{'success'}==1) {
		return 1;
	} else { 
		return 0;
	}
}

=head2 DESTROY 

destructor, calls logout method on destruction
=cut
sub DESTROY {
	my ($self) = @_;
	$self->logout();
}

=head1 AUTHOR

Vlatko Kosturjak, C<< <kost at linux.hr> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rapid7-nexpose-api at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Rapid7-NeXpose-API>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Rapid7::NeXpose::API


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Rapid7-NeXpose-API>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Rapid7-NeXpose-API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Rapid7-NeXpose-API>

=item * Search CPAN

L<http://search.cpan.org/dist/Rapid7-NeXpose-API/>

=back


=head1 REPOSITORY

Repository is available on GitHub: https://github.com/kost/rapid7-nexpose-api-perl

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Vlatko Kosturjak.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Rapid7::NeXpose::API
