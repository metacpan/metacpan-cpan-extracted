#! perl

package SugarSync::API;

use warnings;
use strict;
use v5.10;

use LWP::UserAgent;
use Carp;
use XML::Simple;
use Data::Dumper;

use constant APIURL  => 'https://api.sugarsync.com';

my $debug = 0;

=head1 NAME

SugarSync::API - Basic API to SugarSync cloud file sharing.

=cut

our $VERSION = '0.07';

=head1 SYNOPSIS

    use SugarSync::API;
    my $sushi = SugarSync::API->new( $username, $password );
    $sushi->get_userinfo;
    say "My SugarSync nickname is ", $sushi->{nickname};

Data structures are discussed in L<SugarSync::API::Data>.

=head1 METHODS

=head2 new [ username, password ]

Create a new API object.

If you pass a username and password, the object will be authorized.
Otherwise, an explicit call to the method C<get_auth> is required.

=cut

sub new {
    my ( $pkg, $user, $pass, $akeyid, $pacckey, $appid ) = @_;
    my $self = {};
    bless $self, $pkg;

    # Developer keys.
    # IMPORTANT: If you're going to develop your own application please
    # register with SugarSync and obtain your own access keys.
    $self->{_akeyid}  = $akeyid  // 'ODxxxxxxxxxxxxxxxxxxxxxxxxx';
    $self->{_pacckey} = $pacckey // 'OTxxxxxxxxxxxxxxxxxxxxxxxxx';
    $self->{_appid}   = $appid   // '/sc/xxxxxxxxxxxxxxxxxxxxxxx';

    if ( defined($user) and defined($pass) ) {
	$self->get_auth( $user, $pass );
    }
    $self;
}

sub api_url {
    # Convenience: API url plus possible addition.
    my ( $self, $extra ) = @_;
    my $ret = APIURL;
    $ret .= "/" . $extra if $extra;
    $ret;
}

=head2 get_auth( username, password )

Get the authorization token for subsequent calls and stores it
internally to be used with other method calls.

Returns the authorization token.

=cut

sub get_auth {
    my ( $self, $username, $password ) = @_;

    my $ua = LWP::UserAgent->new( agent => 'perl post' );

    unless ( $self->{_authdata}->[2] ) {
	# Use stored information if available.
	$username //= $self->{_authdata}->[0];
	$password //= $self->{_authdata}->[1];

	# Strictly speaking, we need to encode the fields into UTF-8.
	# Currently, assume ASCII...
	my $msg = <<EOD;
<?xml version="1.0" encoding="UTF-8"?>
<appAuthorization>
    <username>$username</username>
    <password>$password</password>
    <application>@{[ $self->{_appid} ]}</application>
    <accessKeyId>@{[ $self->{_akeyid} ]}</accessKeyId>
    <privateAccessKey>@{[ $self->{_pacckey} ]}</privateAccessKey>
</appAuthorization>
EOD

	# Alternatively, use XML::Writer.
	# A bit overkill since this is the only piece of XML we'll need.
	# my $xml = XML::Writer->new( OUTPUT => \$msg );
	# $xml->startTag("authRequest");
	# $xml->dataElement( "username",         $username );
	# $xml->dataElement( "password",         $password );
	# $xml->dataElement( "accessKeyId",      AKEYID );
	# $xml->dataElement( "privateAccessKey", PACCKEY );
	# $xml->endTag("authRequest");
	# $xml->end;

	my $res = $ua->post( $self->api_url('app-authorization'),
			     Content_Type => 'text/xml',
			     Content => $msg );

	# Returns "201 Created" upon success.
	Carp::croak( $res->error_as_HTML ) unless $res->is_success;
	warn( $res->as_string ) if $debug;
	my $loc = $1 if $res->as_string =~ /Location:\s+(.*)$/m;
	Carp::croak("Failed to get a refresh token") unless $loc;

	# Store information so we can re-authenticate when the token expires.
	# Currently, 1 hour.
	$self->{_authdata} = [ $username, $password, $loc ];
    }

    my $loc = $self->{_authdata}->[2];
    my $msg = <<EOD;
<?xml version="1.0" encoding="UTF-8"?>
<tokenAuthRequest>
    <refreshToken>$loc</refreshToken>
    <accessKeyId>@{[ $self->{_akeyid} ]}</accessKeyId>
    <privateAccessKey>@{[ $self->{_pacckey} ]}</privateAccessKey>
</tokenAuthRequest>
EOD

    my $res = $ua->post( $self->api_url('authorization'),
			 Content_Type => 'text/xml',
			 Content => $msg );

    Carp::croak( $res->error_as_HTML ) unless $res->is_success;
    warn( $res->as_string ) if $debug;
    $loc = $1 if $res->as_string =~ /Location:\s+(.*)$/m;
    Carp::croak("Failed to get an access token") unless $loc;

    # Store authentication token.
    $self->{_auth} = $loc;
}

=head2 get_userinfo

Retrieves the user info, e.g., quota, shared folders and so on.

=cut

sub get_userinfo {
    my ( $self ) = @_;
    $self->{userinfo} = 'xxx';	# prevent recursion
    my $ui = $self->get_url_xml( $self->api_url('user') );
    $self->{userinfo} = $ui;
    $self->{$_} = $ui->{$_}
      for qw(nickname username receivedShares syncfolders);
}

=head2 get_receivedShares

Returns the data for the shared folders.

=cut

sub get_receivedShares {
    my ( $self ) = @_;

    # Make sure we have user info.
    $self->get_userinfo unless $self->{userinfo};

    $self->{receivedShare} = $self->get_url_xml( $self->{receivedShares} )->{receivedShare};
}

=head2 get_receivedShare( $share )

Retrieves detailed information for a shared folder.

=cut

