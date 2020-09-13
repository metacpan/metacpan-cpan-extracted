package Pepper::Commander;

use 5.022001;
use strict;
use warnings;

our $VERSION = "1.2.1";

# for accepting options
use IO::Prompter;

# for getting default hostname/domain name
use Net::Domain qw( hostfqdn domainname );

# for doing everything else
use Pepper;
use Pepper::DB;
use Pepper::Templates;

# for test-endpoint
use Plack::Test;
use Plack::Util;
use HTTP::Request::Common;

# create myself and try to grab arguments
sub new {
	my ($class) = @_;

	# set up the object with all the options data
	my $self = bless {
		'pepper_directory' => $ENV{HOME}.'/pepper',
		'pepper' => Pepper->new(
			'skip_db' => 1,
			'skip_config' => 1,
		),
	}, $class;

	return $self;
}

# dispatch based on $ARGV[0]
sub run {
	my ($self,@args) = @_;
	
	my $dispatch = {
		'help' => 'help_screen',
		'setup' => 'setup_and_configure',
		'config' => 'setup_and_configure',
		'set-endpoint' => 'set_endpoint',
		'list-endpoints' => 'list_endpoints',
		'delete-endpoint' => 'delete_endpoint',
		'test-db' => 'test_db',
		'test-endpoint' => 'test_endpoint',
		'start' => 'plack_controller',
		'stop' => 'plack_controller',
		'restart' => 'plack_controller',
	};
	
	# have to be one of these
	if (!$args[0] || !$$dispatch{$args[0]}) {

		die "Usage: pepper help|setup|set-endpoint|delete-endpoint|list-endpoints|test-db|test-endpoint|start|stop|restart\n";
		
	# can not do anything without a config file
	} elsif ($args[0] ne 'setup' && !(-e $self->{pepper}->{utils}->{config_file})) {
		die "You must run 'pepper setup' to create a config file.\n";
	
	# otherwise, run it
	} else {
		my $method = $$dispatch{$args[0]};
		$self->$method(@args);
	
	}
		
}

# print documentation on how to use this
sub help_screen {
	my ($self,@args) = @_;

print qq{

pepper: Utility command to configure and control the Pepper environment.

# sudo pepper setup

This is the configuration mode. The Pepper workspace will be created as a 'pepper'
directory within your home directory, aka $ENV{HOME}/pepper, unless it already exists.  
You will be prompted for the configuration options, and your configuration file will 
be created or overwritten.

# pepper test-db

This will perform a basic connection / query test on the database config you provided
via 'pepper setup'.  

# pepper set-endpoint [URI] [PerlModule]

This creates an endpoint mapping in Pepper to tell Plack how to dispatch incoming
requests.  The first argument is a URI and the second is a target Perl module for
handing GET/POST requests to the URI.  If these two arguments are not given, you
will be prompted for the information.  

If the Perl module does not exist under $ENV{HOME}/pepper/lib, an initial version will be created.

# pepper list-endpoints

This will output your configured endpoint mappings.

# pepper test-endpoint [URI]

This will run Plack::Test against the URI's endpoint to see that it will return 200 OK.
This is not a test of functionality, just a test that the endpoint executes and returns 200.

# pepper delete-endpoint [URI]

Removes an endpoint mapping from Pepper.  The Perl module will not be deleted.

# pepper start [#Workers] [dev-reload]

Attempts to start the Plack service.  Provide an integer for the #Workers to spcify the 
maximum number of Plack processes to run.  The default is 10.

If you indicate a number of workers plus 'dev-reload' as the third argument, Plack 
will be started with the auto-reload option to auto-detect changes to your code.
If that is not provided, you will need to issue 'pepper restart' to put your code 
changes into effect.  Enabling dev-reload will slow down Plack significantly, so it 
is only appropriate for development environments.

# pepper restart

Restarts the Plack service and put your code changes into effect.

};

}

