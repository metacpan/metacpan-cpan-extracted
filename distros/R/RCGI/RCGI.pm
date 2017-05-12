package RCGI;

require 5.000;

$VERSION = "1.20";
sub Version { $VERSION; }

use RCGI::Config;

use strict;
use vars qw(@ISA @EXPORT $DefaultClass );
#use MIME::Base64;
use HTTP::Request::Common;  
use LWP::UserAgent;
use LWP::Simple;
use URI::URL;
use CGI;
use Data::Dumper;
use Data::Undumper;
use Carp qw( carp cluck );
use IO::Pipe;

require Exporter;
@ISA = ('Exporter');
@EXPORT = qw(Invoke Async_Invoke);

#
# Method: new
# Create Remote CGI subroutine call
#
sub new {
    my($class,$base_url,$library_path,$module,$subroutine,%options) = @_;
    my $self = {};

    bless $self,ref $class || $class || $DefaultClass;
    if (defined($base_url)) {
	$self->{'base_url'} = $base_url;
    }
    if (defined($library_path)) {
	$self->{'library_path'} = $library_path;
    }
    if (defined($module)) {
	$self->{'module'} = $module;
    }
    if (defined($subroutine)) {
	$self->{'subroutine'} = $subroutine;
    }
    if (defined($options{'async'})) {
	$self->{'async'} = $options{'async'};
    }
    if (defined($options{'wantarray'})) {
	$self->{'wantarray'} = $options{'wantarray'};
    }
    if (defined($options{'timeout'})) {
	$self->{'timeout'} = $options{'timeout'};
    }
    if (defined($options{'username'})) {
	$self->{'username'} = $options{'username'};
    }
    if (defined($options{'password'})) {
	$self->{'password'} = $options{'password'};
    }
    if (defined($options{'user_agent'})) {
	$self->{'user_agent'} = $options{'user_agent'};
    }
    return $self;
}


sub new_job {
    my($class) = shift;
    my($my_job_type) = shift;
    my($min_load) = shift;
    my($log_file) = $RCGI::Config::path ."/sar";
    my($server_file) = $RCGI::Config::path ."/server.conf";
    my($load_file) = $RCGI::Config::path ."/load";
    my($job_type_file) = $RCGI::Config::path ."/jobs.conf";
    my(%SAR);
    my($datetime, $usr, $delta_usr, $sys, $delta_sys, $wio, $delta_wio);
    my($idle, $delta_idle);
    my($machine, $number_processors, $processes_per_processor,$reserve);
    my(%PROCESS_PERCENT);
    my(%RESERVE);
    my(%LOAD);
    my(%DATETIME);
    my(%IDLE, %DELTA_IDLE);
    my($load_time, $load_idle);
    my($max_idle, $min_delta_idle) = (-1000, 100);
    my($current_idle);
    my($assigned_machine);
    my($job_type, $server, $task_url, $library_path, $module, $subroutine,
       %options);
    my(%JOB_TYPE);
    my($ref_options);
    my($remote);

    if (!open(JOBS,"$job_type_file")) {
	$remote = new RCGI;
	$remote->{'status'} = -10;
	$remote->{'error_message'} = "Unable to open jobs.conf: $job_type_file\n";
	return $remote;
    }
    while(<JOBS>) {
	# Remove comments
	s/\#.*$//;
	if (/^\s*$/) {
	    next;
	}
	($job_type, $server, $task_url, $library_path, $module, $subroutine,
	 %options) = split("\t");
	if ($my_job_type eq $job_type) {
	    $JOB_TYPE{$server} = {};
	    $JOB_TYPE{$server}->{'task_url'} = $task_url;
	    $JOB_TYPE{$server}->{'library_path'} = $library_path;
	    $JOB_TYPE{$server}->{'module'} = $module;
	    $JOB_TYPE{$server}->{'subroutine'} = $subroutine;
	    $ref_options = [];
	    push @$ref_options, %options;
	    $JOB_TYPE{$server}->{'options'} = $ref_options;
	}
    }
    close(JOBS);
    if (!defined(%JOB_TYPE) ||
	join('',(keys %JOB_TYPE)) =~ /^\s*$/) {
	$remote = new RCGI;
	$remote->{'status'} = -20;
	$remote->{'error_message'} = "No job types defined of type: $my_job_type\n";
	return $remote;
    }
    if (!open(SERVER,"$server_file")) {
	$remote = new RCGI;
	$remote->{'status'} = -11;
	$remote->{'error_message'} = "Unable to open server.conf: $server_file\n";
	return $remote;
    }
    while(<SERVER>) {
	# Remove comments
	s/\#.*$//;
	if (/^\s*$/) {
	    next;
	}
	s/\s+/\t/g;
	($machine, $number_processors, $processes_per_processor, $reserve) =
	    split("\t");
	$RESERVE{$machine} = $reserve;
	$PROCESS_PERCENT{$machine} =
	    (100 / int( $number_processors * $processes_per_processor) );
    }
    close(SERVER);
    if (!dbmopen(%SAR,$log_file,0664)) {
	$remote = new RCGI;
	$remote->{'status'} = -12;
	$remote->{'error_message'} = "Unable to open sar file: $log_file\n";
	return $remote;
    }
    foreach $machine (keys %SAR) {
	( $datetime, $usr, $delta_usr,
	 $sys, $delta_sys,
	 $wio, $delta_wio,
	 $idle ,$delta_idle ) =
	     split("\t",$SAR{$machine});
	$DATETIME{$machine} = $datetime;
	$IDLE{$machine} = $idle;
	$DELTA_IDLE{$machine} = $delta_idle;
    }
    dbmclose(%SAR);
    # Need to just assign to machines for the job_type in question
    open(LOADLOCK,"$load_file.dir");
    flock(LOADLOCK,2); # Lock exclusive and blocking
#    flock(fileno(LOADLOCK),2); # Lock exclusive and blocking
    if (!dbmopen(%LOAD,$load_file,0664)) {
	$remote = new RCGI;
	$remote->{'status'} = -13;
	$remote->{'error_message'} = "Unable to open load file: $load_file\n";
	return $remote;
    }
    foreach $machine (keys %JOB_TYPE) {
	($load_time, $load_idle) = split("\t",$LOAD{$machine});
	# if the measurement time hasn't changed, use calculated idle
	# otherwise go with fresh measurement
	if ($load_time ne $DATETIME{$machine} ||
	    $load_time =~ /^\s*$/) {
	    $load_idle = $IDLE{$machine};
	    $IDLE{$machine} = $load_idle;
	}
	# check for a server configuration--otherwise use defaults
	if (!defined($PROCESS_PERCENT{$machine})) {
	    $PROCESS_PERCENT{$machine} = (100 / int( 1 * 2 ) );
	    $RESERVE{$machine} = 0;
	    print STDERR
		"No server configuration for: $machine--using defaults:"
		    . $PROCESS_PERCENT{$machine} . ' '
			. $RESERVE{$machine} . "\n";
	}
	# look for maximum idle and minimum delta_idle
	$current_idle = ($load_idle - $PROCESS_PERCENT{$machine} - $RESERVE{$machine});
	if ($current_idle > $max_idle ||
	    ($current_idle == $max_idle &&
	     $DELTA_IDLE{$machine} <= $min_delta_idle)) {
	    $max_idle = $load_idle
		- $PROCESS_PERCENT{$machine} - $RESERVE{$machine};
	    $min_delta_idle = $DELTA_IDLE{$machine};
	    $assigned_machine = $machine;
	}
    }
    if ($assigned_machine =~ /^\s*$/) {
	$remote = new RCGI;
	$remote->{'status'} = -24;
	$remote->{'error_message'} = "Unable to assign machine from: "
	    . join(' ',(keys %JOB_TYPE)) . "\n";
	return $remote;
    }
    if ($DATETIME{$assigned_machine} =~ /^\s*$/) {
	$remote = new RCGI;
	$remote->{'status'} = -25;
	$remote->{'error_message'} = "No sar measurement for machine: $assigned_machine\n";
	return $remote;
    }
    if ($JOB_TYPE{$assigned_machine} =~ /^\s*$/) {
	$remote = new RCGI;
	$remote->{'status'} = -26;
	$remote->{'error_message'} = "No job type definition for machine: $assigned_machine\n";
	return $remote;
    }
    if ($JOB_TYPE{$assigned_machine}->{'task_url'} =~ /^\s*$/ ||
	$JOB_TYPE{$assigned_machine}->{'module'} =~ /^\s*$/ ||
	$JOB_TYPE{$assigned_machine}->{'subroutine'} =~ /^\s*$/ ) {
	$remote = new RCGI;
	$remote->{'status'} = -27;
	$remote->{'error_message'} = "Missing task_url, module, or subroutine in job type definition for machine: $assigned_machine\n";
	dbmclose(%LOAD);
	flock(LOADLOCK,8); # unlock
#	flock(fileno(LOADLOCK),8); # unlock
	close(LOADLOCK);
	return $remote;
    }
    if ($IDLE{$assigned_machine} < $min_load) {
	$remote = new RCGI;
	$remote->{'status'} = -30;
	$remote->{'error_message'} = "The load is less than the minimum: $min_load % for job: $my_job_type -- try again when the computers are less busy.\n";
	return $remote;
    } else {
	$LOAD{$assigned_machine} =
	    join("\t",
		 ( $DATETIME{$assigned_machine},
		  $IDLE{$assigned_machine} - $PROCESS_PERCENT{$assigned_machine} ) );
	dbmclose(%LOAD);
	flock(LOADLOCK,8); # unlock
#	flock(fileno(LOADLOCK),8); # unlock
	close(LOADLOCK);
    }
    $ref_options = $JOB_TYPE{$assigned_machine}->{'options'};
    $remote = new RCGI($JOB_TYPE{$assigned_machine}->{'task_url'},
			   $JOB_TYPE{$assigned_machine}->{'library_path'},
			   $JOB_TYPE{$assigned_machine}->{'module'},
			   $JOB_TYPE{$assigned_machine}->{'subroutine'},
			   @$ref_options);
    $remote->{'server'} = $assigned_machine;
    $remote->{'process_percent'} = $PROCESS_PERCENT{$assigned_machine};
    $remote->{'datetime'} = $DATETIME{$assigned_machine};
    return ($remote);
}

