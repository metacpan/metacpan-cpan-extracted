# Slauth storage interface to DB4 library

package Slauth::Storage::DB;

use strict;
#use warnings FATAL => 'all', NONFATAL => 'redefine';
use Slauth::Config;
use IO::File;
use DB_File;
use Digest::MD5 'md5_base64';
use CGI::Carp qw(cluck fatalsToBrowser);

our %cache;
our $salt_chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+_=;.,<>!@#$^&*()~';
sub debug { Slauth::Config::debug; }

# seed the pseudorandom number generator (once upon loading the package)
# Use /dev/urandom to seed the system from cryptographic-quality entropy.
if ( ! defined $Slauth::Storage::DB::srand_done ) {
	my $rand_dev;

	if ( -c "/dev/urandom"
		and $rand_dev = IO::File->new( "/dev/urandom", "r" ))
	{
		my $raw;

		if ( read $rand_dev, $raw, 4 ) {
			srand ( unpack ( "L*", $raw ));
		} else {
			# failed to read /dev/urandom
			# so get something somewhat random
			srand (time ^ $$ ^ unpack "L*", `ps axww | gzip`);
		}
		close $rand_dev;

		$Slauth::Storage::DB::srand_done = 1;
	} else {
		# failed to find or open /dev/urandom
		# so get something somewhat random
		srand (time ^ $$ ^ unpack "%L*", `ps axww | gzip`);
	}
}

# instantiate a new object
sub new
{
        my $class = shift;
        my $self = {};
	debug and print STDERR "debug: Slauth::Storage::DB new @ ".localtime()."\n";
        bless $self, $class;
        $self->initialize(@_);
        return $self;
}

# set up the data needed within a DB object
sub opendb
{
	my ( $self, $config ) = @_;

	# open the DB file, create if necessary and possible
	if ( !$config ) {
		confess "Slauth::Storage::DB::opendb() - config is undefined\n";
	}
	my $realm = $config->get( "realm" );
	if ( !defined $realm ) {
		confess( "opendb: realm is empty" );
	}
	$self->{db_path} = $config->get ( "dir" )
		."/".$self->{file_prefix}.$realm.".db";

	# use a cached DB handle if available, since other Apache threads
	# may have already opened this database - we re-use it
	if ( defined $Slauth::Storage::DB::cache{$self->{db_path}}) {
		if ( $Slauth::Storage::DB::cache{$self->{db_path}}{count}++ < 50 ) {
			# sanity-check the cache, discard if key lookup fails
			my ( $key, $val ) = each %{$Slauth::Storage::DB::cache{$self->{db_path}}{db}};
			if ( defined $key ) {
				debug and print STDERR "Slauth::Storage::DB::opendb: use cached DB for ".$self->{db_path}."\n";

				# use the data from the cache
				$self->{db} =
					$Slauth::Storage::DB::cache{$self->{db_path}}{db};
				$self->{dbobj} =
					$Slauth::Storage::DB::cache{$self->{db_path}}{dbobj};
			} else {
				# the lookup failed to get a key/value pair
				# so delete it from the cache
				# Note: tied hashes aren't perfect - this
				# is not a failure if the DB_File is empty.
				# But that situation is rare and this action
				# will not cause it to fail in that case.
				debug and print STDERR "Slauth::Storage::DB::opendb: destroy cached DB for ".$self->{db_path}.": sanity check failed\n";
				my $db = $Slauth::Storage::DB::cache{$self->{db_path}}{db};
				delete $Slauth::Storage::DB::cache{$self->{db_path}};
				untie %{$db};
			}
		} else {
			# enough recycling!  Don't keep it forever in case
			# it gets corrupted
			debug and print STDERR "Slauth::Storage::DB::opendb: expire cached DB for ".$self->{db_path}."\n";
			my $db = $Slauth::Storage::DB::cache{$self->{db_path}}{db};
			delete $Slauth::Storage::DB::cache{$self->{db_path}};
			untie %{$db};
		}
	}
	
	if ( !defined $self->{db}) {
		my ( %db, $res );
		$res = tie %db, "DB_File", $self->{db_path},
			O_CREAT|O_RDWR, 0660, $DB_HASH;
		if ( ! defined $res ) {
			debug and print STDERR "Slauth::Storage::DB::opendb: DB tie failed for ".$self->{db_path}.": $!\n";
			$self->{error} = "tie failed";
			return;
		}
		debug and print STDERR "Slauth::Storage::DB::opendb: open DB for ".$self->{db_path}."\n";
		$self->{dbobj} = $res;
		$self->{db} = \%db;
		#$self->{dbobj}->unlockDB();
		$Slauth::Storage::DB::cache{$self->{db_path}} = {};
		$Slauth::Storage::DB::cache{$self->{db_path}}{db} = \%db;
		$Slauth::Storage::DB::cache{$self->{db_path}}{dbobj} = $res;
		$Slauth::Storage::DB::cache{$self->{db_path}}{count} = 0;
	}
}

# report if there were any errors
sub error
{
	my $self = shift;
	return $self->{error};
}

# read a user record
sub read_record
{
	my ( $self, $key ) = @_;

	debug and print STDERR "Slauth::Storage::DB: key=$key dbpath=".$self->{db_path}."\n";
	$! = undef;
	if ( defined $self->{db}{$key}) {
		#$self->{dbobj}->lockDB();
		debug and print STDERR "Slauth::Storage::DB: retval="
			.$self->{db}{$key}."\n";
		#$self->{dbobj}->unlockDB();
		return split ( /::/, $self->{db}{$key} );
	} else {
		debug and print STDERR "Slauth::Storage::DB: read error: $!\n";
	}
	return undef;
}

# write a raw text record - preparation mus tbe done by subclasses
sub write_raw_record
{
	my ( $self, $key, $rec ) = @_;
	#$self->{dbobj}->lockDB();
	my $status = ( $self->{db}{$key} = $rec );
	$self->{dbobj}->sync;
	#$self->{dbobj}->unlockDB();
	return $status;
}

# generate a salt (randomizer) string, used for adding randomness to
# password hashes, making the difficulty of brute-force cracking of
# a password not worth the trouble, even if the stored hash is exposed.
sub gen_salt
{
	my ($str, $i);

	$str = "";
	for ( $i = 0; $i < 10; $i++ ) {
		$str .= substr ( $Slauth::Storage::DB::salt_chars,
			int(rand(length($Slauth::Storage::DB::salt_chars))),
			1 );
	}
	return $str;
}

1;
