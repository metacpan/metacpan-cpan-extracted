# Slauth storage interface to DB4 library

package Slauth::Storage::Confirm_DB;

use strict;
#use warnings FATAL => 'all', NONFATAL => 'redefine';
use base "Slauth::Storage::DB";
use Slauth::Config;
use Digest::MD5 'md5_base64';

sub debug { Slauth::Config::debug; }

# instantiate a new object
sub new
{
	my $class = shift;
	my $self = {};
	debug and print STDERR "debug: Slauth::Storage::Confirm_DB new\n";
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

# set up the data needed within a Confirm_DB object
sub initialize
{
	my ( $self, $config ) = @_;

        # set filename prefix string
        $self->{file_prefix} = "confirm-";

        # use parent class' Slauth::Storage::DB::opendb to open the DB
        $self->opendb( $config );
}

# write a confirmation record
sub write_record
{
	my ( $self, $login, $email ) = @_;
	my $salt = Slauth::Storage::DB::gen_salt();
	my $time = time;
	my $confirm_hash = md5_base64( $login."-".$email."-".$salt."-".$time );
	my $rec = join ( "::", $login, $confirm_hash, $salt, $email, $time );
	$self->write_raw_record($confirm_hash,$rec);
	return $confirm_hash;
}

# get confirmation data
# external function
sub get_confirm
{
	my $confirm_hash = shift;
	my $config = shift;
	debug and print STDERR "Slauth::Storage::Confirm_DB::get_confirm: begin\n";
	my $confirm_db = Slauth::Storage::Confirm_DB->new( $config );
	debug and print STDERR "Slauth::Storage::Confirm_DB::get_confirm: confirm_hash=$confirm_hash\n";
	return $confirm_db->read_record($confirm_hash);
}

# delete expired confirmation data
# external function
sub delete_confirm
{
	my $confirm_hash = shift;
	my $config = shift;
	debug and print STDERR "Slauth::Storage::Confirm_DB::delete_confirm: begin\n";
	my $confirm_db = Slauth::Storage::Confirm_DB->new( $config );
	debug and print STDERR "Slauth::Storage::Confirm_DB::delete_confirm: confirm_hash=$confirm_hash\n";
	$confirm_db->{dbobj}->del( $confirm_hash );
}

# convert MD5 to URL-safe string
sub md5tourlsafe
{
	my $str = shift;
	$str =~ s/\+/-/g;
	$str =~ s/\//./g;
	return $str;
}

# convert URL-safe to MD5 string
sub urlsafetomd5
{
	my $str = shift;
	$str =~ s/-/\+/g;
	$str =~ s/\./\//g;
	return $str;
}

1;
