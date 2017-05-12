package Net::OpenID::JanRain::Stores::FileStore;

=head1 JanRain OpenID File Store

This module maintains a directory structure that saves state for the
JanRain OpenID Library.

=head2 Synopsis:

C<< Net::OpenID::JanRain::Stores::FileStore->new("directory") >>

=cut

# vi:ts=4:sw=4

use warnings;
use strict;

use Carp;
use MIME::Base64 qw(encode_base64);
use File::Spec;
use File::Temp qw( tempfile );
use Net::OpenID::JanRain::CryptUtil qw( sha1 randomString );

our @ISA = qw(
	Net::OpenID::JanRain::Stores
	);

# Functions
sub _safe64 {
    my ($s) = @_;
    my $h64 = encode_base64(sha1($s));
    $h64 =~ s/\+/_/g;
    $h64 =~ s!/!.!g;
    $h64 =~ s/=//g;
    $h64 =~ s/\n//g;
    return $h64;
}
########################################################################
sub _isFilenameSafe {
    my ($c) = @_;
    return  
}
########################################################################
sub _filenameEscape {
    my ($s) = @_;
}
########################################################################
# Attempt to remove a file, returning whether the file existed at
# the time of the call.
sub _removeIfPresent {
	my ($filename) = @_;
    if ((unlink $filename) == 0) { 
        die "Could not remove $filename. $!" if -e $filename;
        return 0;
    }
    return 1;
} # end removeIfPresent
########################################################################
# _ensureDir
# Create dir_name as a directory if it does not exist. If it
# exists, make sure that it is, in fact, a directory.
sub _ensureDir {
	my ($dir_name) = @_;
    mkdir $dir_name, 0755 
        || -d $dir_name 
        || die "Unable to make directory $dir_name. $!";
    return -d $dir_name;
} # end ensureDir
########################################################################

