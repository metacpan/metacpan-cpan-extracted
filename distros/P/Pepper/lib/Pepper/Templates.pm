package Pepper::Templates;
# module that holds templates needed to setup this kit.
# used by Pepper::Commander (and our install tests)

# For the record, I do hate doing it this way, and I should find a better solution.

use 5.022001;
use strict;
use warnings;

our $VERSION = "1.4";

# just need to be an object
sub new {
	my ($class) = @_;

	# set up the object with all the options data
	my $self = bless {
		'pepper_directory' => $ENV{HOME}.'/pepper',
	}, $class;

	return $self;
}

# we will use like an object, but no real need for new()
sub get_template {
	my ($self,$template_wanted) = @_;
	
	# presume they need the endpoint handler
	$template_wanted ||= 'endpoint_handler';
	
	# only if we can provide it
	return 'Not available' if !$self->can($template_wanted);
	
	# otherwise, send out
	return $self->$template_wanted();
	
	# our method map
	
}

### Start our templates

# for the testing phase of cpanm
sub test_template {
	my $self = shift;
	
	return q[[%test_date%] was a [%test_day%]];
}

# return the template for endpoint handlers
sub endpoint_handler {
	my $self = shift;
	return q[package [%endpoint_handler%];
# provides handler for Endpoint URI: [%endpoint_uri%]

# promote better coding
use strict;
use warnings;

# handle the request
sub endpoint_handler {
	my ($class,$pepper) = @_;  
	# the $class is there becauase this is a fake object; please see https://perldoc.perl.org/5.32.0/perlootut.html

	### YOUR FANTASTIC CODE GOES HERE
	# Parameters sent via GET/POST or JSON body are available 
	# within $pepper->{params}
	#
	# Simply return your prepared content and Pepper will deliver
	# it to the client.  To send JSON, return a reference to an Array or Hash.
	# HTML or Text can also be returned. Please see the documentation for other options.
	# 
	# Please see perldoc pepper for methods available in $pepper

	# for example: just a very basic start
	my $starter_content = {
		'current_timestamp' => $pepper->time_to_date( time(), 'to_date_human_full' ),
		'hello' => 'world',
		'psgi_params' => $pepper->{params},
	};
	
	# return the content back to the main process, and Pepper will send it out to the client
	# sending a data structure back will send that structure in JSON to the client
	# you can alse return HTML or any text 
	
	return $starter_content;

}

1;
];
}

# templates for the HTML example endpoint
sub html_example_endpoint {
	my ($self,$send_handler) = @_;
	
	# we have two parts to this: a TT template and a endpoint handler module
	if (!$send_handler) {
		return q[[%# This template is used for the /pepper/html_example example endpoint.  
	Please see $ENV{HOME}/pepper/lib/PepperApps/HTMLExample.pm %]
	
<!DOCTYPE html>
<html>
<head>
	<meta charset="utf-8" />
	<title>Pepper HTML Example</title>
</head>
<body>

[% IF pepper_cookie %]
	<h3>I Found a Cookie</h3>
	Cookie value: [% pepper_cookie %]
[% END %]

[% IF provided_phrase %]
	<h3>Results of Form</h3>
	<ul>
	[% FOREACH fact IN phrase_facts.keys.sort %]
	   <li> [% fact %] == [% phrase_facts.$fact %] </li>
	[% END %]	
	</ul>
	
	<h3>Resubmit our Very Basic Form</h3>
	
	[% SET submit_word = 'Re-Submit' %]
	
[% ELSE %]

	<h3>Very Basic Form</h3>

	[% SET submit_word = 'Submit' %]
	
[% END %]

<form action="/pepper/html_example" method="post">

<strong>Provide a phrase:</strong>
<br/><input type="text" size="40" name="provided_phrase" value="[%provided_phrase%]"/>
<br/><br/>

<strong>Demo Setting a Cookie:</strong>
<br/><input type="checkbox" name="set_demo_cookie" value="yes"/>&nbsp;Click to have Pepper set a cookie with a random string.
<br/>Close the browser and return to see that the cookie persists.
<br/>Submitting with this check will overwrite the previous cookie.
<br/><br/>


<strong>Return JSON:</strong>
<br/><input type="checkbox" name="return_json" value="yes"/>&nbsp;Click to have the response be JSON instead of HTML.
<br/>Leave un-checked to compare the results with the content of the template.
<br/><br/>

<button type="Submit">[%submit_word%] Form</button>

</form>

</body>
</html>
];
	# otherwise, send out the perl module
	} else {
	
		return q[package PepperApps::HTMLExample;
# provides the example handler for Endpoint URI: /pepper_examples/html_example

# promote better coding
use strict;
use warnings;

# our request handler method
sub endpoint_handler {
	my ($class,$pepper) = @_;
	# the $class is there becauase this is a fake object; please see https://perldoc.perl.org/5.32.0/perlootut.html

	# if they submitted the form, prepare our silly example data structure
	my $phrase_facts = {};
	if ($pepper->{params}{provided_phrase}) {
		# put together some useless facts
		$phrase_facts = {
			'Provided value'=> $pepper->{params}{provided_phrase},
			'Value length' => length( $pepper->{params}{provided_phrase} ),
			'Last three characters' => substr($pepper->{params}{provided_phrase}, -3, 3),
			'Form submited' => $pepper->time_to_date(time(), 'to_date_human_time').' '.$pepper->{utils}->{time_zone_name}
		};
		
		# if they checked the option to receive JSON back, return that data structure
		# and Pepper.pm will convert it to JSON before sending out
		return $phrase_facts if $pepper->{params}{return_json};
	}
	
	# set the demo cookie?
	my $pepper_cookie;
	if ($pepper->{params}{set_demo_cookie}) {
		$pepper_cookie = $pepper->random_string(20); # so we can display in the page
		$pepper->set_cookie({
			'name' => 'Pepper_Demo_Cookie', # could be any name
			'value' => $pepper_cookie, # could be any string; nice to encrypt
		}); 
		
	# even if we aren't setting it, let's show it to the nice people
	} else {
		$pepper_cookie = $pepper->{cookies}{Pepper_Demo_Cookie};
	}
	
	# if they didn't check the return-JSON option, we will prepare some HTML via
	# our basic Template Toolkit template.  Please check out [%pepper_directory%]/templates/system/html_example.tt
	return $pepper->template_process({
		'template_file' => 'system/html_example.tt',
		'template_vars' => {
			'provided_phrase' => $pepper->{params}{provided_phrase},
			'phrase_facts' => $phrase_facts,
			'pepper_cookie' => $pepper_cookie,
		},
	});

	# all through, all done
}

1;
];

	}
}