sub Success {
    my($self) = shift;
    return ( ($self->{'status'} == 200) ? 1 : 0);
}

sub Status {
    my($self) = shift;
    return $self->{'status'};
}

sub Error_Message {
    my($self) = shift;
    return $self->{'error_message'};
}

sub Base_URL {
    my($self) = shift;
    my($arg) = shift;
    my($return);

    $return = $self->{'base_url'};
    if (defined($arg)) {
	$self->{'base_url'} = $arg;
    }
    return $return;
}

sub Library_Path {
    my($self) = shift;
    my($arg) = shift;
    my($return);

    $return = $self->{'library_path'};
    if (defined($arg)) {
	$self->{'library_path'} = $arg;
    }
    return $return;
}

sub Module {
    my($self) = shift;
    my($arg) = shift;
    my($return);

    $return = $self->{'module'};
    if (defined($arg)) {
	$self->{'Module'} = $arg;
    }
    return $return;
}

sub Subroutine {
    my($self) = shift;
    my($arg) = shift;
    my($return);

    $return = $self->{'subroutine'};
    if (defined($arg)) {
	$self->{'subroutine'} = $arg;
    }
    return $return;
}

sub Async {
    my($self) = shift;
    my($arg) = shift;
    my($return);

    $return = $self->{'async'};
    if (defined($arg)) {
	$self->{'async'} = $arg;
    }
    return $return;
}

sub Wantarray {
    my($self) = shift;
    my($arg) = shift;
    my($return);

    $return = $self->{'wantarray'};
    if (defined($arg)) {
	$self->{'wantarray'} = $arg;
    }
    return $return;
}

sub Username {
    my($self) = shift;
    my($arg) = shift;
    my($return);

    $return = $self->{'username'};
    if (defined($arg)) {
	$self->{'username'} = $arg;
    }
    return $return;
}

sub Password {
    my($self) = shift;
    my($arg) = shift;
    my($return);

    $return = $self->{'password'};
    if (defined($arg)) {
	$self->{'password'} = $arg;
    }
    return $return;
}

sub Timeout {
    my($self) = shift;
    my($arg) = shift;
    my($return);

    $return = $self->{'timeout'};
    if (defined($arg)) {
	$self->{'timeout'} = $arg;
    }
    return $return;
}

sub User_Agent {
    my($self) = shift;
    my($arg) = shift;
    my($return);

    $return = $self->{'user_agent'};
    if (defined($arg)) {
	$self->{'user_agent'} = $arg;
    }
    return $return;
}


