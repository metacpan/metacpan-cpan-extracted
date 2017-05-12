#!/usr/bin/perl -w
#
# Here we test the presence of optional modules,
# needed for some registries in Net::DRI but not all of them,
# and we warn the user if they are not present

use Test::More tests => 11;

SKIP: {
	eval { require Net::SMTP; };
	skip 'Module Net::SMTP is not installed, you need it if you want to use Net::DRI for: AFNIC (emails)',1 if $@;
	require_ok('Net::DRI::Transport::SMTP');
}

SKIP: {
	eval { require MIME::Entity; };
	skip 'Module MIME::Entity is not installed, you need it if you want to use Net::DRI for: AFNIC (emails)',2 if $@;
	require_ok('Net::DRI::Protocol::AFNIC::Email::Message');
	require_ok('Net::DRI::Protocol::AFNIC::Email'); ## depends on Message
}

SKIP: {
	eval { require XMLRPC::Lite; };
	skip 'Module XMLRPC::Lite is not installed, you need it if you want to use Net::DRI for: Gandi (WebServices)',2 if $@;
	require_ok('Net::DRI::Transport::HTTP::XMLRPCLite');
        require_ok('Net::DRI::Protocol::Gandi::WS::Connection'); ## depends on XMLRPC::Data
}

SKIP: {
	eval { require SOAP::Lite; };
	skip 'Module SOAP::Lite is not installed, you need it if you want to use Net::DRI for: AFNIC (WebServices), BookMyName (WebServices)',1 if $@;
	require_ok('Net::DRI::Transport::HTTP::SOAPLite');
}

SKIP: {
	eval { require SOAP::WSDL; }; ## also needs SOAP::Lite
	skip('Module SOAP::WSDL is not installed, you need it if you want to use Net::DRI for: OVH (WebServices)',1) if $@;
	require_ok('Net::DRI::Transport::HTTP::SOAPWSDL');
}

SKIP: {
	eval { require LWP::UserAgent; };
	skip('Module LWP::UserAgent is not installed, you need it if you want to use Net::DRI for: OpenSRS (XCP), .PL (EPP over HTTPS)',1) if $@;
	require_ok('Net::DRI::Transport::HTTP');
}

SKIP: {
	eval { require HTTP::Request; };
	skip('Module HTTP::Request is not installed, you need it if you want to use Net::DRI for: .PL (EPP over HTTPS) .IT (EPP over HTTPS)',1) if $@;
	require_ok('Net::DRI::Protocol::EPP::Extensions::HTTP');
}

SKIP: {
	eval { require Digest::MD5; };
	skip('Module Digest::MD5 is not installed, you need it if you want to use Net::DRI for: OpenSRS (XCP)',1) if $@;
        eval { require HTTP::Request; };
        skip('Module HTTP::Request is not installed, you need it if you want to use Net::DRI for: OpenSRS (XCP)',1) if $@;
	require_ok('Net::DRI::Protocol::OpenSRS::XCP::Connection');
}

SKIP: {
	eval { require IO::Uncompress::RawInflate; };
	skip('Module IO::Uncompress::RawInflate is not installed, you need it if you want to use Net::DRI for: .DE (IRIS DCHK over LWZ)',1) if $@;
	eval { require Net::DNS; };
	skip('Module Net::DNS is not installed, you need it if you want to use Net::DRI for: .DE (IRIS DCHK over LWZ)',1) if $@;
	require_ok('Net::DRI::Protocol::IRIS::LWZ');
}

exit 0;