# return the template for our PSGI handler script
sub psgi_script {
	my $self = shift;
	return q[#!/usr/bin/env perl
# This is the PSGI script which runs Pepper as a Plack application
# Run via 'pepper start'
# Each worker/thread started by Plack/Gazelle (or other) will run a copy of this script

# Please see the Perldoc notes below for more info about what this is.

# load our plack modules
use Plack::Request;		# access the incoming request info (like $q = new CGI;)
use Plack::Response;	# handles the outgoing respose
use Plack::Builder;		# enable use of middleware
use Plack::Middleware::DBIx::DisconnectAll;		# protect DB connections
use Plack::Middleware::Timeout;
use File::RotateLogs;	# log rotation
# probably more middleware to come

# load up the modules we require
use Pepper;
use Pepper::Utilities;

# be nice
use strict;
use warnings;

# Here is the PSGI app itself; Plack needs a code reference, so work it like so:
my $app = sub {
	# grab the incoming request
	my $request = 'Plack::Request'->new(shift);
	# set up the response object
	my $response = 'Plack::Response'->new(200);
	
	# eval{} the real work, so we can maybe log the errors
	eval {
		my $pepper = Pepper->new(
			'request' => $request, 
			'response' => $response,
		);
		
		# put our logic for find and executing the needed handler into the $pepper object
		$pepper->execute_handler();
		# that will retrieve and ship out the content
	};
	
	# catch the 'super' fatals, which is when the code breaks (usually syntax-error) before logging
	if ($@ && $@ !~ /^(Execution stopped|Redirected)/) {
		my $error_message = $@;

		# tie our UtilityBelt to the current request
		my $utils = Pepper::Utilities->new(); # need this for logging
		$utils->{response} = $response;
		$utils->{request} = $request;
			
		# send the message to to client
		if ($@ =~ /Plack::Middleware::Timeout/) { 
			# we want to log exactly what happened
			$utils->logger({
				'url' => 'https://'.$request->env->{HTTP_HOST}.$request->request_uri(),
				'params' => $request->parameters,
			},'timeouts');
			# omnitool_routines.js will know how to handle this
			$utils->send_response('Execution failed due to timeout.',3); 

		# display via the utility belt
		} else {
			$utils->send_response('Fatal Error: '.$error_message,3);
		}
	}
	
	# vague server name
	$response->header('Server' => 'Pepper');

	# consider setting these security headers
	# if you have HTTPS/TLS configured:
	# $response->header('Strict-Transport-Security' => 'max-age=63072000; includeSubdomains;');
	
	# to limit where JS/CSS and other content can originate.  This limits to the same URL
	# this is how you prevent inline JavaScript and Style tags, which is how XSS attacks happen.
	# see: https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP
	# $response->header('Content-Security-Policy' => qq{default-src 'self'; frame-ancestors 'self'; img-src 'self' data: 'self'; style-src 'self'});
		
	# finish up with our response
	$response->finalize;
};

# rotate the log every day
my $rotatelog = File::RotateLogs->new(
	logfile => 'PEPPER_DIRECTORY/log/pepper_access_log.%Y%m%d%H%M',
	linkname => 'PEPPER_DIRECTORY/log/pepper_access_log',
	rotationtime => 86400,
	maxage => 86400,
);

# use Plack::Middleware::ReverseProxy to make sure the remote_addr is actually the client's IP address
builder {
	# try not to have hung MySQL connections
	enable "DBIx::DisconnectAll";
	# set a reasonable timeout of 30 seconds
	# response will be generated by error handling in main subroutine
	# enable "Timeout", timeout  => 30;
	# use Plack::Middleware::ReverseProxy to make sure the remote_addr is actually the client's IP address
	enable_if { $_[0]->{REMOTE_ADDR} eq '127.0.0.1' }
	"Plack::Middleware::ReverseProxy";
	# nice access log
	enable 'Plack::Middleware::AccessLog',
		format => '%P - %h - %t - %V - %r - %b - "%{User-agent}i"',
		# the worker PID, the Remote Client IP, Local Time of Service, HTTP Type, URI, HTTP Ver,
		# Response Length and client browser; separated by dashes
		logger => sub { 
			$rotatelog->print(@_) 
		};
	$app;
};

# plack seems not to like 'exit' commands in these scripts
];
}

