# Slauth storage interface to DB4 library

package Slauth::Storage::User_DB;

use strict;
#use warnings FATAL => 'all', NONFATAL => 'redefine';
use base "Slauth::Storage::DB";
use IO::File;
use Digest::MD5 'md5_base64';

sub debug { Slauth::Config::debug; }

# instantiate a new object
sub new
{
	my $class = shift;
	my $self = {};
	debug and print STDERR "debug: Slauth::Storage::User_DB new\n";
	bless $self, $class;
	$self->initialize(@_);
	return $self;
}

#
# the record structure is as follows:
#   0	login name
#   1   password MD5 hash
#   2	password hashing salt (randomizing string)
#   2   name
#   3	e-mail
#   5	groups
#

# set up the data needed within a DB_User object
sub initialize
{
	my ( $self, $config ) = @_;

        # set filename prefix string
        $self->{file_prefix} = "user-";

        # use parent class' Slauth::Storage::DB::opendb to open the DB
        $self->opendb( $config );
}

# write a (possibly new) user record
sub write_record
{
	my ( $self, $login, $password, $name, $email, @groups ) = @_;
	my $salt = Slauth::Storage::DB::gen_salt();
	my $pw_hash = md5_base64( $password."-".$salt );
	my $rec = join ( "::", $login, $pw_hash, $salt, $name, $email,
		join ( ",", @groups ));
	return $self->write_raw_record($login,$rec);
}

# check a user's password
# external function
sub check_pw
{
	my ( $login, $pw_test, $config ) = @_;
	my ( $user_login, $user_pw_hash, $user_salt, $user_name,
		$user_email, $user_groups )
		= Slauth::Storage::User_DB::get_user($login, $config);
	my $pw_hash_test = md5_base64( $pw_test."-".$user_salt );

	# This comparison uses a one-way hash - the user's password
	# has not been stored in clear text and is not available anywhere.
	# If the submitted password hashed with the salt (randomizer) string
	# matches the password hash (prepared the same way), it's a match.
	my $result = ( $pw_hash_test eq $user_pw_hash );
	debug and print STDERR "Slauth::Storage::User_DB::check_pw: $result\n";
	return $result;
}

# get user data
# external function
sub get_user
{
	my $login = shift;
	my $config = shift;
	debug and print STDERR "Slauth::Storage::User_DB::get_user: begin\n";
	my $user_db = Slauth::Storage::User_DB->new( $config );
	debug and print STDERR "Slauth::Storage::User_DB::get_user: login=$login\n";
	return $user_db->read_record($login);
}

1;
