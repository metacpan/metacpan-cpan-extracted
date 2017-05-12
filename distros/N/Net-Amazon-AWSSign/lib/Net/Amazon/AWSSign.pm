package Net::Amazon::AWSSign;

use 5.008;
use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.12';

use MIME::Base64;
use Digest::SHA qw(hmac_sha256_base64);
use URI::Escape;


# General stuff
my $request;
my $SOAPAction;
my $SOAPTimestamp;
my @params;
my $finalString='';
my $finalParams='';
my $AWSSignature='';
my $finalRequestURL;
# My throwaway temp arrays
my @a;
my @b;
# My throwaway temp variables
my $z;
my $y;
# For the secret generator
my $requestProtocol;
my $requestHost;
my $requestPath;


## OO Subs
# Construct an object, called with your AWS key and secret 
sub new
{
  my $class = shift;
  my $self = {
        _AWSKey => shift,
        _AWSSecret  => shift,
  };
  bless $self, $class;
  return $self;
}


sub addRESTSecret {
  my ($self, $request)=@_;
  unless ($request=~m/\&Timestamp=2/) { 
  	$request=$request . "&Timestamp=" . &getAWSTimeStamp(); 
  }
  $finalString="GET\n";
  # Not sure why I thought this was important, but I probably had some rationale, so leaving it in here.
  if ($request=~m/^(http|https)?:\/\/(.*?)\/(.*?)\?/) { 
	$requestProtocol="$1";
  	$requestHost="$2"; 
  	$requestPath="/$3"; 
  	$finalString=$finalString . "$2\n/$3\n"; 
  }else{ 
  	return "ERROR: Cannot determine hostname and base path of request"; 
  }
  # Get just the parameters
  @a=split(/\?/, $request, 2);
  # If we don't already have the subscription ID in the argument list, then add it.
  unless ($a[1]=~m/$self->{_AWSKey}/) { $a[1]="$a[1]&AWSAccessKeyId=$self->{_AWSKey}"; }
  # Ditto for the SHA version and Signature version
  unless ($a[1]=~m/HmacSHA256/) { $a[1]="$a[1]&SignatureMethod=HmacSHA256"; }
  unless ($a[1]=~m/SignatureVersion/) { $a[1]="$a[1]&SignatureVersion=2"; }

  @params=split(/\&/, $a[1]);
  # Sort and URI encode arguments, slam them into @b
  undef @b;
  foreach $z (sort @params) { 
  	@a=split(/=/, $z, 2); 
	# To allow for passing in url-encoded strings, we decode it then encode it
	$a[1]=URI::Escape::uri_unescape( "$a[1]");
  	$a[1]=URI::Escape::uri_escape( "$a[1]", "^A-Za-z0-9\-_.~" ); 
  	$z=join('=', @a); 
  	push (@b, $z); 
  }
  $finalString="$finalString" . join ('&', @b);

  $AWSSignature=hmac_sha256_base64("$finalString", "$self->{_AWSSecret}");
  # For some reason we usually need an equals sign appended.  Check if required
  unless ($AWSSignature=~m/=$/) { $AWSSignature=$AWSSignature . "="; }
  $AWSSignature=URI::Escape::uri_escape( "$AWSSignature", "^A-Za-z0-9\-_.~" );
  return "$requestProtocol://" . $requestHost . $requestPath . "?" . join ('&', @b) . "&Signature=" . $AWSSignature;
}

sub SOAPSig {
  my ($self, $SOAPAction)=@_;
  $SOAPTimestamp=&getAWSTimeStamp();
  $finalString=$SOAPAction . $SOAPTimestamp;
  $AWSSignature=hmac_sha256_base64("$finalString", "$self->{_AWSSecret}");
  # For some reason we usually need an equals sign appended.  Check if required
  unless ($AWSSignature=~m/=$/) { $AWSSignature=$AWSSignature . "="; }
  @a=("$SOAPTimestamp", "$AWSSignature");
  return @a;
}


## Internal subs
sub getAWSTimeStamp {
	# The Timestamp must be generated in a specific format.
    return sprintf("%04d-%02d-%02dT%02d:%02d:%02d.000Z",
       sub {    ($_[5]+1900,
                 $_[4]+1,
                 $_[3],
                 $_[2],
                 $_[1],
                 $_[0])
           }->(gmtime(time)));
}

1;

__END__

=head1 NAME

Net::Amazon::AWSSign - Perl extension to create signatures for AWS requests

=head1 SYNOPSIS

  use Net::Amazon::AWSSign;
  my $awsKey="AWS_Access_Key";  # Get this from AWS if you don't already have one
  my $awsSecret="AWS_Secret_Key";  # Get this from AWS if you don't already have one
  my $awsSign=new Net::Amazon::AWSSign("$awsKey", "$awsSecret");  # New object
  # SOAP
  my $awsSOAPAction=ItemSearch;
  my ($SOAPTimestamp, $SOAPSignature)=$awsSign->SOAPSig($awsSOAPAction);
  # REST
  my $awsASIN='B000002U82';   # Dark Side of the Moon
  my $awsRESTURI="http://webservices.amazon.com/onca/xml?Service=AWSECommerceService&Operation=ItemLookup&ItemId=$awsASIN&ResponseGroup=Medium"; # Simple lookup
  my $awsSignedRESTURI=$awsSign->addRESTSecret($awsRESTURI);  # Returns signed REST query URI for lwp-get, curl, etc.

=head1 DESCRIPTION

This module can be used to sign requests for most Amazon AWS services.  While this is designed for simple lookups, it should work for pretty much any service (i.e. EC2), since the signing method is the same for all Amazon services.
If you want to write your own program to use an Amazon API, this module might save you some time.  Or, feel free to paste it into your own modules as long as you follow the license requirements.

As for available methods, the synopsis / example pretty much says it all.  But, in the interest of full documentation...

=head2 METHODS

=over 4

=item * new Net::Amazon::AWSSign("$AWS_Key", "$AWS_Secret")

Creates a new object.  If you don't have a AWS key / secret you can register to get one free at http://aws.amazon.com/.

=item * SOAPSig($AWS_SOAP_Action)

Returns values for aws:Timestamp and aws:Signature to be included in your SOAP header.  AWS recommends that you use certificate-based WS-Security instead of this method, but if you just need to do some quick and dirty one-time work it'll get the job done.

=item * addRESTSecret($Unsigned_URI)

Takes an unsigned REST URI as an argument and returns the signed URI.  If the key is not already included in the URI, it will be automatically added before signing.

=back

=head2 SPECIAL CHARACTERS

If you need to insert special characters (most commonly '&') in your query string then you should escape them beforehand.
For example:

  my $awsRESTURI="http://webservices.amazon.com/onca/xml?Service=AWSECommerceService&Operation=ItemSearch&SearchIndex=Books&Condition=All&Keywords=Heckle%26Jeckle";

=head1 SEE ALSO

Net::Amazon::Signature  - if AWSSign doesn't meet your needs, then maybe this will.

=head1 AUTHOR

Naton Aiman-Smith, E<lt>naton@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Naton Aiman-Smith

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
