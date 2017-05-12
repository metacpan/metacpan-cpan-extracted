package Nagios::Plugin::OverHTTP;

use 5.008001;
use strict;
use warnings 'all';

###########################################################################
# METADATA
our $AUTHORITY = 'cpan:DOUGDUDE';
our $VERSION   = '0.16';

###########################################################################
# MOOSE
use Moose 0.74;
use MooseX::StrictConstructor 0.08;

###########################################################################
# MOOSE TYPES
use Nagios::Plugin::OverHTTP::Library 0.14 qw(
	Hostname
	HTTPVerb
	Path
	Status
	Timeout
	URL
);

###########################################################################
# MODULE IMPORTS
use Carp qw(croak);
use Const::Fast qw(const);
use HTTP::Request 5.827;
use HTTP::Status 5.817 qw(:constants);
use LWP::UserAgent;
use Nagios::Plugin::OverHTTP::Formatter::Nagios::Auto;
use Nagios::Plugin::OverHTTP::Middleware::PerformanceData;
use Nagios::Plugin::OverHTTP::Parser::Standard;
use Nagios::Plugin::OverHTTP::Response;
use Try::Tiny 0.04;
use URI;

###########################################################################
# ALL IMPORTS BEFORE THIS WILL BE ERASED
use namespace::clean 0.04 -except => [qw(meta)];

###########################################################################
# MOOSE ROLES
with 'MooseX::Getopt';

###########################################################################
# PUBLIC CONSTANTS
const our $STATUS_OK       => 0;
const our $STATUS_WARNING  => 1;
const our $STATUS_CRITICAL => 2;
const our $STATUS_UNKNOWN  => 3;

###########################################################################
# PRIVATE CONSTANTS
const my $DEFAULT_REQUEST_METHOD => q{GET};

###########################################################################
# ATTRIBUTES
has 'autocorrect_unknown_html' => (
	is            => 'rw',
	isa           => 'Bool',
	documentation => q{When a multiline HTML response without a status is }
	                .q{received, this will add something meaningful to the}
	                .q{ first line},

	default       => 1,
);
has 'critical' => (
	is            => 'rw',
	isa           => 'HashRef[Str]',
	documentation => q{Specifies performance levels that result in a }
	                .q{critical status},

	default       => sub { {} },
);
has 'default_status' => (
	is            => 'rw',
	isa           => Status,
	documentation => q{The default status if none specified in the response},

	coerce        => 1,
	default       => $Nagios::Plugin::OverHTTP::Library::STATUS_UNKNOWN,
	trigger       => sub { shift->_clear_parser },
);
has 'hostname' => (
	is            => 'rw',
	isa           => Hostname,
	documentation => q{The hostname on which the URL is located},

	builder       => '_build_hostname',
	clearer       => '_clear_hostname',
	lazy          => 1,
	predicate     => '_has_hostname',
	trigger       => \&_reset_trigger,
);
has 'message' => (
	is            => 'ro',
	isa           => 'Str',

	builder       => '_build_message',
	clearer       => '_clear_message',
	lazy          => 1,
	predicate     => 'has_message',
	traits        => ['NoGetopt'],
);
has 'parser' => (
	is            => 'rw',
	does          => 'Nagios::Plugin::OverHTTP::Parser',
	documentation => q{HTTP response parser},

	builder       => '_build_parser',
	clearer       => '_clear_parser',
	lazy          => 1,
	traits        => ['NoGetopt'],
);
has 'path' => (
	is            => 'rw',
	isa           => Path,
	documentation => q{The path of the plugin on the host},

	builder       => '_build_path',
	clearer       => '_clear_path',
	coerce        => 1,
	lazy          => 1,
	predicate     => '_has_path',
	trigger       => \&_reset_trigger,
);
has 'ssl' => (
	is            => 'rw',
	isa           => 'Bool',
	documentation => q{Whether to use SSL (defaults to no)},

	builder       => '_build_ssl',
	clearer       => '_clear_ssl',
	lazy          => 1,
	predicate     => '_has_ssl',
	trigger       => \&_reset_trigger,
);
has 'timeout' => (
	is            => 'rw',
	isa           => Timeout,
	documentation => q{The HTTP request timeout in seconds (defaults to nothing)},

	clearer       => 'clear_timeout',
	predicate     => 'has_timeout',
);
has 'status' => (
	is            => 'ro',
	isa           => Status,

	builder       => '_build_status',
	clearer       => '_clear_status',
	lazy          => 1,
	predicate     => 'has_status',
	traits        => ['NoGetopt'],
);
has 'url' => (
	is            => 'rw',
	isa           => URL,
	documentation => q{The URL to the remote nagios plugin},

	builder       => '_build_url',
	clearer       => '_clear_url',
	lazy          => 1,
	predicate     => '_has_url',
	trigger       => sub {
		my ($self) = @_;

		# Clear the state
		$self->_clear_state;

		# Populate out other properties from the URL
		$self->_populate_from_url;
	},
);
has 'useragent' => (
	is            => 'rw',
	isa           => 'LWP::UserAgent',

	default       => sub { LWP::UserAgent->new; },
	lazy          => 1,
	traits        => ['NoGetopt'],
);
has 'verb' => (
	is            => 'rw',
	isa           => HTTPVerb,
	documentation => q{Specifies the HTTP verb with which to make the request},

	default       => 'GET',
);
has 'warning' => (
	is            => 'rw',
	isa           => 'HashRef[Str]',
	documentation => q{Specifies performance levels that result in a }
	                .q{warning status},

	default       => sub { {} },
);

