package Net::FS::Flickr;
use Data::Dumper;
use LWP::Simple;
use Acme::Steganography::Image::Png;
use File::Temp qw/tempdir/;
use Cwd qw(cwd);
use Net::FS::Flickr::Access;
use Net::FS::Flickr::DefaultImage;

use strict;
our $VERSION           = "0.1";
our $FILESTORE_VERSION = "0.1"; # this way we can track different revisions of filestore format


=head1 NAME

Net::FS::Flickr - store and retrieve files on Flickr

=head1 SYNOPSIS

    my $fs = Net::FS::Flickr->new( key => $key, secret => $secret );

    $fs->set_auth($auth_key); # see API KEYS AND AUTH KEY section
    $fs->store("file.txt");
    $fs->store("piccy.jpg", "renamed_piccy.jpg");

    open (FILE, ">output.jpg") || die "Couldn't write to file: $!\n";
    binmode (FILE);
    print FILE $fs->retrieve("renamed_piccy.jpg");
    close (FILE);

=head1 API KEYS AND AUTH KEY

You will need to sign up for an API key and then get the corresponding
secret key. You can do that from here

http://www.flickr.com/services/api/key.gne

Finally you will need to get an auth key. As described here 

http://www.flickr.com/services/api/auth.howto.desktop.html

the helper script C<flickrfs> supplied with this distribution can help with that.

=head1 METHODS

=cut

=head2 new

Takes a valid API key and a valid secret key

=cut

sub new {
    my $class = shift;
    my %opts  = @_;
	my $flickr = Net::FS::Flickr::Access->new({ key => $opts{key}, secret => $opts{secret} });
    my $writer = Acme::Steganography::Image::Png::RGB::556FS->new();
    my $self = { _flickr => $flickr, _writer => $writer };
    return bless $self, $class;
}

=head2 files [nsid, email or username]

Get a list of all the files on the system

Given an nsid, username or email, use that. Otherwise use the nsid from 
the auth token.

=cut