#
# %cgi_form = Process_Parameters( new CGI, \%TRANSLATE, \%IGNORE );
#
# OR
#
# %cgi_form = Process_Parameters( new CGI);
#
# OR
#
# %cgi_form = Process_Parameters( new CGI, { 'myparam1' => 'param1'} , 
#			         { 'myparam2' => 1 });
#
sub Process_Parameters {
    my($cgi_query) = shift;
    my($translate) = shift;
    my($ignore) = shift;
    my($file_upload) = shift;
    my(%cgi_form);
    my(%options);
    my($upload_handle);
    my($upload_value);
    
    if (!defined($translate)) {
	$translate = {};
    }
    if (!defined($ignore)) {
	$ignore = {};
    }
    if (!defined($file_upload)) {
	$file_upload = {};
    }
    map {
	if (!defined($ignore->{$_})) {
	    if (defined($translate->{$_})) {
		if (defined($file_upload->{$_})) {
		    $upload_handle = $cgi_query->param($_);
		    undef $upload_value;
		    while(<$upload_handle>) {
			$upload_value .= $_;
		    }
		    $cgi_form{'upload:' . $translate->{$_}} = $upload_value;
		} else {
		    $cgi_form{$translate->{$_}} = $cgi_query->param($_);
		}
	    } else {
		if (defined($file_upload->{$_})) {
		    $upload_handle = $cgi_query->param($_);
		    undef $upload_value;
		    while(<$upload_handle>) {
			$upload_value .= $_;
		    }
		    $cgi_form{'upload:' . $_} = $upload_value;
		} else {
		    $cgi_form{$_} = $cgi_query->param($_);
		}
	    }
	}
    } $cgi_query->param;
    $options{'user_agent'} = $cgi_query->user_agent();
    $options{'user_name'} = $cgi_query->user_name();
    $options{'referer'} = $cgi_query->referer();
    $options{'remote_addr'} = $cgi_query->remote_addr();
    $options{'remote_ident'} = $cgi_query->remote_ident();
    $options{'remote_host'} = $cgi_query->remote_host();
    $options{'remote_user'} = $cgi_query->remote_user();
    $options{'request_method'} = $cgi_query->request_method();
    $options{'method'} = ($cgi_query->request_method() =~ /POST/) ? 1 : 0;
    return (\%cgi_form, %options);
}

sub Mime_Encode {
    my($form) = shift;
    my($output);
    my($field, $file);

    map {
	$field = $_;
	if ($field =~ /^upload:/) {
	    $field =~ s/^upload://;
	    $file = 1;
	} else {
	    $file = 0;
	}
	if ($field !~ /^\s*$/) {
	    $output .= Mime_Item($field => $form->{$_}, $file);
	}
    } (keys %$form);
    $output .= "-----------------------------7cea139e4f0538--\r\n";
    return $output;
}

# Mime_Item( 'field_name' => $value);
#
# or
#
# Mime_Item( 'field_name' => $filename, 1);

sub Mime_Item {
    my($field_name) = shift;
    my($value) = shift;
    my($file) = shift;
    my($filename);
    my($mime_filename);
    my($encoded);
    my($encode_type);
    my($return);

    if ($file) {
	$filename = $value;
	$mime_filename = "; filename=\"$filename\"";
	undef $value;
	$encode_type = 0;
	open(FILE,"$filename");
	while(<FILE>) {
	    $value .= $_;
	    # test for ASCII values only and set encode_type = 0 if so
	}
	close(FILE);
    }
    $return .= "-----------------------------7cea139e4f0538\r\n";
    $return .= "Content-Disposition: form-data; name=\"$field_name\"$mime_filename\r\n";

    if ($mime_filename !~ /^\s*$/) {
	if ($encode_type == 1) { # raw binary
	    $return .= "Content-Type: application/octet-stream\r\n\r\n$value\r\n";
	} elsif ($encode_type == 0) { # raw because ASCII only
	    $return .= "Content-Type: text/plain\r\n\r\n$value\r\n";
	} else {		# base64 encoded
#	    # it doesn't seem like this is desirable or necessary
#	    $encoded = MIME::Base64::encode($value);    
#	    $return .= "Content-Type: application/octet-stream\r\n";
#	    $return .= "Content-Transfer-Encoding: base64\r\n\r\n";
#	    $return .= "$encoded\r\n";
	}
    } else {
	$return .= "\r\n$value\r\n";
    }
}


# For POST
#
# run_cgi_command($base_url, \%cgi_form);
#
# For GET
#
# run_cgi_command($base_url, \%cgi_form, 'method' => 1);
#
# Options are:
#
# method => (0 or undef) or 1  are GET or POST (and 2 for PUT)
# nph => (0 or undef) or 1
# username => 'username'
# password => 'password'
# user_agent => 'user_agent' (i.e. 'Mozilla')
# timeout => timeout in seconds (default is 180)

