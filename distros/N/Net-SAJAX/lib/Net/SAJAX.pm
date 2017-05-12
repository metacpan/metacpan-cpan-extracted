package Net::SAJAX;

use 5.008003;
use strict;
use warnings 'all';

###############################################################################
# METADATA
our $AUTHORITY = 'cpan:DOUGDUDE';
our $VERSION   = '0.107';

###############################################################################
# MOOSE
use Moose 0.77;
use MooseX::StrictConstructor 0.08;

###############################################################################
# MOOSE TYPES
use MooseX::Types::URI 0.02 qw(Uri);

###############################################################################
# MODULE IMPORTS
use Carp qw(croak);
use English qw(-no_match_vars);
use HTTP::Request::Common 5.814 (); # No imports
use JE 0.033;
use List::MoreUtils qw(any);
use LWP::UserAgent 5.819;
use Net::SAJAX::Exception 0.103;
use URI 1.22;
use URI::QueryParam;

###############################################################################
# ALL IMPORTS BEFORE THIS WILL BE ERASED
use namespace::clean 0.04 -except => [qw(meta)];

###############################################################################
# ATTRIBUTES
has autoclean_garbage => (
	is            => 'rw',
	isa           => 'Bool',
	default       => 0,
	documentation => q{Whether or not to try automatic cleaning of garbage in the response},
);
has javascript_engine => (
	is            => 'ro',
	isa           => 'JE',
	default       => sub { JE->new(max_ops => 1000) },
	documentation => q{JE object used for executing returned JavaScript},
);
has send_rand_key => (
	is            => 'rw',
	isa           => 'Bool',
	default       => 0,
	documentation => q{Whether or not to send a random key with the request},
);
has target_id => (
	is            => 'rw',
	isa           => 'Str',
	clearer       => 'clear_target_id',
	predicate     => 'has_target_id',
	documentation => q{The target ID to send with the request},
);
has url => (
	is            => 'rw',
	isa           => Uri,
	coerce        => 1,
	required      => 1,
	documentation => q{The URL to send the request to},
);
has user_agent => (
	is            => 'rw',
	isa           => 'LWP::UserAgent',
	default       => sub { LWP::UserAgent->new },
	documentation => q{The user agent that will be used to make the requests},
);

###############################################################################
# METHODS
sub call {
	my ($self, %args) = @_;

	# Build a request object
	my $request = $self->_build_request_for_call(%args);

	# Get a response
	my $response = $self->user_agent->request($request);

	if (!$response->is_success) {
		# The response was not successful
		Net::SAJAX::Exception->throw(
			class    => 'Response',
			message  => 'An error occurred in the response',
			response => $response,
		);
	}

	# Get the status and data from the response
	my ($status, $data) = $self->_parse_data_from_response($response);

	if ($status eq q{-}) {
		# This is an error
		Net::SAJAX::Exception->throw(
			class   => 'RemoteError',
			message => $data,
		);
	}

	# Evaluate the data
	my $je_object = $self->javascript_engine->eval($data);

	if ($EVAL_ERROR) {
		# JavaScript error when running code
		Net::SAJAX::Exception->throw(
			class             => 'JavaScriptEvaluation',
			javascript_error  => $EVAL_ERROR,
			javascript_string => $data,
			message           => 'JavaScript error occurred while running code',
		);
	}

	# Get the perl data structure
	my $perl_ref = eval { $self->_unwrap_je_object($je_object) };

	if ($EVAL_ERROR) {
		# An error occurred while expanding the JavaScript structure.
		if (blessed $EVAL_ERROR eq 'Net::SAJAX::Exception::JavaScriptConversion') {
			# Rethrow the error but with the over all JE object
			Net::SAJAX::Exception->throw(
				class             => 'JavaScriptConversion',
				javascript_object => $data,
				message           => 'Failed converting JavaScript object to Perl',
			);
		}
		else {
			croak $EVAL_ERROR;
		}
	}

	return $perl_ref;
}

