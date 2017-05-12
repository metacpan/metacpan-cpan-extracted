package Net::Amazon::MechanicalTurk;
use warnings;
use strict;
use Carp;
use Config;
use Net::Amazon::MechanicalTurk::Constants ':ALL';
use Net::Amazon::MechanicalTurk::BaseObject;
use Net::Amazon::MechanicalTurk::Transport;
use Net::Amazon::MechanicalTurk::Response;
use Net::Amazon::MechanicalTurk::PagedResultsIterator;
use Net::Amazon::MechanicalTurk::Properties;
use Net::Amazon::MechanicalTurk::OSUtil;
use Net::Amazon::MechanicalTurk::ModuleUtil;
use Net::Amazon::MechanicalTurk::FilterChain;
use MIME::Base64;
use Digest::HMAC_SHA1 qw{ hmac_sha1 };
use URI;

=head1 NAME

Net::Amazon::MechanicalTurk - Amazon Mechanical Turk SDK for Perl

=head1 VERSION

Version 1.02

=cut

our $VERSION = '1.02';

=head1 CONFIGURATION

Configuring your access keys and web service urls.

MechanicalTurk needs access keys for authentication.
If you do not specify all of the relevant attributes,
The file mturk.properties is read from your home directory
for this information.

Run the command:

    perl -MNet::Amazon::MechanicalTurk::Configurer -e configure

to help you create this file.

=head1 SYNOPSIS

Module for MechanicalTurk API.

    use Net::Amazon::MechanicalTurk;

    # Create a new MechTurk client
    my $mturk = Net::Amazon::MechanicalTurk->new();


    # Create a new MechTurk client without using mturk.properties
    my $mturk = Net::Amazon::MechanicalTurk->new(
        serviceUrl     => 'https://mechanicalturk.sandbox.amazonaws.com/?Service=AWSMechanicalTurkRequester',
        serviceVersion => '2007-06-21',
        accessKey      => '1AAAAA1A1AAAAA11AA11',
        secretKey      => '1aAaAAAAAAAA+aAaAaaaaaaAAA/AAAAAA1a1aAaa'
    );


    # Get your balance
    my $balance = $mturk->GetAccountBalance->{AvailableBalance}[0]{Amount}[0];
    print "Your balance is $balance\n";


    # CreateHIT
    my $question = "Tell me something interesting.";

    my $questionXml = <<END_XML;
    <?xml version="1.0" encoding="UTF-8"?>
    <QuestionForm xmlns="http://mechanicalturk.amazonaws.com/AWSMechanicalTurkDataSchemas/2005-10-01/QuestionForm.xsd">
      <Question>
        <QuestionIdentifier>1</QuestionIdentifier>
        <QuestionContent>
          <Text>$question</Text>
        </QuestionContent>
        <AnswerSpecification>
          <FreeTextAnswer/>
        </AnswerSpecification>
      </Question>
    </QuestionForm>
    END_XML

    my $result = $mturk->CreateHIT(
        Title       => 'Answer a question',
        Description => 'Test HIT from Perl',
        Keywords    => 'hello, world',
        Reward => {
            CurrencyCode => 'USD',
            Amount       => 0.01
        },
        RequesterAnnotation         => 'Test Hit',
        AssignmentDurationInSeconds => 60 * 60,
        AutoApprovalDelayInSeconds  => 60 * 60 * 10,
        MaxAssignments              => 1,
        LifetimeInSeconds           => 60 * 60,
        Question                    => $questionXml
    );

    printf "Created HIT:\n";
    printf "HITId:     %s\n", $result->{HITId}[0];
    printf "HITTypeId: %s\n", $result->{HITTypeId}[0];


    # Approve all submitted assignments
    my $hits = $mturk->GetReviewableHITsAll;
    while (my $hit = $hits->next) {
        my $hitId = $hit->{HITId}[0];
        my $assignments = $mturk->GetAssignmentsForHITAll(
            HITId => $hitId,
            AssignmentStatus => 'Submitted'
        );
        while (my $assignment = $assignments->next) {
            my $assignmentId = $assignment->{AssignmentId}[0];
            $mturk->ApproveAssignment( AssignmentId => $assignmentId );
        }
    }

=head1 ERROR HANDLING

Most methods indicate an error condition through die or Carp::croak.
This is similar to throwing an exception in other languages.
To catch an error, use eval:

    eval {
        $mturk->callSomeMethod();
    };
    if ($@) { # catch an error
       warn "The following error occurred: ", $@, "\n";

       # You can access the error code through the last response object.
       print "Error Code: ", $mturk->response->errorCode, "\n";

       # You can also access the last request made.
       print "Error while calling operation, ",
             $mturk->request->{Operation}, "\n";
    }


