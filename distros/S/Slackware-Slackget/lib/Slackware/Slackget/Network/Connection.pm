package Slackware::Slackget::Network::Connection;

use warnings;
use strict;
use Slackware::Slackget::Status ;

=head1 NAME

Slackware::Slackget::Network::Connection - A wrapper for network operation in slack-get

=head1 VERSION

Version 1.0.0

=cut

our $VERSION = '1.0.0';
our $ENABLE_DEPRECATED_COMPATIBILITY_MODE=0;
our $DEBUG= $ENV{SG_DAEMON_DEBUG};

# my %equiv = (
# 	'normal' => 'IO::Socket::INET',
# 	'secure' => 'IO::Socket::SSL',
# 	'ftp' => 'Net::FTP',
# 	'http' => 'LWP::Simple'
# );

our @ISA = qw();

=head1 SYNOPSIS

This class is anoter wrapper for slack-get. It will encapsulate all network operation. This class can chang a lot before the release and it may be rename in Slackware::Slackget::NetworkConnection.

=head2 Some words about subclass

WARNING: The Slackware::Slackget::Network::Connection::* "drivers" API changed with version 1.0.0

This class use subclass like Slackware::Slackget::Network::Connection::HTTP or Slackware::Slackget::Network::Connection::FTP as "drivers" for a specific protocol. 

You can add a "driver" class for a new protocol easily by creating a module in the Slackware::Slackget::Network::Connection:: namespace. 

You must know that all class the Slackware::Slackget::Network::Connection::* must implements the following methods (the format is : <method name(<arguments>)> : <returned value>, parmameters between [] are optionnals):

	- __test_server : a float (the server response time)
	- __fetch_file([$remote_filename],[$local_file]) : a boolean (1 or 0). NOTE: this method store the fetched file on the hard disk. If $local_file is not defined, fetch() must store the file in <config:update-directory> or in "download_directory" (constructor parameter).
	- __get_file([$remote_filename]) : the file content

