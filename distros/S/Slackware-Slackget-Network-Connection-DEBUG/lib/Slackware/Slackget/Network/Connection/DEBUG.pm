package Slackware::Slackget::Network::Connection::DEBUG;

BEGIN {
	srand (time ^ $$ ^ unpack "%L*", `ps axww | gzip`);
	print STDOUT "[Slackware::Slackget::Network::Connection::DEBUG] driver compiled.\n";
}

use warnings;
use strict;
require Slackware::Slackget::Network::Connection;

=head1 NAME

Slackware::Slackget::Network::Connection::DEBUG - This class iimplements the debug:// protocol driver for Slackware::Slackget::Network::Connection

=head1 VERSION

Version 0.5

=cut

our $VERSION = '0.5';
print STDOUT "[Slackware::Slackget::Network::Connection::DEBUG] enable Slackware::Slackget::Network::Connection debug mode.\n";
$Slackware::Slackget::Network::Connection::DEBUG=1;

=head1 SYNOPSIS

This class implements the debug:// protocol driver for Slackware::Slackget::Network::Connection.

You can't use this class without the Slackware::Slackget::Network::Connection one.

This class was implemented for 2 main reasons :

	* To help coding and debuging new protocol drivers
	* As a tutorial on how to code a new driver.

You should always remember that this class do absolutly nothing !

All downloads are fake ones as well as the 

=cut

sub new
{
	my ($class,$url,$config) = @_ ;
	my $self = {};
	return undef unless (is_url($self,$url));
	bless($self,$class);
	$self->parse_url($url) ;
	_debug_print("constructor called (it should not).");
	return $self;
}

sub _debug_print {
	print STDOUT "[Slackware::Slackget::Network::Connection::DEBUG] @_";
}

=head1 CONSTRUCTOR

=head2 new

This class is not designed to be instanciate alone or used alone. You have to use the Slackware::Slackget::Network::Connection.

=head1 FUNCTIONS

=head2 __test_server

This method act as if it test the rapidity of a repository. It return a random number between 10 and 90.

Moreover it output a message on the standard output (STDOUT).

	my $time = $self->test_server() ;

=cut

sub __test_server {
	my $self = shift ;
	_debug_print("protocol : $self->{DATA}->{protocol}\n");
	_debug_print("host : $self->{DATA}->{host}\n");
	return (rand(90)+10);
}

=head2 __get_file

Return the following string :

	"This is a debug output from the Slackware::Slackget::Network::Connection::DEBUG network driver.\n"

If you want it to return an error, please set an extra data called 'debug-want-error', like that :

	$connection->object_extra_data('debug-want-error', 1);
	$connection->get_file('TEST.TXT');

You can use this method like any other connection driver's one :

	my $file = $connection->get_file('PACKAGES.TXT') ;

It output some informations (protocol, host, path and remote file) on the standard output (STDOUT).

=cut

sub __get_file {
	my ($self,$remote_file) = @_ ;
	_debug_print("[__get_file] protocol=".$self->protocol()."\n");
	_debug_print("[__get_file] host=".$self->host()."\n");
	_debug_print("[__get_file] path=".$self->path()."\n");
	_debug_print("[__get_file] remote file downloaded=".$remote_file."\n");
	$self->post_event('progress',$remote_file,1,100);
	sleep 1;
	$self->post_event('progress',$remote_file,33,100);
	sleep 1;
	$self->post_event('progress',$remote_file,66,100);
	sleep 1;
	$self->post_event('progress',$remote_file,99,100);
	sleep 1;
	$self->post_event('progress',$remote_file,100,100);
	return undef if($self->object_extra_data('debug-want-error'));
	return "This is a debug output from the Slackware::Slackget::Network::Connection::DEBUG network driver.\n";
}

=head2 __fetch_file

Provide a 