=head1 WEB SERVICE METHODS

All of the operations listed in the MechanicalTurk API may be called
on a MechanicalTurk instance.  To see a list of those operations and
what parameters they take see the following URL:

       http://docs.amazonwebservices.com/AWSMechanicalTurkRequester/2007-06-21/

=head2 WEB SERVICE RESULTS

The MechanicalTurk web service returns XML for a request.  This module will
parse the XML into a generic perl data structure consisting of hashes
and arrays.  This data structure is then looked through to find a result.
A result is the first child element under the root element whose element
name is not OperationRequest.  The XML returned by the webservice contains
information rarely used.  (If you ever need this extra information it
is available through the response attribute on the MechanicalTurk instance.)

Although the results are normal data structures, they also
have methods added to them through the package

Net::Amazon::MechanicalTurk::DataStructure.

This package provides a few methods, however the most useful one during
development is toString.  The toString method will help you figure out how
to access the information you need from the result.  Here is an example
of the result as returned by GetAccountBalance.

    my $result = $mturk->GetAccountBalance;
    print $result->toString, "\n";
    printf "Available Balance: %s\n", $result->{AvailableBalance}[0]{Amount}[0];

    <<Net::Amazon::MechanicalTurk::DataStructure>>
    [AvailableBalance]
      [0]
        [Amount]
          [0] 10000.00
        [CurrencyCode]
          [0] USD
        [FormattedPrice]
          [0] $10,000.00
    [OnHoldBalance]
      [0]
        [Amount]
          [0] 0.00
        [CurrencyCode]
          [0] USD
        [FormattedPrice]
          [0] $0.00
    [Request]
      [0]
        [IsValid]
          [0] True

    Available Balance: 10000.00

Implementation Note: Hash values always contain arrays, even when the
WSDL/XSD specifies that child element of another element only occurs
once.  This perl module does not use the WSDL or XSD for reading or
generating XML and does not know if a child element should occur once
or many times.  It treats the XML as if the element could always occur
more than once.  It could have been written to condense a single
occurence in an array to 1 scalar item, however this would require
API users to test if a value is a SCALAR or an ARRAY.


=head1 ITERATING METHODS

Some of the MechanicalTurk operations, such as GetAssignmentsForHIT
are limited in the number of results returned.  These methods have
the parameters PageSize and PageNumber, which can be used to go
through an entire list of results.

Instead of writing the code to iterate through all of the results
using pages, you can make a call to that method with the word 'All'
appended to the method name.  An object will be returned, which has
a method called next, which will return the next item in the results
or undef when there are no more results.

Example using an iterator for the GetAssignmentsForHIT operation:

    my $assignments = $mturk->GetAssignmentsForHITAll(
        HITId => $hitId,
        AssignmentStatus => 'Submitted'
    );
    while (my $assignment = $assignments->next) {
        my $assignmentId = $assignment->{AssignmentId}[0];
        $mturk->ApproveAssignment( AssignmentId => $assignmentId );
    }

=head1 EXTENDED METHODS

Methods which provide additional functionaliy on top of Mechanical Turk

Extra methods are available through a dynamic extension mechanism.
Modules under Net::Amazon::MechanicalTurk::Command add extra functionality
to the MechanicalTurk client.

Explanation:

If you were to call the method listOperations, the module
Net::Amazon::MechanicalTurk::Command::ListOperations would be loaded
and the method listOperations would be added to the MechanicalTurk
client.


See the perldocs for those commands:

=over

L<Net::Amazon::MechanicalTurk::Command::LoadHITs>.

L<Net::Amazon::MechanicalTurk::Command::UpdateHITs>.

L<Net::Amazon::MechanicalTurk::Command::RetrieveResults>.

L<Net::Amazon::MechanicalTurk::Command::GetAvailableBalance>.

L<Net::Amazon::MechanicalTurk::Command::GetHITTypeURL>.

L<Net::Amazon::MechanicalTurk::Command::AddRetry>.

L<Net::Amazon::MechanicalTurk::Command::DeleteHIT>.

L<Net::Amazon::MechanicalTurk::Command::ParseAssignmentAnswer>.

=back

=head1 ATTRIBUTE METHODS

=over 4

=item accessKey or access_key

Get or set the access key used for authentication.

=item secretKey or secret_key

Get or set the secret key used for signing web service requests.

=item serviceUrl or service_url