# test that the database connection works; hard to do this in module install
sub test_db {
	my ($self,$mode) = @_;
	
	$mode ||= 'print';
	
	my $utils = $self->{pepper}->{utils};
		$utils->read_system_configuration();
	
	my $db;
	eval {
		$db = Pepper::DB->new({
			'config' => $utils->{config},
			'utils' => $utils,
		});
	};
	
	my $result_message = '';
	my $current_timestamp = '';
	if ($@) {
		$result_message = "\n\nCOULD NOT CONNECT TO THE DATABASE.\nERROR MESSAGE: $@";
		$result_message .= "\nPlease confirm config and re-run 'sudo pepper setup' as needed.\n\n";
	
	# connected / test querying
	} else {
		($current_timestamp) = $db->quick_select('select current_timestamp');
	
	}
	
	# if the query succeeded...
	if ($current_timestamp =~ /^\d{4}\-\d{2}\-\d{2}\s/) {
		$result_message = "\nYour database connection appears to be working.\n\n";
	
	# if it did not and there is no connection error...
	} elsif (!$result_message) {
		$result_message = "\n\nCOULD NOT QUERY THE DATABASE.\nERROR MESSAGE: $@".
							"\nPlease confirm config and re-run 'sudo pepper setup' as needed.\n\n";
	}

	# if we are in setup mode, we will exit here; otherwise, we just print
	print $result_message;
	if ($mode eq 'setup' && $result_message =~ /ERROR/) {
		exit;
	}

}

# create directory structure, build configs, create examples
sub setup_and_configure {
	my ($self,@args) = @_;

	my ($config_options_map, $config, $subdir_full, $subdir, $map_set, $key);

	if (! (-d $self->{pepper_directory} ) ) {
		mkdir ($self->{pepper_directory});
	}
	foreach $subdir ('lib','config','psgi','log','template','template/system') {
		$subdir_full = $self->{pepper_directory}.'/'.$subdir;
		mkdir ($subdir_full) if !(-d $subdir_full);
	}
	
	# sanity
	my $utils = $self->{pepper}->{utils};
	
	$config_options_map = [
		['development_server',
			qq{
Is this a development server? 
If you select 'Y', errors will be piped to the screen and logged.
Select 'N' for production servers, where errors will be logged but not shown to the user. 
(Y or N)},'Y'],
		['use_database',qq{
Auto-Connect to a MySQL/MariaDB database server? 
This will make the database/SQL methods available via the \$pepper object. 
(Y or N)},'Y'],
		['database_server', "\n".'Hostname or IP Address for your MySQL/MariaDB server (required)'],
		['database_username', "\n".'Username to connect to your MySQL/MariaDB server (required)'],
		['database_password', "\n".'Password to connect to your MySQL/MariaDB server (required)'],
		['connect_to_database', qq{
Default database for the MySQL/MariaDB connection.},'information_schema'],
		['url_mappings_database', 
			qq{
Database to store URL/endpoint mappings. 
A 'pepper_endpoints' table will be created and maintained via 'pepper set-endpoint'. 
This is a faster option for handling requests, but you may leave blank for JSON config file.}],
		['default_endpoint_module', 
			qq{
Default endpoint-handler Perl module.
This will be used for URI's that have not been configured via 'pepper set-endpoint'.
Exapme:  PepperApps::NiceEndPoint. Built under $self->{pepper_directory}/lib.
Leave blank for example module.}],
	];
	
	# does a configuration already exist?
	if (-e $utils->{config_file}) {
		$utils->read_system_configuration();
		foreach $map_set (@$config_options_map) {
			$key = $$map_set[0];
			$$map_set[2] = $utils->{config}{$key} if $utils->{config}{$key}; 
		}
	}	
	
	# shared method below	
	$config = $self->prompt_user($config_options_map);
	
	# calculate the endpoint storage
	if ($$config{url_mappings_database}) {
		$$config{url_mappings_table} = $$config{url_mappings_database}.'.pepper_endpoints';
	} else {
		$$config{url_mappings_file} = $self->{pepper_directory}.'/config/pepper_endpoints.json';
	}

	# default endpoint handler
	$$config{default_endpoint_module} ||= 'PepperApps::PepperExample';
	
	# now write the config file
	$utils->write_system_configuration($config);
	
	# if they want to connect to a database, let's test that now
	if ($$config{use_database} eq 'Y') {
		$self->test_db('setup');
	}

	# install some needed templates
	my $template_files = {
		'endpoint_handler.tt' => 'endpoint_handler',
		'html_example.tt' => 'html_example_endpoint',
		'pepper.psgi' => 'psgi_script',
		'pepper_apache.conf' => 'apache_config',
		'pepper.service' => 'systemd_config',
		'example_perl_script.pl' => 'sample_script',
	};
	my $pepper_templates = Pepper::Templates->new();

	foreach my $t_file (keys %$template_files) {
		my $dest_dir = 'template/system'; # everything by the PSGI script goes in 'template'
			$dest_dir = 'psgi' if $t_file eq 'pepper.psgi';
		my $dest_file = $self->{pepper_directory}.'/'.$dest_dir.'/'.$t_file;

		# skip if already in place
		next if -e $dest_file;
		
		# save the new template file
		my $template_method = $$template_files{$t_file};
		my $contents = $pepper_templates->$template_method();
		
		# set the username for the SystemD service
		$contents =~ s/User=root/User=$ENV{USER}/;
		
		# now save it out
		$utils->filer($dest_file,'write',$contents);
	}

	# set the default example endpoint; hopefully the example module
	$self->set_endpoint('default','default',$$config{default_endpoint_module});

	# if the HTML endpoint example isn't already there, add it in
	my $html_example_handler = $self->{pepper_directory}.'/lib/PepperApps/HTMLExample.pm';
	if (!(-e "$html_example_handler")) {
		mkdir( $self->{pepper_directory}.'/lib/PepperApps');
		$self->set_endpoint('/pepper/html_example','/pepper/html_example','PepperApps::HTMLExample');
		# make it second, so nothing will be said on first go-round
		my $html_example_code = $pepper_templates->html_example_endpoint('perl');
		$utils->filer($html_example_handler,'write',$html_example_code);
	}

	print "\nConfiguration complete and workspace ready under $self->{pepper_directory}\n";

}