This method return a Slackware::Slackget::Status object with the following object declaration :

	my $state =  Slackware::Slackget::Status->new(codes => {
		0 => "All goes well. Server said: $ret_code - ".status_message( $ret_code ),
		1 => "Destination directory does not exist.\n",
		2 => "Destination directory is not writable.\n",
		3 => "Server error, you must choose the next host for this server. \nServer said: \nThis is a debug output from the Slackware::Slackget::Network::Connection::DEBUG network driver.",
	});

This method is also affected by the 'debug-want-error' extra data (if set with a true value it will generate a download error event).

This method is also affected by the 'debug-want-success' extra data (if set with a true value, it will generate a download finished event)

The default behavior is to randomize the generated state.

=cut

sub __fetch_file {
	my ($self,$remote_file,$local_file) = @_ ;
	$remote_file = $self->file unless(defined($remote_file));
	my $state =  Slackware::Slackget::Status->new(codes => {
		0 => "All goes well.",
		1 => "Destination directory does not exist.",
		2 => "Destination directory is not writable.",
		3 => "Server error, you must choose the next host for this server. \nServer said: \nThis is a debug output from the Slackware::Slackget::Network::Connection::DEBUG network driver.",
		4 => "Module error: unable to determine the path to save $remote_file",
	});
	unless(defined($local_file)){
		if(defined($self->{DATA}->{download_directory}) && -e $self->{DATA}->{download_directory}){
			$remote_file=~ /([^\/]*)$/;
			$local_file = $self->{DATA}->{download_directory}.'/'.$1 ;
		}
		elsif(defined($self->{DATA}->{config})){
			$remote_file=~ /([^\/]*)$/;
			$local_file = $self->{DATA}->{config}->{common}->{'update-directory'}.'/'.$1 ;
		}
		else{
			warn "[Slackware::Slackget::Network::Connection::DEB$self->object_extra_data('debug-want-error')UG] unable to determine the path to save $remote_file.\n";
			return $state->current(4);
			return $state;
		}
	}
	_debug_print("[__get_file] protocol=".$self->protocol()."\n");
	_debug_print("[__get_file] host=".$self->host()."\n");
	_debug_print("[__get_file] path=".$self->path()."\n");
	_debug_print("[__get_file] remote file downloaded=".$remote_file."\n");
	_debug_print("[__get_file] local file=".$local_file."\n");
	$self->post_event('progress',$remote_file,1,100);
	sleep 1;
	$self->post_event('progress',$remote_file,33,100);
	sleep 1;
	$self->post_event('progress',$remote_file,66,100);
	sleep 1;
	$self->post_event('progress',$remote_file,99,100);
	sleep 1;
	$self->post_event('progress',$remote_file,100,100);
	my $errno = int(rand(3));
	$errno++ if($errno <= 0 && $self->object_extra_data('debug-want-error') );
	$errno = 0 if($self->object_extra_data('debug-want-success'));
	$state->current($errno);
	return $state;
}

sub _validate_url {
	my ($self,$url)=@_ ;
	if($url =~ m?^debug://.+?){
		_debug_print("validating the following url as a valid debug one : $url\n");
		return 1 ;
	}else{
		_debug_print("could not validate the following url as a valid debug one : $url\n");
		return 0;
	}
}

=head1 AUTHOR

DUPUIS Arnaud, C<< <a.dupuis at infinityperl.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-slackware-slackget-network-connection-debug at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Slackware-Slackget-Network-Connection-DEBUG>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Slackware::Slackget::Network::Connection::DEBUG


You can also look for information at:

=over 4

=item * Infinity Perl website

L<http://www.infinityperl.org>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Slackware-Slackget-Network-Connection-DEBUG>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Slackware-Slackget-Network-Connection-DEBUG>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Slackware-Slackget-Network-Connection-DEBUG>

=item * Search CPAN

L<http://search.cpan.org/dist/Slackware-Slackget-Network-Connection-DEBUG>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2007 DUPUIS Arnaud, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Slackware::Slackget::Network::Connection::DEBUG
