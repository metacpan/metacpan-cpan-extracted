package Net::GNUDBSearch::Cd;

=pod

=head1 NAME

Net::GNUDBSearch::Cd - Storage for L<Net::GNUDBSearch> results.

=head1 SYNOPSIS

	use Net::GNUDBSearch::Cd;
	my $config = {
		'album' => 'Alway Outnumbered, Never Outgunned',
		'artist' => 'The Prodigy',
		'id' => '950cc10c',
		'genre' => 'misc'			
	}
	my $searchCd = Net::GNUDBSearch::Cd->new($config);
	my $artist = $searchCd->getArtist();
	my $album = $searchCd->getAlbum();

=head1 DESCRIPTION

Class for storage of L<Net::GNUDBSearch> results, normally not instantiated directly but can used to lookup a specific GNUDB entry.

For inherited methods see L<Net::GNUDB::Cd>.

=head1 METHODS

=cut

use warnings;
use strict;
use Carp;
use Net::GNUDB::Cd;
use base qw(Net::GNUDB::Cd);
#########################################################

=head2 new($config)

	my $config = {
		'album' => 'Alway Outnumbered, Never Outgunned',
		'artist' => 'The Prodigy',
		'id' => '950cc10c',
		'genre' => 'misc'			
	}
	my $searchCd = Net::GNUDBSearch::Cd->new($config);

Constructor, returns a new instance of the search CD object. Requires all four of the above elements in the provided hash reference for operation. These
elements must match a GNUDB entry.

=cut

#########################################################
sub new{
	my($class, $config) = @_;
	my $self = $class->SUPER::new($config);
	$self->{'__album'} = undef;
	$self->{'__artist'} = undef;
	bless $self, $class;
	$self->__setAlbum($config->{'album'});
	$self->__setArtist($config->{'artist'});
	return $self;
}
#########################################################

=head2 getAlbum()

	my $albumName = $searchCd->getAlbum()

Returns the same album name string as given in the config on object creation.

=cut

#########################################################
sub getAlbum{
	my $self = shift;
	return $self->{'__album'};
}
#########################################################

=head2 getArtist()

	my $artistName = $searchCd->getArtist()

Returns the same artist name string as given in the config on object creation.

=cut

#########################################################
sub getArtist{
	my $self = shift;
	return $self->{'__artist'};
}
#########################################################
sub __setAlbum{
	my($self, $album) = @_;
	$self->{'__album'} = $album;
	return 1;
}
#########################################################
sub __setArtist{
	my($self, $artist) = @_;
	$self->{'__artist'} = $artist;
	return 1;
}
#########################################################

=pod

=head1 Author

MacGyveR <dumb@cpan.org>

Development questions, bug reports, and patches are welcome to the above address.

=head1 Copyright

Copyright (c) 2012 MacGyveR. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 See Also

L<Net::GNUDBSearch::Cd>

=cut

#########################################################
return 1;