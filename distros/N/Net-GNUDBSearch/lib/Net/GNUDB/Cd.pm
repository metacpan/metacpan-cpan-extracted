package Net::GNUDB::Cd;

=pod

=head1 NAME

Net::GNUDB::Cd - Base class for L<Net::GNUDBSearch> results.

=head1 SYNOPSIS

	use Net::GNUDB::Cd;
	my $config = {
		'id' => '950cc10c',
		'genre' => 'misc'			
	}
	my $cd = Net::GNUDB::Cd->new($config);
	my $id = $cd->getId();
	my $genre = $cd->getGenre();
	my $tracks = $cd->getTracks();

=head1 DESCRIPTION

Base class for L<Net::GNUDBSearch> results, normally not instantiated directly but can used to lookup a specific GNUDB entry.

=head1 METHODS

=cut

use warnings;
use strict;
use Carp;
use Net::FreeDB2;
use Net::FreeDB2::Match;
use Net::FreeDB2::Entry;	#see bug: https://rt.cpan.org/Ticket/Display.html?id=69089
#########################################################

=head2 new($config)

	my $config = {
		'id' => '950cc10c',
		'genre' => 'misc'			
	}
	my $cd = Net::GNUDB::Cd->new($config);

Constructor, returns a new instance of the search CD object. Requires all two of the above elements in the provided hash reference for operation. These
elements must match a GNUDB entry.

=cut

#########################################################
sub new{
	my($class, $config) = @_;
	my $self = {
		'__id' => undef,
		'__genre' => undef,
		'__tracks' => []
	};
	bless $self, $class;
	$self->__setId($config->{'id'});
	$self->__setGenre($config->{'genre'});
	return $self;
}
########################################################

=head2 getTracks()

	my $tracks = $cd->getTracks()

Returns an array reference of track names for the CD found from the details in the config given at object creation.

This method actually performs the lookup to the GNUDB database.

=cut

########################################################
sub getTracks{
	my $self = shift;
	my @tracks = @{$self->{'__tracks'}};
	if($#tracks == -1){
		my $connectionConfig = {
	        client_name => ref($self),
	        client_version => 1.0,
	        protocol => "HTTP",
	        freedb_host => "gnudb.gnudb.org"
	 	};
		my $conn = Net::FreeDB2->connection($connectionConfig);
		my $matchConfig = {
			"categ" => $self->getGenre(),
			"discid" => $self->getId()
		};
		my $match = Net::FreeDB2::Match->new($matchConfig);
		my $res = $conn->read($match);
	 	if($res->hasError()){
	  		confess('Error quering GNUDB');
	 	}
	 	else{	#all ok
	 		my $entry = $res->getEntry();
	 		@tracks = $entry->getTtitlen(0);	#get all tracks;
	 		$self->{'__tracks'} = \@tracks;
	 	}
	}
	return @tracks;
}
#########################################################

=head2 getId()

	my $id = $cd->getId()

Returns the same ID string as given in the config on object creation.

=cut

#########################################################
sub getId{
	my $self = shift;
	return $self->{'__id'};
}
#########################################################

=head2 getGenre()

	my $genre = $cd->getGenre()

Returns the same genre string as given in the config on object creation.

=cut

#########################################################
sub getGenre{
	my $self = shift;
	return $self->{'__genre'};
}
#########################################################
sub __setId{
	my($self, $id) = @_;
	if(defined($id)){
		if($id =~ m/^[0-9a-fA-F]+$/){
			$self->{'__id'} = $id;
			return 1;
		}
		else{
			confess("Invalid ID");
		}
	}
	else{
		confess("No ID given");
	}
	return 0;
}
#########################################################
sub __setGenre{
	my($self, $genre) = @_;
	if(defined($genre)){
		$self->{'__genre'} = $genre;
		return 1;
	}
	else{
		confess("No genre given");
	}
	return 0;
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

L<Net::GNUDBSearch>

=cut

#########################################################
return 1;