sub run_cgi_command {
    my($base_url) = shift;	# Base URL to call
    my($form) = shift;		# reference to associative array
                                # of CGI parameters
    my(%options) = @_;		# Get options as associative array
    my($string_method) = ($options{'method'}) ?
	(($options{'method'} == 2) ? 'PUT' : 'POST') : 'GET';
    my($ua) = new LWP::UserAgent;
    my($req);
    my($headers_printed);
    my($removed);
    my($file_upload) = 0;
    my($result);

    # check for a file upload field
    map {
	if (/^upload:/) {
	    $file_upload = 1;
	}
    } (keys %$form);
    if ($file_upload) {
	if ($string_method eq 'PUT') {
	    $req = new HTTP::Request $string_method, $base_url;
#	    $req->content_type('multipart/form-data'); # and multipart form
	    $req->content('');
	    map {
		if (/^upload:/) {
		    open(FILE,$form->{$_});
		    $req->add_content(join('',<FILE>));
		    close(FILE);
		}
	    } (keys %$form);
	} else {
	    $string_method = 'POST'; # must be POST'ed
	    $req = new HTTP::Request $string_method, $base_url;
	    $req->content_type('multipart/form-data'); # and multipart form
	    $req->content(Mime_Encode($form)); # %form content as mime encoded
	}
    } else {
	$req = new HTTP::Request $string_method, $base_url;
	my($curl) = new URI::URL "http:";      # create an empty HTTP URL object
	$curl->query_form(%$form);	# add CGI parameters
	$req->content_type('application/x-www-form-urlencoded');
	$req->content($curl->equery); # %form content as escaped query string
    }

    if (defined($options{'user_agent'})) {
	$ua->agent($options{'user_agent'});
    }
    if (defined($options{'timeout'})) {
	$ua->timeout($options{'timeout'});
    }
    if (defined($options{'username'}) && defined($options{'password'})) {
	$req->authorization_basic($options{'username'}, $options{'password'});
    }

    if ($options{'nph'}) {
	$| = 1;
	$ua->request($req,
		     sub {
			 my($chunk, $res) = @_;
			 if (!$headers_printed) {
			     $headers_printed = 1;
			     $chunk =~ s/HTTP.*\s+(\d+)\s+OK/Status: $1 OK/m;
			     $chunk =~ s/Content-Type: (.*)\n/Content-Type: $1\n\n\n/m;
			     $chunk =~ s/Connection: close\s*\n//m;
			     $chunk =~ s/Date: .*\s*\n//m;
			     $chunk =~ s/Expires: .*\s*\n//m;
			     $chunk =~ s/Server: .*\s*\n//m;
			     $chunk =~ s/Client-Date: .*\s*\n//m;
			     $chunk =~ s/Client-Peer: .*\s*\n//m;
			     $chunk =~ s/Link: .*\s*\n//m;
			     $chunk =~ s/Title: .*\s*\n//m;
			 }
			 print $chunk;
		     },
    1024
		     );
	return '';
    } else {
	$result = $ua->request($req)->as_string;
	$result =~ s/\r//gm;
	$result =~ s/\t/\r/gm;
	$result =~ s/\n/\t/gm;
	$| = 1;
        my($last_result);
        # Remove any lines between HTTP and Content-Type
	while ($result !~ /^HTTP[^\t]*\s+\d+[^\t]*\t\s*Content-[Tt]ype:/ &&
               $result ne $last_result) {
             $last_result = $result;
             ($removed) = $result =~ /^HTTP[^\t]*\s+\d+[^\t]*\t([^\t]*)\t/;
             $result =~ s/^(HTTP[^\t]*\s+\d+[^\t]*\t)[^\t]*\t/$1/;
        }
	$result =~ s/\t/\n/gm;
	$result =~ s/\r/\t/gm;
	$result =~ s/HTTP.*\s+(\d+)\s+OK/Status: $1 OK/m;
	$result =~ s/Content-[Tt]ype: (.*)\n/Content-Type: $1\n\n\n/m;
	$result =~ s/Connection: close\s*\n//m;
	$result =~ s/Client-Date: .*\s*\n//m;
	$result =~ s/Client-Peer: .*\s*\n//m;
	$result =~ s/Date: .*\s*\n//m;
	$result =~ s/Server: .*\s*\n//m;
	$result =~ s/Link: .*\s*\n//m;
	$result =~ s/Title: .*\s*\n//m;
	return $result;
    }
}

#my($res) = $ua->request($req, "result_file");
#if ($res->is_success) {
#    print "ok\n";
#}


# perl subroutine to call a perl subroutine remotely
#
# @my_result = $rcgi->Call( @arguments );
# $my_result = $rcgi->Call( @arguments );
#

sub Call {
    my($self) = shift;
    my($arg_dump) = Data::Dumper->new([ \@_ ])
	->Purity(1)
	    ->Indent(0)
		->Dumpxs;
    my($method)     = 1;
    my($wantarray)  = (defined($self->{'wantarray'})) ? $self->{'wantarray'}
	:(wantarray) ? 1 : 0;
    my(%cgi_form) = (		# Setup CGI parameters to pass
		     'library_path' => $self->{'library_path'},
		     'module' => $self->{'module'},
		     'subroutine' => $self->{'subroutine'},
		     'arguments' => $arg_dump,
		     'wantarray' => $wantarray
		     );
    my($sleep_count) = 6;
    my($result);

    # Make sure there were not setup errors
    if (defined($self->{'status'}) &&
	$self->{'status'} < 0) {
	return undef;
    }
    # Make sure we have what we need
    if (!defined($self->{'base_url'}) ||
	!defined($self->{'module'}) ||
	!defined($self->{'subroutine'})) {
	$self->{'status'} = -1;
	$self->{'error_message'} =
	    'base_url, module, or subroutine needs to be set';
    }
    if ($self->{'async'}) {
	# Asynchronous calls (nonblocking)
	# Setup pipe and fork background process to wait on remote server
	do {
	    $self->{'pipe'} = new IO::Pipe;
	    $self->{'waitpipe'} = new IO::Pipe;
	    $self->{'pid'} = fork();
	    unless( defined($self->{'pid'})) {
		cluck "cannot fork: $!";
		if( $sleep_count-- < 0) {
		    carp "bailing out";
		    $self->{'status'} = -2;
		    $self->{'error_message'} = 'Unable to fork process';
		    return undef;
		}
		sleep 10;
	    }
	} until defined $self->{'pid'};
	
	if ($self->{'pid'}) {			# parent
	    $self->{'pipe'}->reader();
	    $self->{'waitpipe'}->writer();
	    $self->{'pipenumber'} = $self->{'pipe'}->fileno();
	} else {
	    $SIG{HUP} = undef;
	    $SIG{INT} = undef;
	    $SIG{QUIT} = undef;
	    $SIG{KILL} = undef;
	    $SIG{PIPE} = undef;
	    $SIG{TERM} = undef;
	    $self->{'pipe'}->writer();
	    $self->{'pipe'}->autoflush();
	    $self->{'waitpipe'}->reader();
	    $result = RCGI::run_cgi_command($self->{'base_url'},
					    \%cgi_form,
					    method => $method,
					    username => $self->{'username'},
					    password => $self->{'password'},
					    timeout => $self->{'timeout'},
					    user_agent => $self->{'user_agent'});
#	    print STDERR "Child $$ Printing result\n";
	    $self->{'pipe'}->print($result);
	    $self->{'pipe'}->close();
#	    print STDERR "Child $$ Waiting done\n";
	    $self->{'waitpipe'}->getline; # Wait for parent to talk to us
	    $self->{'waitpipe'}->close(); # and then close and exit
#	    print STDERR "Child $$ Exiting\n";
	    exit;
	}
    } else {
	# Synchronous calls (blocking)
	$result = RCGI::run_cgi_command($self->{'base_url'},
					\%cgi_form,
					method => $method,
					username => $self->{'username'},
					password => $self->{'password'},
					timeout => $self->{'timeout'},
					user_agent => $self->{'user_agent'});
	$result = $self->Process_Result($result);
	if (!defined($self->{'status'}) ||
	    $self->{'status'} =~ /^\s*$/ ||
	    $self->{'status'} > 200) {
	    return undef;
	} else {
	    # Strip Content-Type header
	    $result =~ s/^\s*Content-[Tt]ype:.*\n//;
	    $result =~ s/^\s*//m;
	    return Data::Undumper::Undump($result);
	}
    }
}

