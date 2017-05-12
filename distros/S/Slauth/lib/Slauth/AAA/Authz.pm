# Slauth authentication

package Slauth::AAA::Authz;

use strict;
#use warnings FATAL => 'all', NONFATAL => 'redefine';

use Slauth::Config;
use Slauth::Config::Apache;
use Slauth::Storage::User_DB;
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
use CGI::Carp qw(fatalsToBrowser);

sub debug { $Slauth::Config::debug; }

sub handler {
	my $r = shift;
	my $requires = $r->requires;
	my $auth_type = $r->auth_type;
	my ( $req );

	# instantiate a Slauth configuration object
	my $config = Slauth::Config->new( $r );

        # check if Slauth is on in this directory
	Slauth::Config::Apache::isEnabled($r) or return DECLINED;

	# verify that we're configured to operate here
	#( $auth_type eq "Slauth" ) or return DECLINED;
	debug and print STDERR "entering Slauth::AAA::Authz\n";

	for $req (@$requires) {
		( defined $req->{requirement}) or next;
		my ( $type, @subs ) = split ( /\s+/, $req->{requirement});
		if ( $type eq "user" ) {
			$r->user or return HTTP_UNAUTHORIZED;
			my $user;
			foreach $user ( @subs ) {
				if ( $user eq $r->user ) {
					debug and print STDERR "Slauth::AAA::Authz: user granted\n";
					return OK;
				}
			}
		} elsif ( $type eq "group" ) {
			$r->user or return HTTP_UNAUTHORIZED;
			my ( $user_login, $user_pw_hash, $user_salt,
				$user_name, $user_email, $user_groups )
				= Slauth::Storage::User_DB::get_user($r->user,
					$config );
			my @groups = split ( /,/, $user_groups );
			my ( $group, $sub_group );
			foreach $group ( @groups ) {
				foreach $sub_group ( @subs ) {
					if ( $group eq $sub_group ) {
						debug and print STDERR "Slauth::AAA::Authz: group granted\n";
						return OK;
					}
				}
			}
		} elsif ( $type eq "valid-user" ) {
			if ( defined $r->user ) {
				debug and print STDERR "Slauth::AAA::Authz: valid-user granted\n";
				return OK;
			}
		}
	}

	debug and print STDERR "Slauth::AAA::Authz: denied\n";
	$r->note_basic_auth_failure;
	return HTTP_UNAUTHORIZED;
}

1;
