package Pepper::Utilities;

$Pepper::Utilities::VERSION = '1.2.1';

# for utf8 support with JSON
use utf8;
use Encode qw( encode_utf8 );

# for encoding and decoding JSON
use Cpanel::JSON::XS;

# for logging via logger()
use Path::Tiny;
use Data::Dumper;

# need some date/time toys
use Date::Format;
use DateTime;
use Date::Manip::Date;

# support template toolkit templates
use Template;

# for being a good person
use strict;
use warnings;

sub new {
	my ($class, $args) = @_;

	# make the object 
	my $self = bless {
		'request' => $$args{request},
		'response' => $$args{response},
		'json_coder' => Cpanel::JSON::XS->new->utf8->allow_nonref->allow_blessed,
		'config_file' => $ENV{HOME}.'/pepper/config/pepper.cfg',
		'pepper_directory' => $ENV{HOME}.'/pepper',
	}, $class;
	
	# read in the system configuration
	$self->read_system_configuration() if !$$args{skip_config};
	
	return $self;	
}

### START METHODS FOR GENERATING RESPONSES AND LOGS

# method to deliver html & json out to the client;
# this must be in here to be available even if not in plack mode
sub send_response {
	my ($self, $content, $stop_here, $content_type, $content_filename) = @_;

	# if not in Plack/PSGI land, we will skip working with $self->{response}

	# $content needs to be one of a text/html string, an ARRAYREF or a HASHREF
	my $ref_type = ref($content);
	
	my ($access_message, $error_id, $access_error, $die_text, $display_error_message, $html_generator, $error_html);
	
	$stop_here ||= 0; # don't want an uninitiated value
	if ($stop_here == 1 || $stop_here == 3) { # if $stop_here is a 1 or 3, we are stopping due to an error condition
		# if it is plain text, we should most likely log the error message sent to us
		# and just present the error ID
		# exception is if you're a developer running a script; in that case,
		# set the 'development_server' in your system configuration
		
		# note access errors for display below
		$access_error = 1 if $content =~ /^Access\:/;

		if (length($content)) { 
			$error_id = $self->logger($content,'fatals'); # 'these errors go into the 'fatals' log
			# send an accurate response code
			$self->{response}->status(500);

			# unless we are on the dev server or it's the no-app message, present the error ID instead
			if ($self->{config}{development_server} eq 'Y' || $content =~ /^No application exists/) {
				$display_error_message = $content;
				# need period at the end
				$display_error_message .= '.' if $display_error_message !~ /(\.|\?|\!)$/;
			} else { # hide the error
				$content = 'Execution failed; error ID: '.$error_id."\n";
				$ref_type = ''; # make sure it gets treated as plain text;
			}

			# if we are in API mode, let's send back JSON
			if ($self->{auth_token}) {
				$ref_type = "HASH" ;
				$content = {
					'status' => 'Error',
					'error_id' => $error_id,
					'display_error_message' => $display_error_message,
				};
				# developers see the actual message
				$$content{display_error_message} = $display_error_message if $display_error_message;

			# if we are in Web UI mode, pipe it out to the user as HTML;
			} elsif ($self->{request}) {
				
				$self->send_response($content);
				if ($self->{db}) { # if we connected to the DB, end our transaction
					$self->{db}->do_sql('rollback');
				}

				# do not continue if in the inner eval{} loop
				if ($stop_here == 1) {
					die 'Execution stopped: '.$content;
				} else { # if $stop_here == 3, then we are in a 'superfatal' from pepper.psgi
					return;
				}
				
			}

		}
	}

	# if they sent a valid content type, no need to change it
	if ($content_type && $content_type =~ /\//) {
		# nothing to do here

	} elsif ($ref_type eq "HASH" || $ref_type eq "ARRAY") { # make it into json
		$content_type = 'application/json';
		$content = $self->json_from_perl($content);

	} elsif ($content =~ /^\/\/ This is Javascript./) { # it is 99% likely to be Javascript
		$content_type = 'text/javascript';

	} elsif ($content =~ /^\/\* This is CSS./) { # it is 99% likely to be CSS
		$content_type = 'text/css';

	} elsif ($content =~ /<\S+>/) { # it is 99% likely to be HTML
		$content_type = 'text/html';

	} elsif (!$ref_type && length($content)) { # it is plain text
		$content_type = 'text/plain';

	} else { # anything else? something of a mistake, panic a little
		$content_type = 'text/plain';
		$content = 'ERROR: The resulting content was not deliverable.';

	}

	# if in Plack, pack the response for delivery
	if ($self->{response}) {
		$self->{response}->content_type($content_type);
		# is this an error?  Change from 200 to 500, if not done so already
		if ($content =~ /^(ERROR|Execution failed)/ && $self->{response}->status() eq '200') {
			$self->{response}->status(500);
		}
		if ($content_filename && $content_type !~ /^image/) {
			$self->{response}->header('Content-Disposition' => 'attachment; filename="'.$content_filename.'"');
		}
		$self->{response}->body($content);
		
	} else { # print to stdout
		print $content;
	}

	if ($stop_here == 1) { # if they want us to stop here, do so; we should be in an eval{} loop to catch this
		$die_text = "Execution stopped.";
		$die_text .= '; Error ID: '.$error_id if $error_id;
		$self->{db}->do_sql('rollback') if $self->{db}; # end our transaction
		die $die_text;
	}
	
}