#
# Process status header
#
sub Process_Result {
    my($self) = shift;
    my($result) = shift;
    my($load_file) = $RCGI::Config::path ."/load";
    my($load_time, $load_idle);
    my(%LOAD);

    if ($result =~ /^Status:\s*200\s*OK/) {
	$self->{'status'} = 200;
	$result =~ s/^Status:.*\n//;
    } elsif ( $result =~ /^\s*HTTP\/[\S\.]+\s+\d+\s+.*/ ) {
	($self->{'status'}, $self->{'error_message'}) =
	    $result =~ /^\s*HTTP\/[\S\.]+\s+(\d+)\s+(.*)/;
	$result =~ s/^HTTP\/\S+\s+\d+.*\n//;
    } else {
	($self->{'status'}, $self->{'error_message'}) =
	    $result =~ /^\s*(\d+)(.*)/;
	$result =~ s/^.*\n//;
	$result =~ s/^.*\n//;
    }
    # Update load, if still valid
    if (defined($self->{'server'})) {
	open(LOADLOCK,"$load_file.dir");
	flock(LOADLOCK,2); # Lock exclusive and blocking
#	flock(fileno(LOADLOCK),2); # Lock exclusive and blocking
	dbmopen(%LOAD,$load_file,0664);
	($load_time, $load_idle) = split("\t",$LOAD{$self->{'server'}});
	if ($load_time eq $self->{'datetime'}) {
	    $LOAD{$self->{'server'}} =
		join("\t",
		     ( $load_time,
		      $load_idle + $self->{'process_percent'} ) );
	}
	dbmclose(%LOAD);
	flock(LOADLOCK,8); # unlock
#	flock(fileno(LOADLOCK),8); # unlock
	close(LOADLOCK);
    }
    return $result;
}

sub Done {
    my($self) = shift;
    my($rin) = '';
    my($rout);

    # Done if there was an error
    if (defined($self->{'status'}) && $self->{'status'} != 200) {
	return 1;
    }
    vec($rin, $self->{'pipenumber'}, 1) = 1;
    # timeout after zero seconds
    return (select($rout = $rin, undef, undef, 0.0) == 1);
}

sub Read {
    my($self) = shift;
    my($result);

    # Done if there was an error
    if (defined($self->{'status'}) && $self->{'status'} != 200) {
	return undef;
    }
#    print STDERR "Getting result from $self->{'pid'}\n";
    while($_ = $self->{'pipe'}->getline) {
	$result .= $_;
    }
    $self->{'pipe'}->close;
#    print STDERR "Delivering done to child $self->{'pid'}\n";
    # clean up child process
    $self->{'waitpipe'}->autoflush;
    $self->{'waitpipe'}->print("done\n\n\n\n"); # write to child to allow it to exit
    $self->{'waitpipe'}->close;
#    kill 'QUIT', $self->{'pid'};
#    kill 'INT', $self->{'pid'};
#    kill 'KILL', $self->{'pid'};
#    print STDERR "Waiting on child $self->{'pid'}\n";
    wait;
#    waitpid $self->{'pid'},WNOHANG;
    $result = $self->Process_Result($result);
    if (!defined($self->{'status'}) ||
	$self->{'status'} =~ /^\s*$/ ||
	$self->{'status'} != 200) {
	return undef;
    } else {
	# Strip Content-Type header
	$result =~ s/^Content-Type:.*\n//;
	$result =~ s/^\s*//m;
	return Data::Undumper::Undump($result);
    }
}

sub Invoke {
    my($my_job_type) = shift;
    my($remote) = new_job RCGI($my_job_type);
    if (defined($remote)) {
	return $remote->Call(@_);
    }
    return undef;
}

sub Async_Invoke {
    my($my_job_type) = shift;
    my($remote) = new_job RCGI($my_job_type);
    if (defined($remote)) {
	$remote->Async(1);
	$remote->Call(@_);
    }
    return $remote;
}

__END__

=head1 NAME

RCGI - Remote CGI distributed processing

=head1 SYNOPSIS

    use RCGI;
    @result = Invoke('jobone',@arguments);
    $result = Invoke('jobtwo',@arguments);

    $remote_subroutine = new RCGI($base_url,$library_path,$module,$subroutine);
    @my_result = $remote_subroutine->Call(@arguments);
    if ($remote_subroutine->Success()) {
         print @my_result,'';
    } else {
         print STDERR "Call to " . $remote_subroutine->Base_URL() .
	   " failed with status: " . $remote_subroutine->Status() .
	          ' ' . $remote_subroutine->Error_Message() . "\n";
    }
    $remote_subroutine->Async(1);
    $remote_subroutine->Wantarray(1);
    $remote_subroutine->Call(@arguments);
    while(! $remote_subroutine->Done()) {
        # This should really be something usefull--like calls to other servers!
        sleep 1;
    }
    @my_result = $remote_subroutine->Read();
    if ($remote_subroutine->Success()) {
         print @my_result,'';
    } else {
         print STDERR "Call to " . $remote_subroutine->Base_URL() .
	   " failed with status: " . $remote_subroutine->Status() .
	          ' ' . $remote_subroutine->Error_Message() . "\n";
    }

    $result = RCGI::run_cgi_command($base_url, \%cgi_form,
	                            method => $method,
                                    username => $username,
                                    password => $password,
                                    timeout => $timeout,
                                    user_agent => $user_agent,
                                    nph => $bool_nph);

    # In a CGI script
    ($cgi_form, %options) = RCGI::Process_Parameters( new CGI );
    $result = RCGI::run_cgi_command($base_url, $cgi_form, %options);

=head1 ABSTRACT

This perl library provides remote execution using CGI on remote web servers.

=head1 INSTALLATION:

=head2 Installation overview

The installation of RCGI for full functionality consists of the following steps:

1) Edit RCGI/Config.pm to change the location of the configuration directory to an appropriate place.

2) Install the RCGI library itself by doing:
        perl Makefile.PL
        make
        make test
        make install

3) Put the B<perlcall.cgi> CGI script and the B<SAR.pm> module on every computer which will be running remote subroutines in the computer's webserver's cgi-bin directory.

