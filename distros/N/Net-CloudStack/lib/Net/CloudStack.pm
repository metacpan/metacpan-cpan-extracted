package Net::CloudStack;

use 5.006;

use Mouse;
use Mouse::Util::TypeConstraints;
use Digest::SHA qw(hmac_sha1);
use MIME::Base64;
use LWP::UserAgent;
use Encode;
use XML::Twig;
use URI::Encode;
use JSON;
use Carp;
use Data::Dumper;

subtype 'CloudStack::YN'
    => as 'Str'
    => where { $_ =~ /^(yes|no)$/ }
=> message { "Please input yes or no" }
;

has 'base_url' => ( #http://localhost:8080
    is => 'rw',
    isa => 'Str',
    required => 1,
    );

has 'api_path' => ( #/client/api?
    is => 'rw',
    isa => 'Str',
    required => 1,
    );

has 'api_key' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    );

has 'secret_key' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    );

has 'send_request' => (
    is => 'rw',
    isa => 'CloudStack::YN',
    default => 'no',
    );

has 'xml_json' => (
    is => 'rw',
    isa => 'Str',
    default => 'xml',
    );

has 'url' => (
    is => 'rw',
    isa => 'Str',
    );

has 'response' => (
    is => 'rw',
    isa => 'Str',
    );

__PACKAGE__->meta->make_immutable;
no Mouse;
no Mouse::Util::TypeConstraints;

### FOR TEST ###

sub test{
    my ($self) = @_;
    my @required = ();

    print "BASE URL:".$self->base_url."\n";
    print "API PATH:".$self->api_path."\n";
    print "API KEY:".$self->api_key."\n";
    print "SECRET KEY:".$self->secret_key."\n";
    print "SEND_REQUEST:".$self->send_request."\n";
    print "XML_JSON:".$self->xml_json."\n";
}


### SUB ROUTINE ###

### COMMAND ###
sub proc{
    my ($self, $cmd, $opt, $required) = @_;

    if(!defined($opt)){
        $opt = "";
    }
    else{
	$opt =~ s/^(.+\=\=)\s+\S*?(\&.+)$/$1$2/; # for SSH Public Key
        $opt =~ s/^(.+\=\=)\s+\S+$/$1/;          # for SSH Public Key

        $opt =~ s/([\=\&])\s+/$1/g;
        $opt =~ s/\s+([\=\&])/$1/g;
    }

    $cmd =~ s/.*:://;

    foreach (@$required){
        croak "$_ is required"  if(!defined($opt) || $opt !~ /[\s\&]*$_\s*\=/);
    }

    $self->gen_url($cmd, $opt);
    if($self->send_request =~ /yes/i){
	$self->gen_response;
    }
}


sub gen_url{
    my ($self, $cmd, $opt) = @_;
    my $base_url = $self->base_url;
    my $api_path = $self->api_path;
    my $api_key = $self->api_key;
    my $secret_key = $self->secret_key;
    my $xml_json = $self->xml_json;
    my $uri = URI::Encode->new();

#step1
    if($opt){
        $cmd .= "&".$opt;
    }
    if($xml_json =~ /json/i){
        $cmd .= "&response=json";
    }
    my $query = "command=".$cmd."&apiKey=".$api_key;
    my @list = split(/&/,$query);
    foreach  (@list){
      if(/(\w+(?:\[\d+\]\.\w+)?)\=(\w.+)/){
            my $field = $1;
            my $value = $uri->encode($2, 1); # encode_reserved option is set to 1
            $_ = $field."=".$value;
        }
    }
    my $output_tmp = join("&",sort @list);

#step2
    foreach  (@list){
        $_ = lc($_);
    }
    my $output = join("&",sort @list);

#step3
    my $digest = hmac_sha1($output, $secret_key);
    my $base64_encoded = encode_base64($digest);chomp($base64_encoded);
    my $url_encoded = $uri->encode($base64_encoded, 1); # encode_reserved option is set to 1
    my $url = $base_url."/".$api_path.$output_tmp."&signature=".$url_encoded;
    $self->url("$url");
#    print Dumper($url);
}

sub gen_response{
    my ($self) = shift;
    my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 });
    my $ua_res = $ua->get($self->url);

#    print Dumper($ua_res);
    if($ua_res->{_content} =~ /^provider_error\:/){
	$self->response($ua_res->{_content}."\n");
    }

    else{
	#json
	if($self->xml_json =~ /json/i){
	    my $obj = from_json(encode('utf8',$ua_res->decoded_content));
	    my $json = JSON->new->pretty(1)->encode($obj);
	    $self->response("$json");
	}
	
	#xml
	else{
	    my $parser = XML::Simple->new;
	    
	    my $xml = encode('utf8',$ua_res->decoded_content);#Please Change cp932 for Win.
	    my $twig = XML::Twig->new(pretty_print => 'indented', );
	    $twig->parse($xml);
	    
	    my $response = $twig->sprint;
	    $self->response("$response");
	}
    }
}


=head1 NAME

Net::CloudStack - Bindings for the CloudStack API

=head1 VERSION

Version 0.01005

=cut

our $VERSION = '0.01005';


=head1 SYNOPSIS

    use Net::CloudStack;
    my $api = Net::CloudStack->new(
        base_url        => 'http://...',
        api_path        => 'client/api?',
        api_key         => '<your api key>',
        secret_key      => '<your secret key>',
        xml_json        => 'json', #response format.you can select json or xml. xml is default.
        send_request    => 'yes',  #yes or no.
                                   #When you select yes,you can get response.
                                   #If you don't want to get response(only generating url),please input no. 
    );

    # CloudStack API Methods
    $api->proc($cmd, $opt);
    $api->proc("listVirtualMachines");
    $api->proc("listVirtualMachines","id=123");

    $api->proc("deployVirtualMachine","serviceofferingid=1&templateid=1&zoneid=1"); # some IDs are depend on your environment.

    # Original Methods
    print $api->url;      # print generated url
    print $api->response; # print API response

=head1 METHODS

This module supports all CloudStack commands,basically you can use methods as following,

$api->some_command("parm1=$parm1&parm2=$parm2")

Please refer B<API Reference> in following B<Developer's Guide:CloudStack>.

L<http://docs.cloud.com/CloudStack_Documentation/Developer%27s_Guide%3A_CloudStack>

Followings are some examples for API command,

=head2 listVirtualMachines

    $api->proc("listVirtualMachines")
    $api->proc("listVirtualMachines","id=$id")

=head2 deployVirtualMachine

    $api->proc("deployVirtualMachine","serviceoffeingid=$serviceoffeingid&templateid=$templateid&zoneid=$zoneid")

=head2 startVirtualMachine/stopVirtualMachine

    $api->proc("startVirtualMachine","id=$id")
    $api->proc("stopVirtualMachine","id=$id")

Followings are some examples for original command,

=head2 test

    $api->test()

This method prints each defined attributes(base_url,api_path,api_key,secret_key,send_request,xml_json).

=head2 url

    $api->url()

This method prints generated URL that is send to CloudStack API.

=head2 test

    $api->response()

This method prints response from CloudStack API.

=head1 AUTHOR

Shugo Numano, C<< <snumano at cpan.org> >>

@shugonumano

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-cloudstack at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-CloudStack>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::CloudStack


You can also look for information at:

=over 5

=item * Developer's Guide:CloudStack

L<http://docs.cloud.com/CloudStack_Documentation/Developer%27s_Guide%3A_CloudStack>

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-CloudStack>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-CloudStack>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-CloudStack>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-CloudStack/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Shugo Numano.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Net::CloudStack