###############################################################################
# PRIVATE METHODS
sub _build_request_for_call {
	my ($self, %args) = @_;

	# Splice out the variables
	my ($function, $arguments, $method)
		= @args{qw(function arguments method)};

	# Set the default value for method. Perl 5.8 doesn't know //=
	$method ||= 'GET';

	if (!defined $function) {
		# No function was specified
		Net::SAJAX::Exception->throw(
			class          => 'MethodArguments',
			argument       => 'function',
			argument_value => $function,
			message        => 'No function was specified to call',
			method         => 'build_request_for_call',
		);
	}

	# Change the method to uppercase
	$method = uc $method;

	if ($method ne 'GET' && $method ne 'POST') {
		# SAJAX only supports GET and POST
		Net::SAJAX::Exception->throw(
			class          => 'MethodArguments',
			argument       => 'method',
			argument_value => $method,
			message        => 'SAJAX only supports the GET and POST methods',
			method         => 'build_request_for_call',
		);
	}

	if (defined $arguments) {
		if (ref $arguments ne 'ARRAY') {
			# Arguments must refer to an ARRAYREF
			Net::SAJAX::Exception->throw(
				class          => 'MethodArguments',
				argument       => 'arguments',
				argument_value => $arguments,
				message        => 'Must pass arguments as an ARRAYREF',
				method         => 'build_request_for_call',
			);
		}

		if(any {ref $_ ne q{}} @{$arguments}) {
			# No argument can be a reference
			Net::SAJAX::Exception->throw(
				class          => 'MethodArguments',
				argument       => 'arguments',
				argument_value => $arguments,
				message        => 'No arguments can be a reference',
				method         => 'build_request_for_call',
			);
		}
	}

	# Clone the URL
	my $call_url = $self->url->clone;

	# Build the SAJAX arguments
	my %sajax_arguments = (rs => $function);

	if ($self->has_target_id) {
		# Add the target ID
		$sajax_arguments{rst} = $self->target_id;
	}

	if ($self->send_rand_key) {
		# Add in a random key to the request
		$sajax_arguments{rsrnd} = scalar time;
	}

	if (defined $arguments) {
		# Add the arguments to the request
		$sajax_arguments{'rsargs[]'} = $arguments;
	}

	# Hold the request
	my $request;

	if ($method eq 'GET') {
		# Add the SAJAX arguments to the URL for a GET request
		$call_url->query_form_hash(%{$call_url->query_form_hash}, %sajax_arguments, );

		# Make the GET request
		$request = HTTP::Request::Common::GET($call_url);
	}
	else {
		# Make the POST request
		$request = HTTP::Request::Common::POST($call_url, \%sajax_arguments);
	}

	# Return the request
	return $request;
}
sub _parse_data_from_response {
	my ($self, $response) = @_;

	# Copy the content for manipulation
	my $content = $response->content;

	if ($self->autoclean_garbage) {
		# Clean out garbage found at the beginning
		if ($content =~ m{^ \s* ([+-] : .*) \z}msx) {
			$content = $1;
		}

		# For the PHP SAJAX, attempt to parse out the exact response
		if ($content =~ m{([+-] : var \s res \s? = \s? .*? ; \s? res;)}msx) {
			$content = $1;
		}
	}

	# Parse out the status and data from the content
	my ($status, $data) = $content
		=~ m{\A \s* (.) . (.*?) \s* \z}msx;

	if (!defined $status) {
		# The response was bad
		Net::SAJAX::Exception->throw(
			class    => 'Response',
			message  => 'Received a bad response',
			response => $response,
		);
	}

	# Return the status and data as an array
	return ($status, $data);
}
sub _unwrap_je_object {
	my ($self, $je_object) = @_;

	# Specify the HASH that maps object types with a subroutine that will
	# convert the object into a Perl scalar.
	my %object_value_map = (
		'JE::Boolean'   => sub { return shift->value },
		'JE::LValue'    => sub { return $self->_unwrap_je_object(shift->get) },
		'JE::Null'      => sub { return shift->value },
		'JE::Number'    => sub { return shift->value },
		'JE::String'    => sub { return shift->value },
		'JE::Undefined' => sub { return shift->value },
		'JE::Object'    => sub {
			my $hash_ref = shift->value;

			# Iterate through each HASH element and unwrap the value
			foreach my $key (keys %{$hash_ref}) {
				$hash_ref->{$key} = $self->_unwrap_je_object($hash_ref->{$key});
			}

			return $hash_ref;
		},
		'JE::Object::Array'  => sub {
			return [ map { $self->_unwrap_je_object($_) } @{shift->value} ];
		},
		'JE::Object::Boolean' => sub { return shift->value },
		'JE::Object::Date'    => sub { return "$_[0]" },
		'JE::Object::Number'  => sub { return shift->value },
		'JE::Object::RegExp'  => sub { return shift->value },
		'JE::Object::String'  => sub { return shift->value },
	);

	# Get the code reference for converting the object
	my $convert_coderef = $object_value_map{ref $je_object};

	if (!defined $convert_coderef) {
		Net::SAJAX::Exception->throw(
			class             => 'JavaScriptConversion',
			javascript_object => $je_object,
			message           => 'Failed converting JavaScript object to Perl',
		);
	}

	return $convert_coderef->($je_object);
}

