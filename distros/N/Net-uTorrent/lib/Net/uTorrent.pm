package Net::uTorrent;

use URI;
use URI::QueryParam;
use HTTP::Request::Common;
use LWP::UserAgent;
use JSON::XS;
use HTML::TreeBuilder;

use 5.010000;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.02';


 our $token;
 our $api_url;
 our $http_request = HTTP::Request->new;
 our $ua = LWP::UserAgent->new;
 our $html_tree = HTML::TreeBuilder->new;
 our $json = JSON::XS->new;
 our $cid; #cache id
 our $error;



sub new {
		my ($class,%args) = @_;
		my $self = bless({}, $class);

		my $host = $args{'hostname'};
		my $port = $args{'port'};
		my  $user = $args{'user'};
		my $pass = $args{'pass'};
        
		$ua->credentials (
					"$host:$port",
					'uTorrent',
					$user => $pass
				 );
		$api_url = "http://$host:$port/gui/";
		my $http = $ua->get($api_url."token.html");
		my $parsed = $html_tree->parse($http->decoded_content); 		# Build HTML tree of elements
		$token = $parsed->{'_body'}->{'_content'}[0]->{'_content'}[0];	# Get authentication token

		return $self;
	  }
	  
	  
sub token {
		return $token;
	  }

sub login_success {

		 if ($token) { return 1; }
		 else { return 0; }

		  }
		  
