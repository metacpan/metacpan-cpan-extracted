package StartCom::API;

#
# StartCom API connector
# author, (c): Philippe Kueck <projects at unixadm dot org>
#

use strict;
use warnings;

use IO::Socket::SSL;
use LWP::UserAgent;
use JSON;
use MIME::Base64;

our $VERSION = "0.2";

sub new {bless {'success' => 1}, $_[0]}

sub success {$_[0]->{'success'}}
sub errormsg {$_[0]->{'error'}}

sub tokenID {
	return $_[0]->{'tokenID'} unless $_[1];
	$_[0]->{'tokenID'} = $_[1];
	1
}

sub client_cert {
	return $_[0]->{'clientCert'} unless $_[1];
	return unless -r $_[1];
	$_[0]->{'clientCert'} = $_[1];
	1
}

sub client_key {
	return $_[0]->{'clientKey'} unless $_[1];
	return unless -r $_[1];
	$_[0]->{'clientKey'} = $_[1];
	1
}

sub certificate {$_[0]->{'certificate'}}
sub intermediate {$_[0]->{'intermediate'}}
sub orderID {$_[0]->{'orderID'}}
sub orderNo {$_[0]->{'orderNo'}}
sub testmode {$_[0]->{'test'} = $_[1]}

sub prepareUA {
	return 1 if $_[0]->{'ua'};
	unless ($_[0]->{'clientCert'} && $_[0]->{'clientKey'}) {
		$_[0]->{'success'} = 0;
		$_[0]->{'error'} = "either client certificate or key is not set";
		return 0
	}
	$_[0]->{'ua'} = new LWP::UserAgent(
		'agent' => 'StartCom::API tester',
		'ssl_opts' => {
			'SSL_verify_mode' => SSL_VERIFY_PEER,
			'SSL_use_cert'    => 1,
			'SSL_cert_file'   => $_[0]->{'clientCert'},
			'SSL_key_file'    => $_[0]->{'clientKey'}
		}
	);
	unless ($_[0]->{'ua'}) {
		$_[0]->{'success'} = 0;
		$_[0]->{'error'} = "could not set up user agent";
		return 0
	}
	1
}

sub processResponse {
	my $res = decode_json $_[1];
	unless ($res->{'status'} == 1) {
		$_[0]->{'success'} = 0;
		$_[0]->{'error'} = sprintf "%d: %s",
			$res->{'errorCode'}, $res->{'shortMsg'};
		return
	}
	unless (exists $res->{'data'}->{'orderStatus'}) {
		$_[0]->{'success'} = 0;
		$_[0]->{'error'}  = "did not get an orderStatus response";
		return
	}

	if ($res->{'data'}->{'orderStatus'} == 1) {
		# Pending
		$_[0]->{'success'} = 1;
		$_[0]->{'error'} = 'certificate is pending';
		$_[0]->{'orderID'} = $res->{'data'}->{'orderID'};
		$_[0]->{'orderNo'} = $res->{'data'}->{'orderNo'};
	} elsif ($res->{'data'}->{'orderStatus'} == 3) {
		# Rejected
		$_[0]->{'success'} = 0;
		$_[0]->{'error'} = "certificate was rejected";
	} elsif ($res->{'data'}->{'orderStatus'} == 2) {
		# Issued
		$_[0]->{'success'} = 1;
		$_[0]->{'error'} = undef;
		$_[0]->{'orderID'} = $res->{'data'}->{'orderID'};
		$_[0]->{'orderNo'} = $res->{'data'}->{'orderNo'};
		$_[0]->{'certificate'} =
			decode_base64 $res->{'data'}->{'certificate'};
		$_[0]->{'intermediate'} =
			decode_base64 $res->{'data'}->{'intermediateCertificate'};
	} else {
		# unknown
		$_[0]->{'success'} = 0;
		$_[0]->{'error'} = "unknown orderStatus ".
			$res->{'data'}->{'orderStatus'}
	}
}

