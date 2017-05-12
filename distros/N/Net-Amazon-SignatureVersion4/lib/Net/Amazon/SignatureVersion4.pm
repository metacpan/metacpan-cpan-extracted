use strict;
use warnings;
package Net::Amazon::SignatureVersion4;
{
  $Net::Amazon::SignatureVersion4::VERSION = '0.006';
}
use MooseX::App qw(Config);
use Digest::SHA qw(sha256_hex hmac_sha256_hex hmac_sha256 hmac_sha256_base64);
use POSIX qw(strftime);
use URI::Encode;
use HTTP::Date;
use 5.010;

# ABSTRACT: Signs requests using Amazon's Signature Version 4.


option 'Access_Key_Id' => (
    is        => 'rw',
    isa       => 'Str',
    reader    => 'get_Access_Key_ID',
    predicate => 'has_Access_Key_ID',
    writer    => 'set_Access_Key_ID',
    );

option 'Secret_Access_Key' => (
    is        => 'rw',
    isa       => 'Str',
    reader    => 'get_Secret_Access_Key',
    predicate => 'has_Secret_Access_Key',
    writer    => 'set_Secret_Access_Key',
    );

option 'region' => (
    is      => 'rw',
    isa     => 'Str',
    writer  => 'set_region',
    reader  => 'get_region',
    default => 'us-east-1',
    );

option 'request' => (
    is      => 'rw',
    isa     => 'Object',
    writer  => 'set_request',
    reader  => 'get_request',
    );

option 'service' => (
    is      => 'rw',
    isa     => 'Str',
    writer  => 'set_service',
    reader  => 'get_service',
    );

option 'time' => (
    is      => 'rw',
    isa     => 'Str',
    writer  => 'set_time',
    reader  => 'get_time',
    );

option 'date_stamp' => (
    is      => 'rw',
    isa     => 'Str',
    writer  => 'set_date_stamp',
    reader  => 'get_date_stamp',
    );

option 'signed_headers' => (
    is      => 'rw',
    isa     => 'Str',
    writer  => 'set_signed_headers',
    reader  => 'get_signed_headers',
    );

sub get_authorized_request{
    
    my $self=shift;
    my $request=$self->get_request();
    $request->header( Authorization => $self->get_authorization() );
    return $request

}

sub get_authorization{
    my $self=shift;
    my %dk=$self->get_derived_signing_key();
    my $sts=$self->get_string_to_sign();
    $sts=~tr/\r//d;
    my $signature=hmac_sha256_hex($sts,$dk{'kSigning'});
    return "AWS4-HMAC-SHA256 Credential=".$self->get_Access_Key_ID()."/".$self->get_date_stamp()."/".$self->get_region()."/".$self->get_service()."/aws4_request, SignedHeaders=".$self->get_signed_headers().", Signature=$signature";
}

sub get_derived_signing_key{
    my $self=shift;
    $self->get_canonical_request(); # This is a hack to get the date set before using it to derive the signing key.
    my %rv=();
    $rv{'kSecret'}="AWS4".$self->get_Secret_Access_Key();
    #say("kSecret: ".unpack('H*',$rv{'kSecret'}));
    $rv{'kDate'}=hmac_sha256($self->get_date_stamp(),$rv{'kSecret'});
    #say("kDate: ".unpack('H*',$rv{'kDate'}));
    $rv{'kRegion'}=hmac_sha256($self->get_region(),$rv{'kDate'});
    #say("kRegion: ".unpack('H*',$rv{'kRegion'}));
    $rv{'kService'}=hmac_sha256($self->get_service(),$rv{'kRegion'});
    #say("kService: ".unpack('H*',$rv{'kService'}));
    $rv{'kSigning'}=hmac_sha256("aws4_request",$rv{'kService'});
    #say("kSigning: ".unpack('H*',$rv{'kSigning'}));
    return %rv;
}
sub get_string_to_sign{
    my $self=shift;

    my $creq=$self->get_canonical_request();
    $creq=~tr/\r//d;
    my $StringToSign="AWS4-HMAC-SHA256\r\n".
	$self->get_time()."\r\n".
	$self->get_date_stamp()."/".
	$self->get_region()."/".
	$self->get_service()."/aws4_request\r\n".
	sha256_hex($creq);
}