sub torrents {
		my ($class,%args) = @_;
		
		my %params = (
			        list	=>	1,	      
			     );
		%params = (%params,%args); #Add optional cache id from argument.
		my @args = qw();
		push @args,\%params;
		my $json_text = api_query_result(@args);
		my $decoded_json = $json->decode($json_text);
		$cid = $decoded_json->{torrentc};
		
		my @torrent = qw();
		
		for (@{$decoded_json->{torrents}}) {
						     my @keys = qw (
						    		     infohash status name size percent downloaded
						   		     uploaded ratio upstream downstream eta label
						   		     peers_connected peers_in_swarm seeds_connected
						   		     seeds_in_swarm availability queue_order remaining
						   		   );
						    my @values = @$_;
						    my %torrent_details;
						    for (my $i = 0; $i <= $#keys; $i++) { $torrent_details{$keys[$i]} = $values[$i]; }
						    push @torrent,\%torrent_details;						   

						 }
		return \@torrent;
	     }
	     
sub cache_id {
		return $cid;
}	     		  

sub get_settings {
		my ($class,$type) = @_;
		$type = 'array' unless $type;
		my @settings;
		my %settings;
		my @type = qw (integer boolean string);

		my @args = qw();
		push @args,{action => 'getsettings'};
		my $json_text = api_query_result(@args);
		my $decoded_json = $json->decode($json_text);
		
		for (@{$decoded_json->{settings}})  {
						      my %settings_info;
						      my @keys = qw (name type value);
						      my @values = @$_;
						      for (my $i = 0; $i <= $#keys; $i++) {  $settings_info{$keys[$i]} = $values[$i]; }
						      $settings_info{'type_human'} = $type[$settings_info{'type'}];
						      $settings{$settings_info{'name'}} = \%settings_info;
						      if ($type eq 'hash') { delete $settings_info{'name'}; }				      
						      push @settings,\%settings_info;
						    }
		if ($type eq 'array') { return \@settings; }
		elsif ($type eq 'hash') { return \%settings; }
}

sub set_settings {
		   my ($class,%settings) = @_;
		   my @args;
		   push @args, {action => 'setsetting'};
		   for my $key (keys %settings) { 
		   push @args, { 's' => $key };
		   push @args, { 'v' => $settings{$key} };
		   }
		   api_query_result(@args);
		   return;
		 }
sub filelist {
		my ($class,@infohash) = @_;
		my @args;
		my @priority_human = qw(skip low normal high);
		my @keys = qw(filename size downloaded priority);
		
		push @args,{action => 'getfiles'};
		for my $hash (@infohash) { push @args,{hash => $hash}; }
		my $json_text = api_query_result(@args);
		my $i = 0; for ($json_text =~ /,"(files)":/g) { my $append = $i++; $json_text =~ s/,"(files)":/,"files$append":/; } # Ugly hack to avoid repeating keys due to bug in uTorrent's JSON generator
		my $decoded_json = $json->decode($json_text);
		my %torrent_hash;
		for my $key (keys %$decoded_json) {
						    if ($key ne 'build') {
						    			   my $torrent = $decoded_json->{$key};
						    			   my $infohash = $$torrent[0];
						    			   my $file_array = $$torrent[1];
						    			   my @files_in_torrent = qw();
						    			   for my $file (@$file_array) {
						    			   					my %fileinfo;
						    			   					for (my $i = 0; $i <= $#$file; $i++) { $fileinfo{$keys[$i]} = $$file[$i]; }
						    			   					$fileinfo{'priority_human'} = $priority_human[$fileinfo{'priority'}];
								    			   			push @files_in_torrent,\%fileinfo;
						    			   			 
							    			   		        }
						    			   $torrent_hash{$infohash} = \@files_in_torrent;
						    			 }

						  }
		return \%torrent_hash;						  
}

sub get_properties {

  		my ($class,@infohash) = @_;
		my @args;
		push @args,{action => 'getprops'};
		for my $hash (@infohash) { push @args,{hash => $hash}; }
		my $json_text = api_query_result(@args);
		my $i = 0; for ($json_text =~ /,"(props)":/g) { my $append = $i++; $json_text =~ s/,"(props)":/,"props$append":/; } # Ugly hack to avoid repeating keys due to bug in uTorrent's JSON generator
		my $decoded_json = $json->decode($json_text);
		my %properties;
		for my $key (keys %$decoded_json) {
						    if ($key ne 'build') {
									    my $property = $decoded_json->{$key};
									    my @trackers = split(/\s+/,$$property[0]->{trackers});
									    $$property[0]->{trackers} = \@trackers;
									    $properties{$$property[0]->{hash}} = $$property[0];
									 }
						  }
		return \%properties;
}

sub set_properties {
		my ($class,@properties) = @_;
		my @args;
		push @args,{action => 'setprops'};
		for my $property (@properties) {
						 push @args, { hash => $$property{'hash'}};
						 delete $$property{'hash'};
						 for my $key (keys %$property) { 
						 				 push (@args, { 's' => $key } );
						 				 push (@args, { 'v' => $$property{$key} } );
						 			       }
					       }
		api_query_result(@args);
		return;



}

sub start {
             my ($class,@infohash) = @_;
             my @args;
             push @args, {action => 'start'};
             for (@infohash) { push @args, { hash => $_ }; }
             api_query_result(@args);
}


sub stop {
             my ($class,@infohash) = @_;
             my @args;
             push @args, {action => 'stop'};
             for (@infohash) { push @args, { hash => $_ }; }
             api_query_result(@args);

}

sub pause {
             my ($class,@infohash) = @_;
             my @args;
             push @args, {action => 'pause'};
             for (@infohash) { push @args, { hash => $_ }; }
             api_query_result(@args);

}

sub resume {
             my ($class,@infohash) = @_;
             my @args;
             push @args, {action => 'unpause'};
             for (@infohash) { push @args, { hash => $_ }; }
             api_query_result(@args);

}

sub force_start {
             my ($class,@infohash) = @_;
             my @args;
             push @args, {action => 'forcestart'};
             for (@infohash) { push @args, { hash => $_ }; }
             api_query_result(@args);


}

sub recheck {
             my ($class,@infohash) = @_;
             my @args;
             push @args, {action => 'recheck'};
             for (@infohash) { push @args, { hash => $_ }; }
             api_query_result(@args);

}

sub remove_torrent {
             my ($class,@infohash) = @_;
             my @args;
             push @args, {action => 'remove'};
             for (@infohash) { push @args, { hash => $_ }; }
             api_query_result(@args);


}


sub remove_data {
             my ($class,@infohash) = @_;
             my @args;
             push @args, {action => 'removedata'};
             for (@infohash) { push @args, { hash => $_ }; }
             api_query_result(@args);


}


sub set_priority {
		my ($class,%args_hash) = @_;
		my @args;
		push @args, { action => 'setprio' };
		push @args, { hash   => $args_hash{'hash'} };
		push @args, { p => $args_hash{'priority'} };
		delete $args_hash{'hash'};
		for (@{$args_hash{'files'}}) { push @args, { f => $_}; }
		api_query_result(@args);
		return;
}


sub add_url {
             my ($class,$url) = @_;
             my @args;
             push @args, { action => 'add-url' };
             push @args, { 's' => $url };
             api_query_result(@args);
             return;
}


sub add_file {
	     my ($class,$file) = @_;
             my $api = URI->new($api_url);
             $api->query_param(action => 'add-file');
             $api->query_param(t => $token);
             
             # This is the only method that uses HTTP POST, so a separate subroutine is not necessary.
             
             my $request = $ua->request (
             					POST $api,
             					Content_Type	=>	'multipart/form-data',
             					Content		=>	[
          								  'torrent_file' => [$file]             					
             								]         
             
             				);

             my $json_text = $request->content;
             my $decoded_json = $json->decode($json_text);
             my $status = $$decoded_json{error};
             $status = 'Success' unless $status;
             return { Status => $status};

}

############################### Module's own sub routines ###############################

sub api_query_result {
			my (@params) = @_;
			my $api = URI->new($api_url);
			for my $array_value (@params) {			
							for my $key (keys %$array_value) {
												$api->query_param_append($key => $$array_value{$key});
											 }			
						       }

			$api->query_param(token => $token);
			my $http = $ua->get($api);
			return $http->decoded_content;
		      }


	 
1;

__END__

=head1 NAME

Net::uTorrent - Perl interface to the uTorrent API.

=head1 SYNOPSIS

	my $utorrent = Net::uTorrent->new (
				    		hostname	=>	'localhost',
				    		port		=>	'12345',
				    		user		=>	'my_username',
				    		pass		=>	'my_password',
				  	  );
	die unless $utorrent->login_success;

=head1 DESCRIPTION

Net::uTorrent is an object oriented interface to the uTorrent API. This module requires the uTorrent WebUI to be enabled.


=head1 METHODS


=head2 login_success()
Returns a boolean indicating whether authentication was successful.


=head2 token()
Returns the authentication token.


=head2 torrents()
Returns a hashref containing all the torrents. Takes an optional hash argument with the key cid which when used will return a hashref containing all the torrents that were changed since the last time this method was used.

		   Examples:
		   	     $utorrent->torrents;
                             $utorrent->torrents( cid => 'abcd' );
                             
=head2 cache_id()
Returns the cid from the previous use of torrents(), which can be used in the next request.

=head2 get_settings()
Returns an array ref containing the uTorrent settings. Takes an optional argument 'hash', which when used will return a hashref containing settings.

		   Examples:
		   	     $utorrent->get_settings;
		   	     $utorrent->get_settings('hash');
		   	     
=head2 set_settings()
Takes a hashref as argument. Allowed keys are the ones returned by get_settings().

		   Examples:
		   	     $utorrent->set_settings (
		   	     				max_ul_rate	=>	5000,
		   	     				max_dl_rate	=>	10000
		   	     			     );
		   	     			     
=head2 filelist()
Takes an array of infohashes as arguments and returns a hashref.

		   Examples:
		   	     $utorrent->filelist(qw '43E2DFD8279552543DABA81E5FCCEA2539C81D1F 663C531B51C9A466B9757282B438F635E64AC3CA');

=head2 get_properties()
Takes an array of infohashes as arguments and returns a hashref.
                   
		   Examples:
		   	     $utorrent->get_properties(qw '43E2DFD8279552543DABA81E5FCCEA2539C81D1F 663C531B51C9A466B9757282B438F635E64AC3CA');
		   	     
=head2 set_properties()
Takes an array of hashrefs as arguments, each of which contains a key 'hash' containing the infohash, and property and value like the ones returned by get_properties.

		   Examples:	   
		   
		   $utorrent->set_properties (
					 	{
						  hash	=>	'43E2DFD8279552543DABA81E5FCCEA2539C81D1F',
						  ulrate	=>	1740,          # Upload speed in bytes/second
						},
						 
						{
						  hash	=>	'663C531B51C9A466B9757282B438F635E64AC3CA',
						  ulrate	=>	7135,
						  dlrate	=>	8330
						}
				       	     );
				       	     
=head2 set_priority()
Takes a hash as argument. Must contain the hash, an array containing the file indexes (starting from 0), and the priority.

		   Examples:
		   
		   $utorrent->set_priority (		   
						hash => '43E2DFD8279552543DABA81E5FCCEA2539C81D1F',
						files => [1,2,3],
						priority => 3    # (0 = skip, 1 = low, 2 = normal, 3 = high)
		   			   );
				       	     
=head2 add_file()
Takes a filename as argument, which when used will add the torrent to uTorrent. This method returns a hashref indicating if an error occured.

		   Examples:
		   
		   $utorrent->add_file('fedora_11_dvd.torrent');
		   
=head2 add_url()
Takes a url as argument.

		   Examples:
		   
		   $utorrent->add_url('http://torrent.fedoraproject.org/torrents//Fedora-11-i686-Live.torrent');
		   
=head2 start() - Start torrent.
Takes an array containing infohashes as argument.

		   Examples:
		   
		   $utorrent->start(qw '43E2DFD8279552543DABA81E5FCCEA2539C81D1F 663C531B51C9A466B9757282B438F635E64AC3CA');

=head2 stop() - Stop torrent.
Takes an array containing infohashes as argument.

		   Examples:
		   
		   $utorrent->stop(qw '43E2DFD8279552543DABA81E5FCCEA2539C81D1F 663C531B51C9A466B9757282B438F635E64AC3CA');


=head2 pause()
Takes an array containing infohashes as argument.

		   Examples:
		   
		   $utorrent->pause(qw '43E2DFD8279552543DABA81E5FCCEA2539C81D1F 663C531B51C9A466B9757282B438F635E64AC3CA');


=head2 resume()
Takes an array containing infohashes as argument.

		   Examples:
		   
		   $utorrent->resume(qw '43E2DFD8279552543DABA81E5FCCEA2539C81D1F 663C531B51C9A466B9757282B438F635E64AC3CA');

=head2 force_start()
Takes an array containing infohashes as argument.

		   Examples:
		   
		   $utorrent->force_start(qw '43E2DFD8279552543DABA81E5FCCEA2539C81D1F 663C531B51C9A466B9757282B438F635E64AC3CA');

=head2 recheck()
Takes an array containing infohashes as argument.

		   Examples:
		   
		   $utorrent->recheck(qw '43E2DFD8279552543DABA81E5FCCEA2539C81D1F 663C531B51C9A466B9757282B438F635E64AC3CA');

=head2 remove_torrent() - Delete a torrent from uTorrent.
Takes an array containing infohashes as argument.

		   Examples:
		   
		   $utorrent->remove_torrent(qw '43E2DFD8279552543DABA81E5FCCEA2539C81D1F 663C531B51C9A466B9757282B438F635E64AC3CA');

=head2 remove_data() - Delete a torrent and the data associated with it.
Takes an array containing infohashes as argument.

		   Examples:
		   
		   $utorrent->remove_data(qw '43E2DFD8279552543DABA81E5FCCEA2539C81D1F 663C531B51C9A466B9757282B438F635E64AC3CA');


=head1 SEE ALSO

http://forum.utorrent.com/viewtopic.php?id=25661

=head1 AUTHOR

rarbox, E<lt>rarbox@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by rarbox

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
