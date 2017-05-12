package Net::ThreeScale::Client;

use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS);

use Carp;
use Data::Dumper;
use Exporter;
use HTTP::Tiny;
use Net::ThreeScale::Response;
use Try::Tiny;

use URI::Escape::XS qw(uri_escape);
use XML::Parser;
use XML::Simple;

my $DEFAULT_USER_AGENT;

use constant {
	TS_RC_SUCCESS                => 'client.success',
	TS_RC_AUTHORIZE_FAILED       => 'provider_key_invalid',
	TS_RC_UNKNOWN_ERROR          => 'client.unknown_error'
};

BEGIN {
	@ISA         = qw(Exporter);
	$VERSION     = "2.1.5";
	@EXPORT_OK   = qw();
	%EXPORT_TAGS = (
		'all' => \@EXPORT_OK,
		'ALL' => \@EXPORT_OK,
	);
	$DEFAULT_USER_AGENT = "threescale_perl_client/$VERSION";

}

sub new {
	my $class = shift;
	my $params = ( $#_ == 0 ) ? { %{ (shift) } } : {@_};

	my $agent_string = $params->{user_agent} || $DEFAULT_USER_AGENT;

	croak("provider_key or service_token/service_id pair are required")
		unless $params->{provider_key} xor ( $params->{service_token} && $params->{service_id});

	my $self = {};
	$self->{provider_key}  = $params->{provider_key}  || undef;
	$self->{service_token} = $params->{service_token} || undef;
	$self->{service_id}    = $params->{service_id}    || undef;

	$self->{url}          = $params->{url} || 'https://su1.3scale.net';
	$self->{DEBUG}        = $params->{DEBUG};
	$self->{HTTPTiny}     = HTTP::Tiny->new(
		'agent'      => $agent_string,
		'keep_alive' => 1,
		'timeout'    => 5,
	);

	return bless $self, $class;
}

sub _authorize_given_url{
    my $self = shift;
    my $url = shift;

    $self->_debug( "start> sending GET request: ", $url );

    my $response = $self->{HTTPTiny}->get($url);
    $self->_debug( "start> got response : ", $response->{content} );

    if (!$response->{success}){
        return $self->_wrap_error($response);
    }
    # HTTP 409 = Conflict
    if ($response->{status} == 409){
        return $self->_wrap_error($response);
    }

    my $data = $self->_parse_authorize_response( $response->{content} );
	
    if ($data->{authorized} ne "true") {
        
        my $reason = $data->{reason};        
        $self->_debug("authorization failed: $reason");
        
        return Net::ThreeScale::Response->new(
            success            => 0,
            error_code         => TS_RC_UNKNOWN_ERROR,
            error_message      => $reason,
            usage_reports      => \@{$data->{usage_reports}->{usage_report}},
        )
    }

    $self->_debug( "success" );
    return Net::ThreeScale::Response->new(
        error_code  => TS_RC_SUCCESS,
        success     => 1,
        usage_reports => \@{$data->{usage_reports}->{usage_report}},
        application_plan => $data->{plan},
    );
}

sub authorize {
	my $self     = shift;
	my $p        = ( $#_ == 0 ) ? { %{ (shift) } } : {@_};

	die("app_id is required") unless defined($p->{app_id});

	my %query = (
		(provider_key  => $self->{provider_key})x!!  $self->{provider_key},
		(service_token => $self->{service_token})x!! $self->{service_token},
		(service_id    => $self->{service_id})x!!    $self->{service_id},
	);

	while (my ($k, $v) = each(%{$p})) {
		$query{$k} = $v;
	}

	my $url = URI->new($self->{url} . "/transactions/authorize.xml");

	$url->query_form(%query);
        return $self->_authorize_given_url( $url );
}


sub authrep {
	my $self     = shift;
	my $p        = ( $#_ == 0 ) ? { %{ (shift) } } : {@_};

	die("user_key is required") unless defined($p->{user_key});

	my %query = (
		(provider_key  => $self->{provider_key})x!!  $self->{provider_key},
		(service_token => $self->{service_token})x!! $self->{service_token},
		(service_id    => $self->{service_id})x!!    $self->{service_id},
	);

	while (my ($k, $v) = each(%{$p})) {
		$query{$k} = $v;
	}

	if ( $query{'usage'} ){
		while (my ($metric_name, $value) = each %{$query{'usage'}} ){
			$query{"usage[$metric_name]"} = $value;
		}
		delete $query{'usage'};
	}

	my $url = URI->new($self->{url} . "/transactions/authrep.xml");
	$url->query_form(%query);

	return $self->_authorize_given_url( $url );
}


sub report {
	my $self     = shift;
	my $p        = ( $#_ == 0 ) ? { %{ (shift) } } : {@_};

	die("transactions is a required parameter") unless defined($p->{transactions});
	die("transactions parameter must be a list")
		unless (ref($p->{transactions}) eq 'ARRAY');

	my %query = (
		(provider_key  => $self->{provider_key})x!!  $self->{provider_key},
		(service_token => $self->{service_token})x!! $self->{service_token},
		(service_id    => $self->{service_id})x!!    $self->{service_id},
	);

	while (my ($k, $v) = each(%{$p})) {
		if ($k eq "transactions") {
			next;
		}

		$query{$k} = $v;
	}

	my $content = "";

	while (my ($k, $v) = each(%query)) {
		if (length($content)) {
				$content .= "&\r\n";
		}

		$content .= "$k=" . uri_escape($v);
	}

	my $txnString = $self->_format_transactions(@{$p->{transactions}});

	$content .= "&" . $txnString;

	my $url = $self->{url} . "/transactions.xml";

	$self->_debug( "start> sending request: ", $url );

	my $response = $self->{HTTPTiny}->post_form($url, { Content=>$content });

	$self->_debug( "start> got response : ", $response->{content} );

	if ( !$response->{success} ) {
		return $self->_wrap_error($response);
	}

	$self->_debug( "success" );

	return Net::ThreeScale::Response->new(
		error_code  => TS_RC_SUCCESS,
		success     => 1,
	);
}

#Wraps an HTTP::Response message into a Net::ThreeScale::Response error return value
sub _wrap_error {
	my $self = shift;
	my $res  = shift;
	my $error_code;
	my $message;

	try {
		( $error_code, $message ) = $self->_parse_errors( $res->{content});
	} catch {
		$error_code = TS_RC_UNKNOWN_ERROR;
		$message    = 'unknown_error';
	};

	return Net::ThreeScale::Response->new(
		success    => 0,
		error_code => $error_code,
		error_message      => $message
	);
}

# Parses an error document out of a response body
# If no sensible error messages are found in the response, insert the standard error value
sub _parse_errors {
	my $self = shift;
	my $body = shift;
	my $cur_error;
	my $in_error  = 0;
	my $errstring = undef;
	my $errcode   = TS_RC_UNKNOWN_ERROR;

	return undef if !defined($body);
	my $parser = new XML::Parser(
		Handlers => {
			Start => sub {
				my $expat   = shift;
				my $element = shift;
				my %atts    = @_;

				if ( $element eq 'error' ) {
					$in_error  = 1;
					$cur_error = "";
					if ( defined( $atts{code} ) ) {
						$errcode = $atts{code};
					}
				}
			},
			End => sub {
				if ( $_[1] eq 'error' ) {
					$errstring = $cur_error;
					$cur_error = undef;
					$in_error  = 0;
				}
			},
			Char => sub {
				if ($in_error) {
					$cur_error .= $_[1];
				}
			  }
		}
	);

	try {
		$parser->parse($body);
	}
	catch {
		$errstring = $_;
	};

	return ( $errcode, $errstring );
}

sub _parse_authorize_response {
	my $self          = shift;
	my $response_body = shift;

	if (length($response_body)) {
		my $xml = new XML::Simple(ForceArray=>['usage_report']);
		return $xml->XMLin($response_body);
	}
	return {};
}

sub _format_transactions {
	my $self          = shift;
	my (@transactions)  = @_;

	my $output = "";

	my $transNumber = 0;

	for my $trans (@transactions) {
		die("Transactions should be given as hashes")
			unless(ref($trans) eq 'HASH');

		die("Transactions need an 'app_id'")
			unless(defined($trans->{app_id}));

		die("Transactions need a 'usage' hash")
			unless(defined($trans->{usage}) and ref($trans->{usage}) eq 'HASH');

		die("Transactions need a 'timestamp'")
			unless(defined($trans->{app_id}));

		my $pref = "transactions[$transNumber]";

		if ($transNumber > 0) {
				$output .= "&";
		}

		$output .= $pref . "[app_id]=" . $trans->{app_id};

		foreach my $k ( sort keys %{$trans->{usage}} ){
			my $v = $trans->{usage}->{$k};
			$k = uri_escape($k);
			$v = uri_escape($v);
			$output .= "&";
			$output .= $pref . "[usage][$k]=$v";
		}

		$output .= "&"
			. $pref
			. "[timestamp]="
			. uri_escape($trans->{timestamp});

		$transNumber += 1;
	}

	return $output;
}

sub _debug {
	my $self = shift;
	if ( $self->{DEBUG} ) {
		print STDERR "DBG:", @_, "\n";
	}

}
1;

=head1 NAME

Net::ThreeScale::Client - Client for 3Scale.com web API version 2.0

=head1 SYNOPSIS

 use Net::ThreeScale::Client;
 
 my $client = new Net::ThreeScale::Client(provider_key=>"my_assigned_provider_key",
                                        url=>"http://su1.3Scale.net");

 # Or initialize by service_token/service_id
 # my $client = new Net::ThreeScale::Client(service_token=>"SERVICE_TOKEN",
 #                                       service_id=>"SERVICE_ID");

 my $response = $client->authorize(app_id  => $app_id,
                                   app_key => $app_key);
          
 if($response->is_success) {
       print "authorized ", $response->transaction,"\"n";
   ...

   my @transactions = (
      {
         app_id => $app_id,
         usage => {
           hits => 1,
         },

         timestamp => "2010-09-01 09:01:00",
      },

      {
         app_id => $app_id,
         usage => {
            hits => 1,
         },

         timestamp => "2010-09-02 09:02:00",
      }
   );

   my $report_response = $client->report(transactions=>\@transactions));
   if($report_response->is_success){
      print STDERR "Transactions reported\n";
   } else {
      print STDERR "Failed to report transactions",
                  $response->error_code(),":",
                  $response->error_message(),"\n";
   }
 } else {
   print STDERR "authorize failed with error :", 
      $response->error_message,"\n";
   if($response->error_code == TS_RC_AUTHORIZE_FAILED) {
      print "Provider key is invalid";
   } else { 
     ...
   }
 }

=head1 CONSTRUCTOR
 
 The class method new(...) creates a new 3Scale client object. This may 
 be used to conduct transactions with the 3Scale service. The object is 
 stateless and transactions may span multiple clients. The following 
 parameters are recognised as arguments to new():

=over 4
 
=item provider_key

(required) The provider key used to identify you with the 3Scale service

=item service_token

(required) Service API key with 3scale (also known as service token).

=item service_id

(required) Service id. Required.

=item url 

(optional) The 3Scale service URL, usually this should be left to the 
default value 

=back

=head1 $response = $client->authorize(app_id=>$app_id, app_key=>$app_key)

Starts a new client transaction the call must include a application id (as 
a string) and (optionally) an application key (string), identifying the
application to use.
 
Returns a Net::ThreeScale::Response object which indicates whether the 
authorization was successful or indicates an error if one occured.  
 
=head1 $response = $client->report(transactions=>\@transactions)

Reports a list of transactions to 3Scale.

=over 4

=item transactions=>{app_id=>value,...}

Should be an array similar to the following:

=over 4

  my @transactions = (
    { 
      app_id => $app_id,
      usage => {
        hits => 1,
     }
     timestamp => "2010-09-01 09:01:00",
    },
    { 
      app_id => $app_id,
      usage => {
        hits => 1,
      }
      timestamp => "2010-09-01 09:02:00",
    },
  );

=back

=back

=head1 EXPORTS / ERROR CODES

The following constants are exported and correspond to error codes 
which may appear in calls to Net::ThreeScale::Response::error_code

=over 4

=item TS_RC_SUCCESS

The operation completed successfully 

=item TS_RC_AUTHORIZE_FAILED

The  passed provider key was invalid

=item TS_RC_UNKNOWN_ERROR

An unspecified error occurred.  See the corresponding message for more detail.

=back

=head1 SUPPORT

3scale support say,
I<We do not have anyone in 3scale actively maintaining it, but we will
certainly monitor pull requests and consider merging any useful contributions.>

=head1 SEE ALSO 

=over 4

=item  Net::ThreeScale::Response

Contains details of response contnet and values. 
 
=back

=head1 AUTHOR 

(c) Owen Cliffe 2008, Eugene Oden 2010.

=head1 CONTRIBUTORS

=over

=item *

Dave Lambley

=item *

Ed Freyfogle

=item *

Marc Metten

=head1 LICENSE

Released under the MIT license. Please see the LICENSE file in the root
directory of the distribution.