sub get_receivedShare {
    my ( $self, $share ) = @_;
    $self->get_url_xml($share);
}

=head2 get_files( $folder )

Retrieves the files data for a folder.

=cut

sub get_files {
    my ( $self, $folder ) = @_;
    my $res = $self->get_url_xml($folder);
    if ( $res->{hasMore} eq 'false' ) {
	return $res->{file};	# ????
    }
    else {
	croak("Files has more -- NYI");
    }
}

=head2 get_collections( $folder )

Retrieves the collections data for a folder.

=cut

sub get_collections {
    my ( $self, $folder ) = @_;
    my $res = $self->get_url_xml($folder);
    if ( $res->{hasMore} eq 'false' ) {
	return $res->{collection};
    }
    else {
	croak("Collection has more -- NYI");
    }
}

=head2 get_url_data( $url )

Retrieves the raw data for a given url.

Handles basic errors, like 401 (authentication token expired) and
temporary server failures.

=cut

my $error;

sub get_url_data {

    # Get the data for the url which must be valid XML.
    # This is the central query function.
    # Upon some other errors, it will retry.
    # Upon auth errors, it will try to re-authenticate.

    my ( $self, $url ) = @_;

    unless ( $url ) {
	local( $Data::Dumper::Indent ) = 1;
	warn Data::Dumper->Dump( [$self], [qw(object)] );
	Carp::cluck( "No URL?" );
	return;
    }

    # Make sure we have user info.
    $self->get_userinfo unless $self->{userinfo};

    my $ua = LWP::UserAgent->new( agent => 'perl get' );
    $ua->default_header( 'Authorization', $self->{_auth} );
    $ua->default_header( 'Host', 'api.sugarsync.com' );

    my $res = $ua->get($url);
    unless ( $res->is_success ) {
	my $line = $res->status_line;
	if ( $line =~ /^(401)/ && $error++ < 20 ) {
	    # Authentication token expired.
	    warn("Reauth... ($line) #$error\n");
	    sleep( 1 );
	    $self->get_auth;
	    return $self->get_url_data($url);
	}
	elsif ( $line =~ /^(50\d)/ && $error++ < 20 ) {
	    # Server unavailable of some sort.
	    warn("Retry... ($line) #$error\n");
	    sleep( $error || 1);
	    return $self->get_url_data($url);
	}
	Carp::croak( $line );
    }
    $error = 0;
    return $res->content;
}

=head2 get_url_xml( $url, $dump )

Retrieves the XML data for a given url and returns it as a Perl structure.

Optionally, dumps (using Data::Dumper) the structure to STDERR.

=cut

sub get_url_xml {

    # Get the data for the url which must be valid XML.
    # Return the XML data as a Perl structure.
    # Optionally, dump the structure for debugging.

    my ( $self, $url, $ddump ) = @_;

    local( $Data::Dumper::Indent ) = 1;

    my $res = XMLin( $self->get_url_data($url) );
    Carp::croak( "Not a HASH result: $res")
	unless UNIVERSAL::isa( $res, 'HASH' );
    warn Data::Dumper->Dump( [$res], [qw(xml_result)] ) if $ddump;

    # Make single-element list for lists, if necessary.
    if ( keys(%$res) == 1 ) {
	my $k = (keys(%$res))[0];
	unless ( UNIVERSAL::isa( $res->{$k}, 'ARRAY' ) ) {
	    $res = { $k => [ $res->{$k} ] };
	    warn Data::Dumper->Dump( [$res], [qw(xml_cooked)] ) if $ddump;
	}
    }

    return $res;
}

=head2 delete_url

Experimental.

=cut

sub delete_url {
    my ( $self, $url ) = @_;

    # Make sure we have user info.
    $self->get_userinfo unless $self->{userinfo};

    my $ua = LWP::UserAgent->new( agent => 'perl get' );
    $ua->default_header( 'Authorization', $self->{_auth} );
    $ua->default_header( 'Host', 'api.sugarsync.com' );

    require HTTP::Request;
    my $req = HTTP::Request->new( DELETE => $url );
    my $res = $ua->request($req);
    unless ( $res->is_success ) {
	my $line = $res->status_line;
	if ( $line =~ /^(401)/ && $error++ < 10 ) {
	    # Authentication token expired.
	    warn("Reauth... ($line) #$error\n");
	    sleep( $error || 1 );
	    $self->get_auth;
	    return $self->delete_url($url);
	}
	elsif ( $line =~ /^(50\d)/ && $error++ < 10 ) {
	    # Server unavailable of some sort.
	    warn("Retry... ($line) #$error\n");
	    sleep( $error || 1);
	    return $self->delete_url($url);
	}
	Carp::croak( $line );
    }
    $error = 0;
    return $res->content;
}

use Time::Local;

sub ts_deparse {

    # Deparse a 2011-08-28T23:03:48.000-07:00 into a Unix epoch time.

    my ( $self, $ts ) = @_;
    Carp::croak("Invalid timestamp: $ts")
	unless $ts =~ /^(\d\d\d\d)-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d).(\d+)-(\d+):(\d+)$/;
    my $t = timegm( $6, $5, $4, $3, $2-1, $1 ) + 3600*$8 + 60*$9;
    #warn("$ts -> ".localtime($t)."\n");
    return $t;
}

1;

=SEE ALSO

L<SugarSync::API::Data>

=head1 AUTHOR

Johan Vromans, C<< <jv at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sugarsync-api at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SugarSync-API>. I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SugarSync::API
    perldoc SugarSync::API::Data

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SugarSync-API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SugarSync-API>

=item * Search CPAN

L<http://search.cpan.org/dist/SugarSync-API>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Mark Willis for producing a non-functional php module.

=head1 COPYRIGHT & LICENSE

Copyright 2011 Johan Vromans, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