###########################################################################
# METHODS
sub check {
	my ($self, %args) = @_;

	# Get the argument for exceptions
	my $catch_exceptions = $args{catch_exceptions} || 0;

	# Save the current timeout for the useragent
	my $old_timeout = $self->useragent->timeout;

	# Set the useragent's timeout to our timeout if a timeout has been declared.
	if ($self->has_timeout) {
		$self->useragent->timeout($self->timeout);
	}

	my $response;

	# Get the response of the plugin
	try {
		# Make request
		$response = $self->request(method => $self->verb, url => $self->url);
	}
	catch {
		if ($catch_exceptions) {
			# Return a response with the error message
			$response = Nagios::Plugin::OverHTTP::Response->new(
				# Message is string of the error
				message => qq{$_},

				# Status is critical
				status => $Nagios::Plugin::OverHTTP::Library::STATUS_CRITICAL,
			);
		}
		else {
			# Rethrow the error
			croak $_;
		}
	}
	finally {
		# Restore the previous timeout value to the useragent
		$self->useragent->timeout($old_timeout);
	};

	return $response;
}
sub create_request {
	my ($self, %args) = @_;

	# Splice the arguments out
	my ($method, $url) = @args{qw(method url)};

	if (!defined $method) {
		# Default method since method is not provided
		$method = $DEFAULT_REQUEST_METHOD;
	}

	# Just the method and URL are supported
	return HTTP::Request->new($method, $url);
}
sub request {
	my ($self, @args) = @_;

	# The request is either the only argument or created from the HASH
	my $request = @args == 1 ? $args[0]
	                         : $self->create_request(@args)
	                         ;

	# Get the response of the plugin
	my $response = $self->useragent->request($request);

	if (!$response->is_success && $response->code == HTTP_INTERNAL_SERVER_ERROR) {
		# This response likely came directly from LWP::UserAgent
		if ($response->message eq 'read timeout') {
			# Make the message explicitly about the timeout
			croak sprintf 'Socket timeout after %d seconds',
				$self->useragent->timeout;
		}
		elsif ($response->message =~ m{\(connect: \s timeout\)}msx) {
			# Failure to connect to the host server
			croak 'Connection refused';
		}
	}

	# Return the parsed response
	return $self->parser->parse($response);
}
sub run {
	my ($self) = @_;

	# Perform the check
	my $response = $self->check(catch_exceptions => 1);

	# Rewrite performance data using default settings
	$response = Nagios::Plugin::OverHTTP::Middleware::PerformanceData
		->new(
			critical_override => $self->critical,
			warning_override  => $self->warning,
		)->rewrite($response);

	# Get the parsed message and status from formatter
	my $formatter = Nagios::Plugin::OverHTTP::Formatter::Nagios::Auto->new(
		response => $response,
	);

	# Print errors first
	print {*STDERR} $formatter->stderr;

	# Print standard output
	print {*STDOUT} $formatter->stdout;

	# Return exit code
	return $formatter->exit_code;
}