# method to add an endpoint mapping to the system
sub set_endpoint {
	my ($self,@args) = @_;
	
	my ($endpoint_data, $endpoint_prompts, $extra_text, $module_file);
	
	my $utils = $self->{pepper}->{utils}; # sanity
	
	# we need the configuration for this
	$utils->read_system_configuration();

	# create a DB object if saving to a table
	if ($utils->{config}{url_mappings_table}) {
		$utils->{db} = Pepper::DB->new({
			'config' => $utils->{config},
			'utils' => $utils,
		});
	}
	
	$endpoint_prompts = [
		['endpoint_uri','URI for endpoint, such as /hello/world (required)'],
		['endpoint_handler', 'Module name for endpoint, such as PepperApps::HelloWorld (required)'],
	];

	# if they passed in two args, we can use those for the endpoints
	if ($args[1] && $args[2]) {
		
		$endpoint_data = {
			'endpoint_uri' => $args[1],
			'endpoint_handler' => $args[2],
		};
	
	# otherwise, prompt them for the information
	} else {
		# shared method below	
		$endpoint_data = $self->prompt_user($endpoint_prompts);	
	}
	
	# commit the change
	$utils->set_endpoint_mapping( $$endpoint_data{endpoint_uri}, $$endpoint_data{endpoint_handler} );
	
	# create the module, if it does not exist
	my (@module_path, $directory_path, $part);
	(@module_path) = split /\:\:/, $$endpoint_data{endpoint_handler};
	if ($module_path[1]) {
		$directory_path = $ENV{HOME}.'/pepper/lib';
		foreach $part (@module_path) {
			if ($part ne $module_path[-1]) {
				$directory_path .= '/'.$part;
				if (!(-d $directory_path)) {
					mkdir($directory_path);
				}
			}
		}
	}
	
	# for the directory in the endpoint
	$$endpoint_data{pepper_directory} = $self->{pepper_directory};
	
	($module_file = $$endpoint_data{endpoint_handler}) =~ s/\:\:/\//g;
	$module_file = $self->{pepper_directory}.'/lib/'.$module_file.'.pm';
	if (!(-e $module_file)) { # start the handler
		$utils->template_process({
			'template_file' => 'system/endpoint_handler.tt',
			'template_vars' => $endpoint_data,
			'save_file' => $module_file
		});	
		$extra_text = "\n".$module_file." was created.  Please edit to taste\n";
		
	} else {
		$extra_text = "\n".$module_file." already exists and was left unchanged.\n";
	}
	
	# all done
	print "\nEndpoint configured for $$endpoint_data{endpoint_uri}\n".$extra_text;
	
}

