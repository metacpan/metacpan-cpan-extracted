# Slauth storage interface to DB4 library

package Slauth::Storage::Session_DB;

use strict;
#use warnings FATAL => 'all', NONFATAL => 'redefine';
use base "Slauth::Storage::DB";
use Slauth::Config;
use Slauth::Storage::User_DB;
use Digest::MD5 'md5_base64';

sub debug { Slauth::Config::debug; }

# instantiate a new object
sub new
{
	my $class = shift;
	my $self = {};
	debug and print STDERR "debug: Slauth::Storage::Session_DB new\n";
	bless $self, $class;
	$self->initialize(@_);
	return $self;
}

#
# the record structure is as follows:
#   0	login name
#   1   session hash - verbatim from cookie
#   2	session hashing salt (randomizing string) - used to generate cookie
#   3   timestamp - used to generate cookie
#   4	IP addresses that this session was created from
#	  - we leave this open for a future feature where users can
#           declare other IP addresses or networks as valid for themselves
#

# set up the data needed within a DB_User object
sub initialize
{
	my ( $self, $config ) = @_;

	# set filename prefix string
	$self->{file_prefix} = "session-";

	# use parent class' Slauth::Storage::DB::opendb to open the DB
	$self->opendb( $config );
}

# write a new session record
sub write_record
{
	my ( $self, $login, $config ) = @_;
	my $salt = Slauth::Storage::DB::gen_salt();
	my $time = time;

	debug and print STDERR "Slauth::Storage::Session_DB::write_record: login=$login\n";

	# get password hash from user data
	my ( $user_login, $user_pw_hash, $user_salt, $user_name,
		$user_email, @user_groups )
		= Slauth::Storage::User_DB::get_user( $login, $config);

	debug and print STDERR "Slauth::Storage::Session_DB::write_record: hash input = $user_pw_hash-$salt-$time\n";
	my $session_hash = md5_base64( "$user_pw_hash-$salt-$time" );
	debug and print STDERR "Slauth::Storage::Session_DB::write_record: session_hash=$session_hash\n";
	my $rec = join ( "::", $login, $session_hash, $salt, $time );
	$self->write_raw_record($session_hash,$rec);
	return $session_hash;
}

# check a user's session cookie
sub check_cookie
{
        my $cookie_test = shift;
	my $config = shift;
	my $session_db = Slauth::Storage::Session_DB->new( $config );
	debug and print STDERR "Slauth::Storage::Session_DB::check_cookie: test=$cookie_test\n";
        my ( $login, $session_hash, $salt, $time ) =
                $session_db->read_record($cookie_test);
	debug and print STDERR "Slauth::Storage::Session_DB::check_cookie: login=".((defined $login) ? $login : "undef")."\n";
	( defined $login ) or return undef;

	# it matched a session cookie record
	# verify the user data in it
	my ( $user_login, $user_pw_hash, $user_salt, $user_name,
		$user_email, @user_groups )
		= Slauth::Storage::User_DB::get_user( $login, $config );
	debug and print STDERR "Slauth::Storage::Session_DB::check_cookie: real input = $user_pw_hash-$salt-$time\n";
        my $cookie_real = md5_base64( "$user_pw_hash-$salt-$time" );
	debug and print STDERR "Slauth::Storage::Session_DB::check_cookie: real=$cookie_real\n";
	if ( $cookie_test eq $cookie_real ) {
		return $user_login;
	}
	undef;
}

1;