# sample SystemD config
sub systemd_config {
	my $self = shift;
	return qq{[Unit]
Description=Pepper/Plack Application Server
After=network.target
After=syslog.target

[Service]

# the number at the end of ExecStart determines the number of workers
ExecStart=/usr/local/bin/pepper start 30
ExecReload=pepper restart
ExecStop=pepper stop
Restart=on-failure
PIDFile=$ENV{HOME}/pepper/log/pepper.pid
KillSignal=SIGTERM
PrivateTmp=true
Type=forking

# IMPORTANT: set this username to something other than root!
User=root

[Install]
WantedBy=multi-user.target
};
}

# sample Apache config
sub apache_config {
	my $self = shift;
	
	return qq{# NOTE: You will need to enable several modules: a2enmod proxy ssl headers proxy_http rewrite
	
# pepper application server virtual host
<VirtualHost *:443>
	ServerName HOSTNAME.YOURDOMAIN.COM
	# ServerAlias ANOTHER-HOSTNAME.YOURDOMAIN.COM
	ServerAdmin you\@yourdomain.com

	# basic webroot options
	DocumentRoot /var/www/html
	Options All

	<Directory "/var/www/html">
		Require all granted
	</Directory>

	# enable HTTPS/TLS server -- this is my config, but adjust to taste
	SSLEngine on
	SSLProtocol -all +TLSv1.2 +TLSv1.3
	SSLHonorCipherOrder on
	SSLCipherSuite "ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-SHA256"
	SSLCompression off
	Header always set Strict-Transport-Security "max-age=63072000; includeSubdomains;"

	# EFF/Certbot certificates are free and work very well.
	# This is how I provision them:
	# certbot --manual certonly --preferred-challenges=dns --email YOUR_EMAIL --server https://acme-v02.api.letsencrypt.org/directory --agree-tos -d YOUR_DOMAIN
	# You will need to install 'certbot,' which involves adding a repo: https://certbot.eff.org/docs/install.html
	SSLCertificateFile /etc/letsencrypt/live/YOUR_DOMAIN/fullchain.pem
	SSLCertificateChainFile  /etc/letsencrypt/live/YOUR_DOMAIN/fullchain.pem
	SSLCertificateKeyFile /etc/letsencrypt/live/YOUR_DOMAIN/privkey.pem
	
	# try to speed things up
	SetOutputFilter DEFLATE
	SetEnvIfNoCase Request_URI "\.(?:gif|jpe?g|png)$" no-gzip

	# start our proxy config to handle requests via Plack
	# You will need to enable the 'proxy' and 'proxy_http' modules
	<Proxy *>
		Order deny,allow
		Allow from all
	</Proxy>

	ProxyRequests Off
	ProxyPreserveHost On

	# send *everything* to Plack -- this is how we can have any endpoint we want
	ProxyPass / http://127.0.0.1:5000/
	ProxyPassReverse / http://127.0.0.1:5000/

	# this is how you exempt files from being served via Plack
	# ProxyPass /favicon.ico !
	
	RequestHeader set X-Forwarded-HTTPS "0"

</VirtualHost>
};
}

# sample Pepper script
sub sample_script {
	my $self = shift;
	
	return q[#!env perl
# sample perl script working with Pepper

# boilerplate
use strict;
use warnings;
use v5.26;

# bring in pepper
use Pepper;
	my $pepper = Pepper->new();

# simple date trick
my $current_day_nice = $pepper->time_to_date( time(), 'to_date_human_dayname' );
say "Today is $current_day_nice";

# if they have a database object, do some more tricks
if ($pepper->{db}) {
	
	# not a great example SQL, but here we go...
	my ($databases, $dbkeys) = $pepper->sql_hash(qq{
		select TABLE_NAME, TABLE_ROWS from information_schema.TABLES 
		where TABLE_TYPE='BASE TABLE'
	});
	
	# output the results as JSON
	say "Database table info in JSON:";
	say $pepper->json_from_perl( $databases );
	
}

# if we were making changes to the database, we'd want 
# to end with $pepper->commit(); to commit that DB transaction
# done	
exit;
];
	
}

1;

__END__

=head1 NAME

Pepper::Templates 

=head1 DESCRIPTION

This provides the templates needed by Pepper::Commander, which powers the 'pepper'
command line program.  Please execute 'pepper help' in your shell for more details
on what is available.