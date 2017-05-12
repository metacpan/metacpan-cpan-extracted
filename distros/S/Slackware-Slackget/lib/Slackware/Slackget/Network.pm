package Slackware::Slackget::Network;

use warnings;
use strict;
use constant {
	SLACK_GET_PROTOCOL_VERSION => 0.5,
	SLACK_GET_PROTOCOL_MESSAGE_START => 0x4200,
	SLACK_GET_PROTOCOL_ACK => 0x4201,
	SLACK_GET_PROTOCOL_NACK => 0x4202,
	SLACK_GET_PROTOCOL_SERVER_END_CONNECTION => 0x4203,
	SLACK_GET_PROTOCOL_MESSAGE_STOP => 0x4242,
	SLACK_GET_PROTOCOL_NEGOCIATION_QUERY_SEND_BACKENDS_LIST => 0x4211,
	SLACK_GET_PROTOCOL_NEGOCIATION_QUERY_SEND_AGREEMENT => 0x4212,
	SLACK_GET_PROTOCOL_NEGOCIATION_QUERY_SEND_ACK => 0x4213,
	SLACK_GET_PROTOCOL_INFO_LEVEL_STANDARD => 0x4250,
	SLACK_GET_PROTOCOL_INFO_LEVEL_IMPORTANT => 0x4251,
	SLACK_GET_PROTOCOL_INFO_LEVEL_PKG => 0x4252,
	SLACK_GET_PROTOCOL_INFO_LEVEL_EMERGENCY => 0x4253,
};
require Slackware::Slackget::Network::Message ;
# require XML::Simple;

=head1 NAME

Slackware::Slackget::Network - A class for network communication

=head1 VERSION

Version 1.0.0 (this version number is absolutly irrelevant and should be considered as an error, real version number is 0.8.2 and is accessible through the $VERSION_REAL variable)

=cut

our $VERSION = '1.0.0';
our $VERSION_REAL='0.8.3';
our @ISA;
my @BACKENDS = ('XML');

=head1 SYNOPSIS

WARNING WARNING : this module's API and behaviour changed a lot since the 0.12 release ! Please take good care of this : WARNING WARNING

This class' purpose is to make all network dialog transparent. You give to this class the raw (XML) network message sent to (or from) a slack-get daemon (sg_daemon) and Slackware::Slackget::Network decode and wrap it for you.
The "plus" of this system is that sg_daemon (or any slack-get client) developpers are safe if something change in the network protocol : it will never change the API.

    use Slackware::Slackget::Network;

    my $net = Slackware::Slackget::Network->new();
    my $message_object = new Slackware::Slackget::Network::Message ;
    $message_object->action('get_connection_id');
    my $xml_msg = $net->encode($message_object);
    my $response_object = $net->decode($xml_msg);
    # $message_object and $response_object are equals in term of values

All methods from this module return a Slackware::Slackget::Network::Message (L<Slackware::Slackget::Network::Message>) object.

Since the 0.12 release of this module this module is nothing more than a encoder/decoder for slack-get's network messages. So no more network handling nor automatic response sent directly through the socket passed as argument.

=cut

sub new
{
	my ($class,%args) = @_ ;
	sub _create_random_id
	{
		my $newpass='';
		for (my $k=1;$k<=56;$k++)
		{
			my $lettre = ('a'...'z',1...9)[35*rand];
			$newpass.=$lettre;
		}
		return $newpass;
	}
	my $self = { _backends => [], _supported_backends => [], _mode => 'server' };
	$self->{_mode} = $args{mode} if( defined($args{mode}) && ($args{mode} eq 'server' || $args{mode} eq 'client') );
	print "[Slackware::Slackget::Network] debug mode activated\n" if($ENV{SG_DAEMON_DEBUG});
# 	my $backend = 'Slackware::Slackget::Network::Backend::XML';
# 	$backend = $args{backend} if(defined($args{backend}));
	
	$args{backends} = [@BACKENDS] unless( defined($args{backends}) );
	foreach my $b (@{$args{backends}}){
		my $backend = "Slackware::Slackget::Network::Backend::$b";
		eval "require $backend;";
		if($@){
			warn "[Slackware::Slackget::Network] backend \"$backend\" cannot be load ($@).\n";# Fall back to Slackware::Slackget::Network::Backend::XML.\n" ;
# 			eval "require Slackware::Slackget::Network::Backend::XML;";
# 			if($@){
# 				warn "[Slackware::Slackget::Network] backend Slackware::Slackget::Network::Backend::XML is not available either. This is critical we can't continue.\n" ;
# 				return undef;
# 			}
		}else{
			my $bo;
			print "[Slackware::Slackget::Network] [debug] creating new $backend object.\n" if($ENV{SG_DAEMON_DEBUG});
			$bo = $backend->new ;
			print "[Slackware::Slackget::Network] [debug] object is $bo.\n" if($ENV{SG_DAEMON_DEBUG});
			push @{$self->{_backends}}, $bo;
			push @{$self->{_supported_backends}}, $b;
		}
	}
	$self->{_PRIV}->{CONNID} = _create_random_id() ;
	print "[Slackware::Slackget::Network] [debug] [constructor] CONNID is $self->{_PRIV}->{CONNID}.\n" if($ENV{SG_DAEMON_DEBUG});
	$self->{_PRIV}->{ACTIONID} = int((rand(10000)+1) * (rand(10000)+1));
	$self->{_PRIV}->{CACHE} = '';
	bless($self,$class);
	return $self;
}

