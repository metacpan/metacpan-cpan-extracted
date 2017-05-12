package Net::DAAP::Server::MythTV;

# vi: ts=4 sw=4

use strict;
use warnings;

use DBI;
use POE;

use base 'Net::DMAP::Server';

our $VERSION = 0.01;

sub new {
	my $class = shift;
	my $self = {@_};
	bless $self, $class;

	# Start DAAP server
	# TODO: Find available port
	$self->{port} = $self->{port} || 3689;
	$self->httpd(POE::Component::Server::HTTP->new(
		Port => $self->{port},
		ContentHandler => {'/' => sub {
			$self->_handler(@_);
		}},
		StreamHandler => sub {
			$self->stream_handler(@_);
		}));

	POE::Session->create(
		inline_states => {
			_start => sub {
				# TODO: Make poll_interval configurable?
				$_[KERNEL]->alarm(poll_changed => time + 20);
			},
			poll_changed => sub {
				$self->poll_changed;
				$_[KERNEL]->yield('_start');
			}});

	# Publish DAAP server
	$self->name || $self->name($class);
	$self->{protocol} = $self->{protocol} || 'daap';

	# TODO: Calculate UUIDs?
	$self->db_uuid || $self->db_uuid('13950142391337751523');
	$self->publisher(Net::Rendezvous::Publish->new);
	$self->service($self->publisher->publish(
		name => $self->name,
		type => '_' . $self->{protocol} . '._tcp',
		port => $self->{port},
		txt => 'Database ID=' . $self->db_uuid
			. "\x01Machine name=" . $self->name));

	# Extra Net::DMAP::Server stuff
	$self->revision(42);
	$self->waiting_clients([]);

	# TODO: Make this a command line option
	$self->debug(1);

	return $self;
}

sub connect {
	my $self = shift;

	# Connect to MythTV
	$self->{db_name} = $self->{db_name} || 'mythconverg';
	$self->{db_host} = $self->{db_host} || 'localhost';
	$self->{db_username} = $self->{db_username} || 'mythtv';
	$self->{db_password} = $self->{db_password} || 'mythtv';

	return DBI->connect_cached(
		'dbi:mysql:database=' . $self->{db_name} . ':host=' . $self->{db_host},
		$self->{db_username},
		$self->{db_password});
}

sub stream_handler {
	my $self = shift;
	my ($request, $response) = @_;

	read $response->{handle}, my $buffer, 4096;
	$response->send($buffer);
}

sub server_info {
	my $self = shift;
	my ($request, $response) = @_;

	$response->content($self->_dmap_pack([
		['dmap.serverinforesponse' => [
			['dmap.status' => 200],
			['dmap.protocolversion' => 2],
			['daap.protocolversion' => $request->header('Client-DAAP-Version')],
			['dmap.itemname' => $self->name],
			['dmap.loginrequired' => 0],
			['dmap.timeoutinterval' => 1800],
			['dmap.supportsautologout' => 0],
			['dmap.supportsupdate' => 0],
			['dmap.supportspersistentids' => 0],
			['dmap.supportsextensions' => 0],
			['dmap.supportsbrowse' => 0],
			['dmap.supportsquery' => 0],
			['dmap.supportsindex' => 0],
			['dmap.supportsresolve' => 0],
			['dmap.databasescount' => 1]]]]));
}

sub databases {
	my $self = shift;
	my ($request, $response) = @_;

	my $dbh = $self->connect;
	my $sth = $dbh->prepare(
		'SELECT COUNT(*) FROM videometadata');
	$sth->execute;

	my ($itemcount) = $sth->fetchrow_array;

	$response->content($self->_dmap_pack([
		['daap.serverdatabases' => [
			['dmap.status' => 200],
			['dmap.updatetype' => 0],
			['dmap.specifiedtotalcount' => 1],
			['dmap.returnedcount' => 1],
			['dmap.listing' => [
				['dmap.listingitem' => [
					['dmap.itemid' => 35],
					['dmap.persistentid' => $self->db_uuid],
					['dmap.itemname' => $self->name],
					['dmap.itemcount' => $itemcount],
					['dmap.containercount' => 1]]]]]]]]));
}

