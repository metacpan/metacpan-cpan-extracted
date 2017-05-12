package Slackware::Slackget::Network::Connection::FILE;

use warnings;
use strict;

require Slackware::Slackget::Network::Connection ;
require Time::HiRes ;
require Slackware::Slackget::Status ;
use File::Copy ;
use Slackware::Slackget::File;

=head1 NAME

Slackware::Slackget::Network::Connection::FILE - This class is the file:// protocol driver for Slackware::Slackget::Network::Connection

=head1 VERSION

Version 1.0.0

=cut

our $VERSION = '0.6.0';
# our @ISA = qw( Slackware::Slackget::Network::Connection ) ;

=head1 SYNOPSIS

This class is the file:// protocol driver for Slackware::Slackget::Network::Connection.

You can't use this class without the Slackware::Slackget::Network::Connection one.

This class need the following extra CPAN modules :

	- File::Copy
	- Time::HiRes


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

=head2 __test_server

This method test the rapidity of the repository, by timing a copy of the FILELIST.TXT file.

	my $time = $self->test_server() ;

=cut

sub __test_server {
	my $self = shift ;
# 	print "[debug file] protocol : $self->{DATA}->{protocol}\n";
# 	print "[debug file] host : $self->{DATA}->{host}\n";
	my $file = $self->{DATA}->{path}.'/'.'FILELIST.TXT';
	$file = $self->strip_slash($file);
	return undef unless( -e $file);
	my $start_time = Time::HiRes::time();
	my @head = copy($file,'/tmp/FILELIST.TXT') or return undef;
	my $stop_time = Time::HiRes::time();
	unlink '/tmp/FILELIST.TXT';
	return ($stop_time - $start_time);
}

=head2 __get_file

Return the given file.

	my $file = $connection->get_file('PACKAGES.TXT') ;

You can pass an extra argument (boolean) to mark the file as a binary one.

=cut

sub __get_file {
	my ($self,$remote_file,$binary) = @_ ;
	$remote_file = $self->file unless(defined($remote_file)) ;
	my $file;
	if($binary or $remote_file =~ /\.tgz$/)
	{
		$file = Slackware::Slackget::File->new($self->strip_slash($self->path().'/'.$remote_file), 'binary' => 1);
	}
	else
	{
		$file = Slackware::Slackget::File->new($self->strip_slash($self->path().'/'.$remote_file), 'binary' => 0);
	}
	return $file->Get_file ;
}

=head2 __fetch_file

Copy a given file to a given location.

	$connection->fetch_file() ; # download the file $connection->file and store it at $config->{common}->{'update-directory'}/$connection->file, this way is not recommended
	or
	$connection->fetch_file($remote_file) ; # download the file $remote_file and store it at $config->{common}->{'update-directory'}/$connection->file, this way is not recommended
	or
	$connection->fetch_file('PACKAGES.TXT',"$config->{common}->{'update-directory'}/".$current_specialfilecontainer_object->id."/PACKAGES.TXT") ; # This is the recommended way.
	# This is equivalent to : $connection->fetch_file($remote_file,$local_file) ;

This method return a Slackware::Slackget::Status object with the following object declaration :

	my $state =  Slackware::Slackget::Status->new(codes => {
		0 => "All goes well. Server said: $ret_code - ".status_message( $ret_code ),
		1 => "Destination directory does not exist.\n",
		2 => "Destination directory is not writable.\n",
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
			warn "[Slackware::Slackget::Network::Connection::FILE] unable to determine the path to save $remote_file.\n";
			return undef;
		}
	}
	my $url = $self->path().'/'.$remote_file;
	$url = $self->strip_slash($url);
# 	print "[debug file] save the fetched file ($url) to $local_file\n";
	my $state =  Slackware::Slackget::Status->new(codes => {
		0 => "All goes well.",
		1 => "Destination directory does not exist.",
		2 => "Destination directory is not writable.",
	});
	if(copy($url,$local_file.'.part')){
		move($local_file.'.part',$local_file);
		$state->current(0);
	}
	else
	{
		if(! -e $self->path())
		{
			
			$state->current(1);
			
		}
		elsif(! -w $self->path())
		{
			$state->current(2);
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

1; # End of Slackware::Slackget::Network::Connection::FILE