# subroutine to process a template via template toolkit
# this is for server-side processing of templates
sub template_process {
	my ($self, $args) = @_;
	# $$args can contain: include_path, template_file, template_text, template_vars, send_out, save_file, stop_here
	# it *must* include either template_text or template_file

	# declare vars
	my ($output, $tt, $tt_error);

	# default include path
	if (!$$args{include_path}) {
		$$args{include_path} = $self->{pepper_directory}.'/template/';
	} elsif ($$args{include_path} !~ /\/$/) { # make sure of trailing /
		$$args{include_path} .= '/';
	}

	# $$args{tag_style} = 'star', 'template' or similiar
	# see https://metacpan.org/pod/Template#TAG_STYLE

	# default tag_style to regular, [% %]
	$$args{tag_style} ||= 'template';

	# crank up the template toolkit object, and set it up to save to the $output variable
	$output = '';
	$tt = Template->new({
		ENCODING => 'utf8',
		INCLUDE_PATH => $$args{include_path},
		OUTPUT => \$output,
		TAG_STYLE => $$args{tag_style},
	}) || $self->send_response("$Template::ERROR",1);

	# process the template
	if ($$args{template_file}) {
		$tt->process( $$args{template_file}, $$args{template_vars}, $output, {binmode => ':encoding(utf8)'} );

	} elsif ($$args{template_text}) {
		$tt->process( \$$args{template_text}, $$args{template_vars}, $output, {binmode => ':encoding(utf8)'} );

	} else { # one or the other
		$self->send_response("Error: you must provide either template_file or template_text",1);
	}

	# make sure to throw error if there is one
	$tt_error = $tt->error();
	$self->send_response("Template Error in $$args{template_file}: $tt_error",1) if $tt_error;

	# send it out to the client, save to the filesystem, or return to the caller
	if ($$args{send_out}) { # output to the client

		# the '2' tells mr_zebra to avoid logging an error
		$self->send_response($output,2);

	} elsif ($$args{save_file}) { # save to the filesystem
		$self->filer( $$args{save_file}, 'write', $output);
		return $$args{save_file}; # just kick back the file name

	} else { # just return
		return $output;
	}
}