sub get_canonical_request{
    my $self=shift;
    use Data::Dumper;

    my $method;
    my $full_uri="";
    my $version;
    my $canonical_query_string="";
    my %headers=();
    
    foreach my $name ( $self->get_request()->header_field_names() ){
	my @value=$self->get_request()->header($name);
	next unless (defined $name & defined $value[0]);
	if (lc($name) eq 'date'){
	    my $time=str2time($value[0]);
	    $self->set_date_stamp(strftime("%Y%m%d", gmtime($time)));
	    $self->set_time(strftime("%Y%m%dT%H%M%SZ",gmtime($time)));
	    
	}
	foreach my $value (@value){
	    local $/ = " ";
	    chomp($value);
	    if (defined $headers{lc($name)}){
		push @{$headers{lc($name)}}, $value;
	    }else{
		$headers{lc($name)}=[$value ];
	    }
	}
    }
    $full_uri=$self->get_request()->uri();
    $full_uri =~ s@^(http|https)://.*?/@/@;
    if ($full_uri=~m/(.*?)\?(.*)/){
	$full_uri=$1;
	$canonical_query_string=$2;
    }
    my @canonical_query_list;
    if ( defined $canonical_query_string){
	if ($canonical_query_string=~m/(.*?)\s.*/){
	    $canonical_query_string=$1
	}
	@canonical_query_list=split(/\&/,$canonical_query_string);
    }
    $canonical_query_string="";
    foreach my $param (sort @canonical_query_list){
	(my $name, my $value)=split(/=/, $param);
	$name="" unless (defined $name);
	$value="" unless (defined $value);
	$canonical_query_string=$canonical_query_string._encode($name)."="._encode($value)."&";
    }
    $canonical_query_string=substr($canonical_query_string, 0, -1) unless ($canonical_query_string eq "");
    $full_uri=~tr/\///s;
    my $ends_in_slash=0;
    if ($full_uri=~m/\w\/$/){
	$ends_in_slash=1;
    }
    my @uri_source=split /\//, $full_uri;
    my @uri_stack;
    foreach my $path_component (@uri_source){
	if ($path_component =~ m/^\.$/){
	    sleep 0;
	}elsif ($path_component =~ m/^..$/){
	    pop @uri_stack;
	}else{
	    push @uri_stack, $path_component;
	}
    }
    $full_uri="/";
    foreach my $path_component (@uri_stack){
	$full_uri=$full_uri."$path_component/";
    }
    $full_uri=~tr/\///s;
    chop $full_uri unless ( $full_uri eq "/" );
    if ($ends_in_slash){
	$full_uri=$full_uri."/";
    }
    my $CanonicalHeaders="";
    my $SignedHeaders="";
    foreach my $header ( sort keys %headers ){
	$CanonicalHeaders=$CanonicalHeaders.lc($header).':';
	foreach my $element(sort @{$headers{$header}}){
	    $CanonicalHeaders=$CanonicalHeaders.($element).",";
	}
	$CanonicalHeaders=substr($CanonicalHeaders, 0, -1);
	$CanonicalHeaders=$CanonicalHeaders."\r\n";
	$SignedHeaders=$SignedHeaders.lc($header).";";
   }

    $SignedHeaders=substr($SignedHeaders, 0, -1);
    $self->set_signed_headers($SignedHeaders);
    my $CanonicalRequest =
	$self->get_request()->method() . "\r\n" .
	$full_uri . "\r\n" .
	$canonical_query_string . "\r\n" .
	$CanonicalHeaders . "\r\n" .
	$SignedHeaders . "\r\n" .
	sha256_hex($self->get_request()->content());
    return $CanonicalRequest;
}