sub apply {
	return unless $_[0]->prepareUA;

	unless ($_[0]->{'tokenID'}) {
		$_[0]->{'success'} = 0;
		$_[0]->{'error'} = "tokenID is not set";
		return
	}

	unless ($_[1]->{'domains'} && ref $_[1]->{'domains'} eq 'ARRAY') {
		$_[0]->{'success'} = 0;
		$_[0]->{'error'} = "domains not set or not an array";
		return
	}

	unless ($_[1]->{'csr'}) {
		$_[0]->{'success'} = 0;
		$_[0]->{'error'} = "csr is missing";
		return
	}

	my $resp = $_[0]->{'ua'}->post(
		'https://api'.($_[0]->{'test'}?'test':'').'.startssl.com/', {
			'RequestData' => encode_json {
				'tokenId' => $_[0]->{'tokenID'},
				'actionType' => 'ApplyCertificate',
				'certType' => $_[1]->{'certType'} || 'DVSSL',
				'domains' => join(",", @{$_[1]->{'domains'}}),
				'csr' => $_[1]->{'csr'}
			}
		}
	);
	unless ($resp->is_success) {
		$_[0]->{'success'} = 0;
		$_[0]->{'error'} = $resp->status_line;
		return
	}
	$_[0]->processResponse($resp->content);
	$_[0]->{'success'}
}

sub retrieve {
	return unless $_[0]->prepareUA;

	unless ($_[0]->{'tokenID'}) {
		$_[0]->{'success'} = 0;
		$_[0]->{'error'} = "tokenID is not set";
		return
	}

	unless ($_[1] && $_[1] =~ /^[a-f0-9]{8}-(?:[a-f0-9]{4}-){3}[a-f0-9]{12}$/) {
		$_[0]->{'success'} = 0;
		$_[0]->{'error'} = "wrong orderID format";
		return
	}

	my $resp = $_[0]->{'ua'}->post(
		'https://apitest.startssl.com/', {
			'RequestData' => encode_json {
				'tokenId' => $_[0]->{'tokenID'},
				'actionType' => 'RetrieveCertificate',
				'orderID' => $_[1]
			}
		}
	);
	return unless $resp->is_success;
	$_[0]->processResponse($resp->content);
	$_[0]->{'success'}
}

1;

__END__

=head1 NAME

StartCom::API - a connector for StartAPI

=head1 VERSION

0.2

=head1 SYNOPSIS

 use StartCom::API;
 $api = new StartCom::API;
 $api->tokenID($mytokenID);
 $api->client_cert($pathtoclientcert);
 $api->client_key($pathtoclientkey);
 $rc = $api->retrieve($myOrderID);
 $rc = $api->apply(...);
 $rc = $api->success;
 $msg = $api->errormsg;
 $cert = $api->certificate;
 $intermed = $api->intermediate;
 $myOrderID = $api->orderID;
 $myOrderNum = $api->orderNo;

=head1 DESCRIPTION

This module allows to connect to the api of StartCom in order to generate or retrieve certificates.

Please see also L<the StartAPI documentation|https://startssl.com/StartAPI/Docs>.

=head1 METHODS

=over 4

=item C<$api = new StartCom::API>

The constructor. Returns a C<StartCom::API> object.

=item C<$api-E<gt>tokenID($key)>

Sets or gets the API key.

=item C<$api-E<gt>client_cert($pathtoclientcert)>

Sets or gets the path to the client certificate file (PEM).

=item C<$api-E<gt>client_key($pathtoclientkey)>

Sets or gets the path to the client key file.

=item C<$api-E<gt>retrieve($orderID)>

Retrieves the certificate corresponding to the C<orderID> and stores it in this object.

Returns 1 on success, 0 or undef on failure.

=item C<$api-E<gt>apply({'certType' =E<gt> '...', 'CSR' =E<gt> '...', ...})>

Applies for a new certificate and, if successful, stores it in this object.

See L<StartAPI documentation|https://startssl.com/StartAPI/Docs#ApplyCertificate> for parameters.

Returns 1 on success, 0 or undef on failure.

=item C<$api-E<gt>success>

Checks whether or not the last call was successful.

=item C<$api-E<gt>errormsg>

Returns the error message if the last call was unsuccessful.

=item C<$api-E<gt>certificate>

If the last call was successful and the certificate was issued, this method returns the certificate.

=item C<$api-E<gt>intermediate>

If the last call was successful and the certificate was issued, this method returns the intermediate certificate.

=item C<$api-E<gt>orderID>

If the last call was successful and the certificate was issued, this method returns the certificate order ID which can be used in conjunction with C<$api-E<gt>retrieve>.

=item C<$api-E<gt>orderNo>

If the last call was successful and the certificate was issued, this method returns the certificate ordering number which is shown in StartCom's web interface.

=item C<$api-E<gt>testmode>

When set to 0, which is the default, the api calls L<https://api.startssl.com>, else L<https://apitest.startssl.com>.

=back

=head1 DEPENDENCIES

=over 8

=item * L<LWP::UserAgent>

=item * L<IO::Socket::SSL>

=item * L<JSON>

=item * L<MIME::Base64>

=back

=head1 AUTHOR

Philippe Kueck <projects at unixadm dot org>

=cut