# method to log messages under the 'log' directory
sub logger {
	# takes three args: the message itself (required), the log_type (optional, one word),
	# and an optional log location/directory
	my ($self, $log_message, $log_type, $log_directory) = @_;

	# return if no message sent; no point
	return if !$log_message;

	# default is 'errors' log type
	$log_type ||= 'errors';

	# no spaces or special chars in that $log_type
	$log_type =~ s/[^a-z0-9\_]//gi;

	my ($error_id, $todays_date, $current_time, $log_file, $now);

	# how about a nice error ID
	$error_id = $self->random_string(15);

	# what is today's date and current time
	$now = time(); # this is the unix epoch / also a quick-find id of the error
	$todays_date = $self->time_to_date($now,'to_date_db','utc');
	$current_time = $self->time_to_date($now,'to_datetime_iso','utc');
		$current_time =~ s/\s//g; # no spaces

	# target log file - did they provide a target log_directory?
	if ($log_directory && -d $log_directory) { # yes
		$log_file = $log_directory.'/'.$log_type.'-'.$todays_date.'.log';
	} else { # nope, take default
		$log_file = $self->{pepper_directory}.'/log/'.$log_type.'-'.$todays_date.'.log';
	}

	# sometimes time() adds a \n
	$log_message =~ s/\n//;

	# if they sent a hash or array, it's a developer doing testing.  use Dumper() to output it
	if (ref($log_message) eq 'HASH' || ref($log_message) eq 'ARRAY') {
		$log_message = Dumper($log_message);
	}

	# if we have the plack object (created via pack_luggage()), append to the $log_message
	if ($self->{request}) {
		$log_message .= ' | https://'.$self->{request}->env->{HTTP_HOST}.$self->{request}->request_uri();
	}

	# append to our log file via Path::Tiny
	path($log_file)->append_raw( 'ID: '.$error_id.' | '.$current_time.': '.$log_message."\n" );

	# return the code/epoch for an innocent-looking display and for fast lookup
	return $error_id;
}

### START GENERAL UTILITIES

# simple routine to get a DateTime object for a timestamp, e.g. 2016-09-04 16:30
sub get_datetime_object {
	my ($self, $time_string, $time_zone_name) = @_;

	# default timezone is New York
	$time_zone_name = $self->{time_zone_name};
		$time_zone_name ||= 'America/New_York';

	my ($dt, $year, $month, $day, $hour, $minute, $second);

	# be willing to just accept the date and presume midnight
	if ($time_string =~ /^\d{4}-\d{2}-\d{2}$/) {
		$time_string .= ' 00:00:00';
	}

	# i will generally just send minutes; we want to support seconds too, and default to 00 seconds
	if ($time_string =~ /\s\d{2}:\d{2}$/) {
		$time_string .= ':00';
	}

	# if that timestring is not right, just get one for 'now'
	if ($time_string !~ /^\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}$/) {

		$dt = DateTime->from_epoch(
			epoch => time(),
			time_zone	=> $time_zone_name,
		);

	#  otherwise, get a custom datetime object
	} else {

		# have to slice-and-dice it a bit to make sure DateTime is happy
		$time_string =~ s/-0/-/g;
		($year,$month,$day,$hour,$minute,$second) = split /-|\s|:/, $time_string;
		$hour =~ s/^0//;
		$minute =~ s/^0//;

		# try to set up the DateTime object, wrapping in eval in case they send an invalid time
		# (which happens if you go for 2am on a 'spring-forward' day
		eval {
			$dt = DateTime->new(
				year		=> $year,
				month		=> $month,
				day			=> $day,
				hour		=> $hour,
				minute		=> $minute,
				second		=> $second,
				time_zone	=> $time_zone_name,
			);
		};

		if ($@) { # if they called for an invalid time, just move ahead and hour and try again
			$hour++;
			$dt = DateTime->new(
				year		=> $year,
				month		=> $month,
				day			=> $day,
				hour		=> $hour,
				minute		=> $minute,
				second		=> $second,
				time_zone	=> $time_zone_name,
			);
		}

	}

	# send it out
	return $dt;
}

# method to read/write/append to a file via Path::Tiny
sub filer {
	# required arg is the full path to the file
	# optional second arg is the operation:  read, write, or append.  default to 'read'
	# optional third arg is the content for write or append operations
	my ($self, $file_location, $operation, $content) = @_;

	# return if no good file path
	return if !$file_location;

	# default operation is 'read'
	$operation = 'read' if !$operation || $operation !~ /read|write|append|basename/;

	# return if write or append and no content
	return if $operation !~ /read|basename/ && !$content;

	# do the operations
	if ($operation eq 'read') {

		$content = path($file_location)->slurp_raw;
		return $content;

	} elsif ($operation eq 'write') {

		path($file_location)->spew_raw( $content );

	} elsif ($operation eq 'append') {

		# make sure the new content ends with a \n
		$content .= "\n" if $content !~ /\n$/;

		path($file_location)->append_raw( $content );

	} elsif ($operation eq 'basename') {

		return path($file_location)->basename;
	}

}


