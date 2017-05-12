package Net::FS::Flickr::Access;
use Flickr::Upload;
use base qw(Flickr::Upload);
use Data::Dumper;


=head1 NAME

Net::FS::Flickr::Access - a sub class of Flickr::Upload with some convenience methods for Net::FS::Flickr

=head1 METHODS

=head2 get_token <frob>

Given a frob get an auth token back

=cut

sub get_token {
	my $self = shift;
	my $frob = shift;
	my $r    = $self->execute_method("flickr.auth.getToken", { 'frob' => $frob } );
	return undef unless defined $r and $r->{success};

	# FIXME: error checking, please.
	return $r->{tree}->{children}->[1]->{children}->[1]->{children}->[0]->{content};

}


=head2 get_frob

Get a frob. 

=cut

sub get_frob {
	my $self = shift;
	
	my $r = $self->execute_method("flickr.auth.getFrob");
	return undef unless defined $r and $r->{success};

	# FIXME: error checking, please. At least look for the node named 'frob'.
	return $r->{tree}->{children}->[1]->{children}->[0]->{content};
}


=head2 get_nsid <name or email>

Given a name or an email, return a nsid

=cut

sub get_nsid {
	my $self    = shift;
	my $name    = shift;
	my $nsid;
	if ($name =~ m!\@N\d+$!) {
		$nsid = $name;
	} else {
		my $r;
		if ($name =~ m!@!) {
			$r = $self->execute_method('flickr.people.findByEmail', { find_email => $name });
		} else {
			$r = $self->execute_method('flickr.people.findByUserName', { username => $name });

		}
		return unless defined $r && $r->{success};
		for (@{$r->{tree}->{children}}) {
			next unless defined $_->{name} && $_->{name} eq "user";
			$nsid = $_->{attributes}->{nsid};
		}
	} 
	return $nsid;

}

=head2 get_photo <id>

Given an id, get some info about a photo

=cut

sub get_photo {
	my $self  = shift;
	my $id    = shift;
	my $token = $self->{auth};
	my $r = $self->execute_method('flickr.photos.getInfo', { auth_token => $token, photo_id => $id });
	die "No such photo\n" unless $r && $r->{success};
	my ($photo) = grep { defined $_->{name} && $_->{name} eq 'photo' } @{$r->{tree}->{children}};
	return $photo;
}

=head2 get_nsid_from_token [token]

Given an auth token (either passed as an argument or via C<set_auth>)  return an nsid

=cut

sub get_nsid_from_token {
	my $self  = shift;
	my $token = shift || $self->{auth};
	my $r = $self->execute_method('flickr.auth.checkToken', { auth_token => $token });
	die "No such nsid\n" unless $r && $r->{success};

	my ($nsid) = map { $_->{attributes}->{nsid} }
				grep { defined $_->{name} && $_->{name} eq 'user' }
				map  { @{ $_->{children} } }
				grep { defined $_->{name} && $_->{name} eq 'auth' } 
				@{$r->{tree}->{children}};
	return $nsid;
}

=head2 get_photos <nsid>

Get all the photos from a given nsid

=cut

use constant PER_PAGE => 500;
sub get_photos {
	my $self   = shift;
	my $nsid   = shift;

	my $count  = $self->get_count($nsid);
	return () unless $count;

	my $pages = int($count/PER_PAGE) + 1;
	my @photos;
	for my $page (1..$pages) {
		# if we try and move get_page into the loop only the first call succeeds
		# subsequent ones mutter about invalid signature. I blame scoping.
		my @tmp = $self->get_page($nsid, $page);
		push @photos, @tmp;
	}
	return @photos;

}


sub get_page {
    my $self   = shift;
    my $nsid   = shift;
	my $page   = shift;
    my $auth   = $self->{auth};
	my $secret = $self->{api_secret};

	my $params = { extras => 'date_upload', user_id => $nsid, auth_token =>  $auth, secret => $secret, page => $page, per_page => PER_PAGE };

  	my $r      = $self->execute_method('flickr.photos.search', $params);

	my @tmp    = map { $_->{attributes} } grep { defined $_->{name} && $_->{name} eq 'photo' }
												map  { @{ $_->{children} } } 
												grep { defined $_->{name} && $_->{name} eq 'photos' } @{$r->{tree}->{children}};		

	return @tmp;
}