Moreover, this "driver" have to respect the namming convention : the protocol name it implements in upper case (for example, if you implements a driver for the rsync:// protocol the module must be called Slackware::Slackget::Network::Connection::RSYNC.pm).

=head1 CONSTRUCTOR

=head2 new

WARNING: Since version 1.0.0 of this module you can't instanciate a Slackware::Slackget::Network::Connection object with a constructor with 1 argument. The followinf syntax is deprecated and no longer supported :

	my $connection = Slackware::Slackget::Network::Connection->new('http://www.nymphomatic.org/mirror/linuxpackages/Slackware-10.1/');

You can force this class to behave like the old version by setting $Slackware::Slackget::Network::Connection::ENABLE_DEPRECATED_COMPATIBILITY_MODE to 1 *BEFORE* calling the constructor.

This constructor take the followings arguments :

	host : a hostname (mandatory)
	path : a path on the remote host
	files : a arrayref wich contains a list of files to download
	config : a reference to a Slackware::Slackget::Config object (mandatory if "download_directory" is not defined)
	download_directory : a directory where this object can store fetched files (mandatory if "config" is not defined)
	InlineStates : a hashref which contains the reference to event handlers (mandatory)
	

	use Slackware::Slackget::Network::Connection;
	
	(1)
	my $connection = Slackware::Slackget::Network::Connection->new(
			host => 'http://www.nymphomatic.org',
			path => '/mirror/linuxpackages/Slackware-10.1/',
			files => ['FILELIST.TXT','PACKAGES.TXT','CHECKSUMS.md5'], # Be carefull that it's the files parameter not file. file is the current working file.
			config => $config,
			InlineStates => {
				progress => \&handle_progress ,
				download_error => \&handle_download_error ,
				download_finished => \&handle_download_finished,
			}
	);
	$connection->fetch_all or die "An error occur during the download\n";
	
	or (the recommended way) :
	
	(2)
	my $connection = Slackware::Slackget::Network::Connection->new(
			host => 'http://www.nymphomatic.org',
			path => '/mirror/linuxpackages/Slackware-10.1/',
			config => $config,
			InlineStates => {
				progress => \&handle_progress ,
				download_error => \&handle_download_error ,
				download_finished => \&handle_download_finished,
			}
	);
	my $file = $connection->get_file('FILELIST.TXT') or die "[ERROR] unable to download FILELIST.TXT\n";
	
	Instead of using the "config" parameter you can use "download_directory" :
	
	my $connection = Slackware::Slackget::Network::Connection->new(
			host => 'http://www.nymphomatic.org',
			path => '/mirror/linuxpackages/Slackware-10.1/',
			download_directory => "/tmp/",
			InlineStates => {
				progress => \&handle_progress ,
				download_error => \&handle_download_error ,
				download_finished => \&handle_download_finished,
			}
	);
	my $file = $connection->get_file('FILELIST.TXT') or die "[ERROR] unable to download FILELIST.TXT\n";
	
	or :
	
	my $status = $connection->fetch('FILELIST.TXT',"$config->{common}->{'update-directory'}/".$server->shortname."/cache/FILELIST.TXT");
	die "[ERROR] unable to download FILELIST.TXT\n" unless ($status);

The global way (1) is not recommended because of the lake of control on the downloaded file. For example, if there is only 1 download which fail, fetch_all will return undef and you don't know which download have failed.


The recommended way is to give to the constructor the following arguments :

	host : the host (with the protocol, do not provide 'ftp.lip6.fr' provide ftp://ftp.lip6.fr. The protocol will be automatically extracted and used to load the correct "driver")
	path : the path to the working directory on the server (Ex: '/pub/linux/distributions/slackware/slackware-10.1/'). Don't provide a 'file' argument.
	config : the Slackware::Slackget::Config object of the application
	mode : a mode between 'normal' or 'secure'. This is only when you attempt to connect to a daemon (front-end/daemon or daemon/daemon connection). 'secure' use SSL connection (** not yet implemented **).
	InlineStates : see above.

=cut

sub new
{
	my ($class,@args) = @_ ;
	print STDOUT "[Slackware::Slackget::Network::Connection] debug is enabled\n" if($DEBUG);
	my $self={};
	bless($self,$class);
# 	print "scalar: ",scalar(@args),"\n";
	if(scalar(@args) < 1){
		warn "[Slackware::Slackget::Network::Connection] you must provide arguments to the constructor. Please have a look at the documentation :\n\tperldoc Slackware::Slackget::Network::Connection\n" ;
		return undef ;
	}
	elsif(scalar(@args) == 1 && $ENABLE_DEPRECATED_COMPATIBILITY_MODE){
		print "[Slackware::Slackget::Network::Connection] [debug] ENABLE_DEPRECATED_COMPATIBILITY_MODE is activate.\n" if($DEBUG);
		if(is_url($self,$args[0])){
			parse_url($self,$args[0]) or return undef; # here is a really paranoid test because if this test fail it fail before (at is_url), so the "or return undef" is "de trop"
			_load_network_module($self) or return undef;
		}
		else{
			return undef;
		}
	}
	else{
		print "[Slackware::Slackget::Network::Connection] [debug] we are working in \"new mode\"\n" if($DEBUG);
		my %args = @args;
# 		warn "[Slackware::Slackget::Network::Connection] You need to provide a \"config\" parameter with a valid Slackware::Slackget::Config object reference.\n" if(!defined($args{config}) && ref($args{config}) ne 'Slackware::Slackget::Config') ;
		if(exists($args{host}) && ((exists($args{config}) && ref($args{config}) eq 'Slackware::Slackget::Config') || defined($args{download_directory})) ) #(exists($args{path}) || exists($args{file}) ) && 
		{
			$self->{DATA}->{download_directory}=$args{download_directory} if(defined($args{download_directory}));
			print "[Slackware::Slackget::Network::Connection] [debug] parsing url\n" if($DEBUG);
			parse_url($self,$args{host}) or return undef;
			print "[Slackware::Slackget::Network::Connection] [debug] going to load network's drivers\n" if($DEBUG);
			_load_network_module($self) or return undef;
			print "[Slackware::Slackget::Network::Connection] [debug] going to fill the internal data section\n" if($DEBUG);
			_fill_data_section($self,\%args);
			if(defined($args{InlineStates}) && ref($args{InlineStates}) eq 'HASH'){
				$self->{InlineStates} = $args{InlineStates};
				foreach ('progress','download_error','download_finished'){
					print "[Slackware::Slackget::Network::Connection] [debug] testing InlineStates/$_\n" if($DEBUG);
					unless(exists($self->{InlineStates}->{$_}) && defined($self->{InlineStates}->{$_})){
						warn "[Slackware::Slackget::Network::Connection] you must provide a sub reference as InlineStates->$_.\n";
						return undef;
					}
				}
			}
			else{
				warn "[Slackware::Slackget::Network::Connection] you must provide some InlineStates.\n";
				return undef;
			}
		}
		else
		{
			warn "[Slackware::Slackget::Network::Connection] you must provide the following parameters to the constructor :\n\thost\n\tconfig or download_directory\n" ;
			return undef ;
		}
		%args = ();
	}
	$self->{OVAR} = {};
	$self->__init_subclass if($self->can('__init_subclass'));
	@args = ();
# 	$self->{STATUS} = {
# 		0 => "All's good\n";
# 	}
	return $self;
}

=head1 EVENTS

Since the version 1.0.0 this class is event driven. To manage those events *YOU HAVE* to pass an InlineStates argument to the constructor (L<new>).

There is 3 events generated by this class :

	* progress : this event is throw when a progress is detected on file download. The handler will receive the followings parameters (in this order) : the downloaded filename, the amount of data downloaded, the total size of the remote file.
	
	* download_error : this is throw when an error occured during download. The handler will receive the following parameters (in this order) : the downloaded filename, a Slackware::Slackget::Status object.
	
	*download_finished : this is throw when a download finished successfully. The handler will receive the following parameters (in this order) : the downloaded filename, a Slackware::Slackget::Status object.

=head1 FUNCTIONS

=head2 is_url

Take a string as argument and return TRUE (1) if $string is an http or ftp URL and FALSE (0) else

	print "$string is a valid URL\n" if($connection->is_url($string)) ;

=cut

sub is_url {
	my ($self,$url)=@_;
	if( defined($self) && $self->can('_validate_url') ){
		if( $self->_validate_url($url) ){
			return 1;
		}
	}
	if($url=~ /file:\/\/(.+)/)
	{
		return 1;
	}
	elsif($url=~ /^(.+):\/\/([^\/]+){1}(\/.*)?$/){
		return 1;
	}
	else{
		return 0 ;
	}
}

=head2 parse_url

extract the following informations from $url :

	- the protocol 
	- the server
	- the file (with its total path)

For example :

	$connection->parse_url("ftp://ftp.lip6.fr/pub/linux/distributions/slackware/slackware-current/slackware/n/dhcp-3.0.1-i486-1.tgz");

Will extract :

	- protocol = ftp
	- host = ftp.lip6.fr
	- file = /pub/linux/distributions/slackware/slackware-current/slackware/n/dhcp-3.0.1-i486-1.tgz

This method return TRUE (1) if all goes well, else return FALSE (0)

=cut

sub parse_url {
	my ($self,$url)=@_;
	return 0 unless(defined($url));
	if($url=~ /file:\/\/(.+)/)
	{
		$self->{DATA}->{protocol} = 'file';
		$self->{DATA}->{file} = $1;
		print "[Slackware::Slackget::Network::Connection] [debug] file is set to $self->{DATA}->{file} fo object $self\n" if($DEBUG);
		#if we can extract a file name and a directory path we do.
		if(defined($self->{DATA}->{file}) && $self->{DATA}->{file}=~ /^(.+\/)([^\/]*)$/i)
		{
			$self->{DATA}->{path} = $1;
			$self->{DATA}->{file} = $2;
			if($DEBUG){
				print "[Slackware::Slackget::Network::Connection] [debug] path is set to $self->{DATA}->{path} fo object $self\n";
				print "[Slackware::Slackget::Network::Connection] [debug] file is set to $self->{DATA}->{file} fo object $self\n";
			}
		}
		return undef unless($self->{DATA}->{path});
		return 1;
	}
	elsif(my @tmp = $url=~ /^(.+):\/\/([^\/]+){1}(\/.*)?$/){
		$self->{DATA}->{protocol} = $1;
		$self->{DATA}->{host} = $2;
		$self->{DATA}->{file} = $3;
		if($DEBUG){
			print "[Slackware::Slackget::Network::Connection] [debug] protocol is set to $self->{DATA}->{protocol} fo object $self\n";
			print "[Slackware::Slackget::Network::Connection] [debug] host is set to $self->{DATA}->{host} fo object $self\n";
			print "[Slackware::Slackget::Network::Connection] [debug] file is set to $self->{DATA}->{file} fo object $self\n";
		}
		#if we can extract a file name and a directory path we do.
		if(defined($self->{DATA}->{file}) && $self->{DATA}->{file}=~ /^(.*\/)([^\/]*)$/i)
		{
			$self->{DATA}->{path} = $1;
			$self->{DATA}->{file} = $2;
		}
		
		return 1;
	}
	else{
		return 0 ;
	}
}

=head2 strip_slash

Remove extra slash (/) in the URL and return the URL.

	my $url = $connection->strip_slash('http://ftp.infinityperl.org//slackware-repository////CHECKSUMS.md5') ;

=cut

sub strip_slash
{
	my ($self,$url) = @_;
	$url=~ s/\/+/\//g;
	if($url=~ /\/{2,}/)
	{
		$self->strip_slash($url);
	}
	else
	{
		$url=~ s/http:\//http:\/\//;
		$url=~ s/ftp:\//ftp:\/\//;
		$url=~ s/file:\//ftp:\/\//;
		return $url;
	}
}

sub _load_network_module {
	my $self = shift;
	my $driver='Slackware::Slackget::Network::Connection::'.uc($self->{DATA}->{protocol});
	print "[Slackware::Slackget::Network::Connection] [debug] preparing to load $driver driver.\n" if($DEBUG);
	eval "require $driver;";
	if($@){
		warn "[Slackware::Slackget::Network::Connection] driver for the network protocol '$self->{DATA}->{protocol}' is not available ($@).\n" ;
		return undef ;
	}
	else{
		push @ISA, $driver ;
		print "[Slackware::Slackget::Network::Connection] [debug] checking if driver $self->{DATA}->{protocol} support all required methods.\n" if($DEBUG);
		return undef unless($self->_check_driver_support_methods);
	}
	return 1;
}

sub _check_driver_support_methods {
	my $self = shift ;
	foreach ('__fetch_file','__get_file','__test_server'){
		return undef unless($self->can($_)) ;
		print "[Slackware::Slackget::Network::Connection] [debug] driver $self->{DATA}->{protocol} support $_() method.\n" if($DEBUG);
	}
	return 1;
}

sub _fill_data_section {
	my $self = shift;
	my $args = shift;
	foreach (keys(%{$args})){
		$self->{DATA}->{$_} = $args->{$_} if(!(defined($self->{DATA}->{$_})));
	}
}

=head2 DEBUG_show_data_section

=cut

sub DEBUG_show_data_section
{
	my $self = shift;
	print "===> DATA section of $self <===\n";
	foreach (keys(%{$self->{DATA}}))
	{
		print "$_ : $self->{DATA}->{$_}";
	}
	print "===> END DATA section <===\n";
}

=head2 test_server

This method test the response time of the mirror, by making a new connection to the server and downloading the FILELIST.TXT file. Be aware of the fact that after testing the connection you will have a new connection (if you were previously connected the previous connection is closed).

	my $time = $connection->test_server() ;

This method call the <DRIVER>->__test_server() method.

=cut

sub test_server {
	my $self = shift;
	$self->__test_server ;
}

=head2 get_file

Download and return a given file.

	my $file = $connection->get_file('PACKAGES.TXT') ;

This method also generate events based on the returned value. If nothing is returned it throw the "download_error" event, else it throw the "download_finished" event.

At this for the moment this method throw a "progress" event with a progress value set at -1.

This method call the <DRIVER>->__get_file() method.

=cut

sub get_file {
	my ($self,$file) = @_;
	$self->post_event('progress',$file,-1,-9999);
	my $state =  Slackware::Slackget::Status->new(codes => {
		0 => "All goes well.\n",
		1 => "An error occured, we recommend to change this server's host.\n"
	});
	my $content = $self->__get_file($file);
	if(defined($content)){
		$state->current(0);
		$self->post_event('download_finished',$file,$state);
		return \$content;
	}else{
		$state->current(1);
		$self->post_event('download_error',$file,$state);
		undef($content);
		return undef;
	}
}

=head2 fetch_file

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

A more explicit error string can be concatenate to state 1. This method also generate events based on the returned value. If nothing is returned it throw the "download_error" event, else it throw the "download_finished" event.

All codes greater or equal than 1 should be considered as errors codes.

At this for the moment this method throw a "progress" event with a progress value set at -1.

This method call the <DRIVER>->__fetch_file() method.

=cut

sub fetch_file {
	my ($self,$file,@args) = @_;
	$self->post_event('progress',$file,-1,-9999);
	my $status = $self->__fetch_file($file,@args);
	if($status->current > 0){
		$self->post_event('download_error',$file,$status);
	}else{
		$self->post_event('download_finished',$file,$status);
	}
	return $status;
}

=head2 fetch_all

This method fetch all files declare in the "files" parameter of the constructor.

	$connection->fetch_all or die "Unable to fetch all files\n";

This method save all files in the $config->{common}->{'update-directory'} (or in the "download_directory") directory (so you have to manage yourself the files deletion/replacement problems).

=cut

sub fetch_all {
	my $self = shift ;
	foreach (@{$self->files}){
		$self->fetch_file($_) or return undef;
	}
	return 1 ;
}

=head2 post_event


=cut

sub post_event {
	my ($self,$event,@args)=@_;
	$self->{InlineStates}->{$event}->(@args,$self);
}

=head1 ACCESSORS

All accessors can get or set a value. You can use them like that :

	$proto->my_accessor('a value'); # to set the value of the parameter controlled by this accessor
	
	my $value = $proto->my_accessor ; # to get the value of the parameter controlled by this accessor

The common accessors are :

=cut

=head2 protocol

return the protocol of the current Connection object as a string :

	my $proto = $connection->protocol ;

=cut

sub protocol {
	return $_[1] ? $_[0]->{DATA}->{protocol}=$_[1] : $_[0]->{DATA}->{protocol};
}

=head2 host

return the host of the current Connection object as a string :

	my $host = $connection->host ;

=cut

sub host {
	return $_[1] ? $_[0]->{DATA}->{host}=$_[1] : $_[0]->{DATA}->{host};
}

=head2 file

return the file of the current Connection object as a string :

	my $file = $connection->file ;

=cut

sub file {
	return $_[1] ? $_[0]->{DATA}->{file}=$_[1] : $_[0]->{DATA}->{file};
}

=head2 files

return the list of files of the current Connection object as an array reference :

	my $arrayref = $connection->files ;

=cut

sub files {
	return $_[1] ? $_[0]->{DATA}->{files}=$_[1] : $_[0]->{DATA}->{files};
}

=head2 path

return or set the path of the current Connection object as a string :

	my $path = $connection->path ;

=cut

sub path {
	return $_[1] ? $_[0]->{DATA}->{path}=$_[1] : $_[0]->{DATA}->{path};
}

=head2 download_directory

set or return the download_directory for the current Connection object as string :

	my $dl_dir = $connection->download_directory ;

=cut

sub download_directory {
	my ($self,$dir) = @_;
	if(defined($dir) && -e $dir){
		$self->{DATA}->{config}->{common}->{'update-directory'} = undef;
		$self->{DATA}->{download_directory} = undef;
		$self->{DATA}->{download_directory} = $dir;
		return $self->{DATA}->{download_directory};
	}
	if(defined($self->{DATA}->{download_directory}) && -e $self->{DATA}->{download_directory}){
		return $self->{DATA}->{download_directory} ;
	}
	elsif(defined($self->{DATA}->{config})){
		return $self->{DATA}->{config}->{common}->{'update-directory'} ;
	}
	return undef;
}

=head2 object_extra_data

This accessor allow you to store and retrieve random data in the connection object.

For example, the slack-get daemon (sg_daemon) use the media id to keep tracks of all connection objects and 
for the reverse resolution, it need to identify the media id from the Connection object. It's done by  the following code :

	$connection->object_extra_data('shortname', $media->shortname());

Extra data are not stored in the same space than object data.

=cut

sub object_extra_data {
	my ($self,$var,$val) = @_;
	if(defined($val)){
		$self->{OVAR}->{$var} = $val;
	}else{
		return $self->{OVAR}->{$var};
	}
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

1; # End of Slackware::Slackget::Network::Connection