# two json translating methods using the great JSON module
# First, make perl data structures into JSON objects
sub json_from_perl {
	my ($self, $data_ref) = @_;

	# for this, we shall go UTF8
	return $self->{json_coder}->encode( $data_ref );
}

# Second, make JSON objects into Perl structures
sub json_to_perl {
	my ($self, $json_text) = @_;

	# first, let's try via UTF-8 decoding
	my $json_text_ut8 = encode_utf8( $json_text );
	my $perl_hashref = {};
	eval {
		$perl_hashref = $self->{json_coder}->decode( $json_text_ut8 );
	};

	return $perl_hashref;
}

# utility to generate a random string
sub random_string {
	my ($self, $length, $numbers_only) = @_;

	# default that to 10
	$length ||= 10;

	my (@chars,$string);

	if ($numbers_only) { # what they want...
		@chars = ('0'..'9');
	} else { # both
		@chars = ('0'..'9', 'A'..'F');
	}

	while ($length--) {
		$string .= $chars[rand @chars]
	};

	return $string;
}


# method to read a JSON file into a hashref
sub read_json_file {
	my ($self, $json_file_path) = @_;
	
	# we shall give them an empty hashref if nothing else
	return {} if !$json_file_path || !(-e $json_file_path);
	
	my $json_content = $self->filer($json_file_path);

	return {} if !$json_content;
	
	return $self->json_to_perl($json_content);
	
}

# method to save JSON into a file
sub write_json_file {
	my ($self, $json_file_path, $data_structure) = @_;
	
	return if !$json_file_path || ref($data_structure) !~ /ARRAY|HASH/;
	
	# writing one liners like this does not make me feel beautiful	
	$self->filer($json_file_path, 'write', $self->json_from_perl($data_structure) );

}