# method to remove an endpoint mapping from the system
sub delete_endpoint {
	my ($self,@args) = @_;

	my $endpoint_prompts = [
		['endpoint_uri','URI for endpoint to delete, such as /hello/world (required)'],
	];
	
	my $endpoint_data;

	# if they passed in two args, we can use those for the endpoints
	if ($args[1]) {
		
		$endpoint_data = {
			'endpoint_uri' => $args[1],
		};
	
	# otherwise, prompt them for the information via shared method below	
	} else {
		$endpoint_data = $self->prompt_user($endpoint_prompts);	
	}

	# we need the configuration for this
	my $utils = $self->{pepper}->{utils}; # sanity
	$utils->read_system_configuration();

	# create a DB object if saving endpoints in a table
	if ($utils->{config}{url_mappings_table}) {
		$utils->{db} = Pepper::DB->new({
			'config' => $utils->{config},
			'utils' => $utils,
		});
	}	
	
	# now delete the endpoint
	$utils->delete_endpoint_mapping( $$endpoint_data{endpoint_uri} );

	# all done
	print "\nDeleted endpoint for $$endpoint_data{endpoint_uri}\n";
	
}


# method to list all of the existing endpoints
sub list_endpoints {
	my ($self) = @_;

	my $utils = $self->{pepper}->{utils}; # sanity
	
	# we need the configuration for this
	$utils->read_system_configuration();
	
	my $url_mappings = {};

	# create a DB object if saving to a table
	if ($utils->{config}{url_mappings_table}) {
		$utils->{db} = Pepper::DB->new({
			'config' => $utils->{config},
			'utils' => $utils,
		});
		
		my $url_mappings_array = $utils->{db}->do_sql(qq{
			select endpoint_uri,handler_module from $utils->{config}{url_mappings_table} 
		});
		foreach my $map (@$url_mappings_array) {
			$$url_mappings{$$map[0]} = $$map[1];
		}
		
	# or maybe a JSON file
	} elsif ($utils->{config}{url_mappings_file}) {
	
		$url_mappings = $utils->read_json_file( $utils->{config}{url_mappings_file} );
		
	}	

	# get a sorted list of URLs	
	my @urls = sort keys %$url_mappings;

	# no urls? 
	if (!$urls[0]) {
		print "\nNo endpoints are configured.  Please use 'pepper set-endpoint'.\n\n";
		return;
	}
	
	# otherwise, print them out
	print "\nCurrent URL-to-code mappings:\n";
	foreach my $url (@urls) {
		print "\n$url --> $$url_mappings{$url}\n";
	}
	print "\n";

	return;
}

# method to test an endpoint
sub test_endpoint {
	my ($self,@args) = @_;
	
	# due to how the command works, it should be in the second one
	my $endpoint_data = {};
	my $endpoint_uri;
	if (!$args[1]) { # prompt the user for input
	
		$endpoint_data = $self->prompt_user([
			['endpoint_uri','URI for endpoint to test, such as /hello/world (required)'],
		]);	
		
		$endpoint_uri = $$endpoint_data{endpoint_uri};
		
	} else { # otherwise, they provided it
		$endpoint_uri = $args[1];

	}

	# return the test
	print "\nTesting $endpoint_uri...\n";
	my $app = Plack::Util::load_psgi $self->{pepper_directory}.'/psgi/pepper.psgi';
	my $test = Plack::Test->create($app);
	my $res = $test->request(GET $endpoint_uri);
	
	# provide the results
	if ($res->status_line eq '200 OK' ) {
		print "Success: Endpoint returns 200 OK\n";
	} else {
		print "Error: Endpoint returns 500 Internal Server Error.  Check fatal log under $self->{pepper_directory}/log\n";
	}

}