###############################################################################
# MAKE MOOSE OBJECT IMMUTABLE
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Net::SAJAX - Interact with remote applications that use SAJAX.

=head1 VERSION

This documentation refers to version 0.107

=head1 SYNOPSIS

  # Construct a SAJAX interaction object
  my $sajax = Net::SAJAX->new(
    url => URI->new('https:/www.example.net/my_sajax_app.php'),
  );

  # Make a SAJAX call
  my $product_name = $sajax->call(
    function  => 'GetProductName',
    arguments => [67632],
  );

  print "The product $product_name is out of stock\n";

  # Make a SAJAX call using POST (usually for big or sensitive data)
  my $result = $sajax->call(
    function  => 'SetPassword',
    method    => 'POST',
    arguments => ['My4w3s0m3p4sSwOrD'],
  );

  if ($result->{result} == 1) {
    print "Your password was successfully changed\n";
  }
  else {
    printf "An error occurred when setting your password: %s\n",
      $result->{error_message};
  }

=head1 DESCRIPTION

Provides a way to interact with applications that utilize the SAJAX library
found at L<http://www.modernmethod.com/sajax/>.

=head1 CONSTRUCTOR

This is fully object-oriented, and as such before any method can be used, the
constructor needs to be called to create an object to work with.

=head2 new

This will construct a new object.

=over

=item B<new(%attributes)>

C<%attributes> is a HASH where the keys are attributes (specified in the
L</ATTRIBUTES> section).

=item B<new($attributes)>

C<$attributes> is a HASHREF where the keys are attributes (specified in the
L</ATTRIBUTES> section).

=back

=head1 ATTRIBUTES

=head2 autoclean_garbage

B<Added in version 0.102>; be sure to require this version for this feature.

This is a Boolean of whether or not to try and automatically clean any garbage
from the SAJAX response. Sometime there are just bad web programmers out there
and there may be HTML or other data above the SAJAX response (most common in
PHP applications). If the stripping fails, then it will work just like normal.
The default value is 0, which will mimic the expected SAJAX behavior.

=head2 has_target_id

This is a Boolean of whether or not the object has a L</target_id> set.

=head2 javascript_engine

This is a L<JE|JE> object that is used to evaluate the JavaScript data received.
Since this is a custom engine in Perl, the JavaScript executed should not have
any security affects. This defaults to C<< JE->new(max_ops => 1000) >>.

=head2 send_rand_key

This is a Boolean of if to send a random key with the request. This is part of
the SAJAX library and is provided for use. The default for the SAJAX library
is to send the random key, but that is an unnecessary method to get around
caching issues, and so is it off by default.

  # Enable sending of a random key
  $sajax->send_rand_key(1);

  # Toggle the setting
  $sajax->send_rand_key(!$sajax->send_rand_key());

=head2 target_id

This is a string that specified the target element ID that the response would
normally be added to. This is completely unnecessary in this library, but
since it is send with the request, it is possible this could affect the data
that is returned. This defaults to nothing and no target ID is sent with the
request.

  # Change the target ID
  $sajax->target_id('content');

  # Clear the target ID (restoring default behavior)
  $sajax->clear_target_id();

Using L</has_target_id>, it can be determined if a target ID is currently
set on the object. Using L</clear_target_id> the target ID will be cleared
from the object, restoring default behavior.

=head2 url

B<Required>. This is a L<URI|URI> object of the URL of the SAJAX application.

=head2 user_agent

This is the L<LWP::UserAgent|LWP::UserAgent> object to use when making
requests. This is provided to handle custom user agents. The default value
is LWP::UserAgent constructed with no arguments.

  # Set a low timeout value
  $sajax->user_agent->timeout(10);