Get or set the endpoint for the webservice.  If this url contains
the query parameters, Version and/or Service.  Then the values
for serviceVersion and serviceName will also be set.

=item serviceName or service_name

Get or set the service name of the web service.

=item serviceVersion or service_version

Get or set the version of the web service.

=item requesterUrl or requester_url

Get or set the URL for the requester website. This is only used for display purposes.

=item workerUrl or worker_url

Get or set the URL for the worker website.  This is only used for display purposes.

=item response

Get the last response from a web service call.
This will be of type Net::Amazon::MechanicalTurk::Response.

=item request

Get the last request used for a web service call.
This will be a hash of all the parameters sent to the transport.

=item filterChain

Get the filterChain used for intercepting web service calls.
This is for advanced use cases and internal use.
This attribute will be of type Net::Amazon::MechanicalTurk::FilterChain.

=item transport

Get or set the transport used for sending web service requests.

The default transport is of type
Net::Amazon::MechanicalTurk::Transport::RESTTransport.

Hint: You can get to the underlying LWP::UserAgent through the RESTTransport
to set connection timeouts.

$mturk->transport->userAgent->timeout(10);

=back

=cut


our @ISA = qw{ Net::Amazon::MechanicalTurk::BaseObject };
our $AUTOLOAD;

Net::Amazon::MechanicalTurk->attributes(qw{
    accessKey
    secretKey
    serviceName
    serviceVersion
    requesterUrl
    workerUrl
    response
    request
    config
    configProperties
    filterChain
});

# Create attribute aliases to support configuration from the properties file.
# (The java command line tool used underscores for its values)
# ( Global config uses AccessKeyId and SecretAccessKey )
Net::Amazon::MechanicalTurk->methodAlias(
    'access_key'      => 'accessKey',
    'AccessKeyId'     => 'accessKey',
    'secret_key'      => 'secretKey',
    'SecretAccessKey' => 'secretKey',
    'service_url'     => 'serviceUrl',
    'service_name'    => 'serviceName',
    'service_version' => 'serviceVersion',
    'requester_url'   => 'requesterUrl',
    'worker_url'      => 'workerUrl'
);

=head1 Constructor

=over

=item init

Initialize a new MechanicalTurk client

=back

=cut

sub init {
    my $self = shift;
    $self->setAttributes(@_);
    $self->_applyConfig;
    $self->setAttributesIfNotDefined(
        transport      => Net::Amazon::MechanicalTurk::Transport->create,
        serviceName    => "AWSMechanicalTurkRequester",
        serviceVersion => $DEFAULT_SERVICE_VERSION,
        serviceUrl     => $SANDBOX_URL,
    );
    foreach my $attr (qw{
        accessKey
        secretKey
        serviceUrl
        serviceVersion})
    {
        if (!defined($self->$attr)) {
            die "Missing value for $attr.\n" .
                "This value may be specified in a config file.\n" .
                "Which may be specified in the following ways:\n" .
                "  1. Set an environment variable named $PROP_ENVNAME to the path of the file.\n".
                "  2. Put the file named $PROP_FILENAME in the current working directory.\n\n" .
                "Example File::\n\n" .
                "access_key:      <Your AWS access key>\n" .
                "secret_key:      <Your AWS secret access key>\n" .
                "service_url:     $SANDBOX_URL\n" .
                "service_version: $DEFAULT_SERVICE_VERSION\n\n" .
                "Alternatively, you may run the command:\n\n" .
                "  " . $Config{perlpath} . " -MNet::Amazon::MechanicalTurk::Configurer -e configure\n\n" .
                "to setup global (per-user) configuration values.\n"
        }
    }
    $self->filterChain(Net::Amazon::MechanicalTurk::FilterChain->new);
    if (!defined $self->requesterUrl) {
        $self->requesterUrl($self->isProduction ? $PRODUCTION_REQUESTER_URL : $SANDBOX_REQUESTER_URL);
    }
    if (!defined $self->workerUrl) {
        $self->workerUrl($self->isProduction ? $PRODUCTION_WORKER_URL : $SANDBOX_WORKER_URL);
    }
}

=head1 Utility Methods

=over

=item isProduction

Tests whether or not the current serviceUrl is for production.

=cut

sub isProduction {
    my $self = shift;
    return $self->serviceUrl =~ /mechanicalturk\.amazonaws\.com/i;
}

=item isSandbox

Tests whether or not the current serviceUrl is for the MechanicalTurk
sandbox environment.

=cut

sub isSandbox {
    my $self = shift;
    return $self->serviceUrl =~ /mechanicalturk\.sandbox\.amazonaws.com/i;
}