###########################################################################
# PRIVATE METHODS
sub _build_after_check {
	my ($self, $attribute) = @_;

	# Perform the check
	my $response = $self->check(catch_exceptions => 1);

	# Rewrite performance data using default settings
	$response = Nagios::Plugin::OverHTTP::Middleware::PerformanceData
		->new(
			critical_override => $self->critical,
			warning_override  => $self->warning,
		)->rewrite($response);

	# Get the parsed message and status from formatter
	my $formatter = Nagios::Plugin::OverHTTP::Formatter::Nagios::Auto->new(
		response => $response,
	);

	# Set the plugin state
	$self->_set_state($formatter->exit_code, $formatter->stdout);

	# Return the specified attribute for build
	return $self->{$attribute};
}
sub _build_from_url {
	my ($self, $attribute) = @_;

	# Populate all fields from the URL
	$self->_populate_from_url;

	# Return the specified attribute for build
	return $self->{$attribute};
}
sub _build_hostname {
	return shift->_build_from_url('hostname');
}
sub _build_message {
	return shift->_build_after_check('message');
}
sub _build_path {
	return shift->_build_from_url('path');
}
sub _build_parser {
	my ($self) = @_;

	# Standard parser with the default status
	return Nagios::Plugin::OverHTTP::Parser::Standard
		->new(default_status => $self->default_status);
}
sub _build_ssl {
	return shift->_build_from_url('ssl');
}
sub _build_status {
	return shift->_build_after_check('status');
}
sub _build_url {
	my ($self) = @_;

	if (!$self->_has_hostname) {
		croak 'Unable to build the URL due to no hostname being provided';
	}
	elsif (!$self->_has_path) {
		croak 'Unable to build the URL due to no path being provided.';
	}

	# Form the URI object
	my $url = URI->new(sprintf 'http://%s%s', $self->{hostname}, $self->{path});

	if ($self->_has_ssl && $self->ssl) {
		# Set the SSL scheme
		$url->scheme('https');
	}

	# Set the URL
	return $url->as_string;
}
sub _clear_state {
	my ($self) = @_;

	$self->_clear_message;
	$self->_clear_status;

	# Nothing useful to return, so chain
	return $self;
}
sub _populate_from_url {
	my ($self) = @_;

	if (!$self->_has_url) {
		croak 'Unable to build requested attributes, as no URL as been defined';
	}

	# Create a URI object from the url
	my $uri = URI->new($self->{url});

	# Set the hostname
	$self->{hostname} = $uri->host;

	# Set the path
	$self->{path} = to_Path($uri->path);

	# Set SSL state
	$self->{ssl} = $uri->scheme eq 'https';

	# Nothing useful to return, so chain
	return $self;
}
sub _reset_trigger {
	my ($self) = @_;

	# Clear the state
	$self->_clear_state;

	# Clear the generated URL
	$self->_clear_url;

	return;
}
sub _set_state {
	my ($self, $status, $message) = @_;

	my %status_prefix_map = (
		$Nagios::Plugin::OverHTTP::Library::STATUS_OK       => 'OK',
		$Nagios::Plugin::OverHTTP::Library::STATUS_WARNING  => 'WARNING',
		$Nagios::Plugin::OverHTTP::Library::STATUS_CRITICAL => 'CRITICAL',
		$Nagios::Plugin::OverHTTP::Library::STATUS_UNKNOWN  => 'UNKNOWN',
	);

	if ($message !~ m{\A $status_prefix_map{$status}}msx) {
		$message = sprintf '%s - %s', $status_prefix_map{$status}, $message;
	}

	$self->{message} = $message;
	$self->{status}  = $status;

	# Nothing useful to return, so chain
	return $self;
}