=head1 METHODS

=head2 call

This method will preform a call to a remote function using SAJAX. This will
return a Perl scalar representing the returned data. Please note that this by
returning a scalar, that includes references.

  # call may return an ARRAYREF for an array
  my $array_ref = $sajax->call(function => 'IReturnAnArray');
  print 'Returned: ', join q{,}, @{$array_ref};

  # call may return a HASHREF for an object
  my $hash_ref = $sajax->call(function => 'IReturnAnObject');
  print 'Error value: ', $hash_ref->{error};

  # There may even be a property of an object that is an array
  my $object = $sajax->call(function => 'GetProductInfo');
  printf "Product: %s\nPrices: %s\n",
    $object->{name},
    join q{, }, @{$object->{prices}};

This method takes a HASH with the following keys:

=over

=item arguments

This is an ARRAYREF that specifies what arguments to send with the function
call. This must not contain any references (essentially only strings and
numbers). If not specified, then no arguments are sent.

=item function

B<Required>. This is a string with the function name to call.

=item method

This is a string that is either C<"GET"> or C<"POST">. If not supplied, then
the method is assumed to be C<"GET">, as this is the most common SAJAX method.

=back

=head2 clear_target_id

This will clear out the L</target_id> set for this object which will cause the
object to no longer send a L</target_id> with the request.

=head1 DIAGNOSTICS

This module, as of version 0.102, will throw
L<Net::SAJAX::Exception|Net::SAJAX::Exception> objects on errors. This means
that all method return values are guaranteed to be correct. Please read the
relevant exception classes to find out what objects will be thrown. Depend
on at least 0.102 if you want to use object-based exception.

=over

=item * L<Net::SAJAX::Exception|Net::SAJAX::Exception> for general
exceptions not in other categories and the base class.

=item * L<Net::SAJAX::Exception::JavaScriptConversion|Net::SAJAX::Exception::JavaScriptConversion>
for errors during the conversion of JavaScript structure to native Perl structure.

=item * L<Net::SAJAX::Exception::JavaScriptEvaluation|Net::SAJAX::Exception::JavaScriptEvaluation>
for errors during the evaluation of JavaScript returned by the server.

=item * L<Net::SAJAX::Exception::MethodArguments|Net::SAJAX::Exception::MethodArguments>
for errors related to the values of arguments given to methods.

=item * L<Net::SAJAX::Exception::RemoteError|Net::SAJAX::Exception::RemoteError>
for remote errors returned by SAJAX itself.

=item * L<Net::SAJAX::Exception::Response|Net::SAJAX::Exception::Response>
for errors in the HTTP response from the server.

=back

=head1 VERSION NUMBER GUARANTEE

This module has a version number in the format of C<< \d+\.\d{3} >>. When the
digit to the left of the decimal point is incremented, this means that this
module was changed in such a way that it will very likely break code that uses
it. Please see L<Net::SAJAX::VersionGuarantee|Net::SAJAX::VersionGuarantee>.

=head1 DEPENDENCIES

=over 4

=item * L<English|English>

=item * L<HTTP::Request::Common|HTTP::Request::Common> 5.814

=item * L<JE|JE> 0.033

=item * L<List::MoreUtils|List::MoreUtils>

=item * L<LWP::UserAgent|LWP::UserAgent> 5.819

=item * L<Moose|Moose> 0.77

=item * L<MooseX::StrictConstructor|MooseX::StrictConstructor> 0.08

=item * L<MooseX::Types::URI|MooseX::Types::URI> 0.02

=item * L<URI|URI> 1.22

=item * L<URI::QueryParam|URI::QueryParam>

=item * L<namespace::clean|namespace::clean> 0.04

=back

=head1 AUTHOR

Douglas Christopher Wilson, C<< <doug at somethingdoug.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-net-sajax at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-SAJAX>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

I highly encourage the submission of bugs and enhancements to my modules.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc Net::SAJAX

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-SAJAX>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-SAJAX>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-SAJAX>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-SAJAX/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2009 Douglas Christopher Wilson.

This program is free software; you can redistribute it and/or
modify it under the terms of either:

=over 4

=item * the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option) any
later version, or

=item * the Artistic License version 2.0.

=back