sub files {
    my $self = shift;
	my $nsid = shift;
	if (!defined $nsid) {
		$nsid = $self->get_nsid_from_token();
	} else {
		$nsid = $self->{_flickr}->get_nsid($nsid);
	}

    my %files;
	foreach my $s ($self->{_flickr}->list_sets()) {
		next unless $s->{title} =~ m!^FlickrStore v[\d.]+ !;
		$files{$'}++;
	}
	return keys %files;
}

=head2 versions <filename> [nsid, email or username]

Returns a list of all the versions of a file

Each item on the list is a hashref containing the date the file was saved
and the id of that version using the keys I<timestamp> and I<id> respectively.

The list is sorted, latest version first.

Because of the way Flickr stores sets, timestamp will always be 0;

Given an nsid, username or email, use that. Otherwise use the nsid from 
the auth token.

=cut

sub versions {
    my $self = shift;
    my $file = shift;
    my $nsid = shift;
    if (!defined $nsid) {
        $nsid = $self->get_nsid_from_token();
    } else {
        $nsid = $self->{_flickr}->get_nsid($nsid);
    }

    my @versions;
    foreach my $s ($self->{_flickr}->list_sets()) {
        next unless $s->{title} =~ m!^FlickrStore v[\d.]+ $file$!;
		my $id        = $s->{id};
		my $timestamp = 0;
        push @versions, { id => $id };
    }
    return @versions;
}

=head2 retrieve <filename> [version] 

Get <filename> from Flickr. 

If the file has multiple versions then you can pass in a version number to get version 
- 1 being the oldest. If you don't pass in a version then you get the latest.


=cut

sub retrieve  {
    my $self    = shift;
    my $file    = shift;
    my $version = shift;

    my @versions = $self->versions($file); 

    die "Couldn't find $file\n" unless @versions;

    my $id;
    if (!defined $version) {
        $id =  $versions[0]->{id};
    } elsif ($version > @versions || $version < 1) {
        die "No such version $version\n";
    } else {
        $id = $versions[-$version]->{id};
    }

	my $dir = tempdir( CLEANUP => 1 );
	my $old = cwd;
	chdir($dir);

	## first get a list of all the photos in this set
	my @photos = $self->{_flickr}->get_set_photos($id);

	## then download them all to the temp directory (in order of upload time)
	my $count = 1;
	my @files;
	foreach my $p (@photos) {
		my $file = "${count}.png"; $count++;
		my $url  = "http://static.flickr.com/".$p->{server}."/".$p->{id}."_".$p->{secret}."_o.png";
		my $rc   = LWP::Simple::getstore($url, $file);
		if (is_error($rc)) {
			die "Couldn't fetch $url - $rc";
		}
		push @files, $file;		
	}

	## then fire-up our steganography stuff
	my $data = $self->{_writer}->read_files(reverse @files);
	chdir($old);
	return $data;
}

=head2 store <filename> [as]

Store the file <filename> on Flickr. If a second filename is given then use that 
as the name on Flickr

This works by stashing the data in the least significant bits of as many images as
is need. by default an, err, default image is used. But you can set alternative 
images using the C<image_pool()> method.

=cut

sub store {
    my $self = shift;
    my $file = shift;
    my $as   = shift;  $as = $file unless defined $as;
    die "No such file $file\n" unless -f $file;

    my $name  = "FlickrStore v$FILESTORE_VERSION $as";

	## First take the file and generate the steganographic images 
	# create a temporary dir
	my $dir = tempdir( CLEANUP => 1 );
	my $old = cwd;
	open (FILE, "$file") || die "Cannot read file $file: $!"; 
	# read the file in
	my $data;
	{ local $/ = undef; $data = <FILE>; }
	close FILE;
	$self->{_writer}->data(\$data); # warning - could take a while
	chdir($dir);

	
	if (!exists $self->{_images} || 'ARRAY' ne ref($self->{_images}) || !@{$self->{_images}}) {
		$self->{_images} = [ Net::FS::Flickr::DefaultImage->restore ];
	}
	my $i = int(rand(scalar(@{$self->{_images}})-1));
	my @filenames = $self->{_writer}->write_images($self->{_images}->[$i]); 
	

	## Then upload the files to Flickr, noting the IDs
	my @ids;
	foreach my $fn (@filenames) {
		my $id = $self->{_flickr}->upload( photo => $fn, auth_token => $self->{_flickr}->{auth} );
		die "Couldn't upload files\n" unless defined $id;
		push @ids, $id;
	}

	# change back
	chdir($old);

	## Then create a new set on your flickr account with the name set as the filename
	my $set_id = $self->{_flickr}->new_set("$name", shift @ids);

	## Then add all the previous images to the set
	$self->{_flickr}->add_to_set($set_id, $_) for @ids;

	## Profit!
	return 1;

}

=head2 image_pool [image[s]]

With no arguments, returns an array of all the images in the current image pool.

If you pass in one or more filenames or Imager objects then those are set as the current pool.

=cut

sub image_pool {
	my $self = shift;
	if (@_) {
		$self->{_images} = [];
	}	

	for (@_) {
		if (ref($_) && $_->isa('Imager')) {
			push @{$self->{_images}}, $_;
			next;
		} elsif (ref($_)) {
			die "$_ is not an Imager object";
		}
		my $tmp = Imager->new;
		$tmp->open( file => $_ ) or die $tmp->errstr();
		push @{$self->{_images}}, $tmp;
	}
	return @{$self->{_images}};

}







=head2 set_auth <auth key>

Set the app authorisation key.

=cut

sub set_auth {
	my $self = shift;
	$self->{_flickr}->{auth} = shift;
}

sub get_frob {
	my $self = shift;
	return $self->{_flickr}->get_frob;
}

sub request_auth_url {
	my $self = shift;
	return $self->{_flickr}->request_auth_url(@_);
}

sub get_token {
    my $self = shift;
    return $self->{_flickr}->get_token(@_);
}

sub get_nsid_from_token {
	my $self = shift;
	return $self->{_flickr}->get_nsid_from_token(@_);
}
1;