=back

=head1 Getters/Setters

=over

=item serviceUrl

serviceUrl determines which host the client communicates with.
Can be given a full Url, or can be set to one of the named urls:
* Sanbox
* Production

=cut

sub serviceUrl {
    # In addition to setting the serviceUrl the url is parsed for parameters
    # that set the serviceName and serviceVersion.
    my $self = shift;
    my $attrName = "Net::Amazon::MechanicalTurk::serviceUrl";
    if ($#_ >= 0) {
        my $serviceUrl = shift;

        # Allow for named endpoints
        if ($serviceUrl =~ m/^Sandbox$/i) {
            $serviceUrl = $SANDBOX_URL;
        }
        elsif ($serviceUrl =~ m/^Prod(uction)?$/i) {
            $serviceUrl = $PRODUCTION_URL;
        }

        my $uri = URI->new($serviceUrl);
        my %params = $uri->query_form;
        if (exists $params{Service}) {
            $self->serviceName($params{Service});
        }
        if (exists $params{Version}) {
            $self->serviceVersion($params{Version});
        }
        $self->{$attrName} = $serviceUrl;
    }
    return $self->{$attrName};
}

=item transport

transport is the object that handles actual comunications with the service.
Pass in an initialized transport or parameters to be passed to Net::Amazon::MechanicalTurk::Transport->create.

=cut

sub transport {
    my $self = shift;
    my $attrName = "Net::Amazon::MechanicalTurk::transport";
    if ($#_ >= 0) {
        my $transport = shift;
        if (UNIVERSAL::isa($transport, "Net::Amazon::MechanicalTurk::Transport")) {
            $self->{$attrName} = $transport;
        }
        else {
            $self->{$attrName} = Net::Amazon::MechanicalTurk::Transport->create($transport, @_);
        }
    }
    return $self->{$attrName};
}

=back

=head1 Mechanical Turk API calls

=over

=item iterator

iterator retrieves a Net::Amazon:MechanicalTurk::PagedResultsIterator for the requested operation and parameters

=cut

