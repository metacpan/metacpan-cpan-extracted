package Slackware::Slackget::Network::Connection::HTTP;

use warnings;
use strict;

use LWP::Simple ;
use File::Basename ;
require File::Copy;
require HTTP::Status ;
require Slackware::Slackget::Network::Connection ;
require Time::HiRes ;
require Slackware::Slackget::Status ;
# use POE::Component::Client::HTTP;

=head1 NAME

Slackware::Slackget::Network::Connection::HTTP - This class encapsulate LWP::Simple

=head1 VERSION

Version 1.0.0

=cut

our $VERSION = '1.0.0';
# our @ISA = qw( Slackware::Slackget::Network::Connection ) ;

=head1 SYNOPSIS

This class encapsulate LWP::Simple, and provide some methods for the treatment of HTTP requests.

You can't use this class without the Slackware::Slackget::Network::Connection one.

This class need the following extra CPAN modules :

	- LWP::Simple
	- Time::HiRes

    use Slackware::Slackget::Network::Connection::HTTP;

    my $foo = Slackware::Slackget::Network::Connection::HTTP->new();
    ...

This module require the following modules from CPAN : LWP::Simple, Time::HiRes.

=cut

sub new
{
	my ($class,$url,$config) = @_ ;
	my $self = {};
# 	return undef if(!defined($config) && ref($config) ne 'HASH');
	return undef unless (is_url($self,$url));
	bless($self,$class);
	$self->parse_url($url) ;
	return $self;
}

=head1 CONSTRUCTOR

=head2 new

This class is not designed to be instanciate alone or used alone. You have to use the Slackware::Slackget::Network::Connection.

=head1 FUNCTIONS

=head2 test_server

This method test the rapidity of the mirror, by timing a head request on the FILELIST.TXT file.

	my $time = $self->test_server() ;

=cut

sub __test_server {
	my $self = shift ;
# 	print "[debug http] protocol : $self->{DATA}->{protocol}\n";
# 	print "[debug http] host : $self->{DATA}->{host}\n";
	my $server = "$self->{DATA}->{protocol}://$self->{DATA}->{host}/";
	$server .= $self->{DATA}->{path}.'/' if($self->{DATA}->{path});
	$server .= 'FILELIST.TXT';
	$server = $self->strip_slash($server);
# 	print "[debug http] Testing a HTTP server: $server\n";
	my $start_time = Time::HiRes::time();
# 	print "[debug http] \$start_time : $start_time\n";
	my @head = head($server) or return undef;
	my $stop_time = Time::HiRes::time();
# 	print "[debug http] \$stop_time: $stop_time\n";
	return ($stop_time - $start_time);
}

=head2 __get_file

Download and return a given file.

	my $file = $connection->get_file('PACKAGES.TXT') ;

=cut

sub __get_file {
	my ($self,$remote_file) = @_ ;
	$remote_file = $self->file unless(defined($remote_file)) ;
	return get($self->strip_slash($self->protocol().'://'.$self->host().'/'.$self->path().'/'.$remote_file));
}

=head2 __fetch_file

Download and store a given file.

	$connection->fetch_file() ; # download the file $connection->file and store it at $config->{common}->{'update-directory'}/$connection->file, this way is not recommended
	or
	$connection->fetch_file($remote_file) ; # download the file $remote_file and store it at $config->{common}->{'update-directory'}/$connection->file, this way is not recommended
	or
	$connection->fetch_file('PACKAGES.TXT',"$config->{common}->{'update-directory'}/".$current_specialfilecontainer_object->id."/PACKAGES.TXT") ; # This is the recommended way.
	# This is equivalent to : $connection->fetch_file($remote_file,$local_file) ;

This method return a Slackware::Slackget::Status object with the following object declaration :

	my $state =  Slackware::Slackget::Status->new(codes => {
		0 => "All goes well.<br/> Server said: <br/>$ret_code - ".status_message( $ret_code ),
		1 => "Server error, you must choose the next host for this server.<br/> Server said: $ret_code - $tmp_status_message",
		2 => "Client error, it seems that you have a problem with you connection or with the slackget10 library <br/>(or with a library which we depended on). It is also possible that the file we try to download was not on the remote server.<br/> Server said: <br/>$ret_code - $tmp_status_message",
		3 => "Server has redirected us, we prefer direct connection, change host for this server.<br/> Server said: <br/>$ret_code - $tmp_status_message",
		4 => "The HTTP connection is not a success and we are not able to know what, we recommend to change the current host of this server.<br/> Server said: <br/>$ret_code - $tmp_status_message"
	});