=head1 CONSTRUCTOR

=head2 new

You can pass the following arguments to the constructor :

* backends => <ARRAYREF>
	my $net = Slackware::Slackget::Network->new(backends => [ 'ZIP' , 'XML' ]);
	# **ATTENTION ** : the order you give to the backends determine the way it will encode/decode messages !
	# in this exemple, decode() will call :
	#	|_ ZIP->backend_decode()
	#	|_ XML->backend_decode()
	# And encode() will call :
	#	|_ XML->backend_encode()
	#	|_ ZIP->backend_encode()

The only included backend is the XML one for the moment. If the backend could not be loaded the constructor fall back to the XML backend.

=head1 FUNCTIONS

All methods return a Slackware::Slackget::Network::Message (L<Slackware::Slackget::Network::Message>) object, and if the remote slack-getd return some data they are accessibles via the data() accessor of the Slackware::Slackget::Network::Message object.

=cut

=head2 decode

Decode a Slackware::Slackget::Network::Message by going through the backend decoding stack.

=cut

sub decode {
	my $self = shift;
	my $input = shift;
	print "[Slackware::Slackget::Network] [debug] decode($input)\n" if($ENV{SG_DAEMON_DEBUG});
	my $output = $input ;
	foreach my $backend (@{$self->{_backends}}){
		print "[Slackware::Slackget::Network] [debug] using backend $backend to decode data\n" if($ENV{SG_DAEMON_DEBUG});
		$output = $backend->backend_decode($output);
	}
	return $output;
}

=head2 encode

Encode a Slackware::Slackget::Network::Message by going through the backend encoding stack.

=cut

sub encode {
	my $self = shift;
	my $message = shift ;
	if($ENV{SG_DAEMON_DEBUG}){
		print "[Slackware::Slackget::Network] [debug] encode() incoming message : $message, dump is :\n";
		require Data::Dumper; print Data::Dumper::Dumper($message),"\n";
	}
	my $output = $message ;
	foreach my $backend (reverse( @{$self->{_backends}} )){
		print "[Slackware::Slackget::Network] [debug] encode() going through $backend\n" if($ENV{SG_DAEMON_DEBUG});
		$output = $backend->backend_encode($output);
	}
	return $output ;
}

=head2 interpret

Interpret a Slackware::Slackget::Network::Message. "Interpret" means "execute actions".

So the interpretable Slackware::Slackget::Network::Message are those supported by this module.

Currently supported actions are : get_connection_id

=cut

sub interpret {
	my $self = shift;
	my $message = shift ;
	return undef unless(defined($message));
	if(defined($message->action)){
		my $func = '__'.$message->action;
		if($self->can($func.'_mode_'.$self->{_mode})) {
			$func = $func.'_mode_'.$self->{_mode};
			print "[Slackware::Slackget::Network] [debug] interpret($message) through $func\n" if($ENV{SG_DAEMON_DEBUG});
			return $self->$func($message) ;
		}elsif($self->can($func)){
			print "[Slackware::Slackget::Network] [debug] interpret($message) through $func\n" if($ENV{SG_DAEMON_DEBUG});
			return $self->$func($message) ;
		}else{
			print "[Slackware::Slackget::Network] [debug] cannot interpret $message\n" if($ENV{SG_DAEMON_DEBUG});
			return undef;
		}
	}
}

=head2 generate

Generate a new Slackware::Slackget::Network::Message formatted for a specific action. Like interpret() it works only with a subset of available actions.

Only the major actions are hardcoded to be automatically generated.