# start the timeToDate method, where we convert between UNIX timestamps and human-friendly dates
sub time_to_date {
	# declare vars & grab args
	my ($self, $timestamp, $task, $time_zone_name) = @_;
	my ($day, $dt, $diff, $month, $templ, $year);

	# default timezone to UTC if no timezone sent or set
	# if they sent a 'utc', force it to be Etc/GMT -- this is for the logger
	$time_zone_name = 'Etc/GMT' if !$time_zone_name || $time_zone_name eq 'utc';

	# allow them to set a default time zone by setting $pepper->{utilities}{time_zone_name}
	# or $ENV{PERL_DATETIME_DEFAULT_TZ}
	$time_zone_name ||= $self->{time_zone_name} || $ENV{PERL_DATETIME_DEFAULT_TZ};

	# set the time zone if not set
	$self->{time_zone_name} ||= $time_zone_name;

	# fix up timestamp as necessary
	if (!$timestamp) { # empty timestamp --> default to current timestamp
		$timestamp = time();
	} elsif ($timestamp =~ /\,/) { # human date...make it YYYY-MM-DD
		($month,$day,$year) = split /\s/, $timestamp; # get its pieces
		# turn the month into a proper number
		if ($month =~ /Jan/) { $month = "01";
		} elsif ($month =~ /Feb/) { $month = "02";
		} elsif ($month =~ /Mar/) { $month = "03";
		} elsif ($month =~ /Apr/) { $month = "04";
		} elsif ($month =~ /May/) { $month = "05";
		} elsif ($month =~ /Jun/) { $month = "06";
		} elsif ($month =~ /Jul/) { $month = "07";
		} elsif ($month =~ /Aug/) { $month = "08";
		} elsif ($month =~ /Sep/) { $month = "09";
		} elsif ($month =~ /Oct/) { $month = "10";
		} elsif ($month =~ /Nov/) { $month = "11";
		} elsif ($month =~ /Dec/) { $month = "12"; }

		# remove the comma from the date and make sure it has two digits
		$day =~ s/\,//;
		$day = '0'.$day if $day < 10;

		$timestamp = $year.'-'.$month.'-'.$day;

	}
	# if they passed a YYYY-MM-DD date, also we will get a DateTime object

	# need that epoch if a date string was set / parsed
	if ($month || $timestamp =~ /-/) {
		$dt = $self->get_datetime_object($timestamp.' 00:00',$time_zone_name);
		$timestamp = $dt->epoch;
		$time_zone_name = 'Etc/GMT'; # don't offset dates, only timestamps
	}

	# default task is the epoch for the first second of the day
	$task ||= 'to_unix_start';

	# proceed based on $task
	if ($task eq "to_unix_start") { # date to unix timestamp -- start of the day
		return $timestamp; # already done above
	} elsif ($task eq "to_unix_end") { # date to unix timestamp -- end of the day
		return ($timestamp + 86399); # most done above
	} elsif ($task eq "to_date_db") { # unix timestamp to db-date (YYYY-MM-DD)
		$templ = '%Y-%m-%d';
	} elsif (!$task || $task eq "to_date_human") { # unix timestamp to human date (Mon DD, YYYY)
		($diff) = ($timestamp - time())/15552000; # drop the year if within the last six months
		if ($diff > -1 && $diff < 1) {
			$templ = '%B %e';
		} else {
			$templ = '%B %e, %Y';
		}
	} elsif ($task eq "to_date_human_full") { # force YYYY in above
		$templ = '%B %e, %Y';
	} elsif ($task eq "to_date_human_abbrev") { # shorter month name in above
		$templ = '%b %e, %Y';
	} elsif ($task eq "to_date_human_dayname") { # unix timestamp to human date (DayOfWeekName, Mon DD, YYYY)
		($diff) = ($timestamp - time())/15552000; # drop the year if within the last six months
		if ($diff > -1 && $diff < 1) {
			$templ = '%A, %b %e';
		} else {
			$templ = '%A, %b %e, %Y';
		}
	} elsif ($task eq "to_year") { # just want year
		$templ = '%Y';
	} elsif ($task eq "to_month" || $task eq "to_month_name") { # unix timestamp to month name (Month YYYY)
		$templ = '%B %Y';
	} elsif ($task eq "to_month_abbrev") { # unix timestamp to month abreviation (MonYY, i.e. Sep15)
		$templ = '%b%y';
	} elsif ($task eq "to_date_human_time") { # unix timestamp to human date with time (Mon DD, YYYY at HH:MM:SS XM)
		($diff) = ($timestamp - time())/31536000;
		if ($diff >= -1 && $diff <= 1) {
			$templ = '%b %e at %l:%M%P';
		} else {
			$templ = '%b %e, %Y at %l:%M%P';
		}
	} elsif ($task eq "to_just_human_time") { # unix timestamp to humantime (HH:MM:SS XM)
		$templ = '%l:%M%P';
	} elsif ($task eq "to_just_military_time") { # unix timestamp to military time
		$templ = '%R';
	} elsif ($task eq "to_datetime_iso") { # ISO-formatted timestamp, i.e. 2016-09-04T16:12:00+00:00
		$templ = '%Y-%m-%dT%X%z';
	} elsif ($task eq "to_day_of_week") { # epoch to day of the week, like 'Saturday'
		$templ = '%A';
	} elsif ($task eq "to_day_of_week_numeric") { # 0..6 day of the week
		$templ = '%w';
	}

	# if they sent a time zone, offset the timestamp epoch appropriately
	if ($time_zone_name ne 'Etc/GMT') {
		# have we cached this?
		if (!$self->{tz_offsets}{$time_zone_name}) {
			$dt = DateTime->from_epoch(
				epoch		=> $timestamp,
				time_zone	=> $time_zone_name,
			);
			$self->{tz_offsets}{$time_zone_name} = $dt->offset;
		}

		# apply the offset
		$timestamp += $self->{tz_offsets}{$time_zone_name};
	}

	# now run the conversion
	$timestamp = time2str($templ, $timestamp,'GMT');
	$timestamp =~ s/  / /g; # remove double spaces;
	$timestamp =~ s/GMT //;
	return $timestamp;
}

### START METHODS FOR pepper setup

