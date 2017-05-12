package Slackware::Slackget::Network::Connection::FTP;

use warnings;
use strict;

require Slackware::Slackget::Network::Connection ;
use Time::HiRes ;
require Net::FTP ;
require File::Copy;
require Slackware::Slackget::File ;

=head1 NAME

Slackware::Slackget::Network::Connection::FTP - This class encapsulate Net::FTP

=head1 VERSION

Version 1.0.0

=cut

our $VERSION = '1.0.0';
our @ISA = qw() ;

=head1 SYNOPSIS

This class encapsulate Net::FTP, and provide some methods for the treatment of FTP requests.

This class need the following extra CPAN modules :

	- Net::FTP
	- Time::HiRes

    use Slackware::Slackget::Network::Connection::FTP;

    my $foo = Slackware::Slackget::Network::Connection::FTP->new();
    ...

=cut

sub new
{
	my ($class,$url,$config) = @_ ;
	my $self = {};
# 	return undef if(!defined($config) && ref($config) ne 'Slackware::Slackget::Config');
# 	$self->{config} = $config ;
	return undef unless (is_url($self,$url));
	$self->{DATA}->{conn} = new Net::FTP ($url);
	bless($self,$class);
	$self->parse_url($url) ;
	return $self;
}

=head1 CONSTRUCTOR

=head2 new

This class is not designed to be instanciate alone or used alone. You have to use the Slackware::Slackget::Network::Connection.

=head1 FUNCTIONS

=head2 __test_server

This method test the rapidity of the mirror, by making a new connection to the server and logging in. Be aware of the fact that after testing the connection you will have a new connection (if you were previously connected the previous connection is closed).

	my $time = $connection->test_server() ;

=cut

sub __test_server {
	my $self = shift ;
# 	print "[debug http] protocol : $self->{DATA}->{protocol}\n";
# 	print "[debug http] host : $self->{DATA}->{host}\n";
	if(defined($self->{DATA}->{conn}))
	{
		$self->{DATA}->{conn}->close ;
		$self->{DATA}->{conn} = undef ;
	}
	
# 	print "[debug http] Testing a FTP server: $self->{DATA}->{host}\n";
	my $start_time = Time::HiRes::time();
# 	print "[debug http] \$start_time : $start_time\n";
	$self->{DATA}->{conn} = Net::FTP->new($self->{DATA}->{host}) or return undef;
	$self->{DATA}->{conn}->login($self->{DATA}->{config}->{'network-parameters'}->{ftp}->{login},$self->{DATA}->{config}->{'network-parameters'}->{ftp}->{password}) or return undef;
	my $stop_time = Time::HiRes::time();
# 	print "[debug http] \$stop_time: $stop_time\n";
	return ($stop_time - $start_time);
}

sub _connect 
{
	my $self = shift ;
# 	print "[_connect] test de config\n";
# 	print "[_connect] config param is $self->{DATA}->{config}\n";
	return undef if(!defined($self->{DATA}->{config}) && ref($self->{DATA}->{config}) ne 'Slackware::Slackget::Config') ;
# 	print "[_connect] test de l'existence d'une connexion\n";
	unless($self->{DATA}->{conn})
	{
# 		print "[_connect] pas de connexion : cr�tion\n";
		$self->{DATA}->{conn} = Net::FTP->new($self->{DATA}->{host}) or return undef;
# 		print "[_connect] login\n";
		$self->{DATA}->{conn}->login($self->{DATA}->{config}->{'network-parameters'}->{ftp}->{login},$self->{DATA}->{config}->{'network-parameters'}->{ftp}->{password}) or return undef;
	}
# 	print "[_connect] That's all folks\n";
	return 1;
}

=head2 _test_current_directory [PRIVATE]

This private methos is used internally each time you require a transfert, for testing if the current directory is the 'path' parameter of the DATA section of the current Connection object.

Do that by sending a PWD command to the server and compare the result with $connection->path.

	$ftp->cwd('/any/remote/directory/') unless($connection->_test_current_directory) ;

Due to the fact that this method is private and internal the example is not really explicit, please look at the code for more informations.

=cut

sub _test_current_directory {
	my $self = shift ;
# 	print "test de connexion\n";
	$self->_connect or return undef;
# 	print "r�ertoire courant : ",$self->conn->pwd,"\n";
# 	print "path : $self->{DATA}->{path}\n";
	my $tmp_path = $self->conn->pwd ;
	if( $self->{DATA}->{path}=~/^$tmp_path\/*$/)
	{
		return 1;
	}
	else
	{
# 		print "CHANGEMENT\n";
		$self->conn->cwd($self->{DATA}->{path}) or return undef;
		return 1;
	}
}

=head2 __get_file

Download and return a given file.

	my $file = $connection->get_file('PACKAGES.TXT') ;

Please note that the Net::FTP module doesn't support a method like that. So, this method is not an encapsulator like the one of HTTP.pm, and use Slackware::Slackget::File to return the content of the downloaded file.

So you'd better to use fetch_file().

=cut

sub __get_file {
	my ($self,$remote_file) = @_ ;
	$remote_file = $self->file unless(defined($remote_file)) ;
	srand (time ^ $$ ^ unpack "%L*", `ps axww | gzip`);
	my $name = $remote_file.'-' ;
	for(my $k=0;$k<=20;$k++){
		$name .= (0..9,'a'..'f')[int(rand(15))];
	}
# 	print "[Slackware::Slackget::Network::Connection::FTP] temp filename is '$name'\n";
	$self->_test_current_directory or return undef;
	$self->conn->get($remote_file,"/tmp/$name") or return undef;
	my $file = new Slackware::Slackget::File ("/tmp/$name",'file-encoding' => $self->{DATA}->{config}->{'file-encoding'}) or return undef ;
	return join "\n",$file->Get_file ;
# 	return get($self->protocol().'://'.$self->host().'/'.$self->path().'/'.$remote_file);
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

	my $status =  Slackware::Slackget::Status->new(codes => {
		0 => "All goes well.\n",
		1 => "An error occured "
	});


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
			warn "[Slackware::Slackget::Network::Connection::FTP] unable to determine the path to save $remote_file.\n";
			return undef;
		}
	}
# 	print "[debug ftp] save the fetched file (",$remote_file,") to $local_file\n";
	$self->_test_current_directory or return undef;
	my $state =  Slackware::Slackget::Status->new(codes => {
		0 => "All goes well.\n",
		1 => "An error occured, we recommend to change this server's host.\n"
	});
	if($self->conn->get($remote_file,$local_file.'.part'))
	{
		File::Copy::move( $local_file.'.part' , $local_file );
		$state->current(0);
	}
	else
	{
		$state->current(1);
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


=head2 conn

An accessor which return the current Net::FTP connection object

=cut

sub conn {
	my $self = shift;
	return $self->{DATA}->{conn};
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

L<http://www.infinityperl.org>

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

1; # End of Slackware::Slackget::Network::Connection::FTP
