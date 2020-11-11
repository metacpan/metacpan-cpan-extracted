package Pepper::PlackHandler;

$Pepper::PlackHandler::VERSION = '1.3';

# for being a good person
use strict;
use warnings;

sub new {
	my ($class,$args) = @_;
	# %$args must have:
	#	'request' => $plack_request_object, 
	#	'response' => $plack_response_object, 
	#	'utils' => Pepper::Utilities object,

	# start the object 
	my $self = bless $args, $class;
	
	# gather up the PSGI environment
	$self->pack_psgi_variables();
	
	return $self;
	
}

# routine to (re-)pack up the PSGI environment
sub pack_psgi_variables {
	my $self = shift;

	# eject from this if we do not have the plack request and response objects
	return if !$self->{request} || !$self->{response};

	my (@vars, $value, @values, $v, $request_body_type, $request_body_content, $json_params, $plack_headers, @plack_uploads, $plack_upload, $uploaded_filename);

	# stash the hostname, URI, and complete URL
	$self->{hostname} = lc($self->{request}->env->{HTTP_HOST});
	$self->{uri} = $self->{request}->path_info();

	# you might want to allow an Authorization Header
	$plack_headers = $self->{request}->headers;
	$self->{auth_token} = $plack_headers->header('Authorization');
	
	# or you might test with cookies
	$self->{cookies} = $self->{request}->cookies;

	# notice how, in a non-PSGI world, you could just pass these as arguments

	# now on to user parameters

	# accept JSON data structures
	$request_body_type = $self->{request}->content_type;
	$request_body_content = $self->{request}->content;
	if ($request_body_content && $request_body_type eq 'application/json') {
		$json_params = $self->{utils}->json_to_perl($request_body_content);
		if (ref($json_params) eq 'HASH') {
			$self->{params} = $json_params;
		}
	}

	# the rest of this is to accept any POST / GET vars

	# create a hash of the PSGI params they've sent
	@vars = $self->{request}->parameters->keys;
	foreach $v (@vars) {
		# ony do it once! --> those multi values will get you
		next if $self->{params}{$v};

		# plack uses the hash::multivalue module, so multiple values can be sent via one param
		@values = $self->{request}->parameters->get_all($v);
		if (scalar(@values) > 1 && $v ne 'client_connection_id') { # must be a multi-select or similiar: two ways to access
			# note that we left off 'client_connection_id' as we only want one of those, in case they got too excited in JS-land
			foreach $value (@values) { # via array, and I am paranoid to just reference, as we are resuing @values
				push(@{$self->{params}{multi}{$v}}, $value);
			}
			$self->{params}{$v} = join(',', @values);  # or comma-delimited list
			$self->{params}{$v} =~ s/^,//; # no leading commas
		} elsif (length($values[0])) { # single value, make a simple key->value hash
			$self->{params}{$v} = $values[0];
		}
	}
	
	# did they upload any files? get the Plack::Request::Upload objects
	@plack_uploads = $self->{request}->uploads->get_all();
	foreach $plack_upload (@plack_uploads) {
		$uploaded_filename = $plack_upload->filename;
		$self->{uploaded_files}{$uploaded_filename} = $plack_upload->path;
	}	
	
	# maybe they sent the auth_token as a PSGI param?
	$self->{auth_token} ||= $self->{params}{auth_token};
	
}

# utility to set a cookie
sub set_cookie {
	my ($self,$cookie_details) = @_;
	
	# need at least a name and value
	return if !$$cookie_details{name} || !$$cookie_details{value};

	# days to live is important; default to 10 days
	$$cookie_details{days_to_live} ||= 10;

	# cookie domain won't work with port numbers at the end
	my $cookie_host = $self->{request}->env->{HTTP_HOST};
	$cookie_host =~ s/\:\d+$//;

	$self->{response}->cookies->{ $$cookie_details{name} } = {
		value => $$cookie_details{value},
		domain  => $cookie_host,
		path => '/',
		expires => time() + ($$cookie_details{days_to_live} * 86400)
	};	
}

1;

=head1 NAME

Pepper::PlackHandler 

=head1 DESCRIPTION

This package receives and packs the PSGI (~ CGI) environment for the Pepper quick-start
kit.  The main Pepper object will create this object and execute pack_psgi_variables() 
automatically, placing the PSGI/Plack parameters appropriately.   

Please execute 'pepper help' in your shell for more details on what is available.