=head2 get_count <nsid>

Get the number of photos that an nsid has

=cut

sub get_count {
	my $self = shift;
	my $nsid = shift;

	my $person   = $self->get_person($nsid);

	my ($photos)  = grep { defined $_->{name} && $_->{name} eq 'photos' } @{$person->{children}}; 
	my ($count)   = grep { defined $_->{name} && $_->{name} eq 'count'  } @{$photos->{children}};
	return $count->{children}->[0]->{content};
}

=head2 get_person <nsid>

Given a person, get info about them

=cut

sub get_person {
    my $self = shift;
    my $nsid = shift;
	my $r =  $self->execute_method('flickr.people.getInfo', { user_id => $nsid, auth_token => $self->{auth}  });
	return undef unless defined $r && $r->{success};
	my ($person) = grep { defined $_->{name} && $_->{name} eq 'person'} @{$r->{tree}->{children}};
	return $person;
}

=head2 new_set <name> <photo id>

Create a new set with the given name and the given photo as the primary

=cut

sub new_set {
	my $self    = shift;
	my $name    = shift;
	my $pri_id  = shift;
 	my $r =  $self->execute_method('flickr.photosets.create', { title => "$name", auth_token => $self->{auth}, primary_photo_id => $pri_id  });
	die "Couldn't create set" unless defined $r;
	die "Couldn't create set - ".$r->{error_message} unless $r->{success};
	my ($set) =  grep { defined $_->{name} && $_->{name} eq 'photoset'} @{$r->{tree}->{children}};
	return $set->{attributes}->{id};
}

=head2 list_sets 

Return all the sets that the current auth key has

Returns a list of hash refs with the id and title as keys.

=cut

sub list_sets {
	my $self = shift;
	my $r =  $self->execute_method('flickr.photosets.getList', {  auth_token => $self->{auth} });
    die "Couldn't get sets" unless defined $r;
    die "Couldn't get sets - ".$r->{error_message} unless $r->{success};
	my @sets = grep { defined $_->{name} && $_->{name} eq 'photoset' }
			   map { @{$_->{children}} }
			   grep { defined $_->{name} && $_->{name} eq 'photosets'} @{$r->{tree}->{children}};

	my @rets;
	foreach my $set (@sets) {
		my $id    = $set->{attributes}->{id};
		my ($t)   = grep { defined $_->{name} && $_->{name} eq 'title'} @{$set->{children}};
		my $title = $t->{children}->[0]->{content};
		push @rets, { id => $id, title => $title };
	}
	return @rets;


}

=head2 add_to_set <set id> <photo id>

Add a photo to a set

=cut

sub add_to_set {
    my $self  = shift;
    my $set   = shift;
	my $photo = shift;
	my $r     =  $self->execute_method('flickr.photosets.create', { auth_token => $self->{auth}, photoset_id => $set, photo_id => $photo  });
 	die "Couldn't add photo to set" unless defined $r;
 	die "Couldn't add photo to set - ".$r->{error_message} unless $r->{success};
}

=head2 get_set_photos <set id>

Return a list of photos from a set

Returns a hashref with the server, secret, id and timestamp as keys

=cut

sub get_set_photos {
	my $self  = shift;
	my $set   = shift;
    my $r     =  $self->execute_method('flickr.photosets.getPhotos', { auth_token => $self->{auth}, photoset_id => $set, extras => 'date_upload'  });
    die "Couldn't add photo to set" unless defined $r;
    die "Couldn't add photo to set - ".$r->{error_message} unless $r->{success};
	my @photos = grep { defined $_->{name} && $_->{name} eq 'photo' }    map { @{$_->{children}} } 
				 grep { defined $_->{name} && $_->{name} eq 'photoset' } @{$r->{tree}->{children}};
 
	my @ret;
	foreach my $p (@photos) {
		$p = $p->{attributes};
		my $timestamp = scalar(localtime($p->{dateupload}));
		push @ret, { server => $p->{server}, secret => $p->{secret}, id => $p->{id}, timestamp => $timestamp };
	}
	return sort { $b->{timestamp} <=> $a->{timestamp} } @ret;
}


=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright 2006, Simon Wistow

=cut

1;