###########################################################################
# MAKE MOOSE OBJECT IMMUTABLE
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Nagios::Plugin::OverHTTP - Nagios plugin to check over HTTP.

=head1 VERSION

This documentation refers to L<Nagios::Plugin::OverHTTP> version 0.16

=head1 SYNOPSIS

  my $plugin = Nagios::Plugin::OverHTTP->new(
      url => 'https://myserver.net/nagios/check_some_service.cgi',
  );

  my $plugin = Nagios::Plugin::OverHTTP->new(
      hostname => 'myserver.net',
      path     => '/nagios/check_some_service.cgi',
      ssl      => 1,
  );

  my $status  = $plugin->status;
  my $message = $plugin->message;

=head1 DESCRIPTION

This Nagios plugin provides a way to check services remotely over the HTTP
protocol.

=head1 CONSTRUCTOR

This is fully object-oriented, and as such before any method can be used, the
constructor needs to be called to create an object to work with.

=head2 new

This will construct a new plugin object.

=over

=item B<< new(%attributes) >>

C<< %attributes >> is a HASH where the keys are attributes (specified in the
L</ATTRIBUTES> section).

=item B<< new($attributes) >>

C<< $attributes >> is a HASHREF where the keys are attributes (specified in the
L</ATTRIBUTES> section).

=back

=head2 new_with_options

This is identical to L</new>, except with the additional feature of reading the
C<@ARGV> in the invoked scope. C<@ARGV> will be parsed for command-line
arguments. The command-line can contain any variable that L</new> can take.
Arguments should be in the following format on the command line:

  --url=http://example.net/check_something
  --url http://example.net/check_something
  # Note that quotes may be used, based on your shell environment

  # For Booleans, like SSL, you would use:
  --ssl    # Enable SSL
  --no-ssl # Disable SSL

  # For HashRefs, like warning and critical, you would use:
  --warning name=value --warning name2=value2

=head1 ATTRIBUTES

  # Set an attribute
  $object->attribute_name($new_value);

  # Get an attribute
  my $value = $object->attribute_name;

=head2 autocorrect_unknown_html

B<Added in version 0.10>; be sure to require this version for this feature.

This is a Boolean of wether or not to attempt to add a meaningful first line to
the message when the HTTP response did not include the Nagios plugin status
and the message looks like HTML and has multiple lines. The title of the web
page will be added to the first line, or the first H1 element will. The default
for this is on.

=head2 critical

B<Added in version 0.14>; be sure to require this version for this feature.

This is a hash reference specifying different performance names (as the hash
keys) and what threshold they need to be to result in a critical status. The
format for the threshold is specified in L</PERFORMANCE THRESHOLD>.

=head2 default_status

B<Added in version 0.09>; be sure to require this version for this feature.

This is the default status that will be used if the remote plugin does not
return a status. The default is "UNKNOWN." The status may be the status number,
or a string with the name of the status, like:

  $plugin->default_status('CRITICAL');

=head2 hostname

This is the hostname of the remote server. This will automatically be populated
if L</url> is set.

=head2 parser

B<Added in version 0.14>; be sure to require this version for this feature.

This is a response parser object that does L<Nagios::Plugin::OverHTTP::Parser>.
By default, it is the L<Nagios::Plugin::OverHTTP::Parser::Standard> parser.

=head2 path

This is the path to the remove Nagios plugin on the remote server. This will
automatically be populated if L</url> is set.

=head2 ssl

This is a Boolean of whether or not to use SSL over HTTP (HTTPS). This defaults
to false and will automatically be updated to true if a HTTPS URL is set to
L</url>.

=head2 timeout