This is the direct code of this method :)

=cut

sub __fetch_file {
	my ($self,$remote_file,$local_file) = @_ ;
	$remote_file = $self->file unless(defined($remote_file));
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
			warn "[Slackware::Slackget::Network::Connection::HTTP] unable to determine the path to save $remote_file.\n";
			return undef;
		}
	}
	my $url = $self->protocol().'://'.$self->host().'/'.$self->path().'/'.$remote_file;
	$url = $self->strip_slash($url);
#  	print "\n[debug http] save the fetched file ($url) to $local_file\n";
	my $ret_code = getstore($url,$local_file.'.part') ;
	File::Copy::move($local_file.'.part',$local_file);
	my $tmp_status_message = status_message( $ret_code );
	$tmp_status_message=~ s/\n/<br\/>/g;
	my $state =  Slackware::Slackget::Status->new(codes => {
		0 => "All goes well.<br/> Server said: <br/>$ret_code - $tmp_status_message",
		1 => "Server error, you must choose the next host for this server.<br/> Server said: <br/>$ret_code - $tmp_status_message",
		2 => "Client error, it seems that you have a problem with you connection or with the Slackware::Slackget library <br/>(or with a library which we depended on). It is also possible that the file we try to download was not on the remote server.<br/> Server said: <br/>$ret_code - $tmp_status_message",
		3 => "Server has redirected us, we prefer direct connection, change host for this server.<br/> Server said: <br/>$ret_code - $tmp_status_message",
		4 => "The HTTP connection is not a success and we are not able to know what is the problem, we recommend to change the current host of this server.<br/> Server said: <br/>$ret_code - $tmp_status_message"
	});
	if(is_success($ret_code)){
		File::Copy::move( $local_file.'.part' , $local_file );
		$state->current(0);
	}
	else
	{
		if(HTTP::Status::is_server_error($ret_code))
		{
			
			$state->current(1);
			
		}
		elsif(HTTP::Status::is_client_error($ret_code))
		{
			$state->current(2);
		}
		elsif(HTTP::Status::is_redirect($ret_code))
		{	
			$state->current(3);	
		}
		else
		{
			$state->current(4);
		}
	}
	return $state;
}

=head2 __fetch_all

This method fetch all files declare in the "files" parameter of the constructor.

	$connection->fetch_all or die "Unable to fetch all files\n";

This method save all files in the $config->{common}->{'update-directory'} directory (so you have to manage yourself the files deletion/replacement problems)

=cut

sub __fetch_all {
	my $self = shift ;
	foreach (@{$self->files}){
		$self->fetch_file($_) or return undef;
	}
	return 1 ;
}


=head2 __download

This method is introduced with the 0.11 release of slackget10 and is the one used to emulate POE behaviour.

This method is here in order to simplify the migration to the new POE based architecture.

download() take only one argument : a file to download and it will call all needed InlineStates when it's possible.

=cut

sub __download {
	my ($self,$file) = @_ ;
}


=head1 AUTHOR

DUPUIS Arnaud, C<< <a.dupuis@infinityperl.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-Slackware-Slackget@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Slackware-Slackget>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Slackware::Slackget


You can also look for information at:

=over 4

=item * Infinity Perl website

L<http://www.infinityperl.org/category/slack-get>

=item * slack-get specific website

L<http://slackget.infinityperl.org>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Slackware-Slackget>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Slackware-Slackget>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Slackware-Slackget>

=item * Search CPAN

L<http://search.cpan.org/dist/Slackware-Slackget>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Bertrand Dupuis (yes my brother) for his contribution to the documentation.

=head1 COPYRIGHT & LICENSE

Copyright 2005 DUPUIS Arnaud, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Slackware::Slackget::Network::Connection::HTTP