sub iterator {
    my $self = shift;
    my $operation = shift;

    my %params;
    if ($#_ == 0 and UNIVERSAL::isa($_[0], "ARRAY")) {
       $params{$operation} = shift;
    }
    else {
        %params = ($#_ == 0) ? %{$_[0]} : @_;
    }

    return Net::Amazon::MechanicalTurk::PagedResultsIterator->new(
        mturk     => $self,
        operation => $operation,
        params    => \%params
    );
}

=item call

call simply invokes the requested operation with the provided parameters and returns the result

=cut

sub call {
    my $self = shift;
    my $operation = shift;

    my %params;
    if ($#_ == 0 and UNIVERSAL::isa($_[0], "ARRAY")) {
       $params{$operation} = shift;
    }
    else {
        %params = ($#_ == 0) ? %{$_[0]} : @_;
    }

    return $self->filterChain->execute(\&_call, $self, $operation, \%params);
}

=back

=cut

# Private methods

sub _call {
    my ($self, $operation, $params) = @_;

    $self->debugMessage("Calling operation $operation.");

    my $timestamp = $self->_createTimestamp;
    my $request = {
        Service        => $self->serviceName,
        AWSAccessKeyId => $self->accessKey,
        Version        => $self->serviceVersion,
        Operation      => $operation,
        Signature      => $self->_createSignature($operation, $timestamp),
        Timestamp      => $timestamp
    };
    while (my ($k,$v) = each %$params) {
        $request->{$k} = $v;
    }

    $self->request($request);

    my $response;
    eval {
        my $xml = $self->transport->call($self, $operation, $request);
        $response = Net::Amazon::MechanicalTurk::Response->new(xml => $xml);
    };
    if ($@) {
        $response = Net::Amazon::MechanicalTurk::Response->new->clientError('TransportError', $@);
    }

    if ($self->debug) {
        $self->debugMessage($response->toString);
    }

    $self->response($response);
    if ($response->errorCode) {
        Carp:croak("[" . $response->errorCode . "] " . $response->errorMessage);
    }

    return $response->result;
}

sub _createTimestamp {
    my @time = gmtime(time());
    return sprintf("%04d-%02d-%02dT%02d:%02d:%02dZ",
        $time[5] + 1900,
        $time[4] + 1,
        $time[3],
        $time[2],
        $time[1],
        $time[0],
    );
}

sub _createSignature {
    my ($self, $operation, $timestamp) = @_;
    my $str = $self->serviceName . $operation . $timestamp;
    my $signature = encode_base64(hmac_sha1($str, $self->secretKey));
    chomp($signature);
    return $signature;
}

sub _applyConfig {
    my ($self) = @_;

    # Find config files
    if (!$self->config) {
        if (exists $ENV{$PROP_ENVNAME}) {
            $self->config($ENV{$PROP_ENVNAME});
        }
        elsif (-f $PROP_FILENAME) {
            $self->config($PROP_FILENAME);
        }
    }

    $self->_applyConfigFile;

    my $homedir = Net::Amazon::MechanicalTurk::OSUtil->homeDirectory;
    if ($homedir and -f "$homedir/$PROP_GLOBAL_DIR/$PROP_GLOBAL_AUTH") {
        $self->config("$homedir/$PROP_GLOBAL_DIR/$PROP_GLOBAL_AUTH");
        $self->_applyConfigFile; # re-apply with global defaults ( will not override other config )
    }
}

sub _applyConfigFile {
    my ($self) = @_;
    # Apply values from config
    if ($self->config) {
        my $props = Net::Amazon::MechanicalTurk::Properties->read($self->config);
        $self->configProperties($props);
        while (my ($k,$v) = each %$props) {
            if (UNIVERSAL::can($self, $k)) {
                eval {
                    if (!defined($self->$k)) {
                        $self->$k($v);
                    }
                };
            }
        }

        # Look for properties which set debug on for a class
        while (my ($k,$v) = each %$props) {
            if ($k =~ /^(.*)(::|-)DEBUG/) {
                my $module = $1;
                $module =~ s/-/::/g;
                if (Net::Amazon::MechanicalTurk::ModuleUtil->tryRequire($module)) {
                    eval {
                        $module->debug($v);
                    };
                    if ($@) {
                        warn "Can't set debug on module ($module) - $@.";
                    }
                }
            }
        }

        $self->debugMessage("Loaded config from " . $self->config);
    }
}

# Hook for calling API methods by operation name

sub AUTOLOAD {
    my ($self) = @_;
    my $operation = $AUTOLOAD;
    $operation =~ s/^.*://;

    # There are 3 different type of AUTOLOADED method calls
    # for the MechTurk client.
    #
    # 1. Basic API calls against the service.
    #    These start with an uppercase letter but do not end in 'All'.
    #    These methods are given to the call method.
    # 2. Iterating calls against the service.
    #    Many MechanicalTurk service calls take a PageSize and PageNumber
    #    parameter.  These are used to get a subset of items.
    #    If you call an service call, but add the word All to the end
    #    an iterator will be returned which knows when to make the next
    #    actual call, while your iterating.
    # 3. High level commands.
    #    This client supports some very high level methods for bulk loading
    #    of hits, bulk approving assignments, downloading results, etc...
    #    These methods may be large and need optional modules so the
    #    loading of those methods are defered. The method is looked for
    #    in a module named:
    #
    #    Net::Amazon::MechanicalTurk::Command::<module>
    #
    #    (Where module is the name of the method with the first letter upper cased.)
    #


    # MechanicalTurk operations start with an uppercase.

    my $sub;
    if ($operation !~ /^[A-Z]/) {
        my $module = "Net::Amazon::MechanicalTurk::Command::" . ucfirst($operation);
        if (Net::Amazon::MechanicalTurk::ModuleUtil->tryRequire($module)) {
            $sub = UNIVERSAL::can($module, $operation);
        }
        if (!$sub) {
            Carp::croak("Method $operation does not exist on class " . ref($self) . ".");
        }
    }
    elsif ($operation =~ /^(.+)All$/) {
        # Special handling for methods ending with ALL
        # An iterator is created which can be used
        # to go across all pages.
        $operation = $1;
        $sub = sub {
            my $_self = shift;
            return $_self->iterator($operation, @_);
        };
    }
    else {
        $sub = sub {
            my $_self = shift;
            return $_self->call($operation, @_);
        };
    }
    no strict 'refs';
    *{"${AUTOLOAD}"} = $sub;
    goto &$sub;
}

=head1 BUGS

Please report any bugs or feature requests through the Amazon Web Services
Developer Connection.

L<http://developer.amazonwebservices.com/connect/forum.jspa?forumID=11>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Amazon::MechanicalTurk

You can also look for information at:

=over

=item

L<http://requester.mturk.com/mturk/welcome>

=item

L<http://developer.amazonwebservices.com/connect/forum.jspa?forumID=11>

=back

=head1 COPYRIGHT & LICENSE

Copyright (c) 2007 Amazon Technologies, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

1; # End of Net::Amazon::MechanicalTurk