4) Create B<sard.conf>, B<server.conf>, and B<jobs.conf> files in the B</usr/rcgi> directory.

5) Start the B<sard> daemon running on a computer which has read and write access to the B</usr/rcgi> directory.

6) (Optional) Edit the line in sardcheck ($sard_user = 'sard_user'), to be the user which ran the the B<sard> daemon in step five.  As the same use as step five, add a crontab entry which looks similar to:

30 * * * * /usr/local/bin/perl /path_to_sardcheck/sardcheck

Steps 2 and 3 are the only steps necessary if the load balancing calls: B<Invoke>, B<Async_Invoke>, or B<new_job RCGI> will not be used.  Step 3 may be neglected if only B<RCGI::run_cgi_command> will be used.

=head2 The /usr/rcgi directory

If you wish to change the location of the configuration directory from the default value of B</usr/rcgi>, edit B<RCGI/Config.pm>.  The configuration must then be made, I<mkdir /usr/rcgi> and set to the correct permissions: I<chgrp rcgi /usr/rcgi ; chmod g+rw /usr/rcgi>.  The DBM files: B<load.dir> and B<load.pag> are created in this directory and must be writable by any user process attempting to B<Invoke> remote subroutines.

The sard.conf, server.conf, and jobs.conf files need to then be created in the B</usr/rcgi> directory.  Following is the format for those files:

=head2 sard.conf

     # machine URL_of_perlcall.cgi path_to_SAR.pm_module
     # Items on a line must be seperated by a single tab
     machine_name	http://www.webserver.url/cgi-bin/perlcall.cgi	path_to_SAR.pm_module

=head2 sard daemon

Usage is: sard /usr/rcgi/sard.conf /usr/rcgi/sar [timeperiod_in_seconds] [bool_verbose]

The sard (System Activity Report Daemon) runs in the background to collect usage from the machines configured in the sard.conf file.  It uses the RCGI library to call (via perlcall.cgi) the SAR.pm module which, on Unix, uses the sar program to collect system activity over, by default, 10 minute periods.  This information is stored in the DBM B<sar> file located in the B</usr/rcgi> directory.

This system activity information is used by the RCGI library to implement load balancing of job requests.

=head2 server.conf

     # machine number_of_processors processes_per_processor reserve_idle(in percent)
     # the high reserve_idle should prevent those machines from being used
     # Items on a line must be seperated by a single tab
     medium	4	2	10
     shared	4	1	50
     dud	1	2	100000
     mine	1	1	100000
     super	12	1	10

=head2 jobs.conf

     # job_type server task_url library_path module subroutine option option_value
     # where option can be: timeout, username, password, user_agent
     # Items on a line must be seperated by a single tab
     jobone	machine1	http://webserver1/cgi-bin/perlcall.cgi	module_path	Module	subroutine	option_name	option_value
     jobone	machine2	http://webserver2/cgi-bin/perlcall.cgi	module_path	Module	subroutine	option_name	option_value
     jobtwo	machine2	http://webserver2/cgi-bin/perlcall.cgi	module_path	Module	subroutine	option_name	option_value
     jobtwo	machine3	http://webserver3/cgi-bin/perlcall.cgi	module_path	Module	subroutine	option_name	option_value

=head2 perlcall.cgi and SAR.pm and other user modules installation

The B<perlcall.cgi> perl CGI script and the B<SAR.pm> module will need to be installed in a I<cgi-bin> directory of the web server of every computer which will be set up to allow jobs to be B<Invoke>'ed or B<Call>'ed.  The B<SAR.pm> module can alternatively be installed anywhere in the standard perl B<@INC> path.

Perl modules to call must be in the standard perl B<@INC> path or in the library path given in the calls or in B<jobs.conf>.

=head2 RCGI libraries installation

To install this package, just change to the directory in which this file is
found and type the following: 

        perl Makefile.PL
        make
        make test
        make install

In order for a job to be invoked, the sard daemon must be running to collect computer processor loads.  The B<perlcall.cgi> CGI script and the B<SAR.pm> module must be installed properly on each computer.

=head1 DESCRIPTION

The RCGI library allows calling Perl subroutines in modules on remote computers with load balancing.

=head2 Load balancing using RCGI

RCGI calculates which machine to invoke a job on by using the machine which has the maximum idle time as determined by:

1) Take the measured idle time for each machine if it is newer than the last calculated idle time for the machine.

2) Subtract the reserve_idle for each machine.

3) If two machines have similar resulting idle times, use the machine with the most increase in measured idle time.

The resulting idle time then has a process usage amount subtracted from it and which is then stored in the DBM B<load> file stored in the B</usr/rcgi> directory for subsequent usage for other job requests.

The process usage for a machine is calculated according to the following formula:

    process_usage = (100 / (machine_processors * processes_per_processor));

=head2 Usage of RCGI

A perl program which is written as:

    use lib 'module_path';
    use Module;
    $result = Module::subroutine(@arguments); # or
    @result = Module::subroutine(@arguments);

can be converted to use a job, jobone:

B<jobs.conf> entry:

     jobone	machine1	http://webserver1/cgi-bin/perlcall.cgi	module_path	Module	subroutine
     jobone	machine2	http://webserver2/cgi-bin/perlcall.cgi	module_path	Module	subroutine

by being rewritten as:

    use RCGI;
    $remote_subroutine = new_job RCGI('jobone');
    $result = $remote_subroutine->Call(@arguments); # or
    @result = $remote_subroutine->Call(@arguments);

or 

    use RCGI;
    $result = Invoke('jobone',@arguments); # or
    @result = Invoke('jobone',@arguments);

or can be rewritten to directly call a specific machine, machine1, as:

    use RCGI;
    $remote_subroutine = new RCGI('http://webserver1/cgi-bin/perlcall.cgi',
				  'module_path',
				  'Module',
				  'subroutine');
    $result = $remote_subroutine->Call(@arguments); # or
    @result = $remote_subroutine->Call(@arguments);

with the error checking for failure of the remote call by:

    if ($remote_subroutine->Success()) {
	print $result;
    } else {
	print "Call to " . $remote_subroutine->Base_URL() .
	    " failed with status: " . $remote_subroutine->Status() .
		' ' . $remote_subroutine->Error_Message() . "\n";
    }


=head2 RCGI Structure