# loads up $self->{config}; auto-called via new() above
sub read_system_configuration {
	my $self = shift;
	
	my ($the_file, $obfuscated_json, $config_json);
	
	# kick out if that file does not exist yet
	if (!(-e $self->{config_file})) {
		$self->send_response('ERROR: Can not find system configuration file.',1);
	}

	# try to read it in
	eval {
		$obfuscated_json = $self->filer( $self->{config_file} );
		$config_json = pack "h*", $obfuscated_json;
		$self->{config} = $self->json_to_perl($config_json);
	};
	
	# error out if there was any failure
	if ($@ || ref($self->{config}) ne 'HASH') {
		$self->send_response('ERROR: Could not read in system configuration file: '.$@,1);
	}

}

# save a system config file
sub write_system_configuration {
	my ($self,$new_config) = @_;
	
	# convert config to JSON
	my $config_json = $self->json_from_perl($new_config);
	# slight obfuscation
	my $obfuscated_json = unpack "h*", $config_json;

	# stash out the file
	path( $self->{config_file} )->spew_raw( $obfuscated_json );

	# set the permissions
	chmod 0600,  $self->{config_file} ;	
}

# method to update the endpoint mapping configs via 'pepper set-endpoint'
sub set_endpoint_mapping {
	my ($self, $endpoint_uri, $endpoint_handler) = @_;
	
	if (!$endpoint_uri || !$endpoint_handler) {
		$self->send_response('Error: Both arguments are required for set_endpoint_mapping()',1);
	}
	
	# did they choose to store in a database table?
	if ($self->{config}{url_mappings_table}) {
	
		# make sure that table exists
		my ($database_name, $table_name) = split /\./, $self->{config}{url_mappings_table};
		my ($table_exists) = $self->{db}->quick_select(qq{
			select count(*) from information_schema.tables 
			where table_schema=? and table_name=?
		},[ $database_name, $table_name ]);

		# if the table does not exist, try to make it
		if (!$table_exists) {
			
			# we won't create databases/schema in this library
			my ($database_exists) = $self->{db}->quick_select(qq{
				select count(*) from information_schema.schemata 
				where schema_name=? 
			},[ $database_name ]);
			
			if (!$database_exists) {
				$self->send_response("Error: Database schema $database_exists does not exist",1);
			}
			
			# safe to create the table
			$self->{db}->do_sql(qq{
				create table $self->{config}{url_mappings_table} (
					endpoint_uri varchar(200) primary key,
					handler_module varchar(200) not null
				)
			});
			
		}
	
		# finally, create the mapping
		$self->{db}->do_sql(qq{
			replace into $self->{config}{url_mappings_table}
			(endpoint_uri, handler_module) values (?, ?)
		}, [$endpoint_uri, $endpoint_handler] );
		
		# save this change
		$self->{db}->commit();
	
	# otherwise, save to a JSON file
	} else {
		
		my $url_mappings = $self->read_json_file( $self->{config}{url_mappings_file} );
		$$url_mappings{$endpoint_uri} = $endpoint_handler;
		$self->write_json_file( $self->{config}{url_mappings_file}, $url_mappings );
		
	}
	
}

# method to delete an endpoint mapping via 'pepper delete-endpoint'
sub delete_endpoint_mapping {
	my ($self, $endpoint_uri) = @_;
	
	if (!$endpoint_uri) {
		$self->send_response('Error: The endpoint uri must be specified for delete_endpoint_mapping()',1);
	}

	# did they choose to store in a database table?
	if ($self->{config}{url_mappings_table}) {

		$self->{db}->do_sql(qq{
			delete from $self->{config}{url_mappings_table} 
			where endpoint_uri=?
		}, [$endpoint_uri] );

		# save this change
		$self->{db}->commit();
	
	# or a JSON file?
	} else {

		my $url_mappings = $self->read_json_file( $self->{config}{url_mappings_file} );
		delete ( $$url_mappings{$endpoint_uri} );
		$self->write_json_file( $self->{config}{url_mappings_file}, $url_mappings );

	}

}

1;

__END__

=head1 NAME

Pepper::Utilities 

=head1 DESCRIPTION

This package provides useful functions for web services and scripts built using the 
Pepper quick-start kit.  These methods can be access via the main 'Pepper' object, 
and are all documented in that package.  Please see 'perldoc Pepper' or the main
documentation on MetaCPAN.