You can generate messages for the following actions : search, build_medias_list, build_update_list, build_installed_list, notification, upgradepkg, installpkg, removepkg, get_patches_list.

=cut

sub generate {
	my $self = shift;
	my $str_msg = shift;
	my @extra_args = @_;
	return undef unless(defined($str_msg));
	my $func = '__'.$str_msg;
	if( $self->can($func.'_generate') ){
		$func = $func.'_generate';
		return $self->$func(@extra_args) ; # only *_generate specific function can receive arguments
	}
	elsif($self->can($func)){
		return $self->$func() ;
	}else{
		return undef;
	}
}

=head2 backends_list

Return the list of supported backends. 

backends_list() returned list contains only backends that can be loaded an instanciated.

=cut

sub backends_list {
	my $self = shift;
	return @{$self->{_supported_backends}}
}

=head2 scan_backends

Return a list of available backends on the system. Some of those backends can be completly broken.

At this point you have absolutly no garanties that all the backends will works.

=cut

sub scan_backends {
	my @backends;
	foreach my $lib (@INC){
		while(<$lib/Slackware/Slackget/Network/Backend/*.pm>){
			print "scan_backends: $_\n";
			# TODO: check the actual need of this scan_backends() method. And if it's usefull, then make it actually return something
		}
	}
}

=head2 cache_data

This method allow you to cache data (incredible isn't it ?). It's use by slack-get to fill network buffer until the complete network message is received.

	$net->cache_data('some kind of stupid data');

=cut

sub cache_data {
	my ($self,@data)=@_;
	$self->{_PRIV}->{CACHE} .= join('',@data);
}

=head2 cached_data

Return previously cached data.

	my $data = $net->cached_data() ;

=cut

sub cached_data {
	my $self = shift;
	return $self->{_PRIV}->{CACHE};
}

=head2 clear_cache

Unconditionnally delete cached data from memory.

	$net->clear_cache();

=cut

sub clear_cache {
	my $self = shift;
	$self->{_PRIV}->{CACHE} = '';
}

sub _get_action_id {
	my $self = shift;
	$self->{_PRIV}->{ACTIONID} += int(rand(1000)+1) ;
	return $self->{_PRIV}->{ACTIONID};
}

=head2 __get_connection_id

Set the id of the connection. The id is generate by the constructor and must not be modified. This method is automatically called by the constructor and is mostly private.

	$net->__get_connection_id ;

=cut

sub __get_connection_id
{
	my $self = shift;
	my $message = shift ;
	if($message){
		print "[Slackware::Slackget::Network] [debug] __get_connection_id as a response (seems so...)\n" if($ENV{SG_DAEMON_DEBUG});
		return Slackware::Slackget::Network::Message->new(
			action => 'get_connection_id', 
			raw_data => {
				Enveloppe => {
					Action => {
						id => $message->{raw_data}->{Enveloppe}->{Action}->{id} ,
						content => 'get_connection_id',
					},
					Data => {
						content => $self->{_PRIV}->{CONNID},
					},
				}
			},
		);
	}else{
		print "[Slackware::Slackget::Network] [debug] __get_connection_id as a request (seems so...)\n" if($ENV{SG_DAEMON_DEBUG});
		my $aid = $self->_get_action_id;
		return Slackware::Slackget::Network::Message->new(
			action => 'get_connection_id', 
			action_id => $aid,
			raw_data => {
				Enveloppe => {
					Action => {
						id => $aid ,
						content => 'get_connection_id',
					},
				}
			},
		);
	}
}

sub __get_connection_id_mode_client {
	my $self = shift;
	my $message = shift ;
	if($message){
		print "[Slackware::Slackget::Network] [debug] __get_connection_id_mode_client interpreting $message\n" if($ENV{SG_DAEMON_DEBUG});
		$self->{_PRIV}->{CONNID} = $message->data()->{Enveloppe}->{Data};
		print "[Slackware::Slackget::Network] [debug] __get_connection_id_mode_client new CONNID is $self->{_PRIV}->{CONNID}.\n" if($ENV{SG_DAEMON_DEBUG});
		return $message;
	}
}

sub __search_generate {
	my ($self, @query) = @_ ;
	my $aid = $self->_get_action_id;
	return Slackware::Slackget::Network::Message->new(
		action => 'search', 
		action_id => $aid,
		raw_data => {
			Enveloppe => {
				Action => {
					id => $aid ,
					content => 'search',
				},
				Data => {
					li => [@query],
				}
			},
		},
	);
}

sub __build_medias_list_generate {
	my ($self) = @_ ;
	my $aid = $self->_get_action_id;
	return Slackware::Slackget::Network::Message->new(
		action => 'build_medias_list',
		action_id => $aid,
		raw_data => {
			Enveloppe => {
				Action => {
					id => $aid ,
					content => 'build_medias_list',
				},
			},
		},
	);
}

sub __build_update_list_generate {
	my ($self) = @_ ;
	my $aid = $self->_get_action_id;
	return Slackware::Slackget::Network::Message->new(
		action => 'build_update_list',
		action_id => $aid,
		raw_data => {
			Enveloppe => {
				Action => {
					id => $aid ,
					content => 'build_update_list',
				},
			},
		},
	);
}

sub __build_installed_list_generate {
	my ($self) = @_ ;
	my $aid = $self->_get_action_id;
	return Slackware::Slackget::Network::Message->new(
		action => 'build_installed_list',
		action_id => $aid,
		raw_data => {
			Enveloppe => {
				Action => {
					id => $aid ,
					content => 'build_installed_list',
				},
			},
		},
	);
}

sub __notification_generate {
	my $self = shift;
	my  @notifications = @_;
	my $aid = $self->_get_action_id;
	my $msg = new Slackware::Slackget::Network::Message;
	$msg->create_enveloppe ;
	$msg->action('notification');
	$msg->action_id($aid);
	if(scalar(@notifications) >= 1 ){
		$msg->data()->{Enveloppe}->{Data}->{li} = [];
		foreach my $nm (@notifications){
			push @{ $msg->data()->{Enveloppe}->{Data}->{li} },$nm;
		}
	}
	return $msg;
}

sub __removepkg_generate {
	my $self = shift;
	my @pkgs = @_ ;
	my $aid = $self->_get_action_id;
	my $msg = new Slackware::Slackget::Network::Message;
	$msg->create_enveloppe ;
	$msg->action('removepkg');
	$msg->action_id($aid);
	if(scalar(@pkgs) >= 1 ){
		$msg->data()->{Enveloppe}->{Data}->{li} = [];
		foreach my $p (@pkgs){
			push @{ $msg->data()->{Enveloppe}->{Data}->{li} },$p;
		}
	}
	return $msg;
}

sub __get_patches_list_generate {
	my ($self) = @_ ;
	my $aid = $self->_get_action_id;
	return Slackware::Slackget::Network::Message->new(
		action => 'get_patches_list',
		action_id => $aid,
		raw_data => {
			Enveloppe => {
				Action => {
					id => $aid ,
					content => 'get_patches_list',
				},
			},
		},
	);
}

sub __upgradepkg_generate {
	my ($self,@pkgs) = @_ ;
	my $aid = $self->_get_action_id;
	my $msg = new Slackware::Slackget::Network::Message;
	$msg->create_enveloppe ;
	$msg->action('upgradepkg');
	$msg->action_id($aid);
	if(scalar(@pkgs) >= 1 ){
		$msg->data()->{Enveloppe}->{Data}->{li} = [];
		push @{ $msg->data()->{Enveloppe}->{Data}->{li} },@pkgs;
	}
	return $msg;
}

sub __installpkg_generate {
	my ($self,@pkgs) = @_ ;
	my $aid = $self->_get_action_id;
	my $msg = new Slackware::Slackget::Network::Message;
	$msg->create_enveloppe ;
	$msg->action('installpkg');
	$msg->action_id($aid);
	if(scalar(@pkgs) >= 1 ){
		$msg->data()->{Enveloppe}->{Data}->{li} = [];
		push @{ $msg->data()->{Enveloppe}->{Data}->{li} },@pkgs;
	}
	return $msg;
}

# 
# =head2 __get_installed_list
# 
# get the list of installed packages on the remote daemon.
# 
# 	my $installed_list = $net->get_installed_list ;
# 
# If an error occured call the appropriate handler.
# 
# In all case return a Slackware::Slackget::Network::Message (L<Slackware::Slackget::Network::Message>) object.
# 
# =cut
# 
# sub __get_installed_list {
# 	my $self = shift;
# 	my $socket = $self->{SOCKET} ;
# 	$self->send_data("get_installed_list:$self->{CONNID}\n") ;
# 	if($self->{handle_responses})
# 	{
# 		return $self->_handle_responses("get_installed_list") ;
# 	}
# }
# 
# =head2 __get_packages_list
# 
# get the list of new avalaible packages on the remote daemon.
# 
# 	my $status = $net->get_packages_list ;
# 
# If an error occured call the appropriate handler.
# 
# In all case return a Slackware::Slackget::Network::Message (L<Slackware::Slackget::Network::Message>) object.
# 
# =cut
# 
# sub __get_packages_list {
# 	my $self = shift;
# 	my $socket = $self->{SOCKET} ;
# 	$self->send_data("get_packages_list:$self->{CONNID}\n") ;
# 	if($self->{handle_responses})
# 	{
# 		return $self->_handle_responses("get_packages_list") ;
# 	}
# }
# 
# =head2 __get_html_info
# 
# Get an HTML encoded string which give some general information on the remote slack-getd
# 
# 	print $net->get_html_info ;
# 
# =cut
# 
# sub __get_html_info
# {
# 	my $self = shift;
# 	my $socket = $self->{SOCKET} ;
# 	$self->send_data("get_html_info:$self->{CONNID}\n") ;
# 	if($self->{handle_responses})
# 	{
# 		return $self->_handle_responses("get_html_info") ;
# 	}
# }
# 
# =head2 __build_packages_list
# 
# Said to the remote slack-getd to build the new packages cache.
# 
# 	my $status = $net->build_packages_list ;
# 
# The returned status contains no significant data in case of success.
# 
# =cut
# 
# sub __build_packages_list
# {
# 	my ($self) = @_ ;
# 	my $socket = $self->{SOCKET} ;
# 	$self->send_data("build_packages_list:$self->{CONNID}\n") ;
# 	if($self->{handle_responses})
# 	{
# 		return $self->_handle_responses("build_packages_list") ;
# 	}
# }
# 
# =head2 __build_installed_list
# 
# Said to the remote slack-getd to build the installed packages cache.
# 
# 	my $status = $net->build_installed_list ;
# 
# The returned status contains no significant data in case of success.
# 
# =cut
# 
# sub __build_installed_list
# {
# 	my ($self) = @_ ;
# 	my $socket = $self->{SOCKET} ;
# 	$self->send_data("build_installed_list:$self->{CONNID}\n") ;
# 	if($self->{handle_responses})
# 	{
# 		return $self->_handle_responses("build_installed_list") ;
# 	}
# }
# 
# =head2 __build_media_list
# 
# Said to the remote slack-getd to build the media list (medias.xml file).
# 
# 	my $status = $net->build_media_list ;
# 
# The returned status contains no significant data in case of success.
# 
# =cut
# 
# sub __build_media_list
# {
# 	my ($self) = @_ ;
# 	my $socket = $self->{SOCKET} ;
# 	$self->send_data("build_media_list:$self->{CONNID}\n") ;
# 	if($self->{handle_responses})
# 	{
# 		return $self->_handle_responses("build_media_list") ;
# 	}
# }
# 
# =head2 __diskspace
# 
# Ask to the remote daemon for the state of the disk space on a specify partition.
# 
# 	$net->handle_responses(1); # We want Slackware::Slackget::Network handle the response and return the hashref.
# 	my $response = $net->diskspace( "/" ) ;
# 	$net->handle_responses(0);
# 	print "Free space on remote computer / directory is ",$response->data()->{avalaible_space}," KB\n";
# 
# Return a Slackware::Slackget::Network::Message object which contains (in case of success) a HASHREF build like that :
# 
# 	$space = {
# 		device => <NUMBER>,
# 		total_size => <NUMBER>,
# 		used_space => <NUMBER>,
# 		available_space => <NUMBER>,
# 		use_percentage => <NUMBER>,
# 		mount_point => <NUMBER>
# 	};
# 
# =cut
# 
# sub __diskspace
# {
# 	my ($self,$dir) = @_ ;
# 	my $socket = $self->{SOCKET} ;
# # 	print STDOUT "[DEBUG::Network.pm] sending command \"diskspace:$dir\" to remote daemon\n";
# 	$self->send_data("diskspace:$self->{CONNID}:$dir\n") ;
# 	if($self->{handle_responses})
# 	{
# 		my $str = '';
# 		my $ds = {};
# 		while(<$socket>)
# 		{
# 			chomp;
# 			if($_=~ /^wait:$self->{CONNID}:/)
# 			{
# 				sleep 1;
# 				next ;
# 			}
# 			if ($_=~ /auth_violation:$self->{CONNID}:\s*(.*)/)
# 			{
# 				return Slackware::Slackget::Network::Message->new(
# 					is_success => undef,
# 					ERROR_MSG => $1,
# 					DATA => $_
# 				);
# 				last ;
# 			}
# 			if($_=~ /^diskspace:$self->{CONNID}:(device=[^;]+;total_size=[^;]+;used_space=[^;]+;available_space=[^;]+;use_percentage=[^;]+;mount_point=[^;]+)/)
# 			{
# 				my $tmp = $1;
# 				print STDOUT "[DEBUG::Network.pm] $tmp contient des info sur diskspace\n";
# 				foreach my $pair (split(/;/,$tmp))
# 				{
# 					my ($key,$value) = split(/=/,$pair);
# 					print STDOUT "[DEBUG::Network.pm] $key => $value\n";
# 					$ds->{$key} = $value;
# 				}
# 			}
# 			else
# 			{
# 				my $code = $self->_handle_protocol($_) ;
# 				last if($code==2);
# 				print STDOUT "[DEBUG::Network.pm] $_ ne contient pas d'info sur diskspace\n";
# 			}
# 			last if($_=~ /^end:$self->{CONNID}:\s*diskspace/);
# 		}
# 		return Slackware::Slackget::Network::Message->new(
# 		is_success => 1,
# 		DATA => $ds
# 		);
# 	}
# 	
# }
# 
# =head2 __search
# 
# take at least two parameters : the word you search for, and a field. Valid fields are those who describe a package entity in the packages.xml file.
# 
# 	my $response = $net->search('gcc','name','description') ; # search for package containing 'gcc' in fields 'name' and 'description'
# 
# Return the remote slack-getd's response in the DATA section of the response (L<Slackware::Slackget::Network::Message>).
# 
# =cut
# 
# sub __search
# {
# 	my ($self,$word,@args) = @_ ;
# 	my $socket = $self->{SOCKET} ;
# 	my $fields = join(';',@args);
# # 	chop $fields ;
# 	$self->send_data("search:$self->{CONNID}:$word:$fields\n") ;
# 	if($self->{handle_responses})
# 	{
# 		return $self->_handle_responses("search") ;
# 	}
# }
# 
# =head2 __websearch
# 
# Take 2 parameters : a reference on an array which contains the words to search for, and another array reference which contains a list of fields (valid fields are thoses describe in the packages.xml file).
# 
# 
# The DATA section of the response (L<Slackware::Slackget::Network::Message>) will contain an ARRAYREF. Each cell of this array will contains a package in HTML
# The returned data is HTML, each package are separed by a line wich only contain the string "__MARK__"
# 
# 	my $response = $network->websearch([ 'burn', 'cd' ], [ 'name', 'description' ]) ;
# 
# =cut
# 
# sub __websearch
# {
# 	my ($self,$requests,$args) = @_ ;
# 	my $socket = $self->{SOCKET} ;
# 	my $fields = join(';',@{$args});
# 	my $words = join(';',@{$requests}) ;
# # 	chop $fields ;
# 	warn "[Slackware::Slackget::Network] (debug::websearch) self=$self, words=$words, fields=$fields\n";
# 	$self->send_data("websearch:$self->{CONNID}:$words:$fields\n") ;
# 	if($self->{handle_responses})
# 	{
# 		my $str = [];
# 		my $idx = 0;
# 		while(<$socket>)
# 		{
# 			if($_=~ /^wait:$self->{CONNID}:/)
# 			{
# 				sleep 1;
# 				next ;
# 			}
# 			last if($_=~ /^end:$self->{CONNID}: websearch/);
# 			if ($_=~ /auth_violation:$self->{CONNID}:\s*(.*)/)
# 			{
# 				return Slackware::Slackget::Network::Message->new(
# 					is_success => undef,
# 					ERROR_MSG => $1,
# 					DATA => $_
# 				);
# 				last ;
# 			}
# 			my $code = $self->_handle_protocol($_) ;
# 			if($_=~/__MARK__/)
# 			{
# 				$idx++;
# 			}
# 			else
# 			{
# 				$str->[$idx] .= $_;
# 			}
# 			last if($code==2);
# 		}
# 		return Slackware::Slackget::Network::Message->new(
# 		is_success => 1,
# 		DATA => $str
# 		);
# 	}
# 	
# }
# 
# =head2 __multisearch
# 
# Take 2 parameters : a reference on an array which contains the words to search for, and another array reference which contains a list of fields (valid fields are thoses describe in the packages.xml file).
# 
# 
# The DATA section of the response (L<Slackware::Slackget::Network::Message>) will contain the XML encoded response.
# 
# 	my $response = $network->websearch([ 'burn', 'cd' ], [ 'name', 'description' ]) ;
# 
# =cut
# 
# sub __multisearch
# {
# 	my ($self,$requests,$args) = @_ ;
# 	my $socket = $self->{SOCKET} ;
# 	my $fields = join(';',@{$args});
# 	my $words = join(';',@{$requests}) ;
# # 	chop $fields ;
# 	$self->send_data("multisearch:$self->{CONNID}:$words:$fields\n") ;
# 	if($self->{handle_responses})
# 	{
# 		return $self->_handle_responses("search") ;
# 	}
# 	
# }
# 
# 
# =head2 __getfile
# 
# This method allow you to download one or more files from a slack-get daemon. This method of download is specific to slack-get and is based on the EBCS protocol.
# 
# Arguments are :
# 
# 	files : pass a Slackware::Slackget::PackageList to this option.
# 	
# 	destdir : a string wich is the directory where will be stored the downloaded files.
# 
# Here is a little code example :
# 
# 	# $pkgl is a Slackware::Slackget::PackageList object.
# 	$net->getfile(
# 		file => $pkgl,
# 		destdir => $sgo->config()->{common}->{'update-directory'}."/package-cache/"
# 	);
# 
# =cut
# 
# sub __getfile
# {
# 	my $self = shift;
# 	my %args = @_ ;
# # 	my $pkgl = $args{'file'};
# 	return Slackware::Slackget::Network::Message->new(
# 				is_success => undef,
# 				ERROR_MSG => "An object of Slackware::Slackget::PackageList type was waited, but another type of object has come.",
# 				DATA => undef
# 			) if(ref($args{'file'}) ne 'Slackware::Slackget::PackageList') ;
# # 	my $destdir = shift;
# 	my $socket = $self->{SOCKET} ;
# 	my $str = 'The following files have been successfully saved : ';
# 	my $file;
# 	my $write_in = 0;
# 	# TODO: termin�ici : envoy�le message de requete de fichiers, et finir le code de r�up�ation des fichiers (voir par ex si il n'y as pas d'erreur).
# 	my $requested_pkgs = '';
# 	$args{'file'}->index_list() ;
# 	foreach (@{$args{'file'}->get_all})
# 	{
# 		$requested_pkgs .= $_->get_id().';'
# 	}
# 	chop $requested_pkgs;
# 	$self->send_data("getfile:$self->{CONNID}:$requested_pkgs\n");
# 	if($self->{handle_responses})
# 	{
# 		my $current_file;
# 		while(<$socket>)
# 		{
# 			if($_=~ /^wait:$self->{CONNID}:/)
# 			{
# 				print "wait\n";
# 				sleep 2;
# 				next ;
# 			}
# 			last if($_=~ /^end:$self->{CONNID}:\s*getfile/);
# 			if ($_=~ /auth_violation:$self->{CONNID}:\s*(.*)/)
# 			{
# 				return Slackware::Slackget::Network::Message->new(
# 					is_success => undef,
# 					ERROR_MSG => $1,
# 					DATA => $_
# 				);
# 				last ;
# 			}
# 			elsif($_ =~ /binaryfile:$self->{CONNID}:\s*(.+)/)
# 			{
# 				undef($file);
# 				$file = Slackware::Slackget::File->new("$args{'destdir'}/$1",'no-auto-load' => 1, 'mode' => 'write','binary' => 1);
# 				$current_file=$1;
# 				$current_file=~ s/\.tgz//;
# 				$write_in = 1;
# 			}
# 			elsif($_ =~ /end:$self->{CONNID}:binaryfile/)
# 			{
# 				$file->Write_and_close ;
# 				$args{'file'}->get_indexed($current_file)->setValue('is-installable',1) ;
# 				$current_file = '';
# 				$str .= $file->filename().' ';
# 				$write_in = 0;
# 			}
# 			my $code = $self->_handle_protocol($_) ;
# 			last if($code==2);
# 			$file->Add($_) if($write_in && $code == 1);
# 		}
# 		return Slackware::Slackget::Network::Message->new(
# 		is_success => 1,
# 		DATA => $str
# 		);
# 	}
# 	
# }
# 
# =head2 __reboot
# 
# 	This method ask the remote daemon to reboot the remote computer.
# 
# =cut
# 
# sub __reboot
# {
# 	my $self = shift;
# 	$self->send_data("reboot:$self->{CONNID}\n");
# }
# 
# =head2 __quit
# 
# Close the current connection.
# 
# 	$net->__quit ;
# 
# =cut
# 
# sub __quit {
# 	my ($self,$mess) = @_ ;
# 	$mess = "end session" unless(defined($mess));
# 	chomp $mess;
# # 	print "[debug Slackware::Slackget::Network] sending \"quit:$self->{CONNID}:$mess\"\n";
# 	$self->send_data("quit:$self->{CONNID}:$mess\n") ;
# # 	$self->{SOCKET}->close() ;
# }
# 
# =head1 ACCESSORS
# 
# =head2 slackget (read only)
# 
# return the current slackget10 object.
# 
# =cut
# 
# sub slackget
# {
# 	my $self = shift ;
# 	return $self->{SGO} ;
# }

=head2 connection_id

Get or set the connection ID.

	$net->connection_id(1234);
	print "Connection ID : ", $net->connection_id , "\n";

=cut

sub connection_id
{
	return $_[1] ? $_[0]->{CONNID}=$_[1] : $_[0]->{CONNID};
}

# =head2 handle_responses (read/write)
# 
# 	Boolean accessor, get/set the value of the handle_responses option.
# 
# =cut
# 
# sub handle_responses
# {
# 	return $_[1] ? $_[0]->{DATA}->{data}=$_[1] : $_[0]->{DATA}->{data};
# }

=head1 PKGTOOLS BINDINGS

Methods in this section are the remote call procedure for pkgtools interactions. The slack-getd daemon use another class for direct call to the pkgtools (L<Slackware::Slackget::PkgTools>).

The 3 methods have the same operating mode : 

1) Take a single Slackware::Slackget::PackageList as argument

2) Do the job

3) If their is more than one choice for the package you try to install, the daemon ask for a choice of you.

3bis) Re-do the job

4) For each package in the Slackware::Slackget::PackageList set a 'status' field which contain the status of the (install|upgrade|remove) process.

=head2 __installpkg

	$net->installpkg($packagelist) ;

=cut

sub __installpkg
{
	my ($self,$packagelist) = @_ ;
	return undef if(ref($packagelist) ne 'Slackware::Slackget::PackageList') ;
	my $request;
	foreach (@{$packagelist->get_all})
	{
		$request .= $_->get_id().';';
	}
	chop $request;
	print "[DEBUG::Network::installpkg] request => $request\n";
	my $socket = $self->{SOCKET} ;
	$self->send_data("installpkg:$self->{CONNID}:$request\n") ;
	if($self->{handle_responses})
	{
		return $self->_handle_responses("installpkg","All packages marked for installation have been treated.") ;
	}
	return 1;
}

=head2 __upgradepkg

	$net->upgradepkg($packagelist) ;

=cut

sub __upgradepkg
{
	my ($self,$packagelist) = @_ ;
	return undef if(ref($packagelist) ne 'Slackware::Slackget::PackageList') ;
	my $request;
	foreach (@{$packagelist->get_all})
	{
		$request .= $_->get_id().';';
	}
	chop $request;
	print "[DEBUG::Network::installpkg] request => $request\n";
	my $socket = $self->{SOCKET} ;
	$self->send_data("upgradepkg:$self->{CONNID}:$request\n") ;
	if($self->{handle_responses})
	{
		return $self->_handle_responses("upgradepkg","All packages marked for upgrade have been treated.") ;
	}
	return 1;
}

=head2 __removepkg

Send network commands to a slack-get daemon. This method (like other pkgtools network call), do nothing by herself, but sending a "removepkg:pkg1;pkg2;..;pkgN" to the slack-getd.

	$net->removepkg($packagelist) ;

=cut

sub __removepkg
{
	my ($self,$packagelist) = @_ ;
	print "[DEBUG::Network::removepkg] packagelist => $packagelist\n";
	return undef if(ref($packagelist) ne 'Slackware::Slackget::PackageList') ;
	my $request;
	foreach (@{$packagelist->get_all})
	{
		$request .= $_->get_id().';';
	}
	chop $request;
	print "[DEBUG::Network::removepkg] request => $request\n";
	my $socket = $self->{SOCKET} ;
	$self->send_data("removepkg:$self->{CONNID}:$request\n") ;
	if($self->{handle_responses})
	{
		return $self->_handle_responses("removepkg","All packages marked for remove have been treated.") ;
	}
	return 1;
}

=head1 DEFAULT HANDLERS

Since the 0.12 release there is no more default handlers.

=cut


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

=head1 SEE ALSO

L<Slackware::Slackget::Network::Message>, L<Slackware::Slackget::Status>, L<Slackware::Slackget::Network::Connection>

=head1 COPYRIGHT & LICENSE

Copyright 2005 DUPUIS Arnaud, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Slackware::Slackget::Network