This is a positive integer for the timeout of the HTTP request. If set, this
will override any timeout defined in the useragent for the duration of the
request. The plugin will not permanently alter the timeout in the useragent.
This defaults to not being set, and so the useragent's timeout is used.

=head2 url

This is the URL of the remote Nagios plugin to check. If not supplied, this will
be constructed automatically from the L</hostname> and L</path> attributes.

=head2 useragent

This is the useragent to use when making requests. This defaults to
L<LWP::Useragent> with no options. Currently this must be an L<LWP::Useragent>
object.

=head2 verb

B<Added in version 0.12>; be sure to require this version for this feature.

This is the HTTP verb that will be used to make the HTTP request. The default
value is C<GET>.

=head2 warning

B<Added in version 0.14>; be sure to require this version for this feature.

This is a hash reference specifying different performance names (as the hash
keys) and what threshold they need to be to result in a warning status. The
format for the threshold is specified in L</PERFORMANCE THRESHOLD>.

=head1 METHODS

=head2 check

This will run the remote check. This is usually not needed, as attempting to
access the message or status will result in the check being performed.

=head2 create_request

B<Added in version 0.14>; be sure to require this version for this feature.

This will create a L<HTTP::Request> object from the arguments including any
additional headers added by the plugin. This method takes a HASH as the
argument with the following keys:

=over 4

=item method

This is the HTTP request method. By default this will be C<GET>.

=item url

B<Required>. This is the URL to request.

=back

=head2 request

B<Added in version 0.14>; be sure to require this version for this feature.

This will return a L<Nagios::Plugin::OverHTTP::Response> object representing
the plugin response from the server. This method takes either one argument
which is a L<HTTP::Request> object that will use L</useragent> to make the
request, or a HASH with the same arguments as L</create_request>. The response
is parsed with the parser in L</parser>.

=head2 run

This will run the plugin in a standard way. The message will be printed to
standard output and the status code will be returned. Good for doing the
following:

  my $plugin = Plugin::Nagios::OverHTTP->new_with_options;

  exit $plugin->run;

=head1 PERFORMANCE THRESHOLD

