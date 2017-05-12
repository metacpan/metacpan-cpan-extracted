package Serengeti::Backend::Native::Transport::Curl;

use strict;
use warnings;

use HTTP::Response;
use URI::Escape qw(uri_escape);
use WWW::Curl::Easy;

use Serengeti::Backend::Native qw($UserAgent %DefaultHeaders);

use accessors::ro qw(curl);

sub new {
    my ($pkg) = @_;
    
    my $curl = WWW::Curl::Easy->new();

    $curl->setopt(CURLOPT_HEADER, 1);
    $curl->setopt(CURLOPT_FOLLOWLOCATION, 0);
    $curl->setopt(CURLOPT_SSL_VERIFYPEER, 0);
    $curl->setopt(CURLOPT_USERAGENT, $UserAgent);
    $curl->setopt(CURLOPT_COOKIEJAR, '/dev/null');
    
    my $self = bless { curl => $curl }, $pkg;

    return $self;
}

sub _setup_curl {
    my ($curl, $options) = @_;
    
    my @headers = map { "$_: $DefaultHeaders{$_}" } keys %DefaultHeaders;
    $curl->setopt(CURLOPT_HTTPHEADER, \@headers);
    
    if ($options->{referrer}) {
        $curl->setopt(CURLOPT_REFERER, $options->{referrer});
    }
    
    return $curl;
}

sub get {
    my ($self, $url, $query_params, $options) = @_;

    my $curl = _setup_curl($self->curl, $options);
    
    $url = URI->new($url);
    
    $query_params = {} unless ref $query_params eq "HASH";
    if ($query_params) {
        my %old_params = $url->query_form();
        $old_params{$_} = $query_params->{$_} for keys %$query_params;
        $url->query_form(\%old_params);
    }

    $curl->setopt(CURLOPT_URL, $url->as_string);
    $curl->setopt(CURLOPT_HTTPGET, 1);
    
    # Target for request
    my $response_body;
    open my $fileb, ">", \$response_body or die "Can't open scalar: $!";
    $curl->setopt(CURLOPT_WRITEDATA,$fileb);

    # Perform request
    my $retcode = $curl->perform();
    
    # Successful request
    unless ($retcode == 0) {
        die $curl->strerror($retcode);
    }
    
    my $response = HTTP::Response->parse($response_body);
    return $response;
}

sub post {
    my ($self, $url, $form_data, $options) = @_;

    my $curl = _setup_curl($self->curl);
    
    $url = URI->new($url);

    $curl->setopt(CURLOPT_URL, $url->as_string);
    
    # Post data
    my $content = join "&", map { 
        uri_escape($_) . "=" . uri_escape($form_data->{$_})
    } keys %$form_data;
    $curl->setopt(CURLOPT_VERBOSE, 1);
    $curl->setopt(CURLOPT_POSTFIELDSIZE, bytes::length($content));
	$curl->setopt(CURLOPT_POSTFIELDS, $content);
#	print STDERR "Content is: $content\n";
    
    # Target for request
    my $response_body;
    open my $fileb, ">", \$response_body or die "Can't open scalar: $!";
    $curl->setopt(CURLOPT_WRITEDATA,$fileb);

    # Perform request
    my $retcode = $curl->perform();
    
    # Successful request
    unless ($retcode == 0) {
        die $curl->strerror($retcode);
    }
 #   print STDERR "Got: \n", $response_body, "\n";
    my $response = HTTP::Response->parse($response_body);
    return $response;
}

1;
__END__