# Methods
########################################################################
# new
# Call with the directory where the files should go.
# All files must reside on the same filesystem.
sub new {
    my $caller = shift;
    my ($dir) = @_;
    my $class = ref($caller) || $caller;
    $dir = File::Spec->rel2abs($dir);
    my $noncedir = File::Spec->catdir($dir, "nonces");
    my $assocdir = File::Spec->catdir($dir, "associations");
    my $tempdir = File::Spec->catdir($dir, "temp");
    my $authkeyn = File::Spec->catfile($dir, "auth_key");
    my $maxnonceage = 6 * 60 * 60;
    my $AUTH_KEY_LEN = 20;
	my $self = {nonce_dir => $noncedir,
                assoc_dir => $assocdir,
                temp_dir => $tempdir,
                auth_key_name => $authkeyn,
                max_nonce_age => $maxnonceage,
                AUTH_KEY_LEN => $AUTH_KEY_LEN};
    
    _ensureDir($dir);
    _ensureDir($noncedir);
    _ensureDir($assocdir);
    _ensureDir($tempdir);

    bless($self, $class);
} # end new
########################################################################
# isDumb
# true if we are a dumb store, which we aren't.
sub isDumb {
    my $self = shift;
    return 0;
}
########################################################################
# readAuthKey
# Read the auth key from the auth key file. Will return None
# if there is currently no key.
sub readAuthKey {
	my $self = shift;
    my $key;
    open AKF, "< $self->{auth_key_name}" or return undef;
    # Read one more byte than necessary to detect corruption
    my $keylen = (read AKF, $key, $self->{AUTH_KEY_LEN}+1);
    return undef if $keylen == 0;
    close AKF;
    return $key;
} # end readAuthKey
########################################################################
# createAuthKey
# Generate a new random auth key and safely store it in the
# location specified by self.auth_key_name.
sub createAuthKey {
	my $self = shift;
    my $auth_key = randomString($self->{AUTH_KEY_LEN});

    my ($fh, $tmpfn) = tempfile(DIR => $self->{temp_dir});
    die "Could not open a temporary file" unless $fh;
    print $fh $auth_key;
    close $fh;

    unless(link($tmpfn, $self->{auth_key_name})) {
        unless(rename ($tmpfn, $self->{auth_key_name})) {
            $auth_key = $self->readAuthKey();
            unless ($auth_key) {
                die 'Failed to create or read Auth Key'
            }
        }
    }
    $self->_removeIfPresent($tmpfn);
    return $auth_key;

} # end createAuthKey
########################################################################
# getAuthKey
# Retrieve the auth key from the file specified by
# self.auth_key_name, creating it if it does not exist.
sub getAuthKey {
	my $self = shift;
    my $auth_key = $self->readAuthKey();
    $auth_key = $self->createAuthKey() unless $auth_key;
    if (length($auth_key) != $self->{AUTH_KEY_LEN}) {
        die "Got invalid auth key from $self->{auth_key_name}. Expected ".
            "$self->{AUTH_KEY_LEN} byte string. Got: $auth_key";
    }
    return $auth_key;
} # end getAuthKey
########################################################################
# getAssociationFilename
# Create a unique filename for a given server url and
# handle. This implementation does not assume anything about the
# format of the handle. The filename that is returned will
# contain the domain name from the server URL for ease of human
# inspection of the data directory.
sub getAssociationFilename {
	my $self = shift;
	my ($server_url, $handle) = @_;
    defined($server_url) || die "getAssociationFilename called without server url";
    unless($server_url =~ m!(.+)://([.\w]+)/?!) {
        die "Bad server URL: $server_url";
    }
    my $proto = $1;
    my $domain = $2;
    
    my $url_hash = _safe64($server_url);
    
    my $handle_hash;

    if ($handle) {
        $handle_hash = _safe64($handle);
    }
    else {
        $handle_hash = '';
    }

    my $filename = "${proto}-${domain}-${url_hash}-${handle_hash}";

    return File::Spec->catfile($self->{assoc_dir}, $filename);
} # end getAssociationFilename
########################################################################
# storeAssociation
# Create a unique filename for a given server url and
# handle. This implementation does not assume anything about the
# format of the handle. The filename that is returned will
# contain the domain name from the server URL for ease of human
# inspection of the data directory.
sub storeAssociation {
	my $self = shift;
	my ($server_url, $association) = @_;
    
    my $association_s = $association->serialize();
    my $filename=$self->getAssociationFilename($server_url, $association->{handle});
    my ($fh, $tmpfn) = tempfile(DIR => $self->{temp_dir});

    unless (print $fh $association_s) {
        warn "Unable to write association to $tmpfn";
        close $fh;
        return;
    }
    # os.fsync(tmp_file.fileno())
    close $fh;

    unless (rename $tmpfn, $filename) {
        unlink $filename;
        unless (rename $tmpfn, $filename) {
            warn "Unable to rename $tmpfn to $filename. $!";
            unlink $tmpfn;
        }
    }
} # end storeAssociation
########################################################################
# getAssociation
# Retrieve an association. If no handle is specified, return
# the association with the latest expiration.
# If no matching association exists, returns undef
sub getAssociation {
    use Net::OpenID::JanRain::Association;
    my $self = shift;
    my ($server_url, $handle) = @_;
    
    defined($handle) or $handle = ''; 
    
    my $filename = $self->getAssociationFilename($server_url, $handle);
    
    if ($handle) {
        return $self->_getAssociation($filename);
    }
    else {
        my @associations = ();
        # The filename with an empty handle is a prefix of all association
        # filenames for a given server URL.
        my $file_match = "$filename*";
        my $file;
        for $file (glob($file_match)) {
            my $assoc = $self->_getAssociation($file);
            if ($assoc) {
                push @associations, $assoc;
            }
        }
        @associations = sort {$a->{issued} <=> $b->{issued}} @associations;
        return pop @associations; # undef if array is empty
    } 
} # end getAssociation
########################################################################
# _getAssociation
# Read an association file and return an association object.
# undef if we have no such association.
sub _getAssociation {
    my $self = shift;
    my ($filename) = @_;

    open FILE, "< $filename" or return undef;
    
    my $assoc_s;
    unless (read FILE, $assoc_s, 1024) { #more bytes than needed
        warn "Unable to read $filename";
        close FILE;
        return undef;
    }
    close FILE;
    my $association = Net::OpenID::JanRain::Association->deserialize($assoc_s);
    #If we find a bunk association, remove it.
    _removeIfPresent($filename) unless $association;
    return $association;
}
########################################################################
# removeAssociation
# Remove an association if it exists. Do nothing if it does not.
sub removeAssociation {
	my $self = shift;
	my ($server_url, $handle) = @_;
    my $assoc = $self->getAssociation($server_url, $handle);
    if ($assoc) {
        return _removeIfPresent($self->getAssociationFilename($server_url, $handle));
    }
    return 0;
} # end removeAssociation
########################################################################
sub storeNonce {
	my $self = shift;
	my ($nonce) = @_;
    my $fn = File::Spec->catfile($self->{nonce_dir}, $nonce);
    open FILE, "> $fn" or die "Could not open nonce file $fn - $!\n";
    close FILE;
} # end storeNonce
########################################################################
sub useNonce {
	my $self = shift;
	my ($nonce) = @_;
    my $fn = File::Spec->catfile($self->{nonce_dir}, $nonce);
    my @stats = stat $fn;
    return undef unless @stats;
    my $mtime = $stats[10];
    unlink $fn || return undef;
    return (($mtime - time) < $self->{max_nonce_age});
} # end useNonce
########################################################################
sub clean {
	my $self = shift;
    my $now = time; # now is the time
    
    # Check all nonces for expiration
    my $fn;
    for $fn (glob(File::Spec->catfile($self->{nonce_dir}, "*"))) {
        my @stats = stat $fn;
        if (@stats) {
            # tenth stat is modification time
            if (($now - $stats[10]) > $self->{max_nonce_age} ) {
                _removeIfPresent($fn);
            }
        }
    }

    # Check all associations for corruption and expiration
    for $fn (glob(File::Spec->catfile($self->assoc_dir,"*"))) {
        my $assoc = _getAssociation($fn); #cleans up corrupted files.
        if($assoc && $assoc->getExpiresIn() == 0) {
            _removeIfPresent($fn);
        }
    }
} # end clean
########################################################################
1;