Anywhere a performance threshold is accepted, the threshold value can be in any
of the following formats (same as listed in
L<http://nagiosplug.sourceforge.net/developer-guidelines.html#THRESHOLDFORMAT>):

=over 4

=item C<< <number> >>

This will cause an alert if the level is less than zero or greater than
C<< <number> >>.

=item C<< <number>: >>

This will cause an alert if the level is less than C<< <number> >>.

=item C<< ~:<number> >>

This will cause an alert if the level is greater than C<< <number> >>.

=item C<< <number>:<number2> >>

This will cause an alert if the level is less than C<< <number> >> or greater
than C<< <number2> >>.

=item C<< @<number>:<number2> >>

This will cause an alert if the level is greater than or equal to
C<< <number> >> and less than or equal to C<< <number2> >>. This is basically
the exact opposite of the previous format.

=back

=head1 PROTOCOL

=head2 HTTP STATUS

The protocol that this plugin uses to communicate with the Nagios plugins is
unique to my knowledge. If anyone knows another way that plugins are
communicating over HTTP then let me know.

A request that returns a C<5xx> status will automatically return as CRITICAL
and the plugin will display the error code and the status message (this will
typically result in C<500 Internal Server Error>).

A request that returns a C<2xx> status will be parsed using the methods listed
in L</HTTP BODY> and L</HTTP HEADER>.

If the response results is a redirect, the L</useragent> will automatically
redirect the response and all processing will ultimately be done on the final
response. Any other status code will cause the plugin to return as UNKNOWN and
the plugin will display the error code and the status message.

=head2 HTTP BODY

The body of the HTTP response will be the output of the plugin unless the
header L</X-Nagios-Information> is present. To determine what the status code
will be, the following methods are used:

=over 4

=item 1.

If a the header C<X-Nagios-Status> is present, the value from that is used as
the output. See L</X-Nagios-Status>.

=item 2.

If the header was not present, then the status will be extracted from the body
of the response. The very first set of all capital letters is taken from the
body and used to determine the result. The different possibilities for this is
listed in L</NAGIOS STATUSES>.

=back

=head2 HTTP HEADER

The following HTTP headers have special meanings:

=head3 C<< X-Nagios-Information >>

B<Added in version 0.12>; be sure to require this version for this feature.

If this header is present, then the content of this header will be used as the
message for the plugin. Note: B<the body will not be parsed>. This is meant as
an indication that the Nagios output is solely contained in the headers. This
MUST contain the message ONLY. If this header appears multiple times, each
instance is appended together with line breaks in the same order for multiline
plugin output support.

  X-Nagios-Information: Connection to database succeeded
  X-Nagios-Information: 'www'@'localhost'

=head3 C<< X-Nagios-Performance >>

B<Added in version 0.14>; be sure to require this version for this feature.

This header specifies various performance data from the plugin. This will add
performance to the list of any data collected from the response body as
specified in L</HTTP BODY>. Many performance data may be contained in a single
header seperated by spaces any many headers may be specified.

  X-Nagios-Performance: 'connect time'=0.0012s

=head3 C<< X-Nagios-Status >>

This header specifies the status. When this header is specified, then this is
will override any other location where the status can come from. The content of
this header MUST be either the decimal return value of the plugin or the status
name in all capital letters. The different possibilities for this is listed in
L</NAGIOS STATUSES>. If the header appears more than once, the first occurance
is used.

  X-Nagios-Status: OK

=head2 NAGIOS STATUSES

=over 4

=item 0 OK

C<< $Nagios::Plugin::OverHTTP::STATUS_OK >>

=item 1 WARNING

C<< $Nagios::Plugin::OverHTTP::STATUS_WARNING >>

=item 2 CRITICAL

C<< $Nagios::Plugin::OverHTTP::STATUS_CRITICAL >>

=item 3 UNKNOWN

C<< $Nagios::Plugin::OverHTTP::STATUS_UNKNOWN >>

=back

=head2 EXAMPLE

The following is an example of a simple bootstrapping of a plugin on a remote
server.

  #!/usr/bin/env perl

  use strict;
  use warnings;

  my $output = qx{/usr/local/libexec/nagios/check_users2 -w 100 -c 500};

  my $status = $? > 0 ? $? >> 8 : 3;

  printf "X-Nagios-Status: %d\n", $status;
  print  "Content-Type: text/plain\n\n";
  print  $output if $output;

  exit 0;

=head1 DEPENDENCIES

=over 4

=item * L<Carp>

=item * L<Const::Fast>

=item * L<HTTP::Request> 5.827

=item * L<HTTP::Status> 5.817

=item * L<LWP::UserAgent>

=item * L<Moose> 0.74

=item * L<MooseX::Getopt> 0.19

=item * L<MooseX::StrictConstructor> 0.08

=item * L<Try::Tiny>

=item * L<URI>

=item * L<namespace::clean> 0.04

=back

=head1 AUTHOR

Douglas Christopher Wilson, C<< <doug at somethingdoug.com> >>

=head1 ACKNOWLEDGEMENTS

=over

=item * Alex Wollangk contributed the idea and code for the
L</X-Nagios-Information> header.

=item * Peter van Eijk pushed me to get performance data handling
implemented.

=back

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-nagios-plugin-overhttp at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Nagios-Plugin-OverHTTP>. I
will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc Nagios::Plugin::OverHTTP

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Nagios-Plugin-OverHTTP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Nagios-Plugin-OverHTTP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Nagios-Plugin-OverHTTP>

=item * Search CPAN

L<http://search.cpan.org/dist/Nagios-Plugin-OverHTTP/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2009-2012 Douglas Christopher Wilson, all rights reserved.

This program is free software; you can redistribute it and/or
modify it under the terms of either:

=over

=item * the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option) any
later version, or

=item * the Artistic License version 2.0.

=back