There are four possible uses or layers for RCGI:

  1. Invoking a module subroutine as a job via perlcall.cgi on the least busy computer defined for that job type.  This may be either synchronous or asynchronous.

  2. Getting a RCGI remote subroutine object for the least busy computer defined for that job type.

  3. Calling a module subroutine via perlcall.cgi on a particular computer.  This may be either synchronous or asynchronous.

  4. Retrieving HTML pages from static HTML pages or CGI scripts using RCGI::run_cgi_command.

=head2 RCGI Structure Diagram

The arrows, '# ==>', show the usable API of RCGI.

                                                               sard.conf
                                                              /
                                                             L
                                                         sard
                                                         |
   1 ==> Invoke or Async_Invoke                          V
                   |             jobs.conf, server,conf, DBM file sar
                   |            /
                   V           L
   2 ==>           new_job RCGI <-----> DBM file load
                        |
                        |
                        V
   3 ==>             new RCGI
                        |
                        |
                        V
                   $remote_subroutine->Call ==> http://www/cgi-bin/perlcall.cgi
                   |                     /|         A
                   |                     /|         |
                   |                    / |         V
                   V                   /  |     return( eval '
   4 ==> RCGI::run_cgi_command        /   |     use lib 'library_path';
                                     /    |     use Module;
                                    /     |     Module::subroutine(@arguments);
                                   L      |     ' );
                   $result or @result     V
          $remote_subroutine->Success     $remote_subroutine->Done
    $remote_subroutine->Error_Message            |
                                                 |
                                                 V
                                          $remote_subroutine->Read
                                                 |
                                                 |
                                                 V
                                               result
                                         $remote_subroutine->Sucess
                                         $remote_subroutine->Error_Message

=head1 Functions and Methods

=head2 Invoke a job request

    @my_result = Invoke('job_name',@arguments);

Invoke a job to synchronously call a remote subroutine.

Where @arguments is the normal list of arguments for the remote subroutine.

=head2 Async_Invoke a job request

    $remote_subroutine = Async_Invoke('job_name',@arguments);

Invoke a job to asynchronously call a remote subroutine.

Where @arguments is the normal list of arguments for the remote subroutine.

=head2 Get a new RCGI object using a job type

    $remote_subroutine = new_job RCGI('job_name');

     OR

    $remote_subroutine = new_job RCGI('job_name',$minimum_load);

This will create a new object which will allow a remote subroutine call for a particular job type.  B<$minimum_load> is the minimum percentage of idle to leave when assigning jobs.

=head2 Creating a new RCGI object:

    $remote_subroutine = new RCGI($base_url,$library_path,$module,$subroutine)

     OR

    $remote_subroutine = new RCGI($base_url,$library_path,$module,$subroutine,
				  -option => value)

The arguments are:

B<$base_url> -- the base URL for the remote subroutine call.  This is the URL for perlcall.cgi on the remote web server.

B<$library_path> -- the location of the module which contains the subroutine for the remote subroutine call.  This is optional--I<undef> may be passed instead if the module is located relative to the perl B<@INC> path.  A '.' may be passed to specify the cgi-bin directory on the remote web server.

B<$module> -- the module which contains the subroutine for the remote subroutine call.

B<$subroutine> -- the name of the subroutine to call for the remote subroutine call.  This subroutine must be callable in the form I<Module_Name::subroutine();>.  Please remember that no executation state is maintained by default on the remote computer.

Options are passed as: -option => value, where -option is one of:

     -async          Do an asynchronous call.
     -wantarray      Force array or scalar result (useful for using with async).
     -username       Username to login to remote web server, if any.
     -password       Password to login to remote web server, if any.
     -user_agent     User_agent to use for remote web server.
     -timeout        Timeout in seconds for web connection (default is 180).

This will create a new object which allows remote subroutine calls.

=head2 Calling the remote subroutine with Call

Synchronous B<Call>

    @my_result = $remote_subroutine->Call(@arguments);

     OR

    $my_result = $remote_subroutine->Call(@arguments);

Where @arguments is the normal list of arguments for the remote subroutine.

Asynchronous B<Call>

    $remote_subroutine->Call(@arguments);

     while(! $remote_subroutine->Done()) {
	# This should really be something useful
	sleep 1;
     }
     @my_result = $remote_subroutine->Read();

     OR

     $my_result = $remote_subroutine->Read();

Where @arguments is the normal list of arguments for the remote subroutine.

=head2 Check to see if an asynchronous call is Done

    $remote_subroutine->Done();

Return true when the asynchronous call has completed.

=head2 Read the results from an asynchronous call

    @my_result = $remote_subroutine->Read();

     OR

    $my_result = $remote_subroutine->Read();

Fetch the result from an asynchronous call.

=head2 Success or failure of the remote subroutine call

    $remote_subroutine->Success()

This returns true if the remote subroutine call was completed with no errors.

=head2 The return Status of rhte remote subroutine call

    $remote_subroutine->Status()

This returns the status code from the remote subroutine call.  Possible values
are:

   -30 -- Machines are busy, the load is less than the load minimum (default is zero idle)

   -27 -- Missing task_url, module, or subroutine for job type definition for assigned machine

   -26 -- Missing job type definition for assigned machine

   -25 -- Missing sar measurement for assigned machine

   -24 -- Unable to assign machine

   -20 -- No job types defined match asked for job type

   -13 -- Unable to open load file

   -12 -- Unable to open sar file

   -11 -- Unable to open server.conf file

   -10 -- Unable to open jobs.conf file

    -1 -- The base URL, the module, or the subroutine were not given.

    -2 -- Unable to fork background process for asynchronous call.

   200 -- Successful call.

  >200 -- Error code from remote web server or CGI script


=head2 Error_Message

    $remote_subroutine->Error_Message()

This returns the associated error message, if any, from an unsuccessful remote subroutine call.  If the B<Status> is greater than 200, then the error message is from the remote web server.

=head2 Base_URL

    $base_url = $remote_subroutine->Base_URL();

     OR

    $remote_subroutine->Base_URL($base_url);

Get or set the base URL for the remote subroutine call.  This is the URL for B<perlcall.cgi> on the remote web server.

=head2 Library_Path

    $library_path = $remote_subroutine->Library_Path();

     OR

    $remote_subroutine->Library_Path($library_path);

Get or set the location of the module which contains the subroutine for the remote subroutine call.  This is optional--I<undef> may be passed instead if the module is located relative to the perl B<@INC> path.  A '.' may be passed to specify the cgi-bin directory on the remote web server.

=head2 Module

    $module = $remote_subroutine->Module();

     OR

    $remote_subroutine->Module($module);

Get or set the module which contains the subroutine for the remote subroutine call.

=head2 Subroutine

    $subroutine = $remote_subroutine->Subroutine();

     OR

    $remote_subroutine->Subroutine($subroutine);

Get or set the name of the subroutine to call for the remote subroutine call.  This subroutine must be callable in the form I<Module_Name::subroutine();>.  Please remember that no executation state is maintained by default on the remote computer.

=head2 Async

    $async = $remote_subroutine->Async();

     OR

    $remote_subroutine->Async($async);

Get or set whether the call is asynchronous.

=head2 Wantarray

    $wantarray = $remote_subroutine->Wantarray();

     OR

    $remote_subroutine->Wantarray($wantarray);

Get or set whether the call returns a scalar or an array (or associative array).

=head2 Username

    $username = $remote_subroutine->Username();

     OR

    $remote_subroutine->Username($username);

Get or set the username, if any, used to login to the remote server.

=head2 Password

    $password = $remote_subroutine->Password();

     OR

    $remote_subroutine->Password($password);

Get or set the password, if any, used to login to the remote server.

=head2 User_Agent

    $user_agent = $remote_subroutine->User_Agent();

     OR

    $remote_subroutine->User_Agent($user_agent);

Get or set the user_agent used to when connecting to the remote server.

=head2 Timeout

    $timeout = $remote_subroutine->Timeout();

     OR

    $remote_subroutine->Timeout($timeout);

Get or set the timeout in seconds used in the connection to the remote server.  Default is 180 seconds.

=head2 Process_Parameters

    ($cgi_form, %options) = RCGI::Process_Parameters( new CGI , \%TRANSLATE, \%IGNORE );

This processes the CGI parameters, using the passed CGI object reference.  The optional %TRANSLATE associative array allows passing CGI parameters with a different parameter field name (i.e., translate paramter foo=1 to bar=1).  The optional %IGNORE associative array specifies CGI parameters which should not be passed on.

Returned are I<$cgi_form> which is a reference to an associative array which contains the CGI parameters in a form ready to pass to B<RCGI::run_cgi_command()> and the I<%options> associative array of options to pass to B<RCGI::run_cgi_command()>.

=head2 run_cgi_command

    $result = RCGI::run_cgi_command($base_url, \%cgi_form, %options);

This fetches an HTML page from either a static HTML page or a CGI script.

B<$base_url> is the URL of the page to get.  \%cgi_form is an associate array whose index is CGI parameters to pass and whose values are the CGI parameter values to pass to the remote CGI script.  If a parameter's name has 'upload:' prepended to it, then the values will be passed using the multipart/form-data file upload method.  (Example $cgi_form = { 'upload:seq_file' => "> sequence\nAAAAA\n" }.)

Options are passed as: -option => value, where -option is one of:

     -method         CGI method to use (GET is default).
                     Values are 0 or undef for GET and 1 for POST
     -nph            Use 1 to treat the remote CGI script as NPH.
     -username       Username to login to remote web server, if any.
     -password       Password to login to remote web server, if any.
     -user_agent     User_agent to use for remote web server.
     -timeout        Timeout in seconds for web connection (default is 180).

=head1 Example Job Invoke Script

     #!/usr/local/bin/perl
     
     use RCGI;
     @result = Invoke('jobtest1','one');
     print @result;

     $result = Invoke('jobtest2','two');
     print $result;
     exit;

    $remote = new_job RCGI('jobtest1');
    @out = $remote->Call('one');
    if ( $remote->Success() == 0) {
	print " Failed with error: " .
	    $remote->Error_Message() . "\n";
	undef @out;
    }
     

=head1 Example Remote Subroutine Call Script

     #!/usr/local/bin/perl
     #
     #
     
     use RCGI;
     
     $base_url = 'http://www.sandrock.edu/cgi-bin/perlcall.cgi';
     $library_path = '/my/module/directory';
     $module = 'MyModule';
     $subroutine = 'my_subroutine';
     $remote_subroutine = new RCGI($base_url,$library_path,$module,$subroutine);
     
     @my_result = $remote_subroutine->Call(0, 'a', 'b');
     $, = "\n";
     if ($remote_subroutine->Success()) {
         print @my_result,'';
     } else {
         print STDERR "Call to " . $remote_subroutine->Base_URL() .
     	" failed with status: " . $remote_subroutine->Status() .
     	    ' ' . $remote_subroutine->Error_Message() . "\n";
     }
     
     $my_result = $remote_subroutine->Call(0, 'a', 'b', 'c');
     if ($remote_subroutine->Success()) {
         print $my_result,'';
     } else {
         print STDERR "Call to " . $remote_subroutine->Base_URL() .
     	" failed with status: " . $remote_subroutine->Status() .
     	    ' ' . $remote_subroutine->Error_Message() . "\n";
     }
     
     $remote_subroutine->Async(1);
     $remote_subroutine->Wantarray(1);
     $remote_subroutine->Call(5, 'async', 'hronous');
     $| = 1;
     while(! $remote_subroutine->Done()) {
         # This should really be something usefull--like calls to other servers!
         sleep 1;
         print ".";
     }
     @my_result = $remote_subroutine->Read();
     $, = "\n";
     if ($remote_subroutine->Success()) {
         print @my_result,'';
     } else {
         print STDERR "Call to " . $remote_subroutine->Base_URL() .
     	" failed with status: " . $remote_subroutine->Status() .
     	    ' ' . $remote_subroutine->Error_Message() . "\n";
     }



=head1 REPORTING BUGS

When reporting bugs/problems please include as much information as possible.

A small script which yields the problem will probably be of help.  If you
cannot include a small script then please include a Debug trace from a
run of your program which does yield the problem.

=head1 AUTHOR INFORMATION

Brian H. Dunford-Shore   brian@ibc.wustl.edu
David J. States          states@ibc.wustl.edu

Copyright 1998, Washington University School of Medicine,
Institute for Biomedical Computing.  All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. 

Address bug reports and comments to:
www@ibc.wustl.edu

=head1 TODO

=over 4

=item Save the result dump in a file for batch mode

=item Save the arguments in a file for queued batch mode

=back

=head1 SEE ALSO

=head1 CREDITS

=head1 BUGS

You really mean 'extra' features ;).  None known.

=head1 COPYRIGHT

Copyright (c) 1997 Washington University, St. Louis, Missouri. All
rights reserved.  This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut

1;