sub _encode{
    #This method is used to add some additional encodings that are not enforced by the URI::Encode module.  AWS expects these.
    my $encoder = URI::Encode->new({ double_encode => 0 });
    my $rv=shift;
#    %20=%2F%2C%3F%3E%3C%60%22%3B%3A%5C%7C%5D%5B%7B%7D&%40%23%24%25%5E=
#    +  =/  ,  ?  %3E%3C%60%22;  :  %5C%7C]  [  %7B%7D&@  #  $  %25%5E=
    $rv=$encoder->encode($rv);
    $rv=~s/\+/\%20/g;
    $rv=~s/\//\%2F/g;
    $rv=~s/\,/\%2C/g;
    $rv=~s/\?/\%3F/g;
    $rv=~s/\;/\%3B/g;
    $rv=~s/\:/\%3A/g;
    $rv=~s/\]/\%5D/g;
    $rv=~s/\[/\%5B/g;
    $rv=~s/\@/\%40/g;
    $rv=~s/\#/\%23/g;
    $rv=~s/\$/\%24/g;
#    $rv=~s///g;
    return $rv;
}
1;

__END__

=pod

=head1 NAME

Net::Amazon::SignatureVersion4 - Signs requests using Amazon's Signature Version 4.

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    use Net::Amazon::SignatureVersion4;

    my $sig=new Net::Amazon::SignatureVersion4();
    my $hr=HTTP::Request->new('GET','http://glacier.us-west-2.amazonaws.com/-/vaults', [ 
				   'Host', 'glacier.us-west-2.amazonaws.com', 
				   'Date', strftime("%Y%m%dT%H%M%SZ",gmtime(time())) , 
				   'X-Amz-Date', strftime("%Y%m%dT%H%M%SZ",gmtime(time())) , 
				   'x-amz-glacier-version', '2012-06-01',
			       ]);
    $hr->protocol('HTTP/1.1');

    $sig->set_request($request); # $request is HTTP::Request
    $sig->set_region('us-west-2');
    $sig->set_service('glacier'); # Must be service you are accessing
    $sig->set_Access_Key_ID('AKIDEXAMPLE'); # Replace with your ACCESS_KEY_ID
    $sig->set_Secret_Access_Key('wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY'); # Replace with your SECRET_KEY
    my $authorized_request=$sig->get_authorized_request();
    my $agent = LWP::UserAgent->new( agent => 'perl-Net::Amazon::SignatureVersion4-Testing');
    my $response = $agent->request($authorized_request);
    if ($response->is_success) {
        say("List of vaults");
        say($response->decoded_content);  # or whatever
        say("Connected to live server");
    }else {
        say($response->status_line);
        use Data::Dumper;
        say("Failed Response");
        say(Data::Dumper->Dump([ $response ]));
    }

=head1 DESCRIPTION

This module implements Amazon's Signature Version 4 as documented at
http://docs.amazonwebservices.com/general/latest/gr/signature-version-4.html

The tests for this module are taken from the test suite provided by
Amazon.  This implementation does not yet pass all the tests.  The
following test is failing:

get-header-value-multiline: Amazon did not supply enough files for
this test.  The test may be run, but the results can not be validated.

=head1 METHODS

=head2 get_authorized_request

    This method does most of the work for the user.  After setting the
    request, region, service, access key, and secret access key, this
    method will return a copy of the request headers with
    authorization.

=head2 get_authorization

    This method gets the authorization line that should be added to
    the headers.  It is likely never to be used by the end user.  It
    is here as a convenient test.

=head2 get_derived_signing_key

    This method implements the derived signing key required for
    version 4. It is likely never to be used by the end user.  It is
    here as a convenient test.

=head2 get_string_to_sign

    This method returns the string to sign.  It is likely never to be
    used by the end user.  It is here as a convenient test.

=head2 get_canonical_request

    This method returns the canonical request.  It is likely never to
    be used by the end user.  It is here as a convenient test.

=head1 AUTHOR

Charles A. Wimmer <charles@wimmer.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Charles A. Wimmer.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
