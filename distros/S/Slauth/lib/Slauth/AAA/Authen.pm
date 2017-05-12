# Slauth authentication

package Slauth::AAA::Authen;

use strict;
#use warnings FATAL => 'all', NONFATAL => 'redefine';

use Slauth::Config;
use Slauth::Config::Apache;
use Slauth::Storage::Session_DB;
use Slauth::Storage::User_DB;
use CGI::Cookie;
use CGI::Carp qw(fatalsToBrowser);
use Exporter 'import';
use APR::Pool;
use APR::Table;
BEGIN {
        if ( $Slauth::Config::Apache::MOD_PERL >= 2 ) {
                require Apache2::Response;
                require Apache2::RequestRec;
                require Apache2::RequestUtil;
                require Apache2::RequestIO;
                require Apache2::Const;
                import Apache2::Const qw( OK DECLINED HTTP_UNAUTHORIZED );
                require Apache2::Access;
        } else {
                require Apache2;
                require Apache::RequestRec;
                require Apache::RequestIO;
                require Apache::RequestUtil;
                require Apache::Const;
                import Apache::Const qw( OK DECLINED HTTP_UNAUTHORIZED );
        }
}

sub debug { Slauth::Config::debug; }

sub handler {
	my $r = shift;
	my $auth_type = $r->auth_type;

	# instantiate a Slauth configuration object
	my $config = Slauth::Config->new( $r );

	# check if Slauth is on in this directory
	debug and print STDERR "entering Slauth::AAA::Authen enabled="
		.(Slauth::Config::Apache::isEnabled($r) ? "yes" : "no" )."\n";
	Slauth::Config::Apache::isEnabled($r) or return DECLINED;

	# we can only do Slauth cookie or Basic authentication
	debug and print STDERR "entering Slauth::AAA::Authen auth_type="
		.$auth_type."\n";
	( $auth_type eq "Slauth" )
		or ( $auth_type eq "Basic" )
		or return DECLINED;
	debug and print STDERR "entering Slauth::AAA::Authen uri=".$r->uri."\n";

	#
	# check user
	#

	# handle Basic HTTP authentication
	debug and print STDERR "Slauth::AAA::Authen: auth_type=$auth_type\n";
	if ( $auth_type eq "Basic" ) {
		my ($status, $password) = $r->get_basic_auth_pw;

		# was the data good?  check the password...
		if ( $status == &OK ) {
			# authentication data received
			if ( Slauth::Storage::User_DB::check_pw(
				$r->user, $password, $config ))
			{
				# good password
				debug and print STDERR "Slauth::AAA::Authen: Basic password OK\n";
				return OK;
			} else {
				# bad password
				debug and print STDERR "Slauth::AAA::Authen: Basic password denied\n";
				$r->realm( $config->get( "realm" ));
				return HTTP_UNAUTHORIZED;
			}

		# was the data bad?  return the error
		# (DECLINED means no data so we fall through to check cookies
		} elsif ( $status != &DECLINED ) {
			debug and print STDERR "Slauth::AAA::Authen: Basic password error $status\n";
			return $status;
		}
	}

	# handle Slauth cookie authentication
	my %cookies = CGI::Cookie->fetch($r);
	if ( defined $cookies{"slauth_session"}) {
		debug and print STDERR "Slauth::AAA::Authen: found cookie\n";
		my $value = $cookies{"slauth_session"}->value;
		debug and print STDERR "Slauth::AAA::Authen: value=$value\n";
		my $expires = $cookies{"slauth_session"}->expires;
		#if (( ! defined $expires ) or $expires < time ) {
		#	# we always use an expiration so this is bogus
		#	# if it doesn't have on if it's expired
		#	debug and print STDERR "Slauth::AAA::Authen: no expiration\n";
		#	return HTTP_UNAUTHORIZED;
		#}
		my $login;
		if ( $login = Slauth::Storage::Session_DB::check_cookie( $value, $config )) {
			debug and print STDERR "Slauth::AAA::Authen: OK login=$login\n";
			$r->user($login);
			return OK;
		}
	}
	debug and print STDERR "Slauth::AAA::Authen: failure\n";

	$r->note_basic_auth_failure;
	return HTTP_UNAUTHORIZED;
}

1;
