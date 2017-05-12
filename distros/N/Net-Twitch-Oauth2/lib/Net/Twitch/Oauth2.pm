package Net::Twitch::Oauth2;
 
use strict;
use warnings;
use LWP::UserAgent;
use URI;
use URI::Escape;
use JSON::Any;
use Carp;
 
use constant ACCESS_TOKEN_URL => 'https://api.twitch.tv/kraken/oauth2/token';
use constant AUTHORIZE_URL => 'https://api.twitch.tv/kraken/oauth2/authorize';
 
our $VERSION = '0.06';
 
sub new {
    my ($class,%options) = @_;
    my $self = {};
    $self->{options} = \%options;
     
    if (!$options{access_token}){
        croak "You must provide your application id when construct new method\n EPI::Twitch::Oauth2->new( application_id => '...' )" unless defined $self->{options}->{application_id};
        croak "You must provide your application secret when construct new method\n EPI::Twitch::Oauth2->new( application_secret => '...' )" unless defined $self->{options}->{application_secret};
    }
     
    $self->{browser}          = $options{browser} || LWP::UserAgent->new;
    $self->{access_token_url} = $options{access_token_url} || ACCESS_TOKEN_URL;
    $self->{authorize_url}    = $options{authorize_url} || AUTHORIZE_URL;
    $self->{access_token}     = $options{access_token};
     
    return bless($self, $class);
}
 
sub get_authorization_url {
    my ($self,%params) = @_;
     
    $params{callback} ||= $self->{options}->{callback};
    croak "You must pass a callback parameter with Oauth v2.0" unless defined $params{callback};
     
    my $scope = join(",", @{$params{scope}}) if defined($params{scope});
     
    my $url = $self->{authorize_url}
    .'?response_type=code'
    .'&client_id='
    .uri_escape($self->{options}->{application_id})
    .'&redirect_uri='
    .uri_escape($params{callback});
     
    $url .= "&scope=$scope" if $scope;
    
    return $url;
}
 
sub post_access_token {
    my ($self,%params) = @_;
    $params{callback} ||= $self->{options}->{callback};
    $params{code} ||= $self->{options}->{code};
     
    croak "You must pass a code parameter with Oauth v2.0" unless defined $params{code};
    croak "You must pass callback URL" unless defined $params{callback};
    $self->{options}->{code} = $params{code};
     
    ###generating access token URL
    my $getURL = $self->{access_token_url}
    .'?client_id='
    .uri_escape($self->{options}->{application_id})
    .'&client_secret='
    .uri_escape($self->{options}->{application_secret})
    .'&grant_type=authorization_code'
    .'&redirect_uri='
    .uri_escape($params{callback})
    .'&code='
    .uri_escape($params{code});
     
    my $response = $self->{browser}->post($getURL);
     
    ##got an error response from twitch
    ##die and display error message
    my $j = JSON::Any->new;
    if (!$response->is_success){
        my $error = $j->jsonToObj($response->content());
        croak "'" .$error->{error}->{type}. "'" . " " .$error->{error}->{message};
    }
     
    ##everything is ok proccess response and extract access token
    my $reply = $j->jsonToObj($response->content());
    my $token = $reply->{access_token};
    my $expires = $reply->{refresh_token};
     
    ###save access token
    if ($token){
        $self->{access_token} = $token;
        return $token;
    }
     
    croak "can't get access token";
}
  
sub get {
    my ($self,$url,$params) = @_;
    unless ($self->_has_access_token($url)) {
        croak "You must pass access_token" unless defined $self->{access_token};
        $url .= $self->{_has_query} ? '&' : '?';
        $url .= "oauth_token=" . $self->{access_token};
    }
     
    ##construct the new url
    my @array;
     
    while ( my ($key, $value) = each(%{$params})){
        $value = uri_escape($value);
        push(@array, "$key=$value");
    }
 
    my $string = join('&', @array);
    $url .= "&".$string if $string;
     
    my $response = $self->{browser}->get($url);
    my $content = $response->content();
    return $self->_content($content);
}
 
sub post {
    my ($self,$url,$params) = @_;
    unless ($self->_has_access_token($url)) {
        croak "You must pass access_token" unless defined $self->{access_token};
        $params->{oauth_token} = $self->{access_token};
    }
    my $response = $self->{browser}->post($url,$params);
    my $content = $response->content();
    return $self->_content($content);
}
 
sub delete {
    my ($self,$url,$params) = @_;
    unless ($self->_has_access_token($url)) {
        croak "You must pass access_token" unless defined $self->{access_token};
        $params->{oauth_token} = $self->{access_token};
    }
    my $response = $self->{browser}->delete($url,$params);
    my $content = $response->content();
    return $self->_content($content);
}
 
sub as_hash {
    my ($self) = @_;
    my $j = JSON::Any->new;
    return $j->jsonToObj($self->{content});
}
 
sub as_json {
    my ($self) = @_;
    return $self->{content};
}
 
sub _content {
    my ($self,$content) = @_;
    $self->{content} = $content;
    return $self;
}
 
sub _has_access_token {
    my ($self, $url) = @_;
    my $uri = URI->new($url);
    my %q = $uri->query_form;
    #also check if we have a query and save result
    $self->{_has_query} = $uri->query();
    if (grep { $_ eq 'oauth_token' } keys %q) {
        return 1;
    }
    return;
}
 
1;