# method to intercept prompts
sub prompt_user {
	my ($self,$prompts_map) = @_;
	
	my ($prompt_key, $prompt_set, $results, $the_prompt);
	
	$$results{use_database} = 'Y'; # default for below
	
	foreach $prompt_set (@$prompts_map) {
		$prompt_key = $$prompt_set[0];

		# if they want to skip database configuration, we will clear/skip the database values
		if ($prompt_key =~ /database/ && $$results{use_database} eq 'N') {
			$$results{$prompt_key} = '';
			next;
		}
	
		# password mode?
	
		$the_prompt = $$prompt_set[1];
		if ($$prompt_set[2]) {
			if ($$prompt_set[0] =~ /password/i) {
				$the_prompt .= ' [Default: Stored value]';
			} else {
				$the_prompt .= ' [Default: '.$$prompt_set[2].']';
			}
		}
		$the_prompt .= ' : ';
		
		if ($$prompt_set[0] =~ /password/i && !$$prompt_set[2]) {
			$$results{$prompt_key} = prompt $the_prompt, -echo=>'*', -stdio, -v, -must => { 'provide a value' => qr/\S/};

		} elsif ($$prompt_set[0] =~ /password/i) {
			$$results{$prompt_key} = prompt $the_prompt, -echo=>'*', -stdio, -v;

		} elsif ($$prompt_set[1] =~ /required/i && !$$prompt_set[2]) {
			$$results{$prompt_key} = prompt $the_prompt, -stdio, -v, -must => { 'provide a value' => qr/\S/};

		} else { 
			$$results{$prompt_key} = prompt $the_prompt, -stdio, -v;
		}		
		
		# Y or N means Y or N
		if ($$prompt_set[1] =~ /Y or N/) {
			$$results{$prompt_key} = uc( $$results{$prompt_key} ) ; # might have typed 'y'
			if ($$results{$prompt_key} !~ /^(Y|N)$/) { # if not exactly right, use the default or just N
				$$results{$prompt_key} = $$prompt_set[2] || 'N';
			}
		}		
		
		# accept defaults
		$$results{$prompt_key} ||= $$prompt_set[2];

	}

	return $results;
}

# method to start and stop plack
sub plack_controller {
	my ($self,@args) = @_;

	my $pid_file = $self->{pepper_directory}.'/log/pepper.pid';
	
	my $dev_reload = '';
		$dev_reload = '-R '.$self->{pepper_directory}.'/lib' if $args[2];
		
	if ($args[0] eq 'start') {

		my $max_workers = $args[1] || 10;

		system(qq{start_server --enable-auto-restart --auto-restart-interval=300 --port=5000 --dir=$self->{pepper_directory}/psgi --log-file=$self->{pepper_directory}/log/pepper.log --daemonize --pid-file=$pid_file -- plackup -s Gazelle --max-workers=$max_workers -E deployment $dev_reload pepper.psgi});
	
	} elsif ($args[0] eq 'stop') {
		
		system(qq{kill -TERM `cat $pid_file`});

	} elsif ($args[0] eq 'restart') {

		system(qq{kill -HUP `cat $pid_file`});
		
	}

}

1;

=head1 NAME

Pepper::Commander 

=head1 DESCRIPTION / PURPOSE

This package provides all the functionality for the 'pepper' command script, which
allows you to configure and start/stop the Pepper Plack service. 

=head2 sudo pepper setup

This is the configuration mode. The Pepper workspace will be created as a 'pepper'
directory within your home directory, aka $ENV{HOME}/pepper, unless it already exists.  
You will be prompted for the configuration options, and your configuration file will 
be created or overwritten.

=head2 pepper test-db

This will perform a basic connection / query test on the database config you provided
via 'pepper setup'.  

=head2 pepper set-endpoint [URI] [PerlModule]

This creates an endpoint mapping in Pepper to tell Plack how to dispatch incoming
requests.  The first argument is a URI and the second is a target Perl module for
handing GET/POST requests to the URI.  If these two arguments are not given, you
will be prompted for the information.  Use 'default' for the URI to set a default
endpoint handler.

If the Perl module does not exist under $ENV{HOME}/pepper/lib, an initial version will be created.

=head2 pepper list-endpoints

This will output your configured endpoint mappings.

=head2 pepper test-endpoint [URI]

This will run Plack::Test against the URI's endpoint to see that it will return 200 OK.
This is not a test of functionality, just a test that the endpoint executes and returns 200.

=head2 pepper delete-endpoint [URI]

Removes an endpoint mapping from Pepper.  The Perl module will not be deleted.

=head2 pepper start [#Workers] [dev-reload]

Attempts to start the Plack service.  Provide an integer for the #Workers to spcify the 
maximum number of Plack processes to run.  The default is 10.

If you indicate a number of workers plus 'dev-reload' as the third argument, Plack 
will be started with the auto-reload option to auto-detect changes to your code.
If that is not provided, you will need to issue 'pepper restart' to put your code 
changes into effect.  Enabling dev-reload will slow down Plack significantly, so it 
is only appropriate for development environments.

=head2 pepper restart

Restarts the Plack service and put your code changes into effect.