sub database_items {
	my $self = shift;
	my ($request, $response) = @_;

	my $dbh = $self->connect;
	my $sth = $dbh->prepare(
		'SELECT filename, plot, intid, title, year FROM videometadata');
	$sth->execute;

	my $listing = [];
	while (my ($filename, $plot, $intid, $title, $year) =
			$sth->fetchrow_array) {
		# TODO: It would be faster to cache this data in the database
		my @stat = stat $filename;
		push @$listing, ['dmap.listingitem' => [
			['dmap.itemkind' => 2],
			['daap.songcontentdescription' => $plot],
			['dmap.itemid' => $intid],
			['daap.songdescription' => $plot],
			['dmap.itemname' => $title],
			['daap.songsize' => $stat[7]],
			['daap.songyear' => $year],
			['com.apple.itunes.has-video' => 1]]];
	}

	$response->content($self->_dmap_pack([
		['daap.databasesongs' => [
			['dmap.status' => 200],
			['dmap.updatetype' => 0],
			['dmap.specifiedtotalcount' => scalar @$listing],
			['dmap.returnedcount' => scalar @$listing],
			['dmap.listing' => $listing]]]]));
}

sub database_playlists {
	my $self = shift;
	my ($request, $response) = @_;

	my $dbh = $self->connect;
	my $sth = $dbh->prepare(
		'SELECT COUNT(*) FROM videometadata');
	$sth->execute;

	my ($itemcount) = $sth->fetchrow_array;

	$response->content($self->_dmap_pack([
		['daap.databaseplaylists' => [
			['dmap.status' => 200],
			['dmap.updatetype' => 0],
			['dmap.specifiedtotalcount' => 1],
			['dmap.returnedcount' => 1],
			['dmap.listing' => [
				['dmap.listingitem' => [
					['dmap.itemid' => 39],
					['dmap.persistentid' => 13950142391337751524],
					['dmap.itemname' => $self->name],
					['com.apple.itunes.smart-playlist' => 0],
					['dmap.itemcount' => $itemcount]]]]]]]]));
}

sub playlist_items {
	my $self = shift;
	my ($request, $response) = @_;

	my $dbh = $self->connect;
	my $sth = $dbh->prepare(
		'SELECT filename, plot, intid, title, year FROM videometadata');
	$sth->execute;

	my $listing = [];
	while (my ($filename, $plot, $intid, $title, $year) =
			$sth->fetchrow_array) {
		# TODO: It would be faster to cache this data in the database
		my @stat = stat $filename;
		push @$listing, ['dmap.listingitem' => [
			['dmap.itemkind' => 2],
			['daap.songcontentdescription' => $plot],
			['dmap.itemid' => $intid],
			['daap.songdescription' => $plot],
			['dmap.itemname' => $title],
			['daap.songsize' => $stat[7]],
			['daap.songyear' => $year],
			['com.apple.itunes.has-video' => 1]]];
	}

	$response->content($self->_dmap_pack([
		['daap.playlistsongs' => [
			['dmap.status' => 200],
			['dmap.updatetype' => 0],
			['dmap.specifiedtotalcount' => scalar @$listing],
			['dmap.returnedcount' => scalar @$listing],
			['dmap.listing' => $listing]]]]));
}

sub database_item {
	my $self = shift;
	my ($request, $response) = @_;

	my ($intid) = ($request->uri->path =~ /^\/databases\/\d+\/items\/(\d+)/);
	my $dbh = $self->connect;
	my $sth = $dbh->prepare(
		'SELECT filename FROM videometadata WHERE intid = ?');
	$sth->execute($intid);

	my ($filename) = $sth->fetchrow_array;
	open $response->{handle}, '<', $filename;

	$response->streaming(1);
}

__END__

=head1 NAME

Net::DAAP::Server::MythTV - Publish MythTV videos to DAAP clients like Apple's Front Row

=head1 DESCRIPTION

MythTV is a homebrew PVR project.  This module publishes MythTV videos, including metadata, to DAAP clients like Apple's Front Row.

=head1 PREREQUISITES

DBI

POE::Component::Server::HTTP

Net::DAAP::DMAP

=head1 AUTHOR

Jack Bates <ms419@freezone.co.uk>

=head1 COPYRIGHT

Copyright 2007, Jack Bates.  All rights reserved.

This program is free software.  You can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

Net::DAAP::Server - The module on which this module is based

L<MythTV|http://mythtv.org/>
