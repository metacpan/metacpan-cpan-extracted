package Net::Linkedin::OAuth2;

use strict;
use warnings;
use JSON::Any;
use LWP::UserAgent;
use Carp 'confess';
use XML::Hash;
use Digest::MD5 'md5_hex';

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.32';


=head1 NAME

Net::Linkedin::OAuth2 - An easy way to authenticate users via LinkedIn.

=head1 VERSION

version 0.32

=head1 SYNOPSIS

my $linkedin = Net::Linkedin::OAuth2->new( key => 'your-app-key', secret	=> 'your-app-secret');
	                                  
=head2 get authorization url({ redirect_uri => 'http://localhost:3000/user/linkedin', scope => ['r_basicprofile','rw_groups','r_emailaddress']})

# scope is an array of permissions that your app requires, see http://developer.linkedin.com/documents/authentication#granting for more details, this field is optional

my $authorization_code_url = $linkedin->authorization_code_url(
    redirect_uri => 'url_of_your_app_to_intercept_success', 
    scope    => ['r_basicprofile','rw_groups','r_emailaddress'] 
);

# convert code response to an access token
# redirect_uri is the url where you will check for the parameter code.
# param('code') is the parameter 'code' that you will get after the user authorizes your app and gets redirected to the redirect_uri (callback) page.
 
my $token_object = $linkedin->get_access_token( 	
	authorization_code => param('code'), 
	redirect_uri =>       'your-app-redirect-url-or-callback'
);
	    
# use the new token to request user information

my $result = $linkedin->request(
	url    => 'https://api.linkedin.com/v1/people/~:(id,formatted-name,picture-url,email-address)?format=json',
	token  => $token_object->{access_token} 
);
	
# we have the email address			
if ($result->{emailAddress}) {
	# ...
}

# Or here is an entire login logic or recipe:

	my $linkedin = Net::Linkedin::OAuth2->new( key => 'your-app-key',
	                                   secret => 'your-app-secret');
	
	
	# catch the code param and try to convert it into an access_token and get the email address
	if (param('code')) {

	    my $token_object = $linkedin->get_access_token(
		    authorization_code => param('code'),
		    # has to be the same redirect_uri you specified in the code before
		    redirect_uri =>       'your-app-redirect-uri-or-callback-url'
	    );
	    
	    my $result = $linkedin->request(
	    	url    => 'https://api.linkedin.com/v1/people/~:(id,formatted-name,picture-url,email-address)?format=json',
		 	token  => $token_object->{access_token} );

		if ($result->{emailAddress}) {
			# we have the email address, authenticate the user and redirect somewhere..
			# ....
			
			return;
		} else {
			# we did not get an email address
			# redirect to try again?
			
			return;
		}
	    
	}
	
	# get the url for permissions
	
	my $authorization_code_url = $linkedin->authorization_code_url(
		# this field is required
	    redirect_uri => 'your-app-redirect', 
	    #array of permissions that your app requires, see http://developer.linkedin.com/documents/authentication#granting for more details, this field is optional
	    scope    => ['r_basicprofile','rw_groups','r_emailaddress'] 
	);
	
	#redirect the user to get their permission
	redirect($authorization_code_url);

	# and catch an error back from linked in
	if (param('error')) {
	    # handle the error
	    # if the user denied, redirect to try again...
	}
    
=head1 SEE ALSO


	http://developer.linkedin.com/documents

=head1 AUTHOR

Asaf Klibansky

discobeta@gmail.com

=head1 METHODS


=head2 authorization_code_url( { redirect_uri => '...', scope => '...'} )

=over

B<Definition:> This method is used to get the url required to authenticate the 
user via LinkedIn OAuth2.
I<It assumes that you have a linkedin api key and secret which you may obtain 
here https://www.linkedin.com/secure/developer.>  Basically this builds the 
url where you should redirect the user to obtain their permission to access 
certain information (scope) on linkedin.

B<Accepts:> a hash or hashref of arguments.  They must include the 
necessary information to build the url.  
I<redirect_url> is a url where the user should be redirect to after successfuly
authorizing (or not) and should be a method ready to capture the 'code' or 
'error' parameters.'
I<scope> scope is an array of permissions that your app requires, 
see http://developer.linkedin.com/documents/authentication#granting for 
more details, this field is optional

B<Returns:> This will return a string containing the url where the user should 
be redirect to in order to obtain their linkedin permissions.
=back

=cut

sub authorization_code_url {
    my ($self, %args) = @_;
    foreach(qw( redirect_uri )) {
        confess "Required '$_' was not specified" unless $args{$_};
    }
    return "https://www.linkedin.com/uas/oauth2/authorization?response_type=code&client_id=$self->{key}&scope=".join('+',$self->{scope})."&state=".rand()."&redirect_uri=$args{redirect_uri}";
}
=back

=head2 get_access_token( { authorization_code => '...', redirect_uri => '...'} )

=over

B<Definition:> This method is used to convert the parameter 'code' that we
got from facebook after obtaining the user permissions into an access token 
that we can later use to access the LinkedIn API.

B<Accepts:> a hash or hashref of arguments.  They must include the 
necessary information to convert the code.  
I<authorization_code> is the parameter linkedin provided you with after 
successfully obtaining a user's permission. 
I<redirect_uri> is a url where the user should be redirect to after successfuly
authorizing (or not) and should be a method ready to capture the 'code' or 
'error' parameters.'

B<Returns:> This will return a hash containing an access_token and an expires_in keys and values

=back

=cut

sub get_access_token {
    my ($self, %args) = @_;   
    foreach(qw( authorization_code redirect_uri )) {
	confess "Required '$_' was not specified" unless $args{$_};
    }
    my $r = $self->{class}->get("https://api.linkedin.com/uas/oauth2/accessToken?grant_type=authorization_code&code=$args{authorization_code}&redirect_uri=$args{redirect_uri}&client_id=$self->{key}&client_secret=$self->{secret}");
    if (!$r->is_success){
        my $j = JSON::Any->new;
        my $error = $j->jsonToObj($r->content());
    }
    my $file = $r->content();
    my $j = JSON::Any->new;
    my $res = $j->jsonToObj($r->content());
    return $res;    
}



=head2 new( { key => '...', secret => '...', scope => ['...'] } )

=over

B<Definition:> This method is used to convert the parameter 'code' that we
got from facebook after obtaining the user permissions into an access token 
that we can later use to access the LinkedIn API.

B<Accepts:> a hash or hashref of arguments.  They must include the 
necessary information to convert the code.  
I<key> is the key linkedin provided you with when you create an app. See
 https://www.linkedin.com/secure/developer for more details.
I<secret> is tha app secret that linkedin provided you with when you create 
an app.
I<scope> scope is an array of permissions that your app requires, 
see http://developer.linkedin.com/documents/authentication#granting for 
more details, this field is optional

B<Returns:> This will create an interface to the linked in API

=back

=cut

sub new {
    my ($class, $args) = @_;
    my $self = bless {}, $class;
    $self->{class} = LWP::UserAgent->new(
		params => $args,
	);
    $self->{ params }  = $args;
    $self->{ key }     = $args->{'key'};
    $self->{ secret }  = $args->{'secret'};
    my @e;
    for (my $n=0; $n <= 2; $n++) {
        push @e, $args->{'scope'}[$n];
    }
    $self->{ scope }   = join('+',@e);
    return $self;
}



=head2 request( { url => '...', token => '...' } )

=over

B<Definition:> This method is used to access the linkedin api.

B<Accepts:> a hash or hashref of arguments.  They must include the 
necessary information to convert the code.  
I<url> is the linkedin API url to access. See
 https://developer.linkedin.com/docs for more details.
I<token> is a valid token that you retrieved from a successful 
linkedin authentication.

B<Returns:> This will return a scalar with the results from a given url

=back

=cut

sub request {
    my ($self, %args) = @_;
    foreach(qw( url token )) {
        confess "Required '$_' was not specified" unless $args{$_};
    }
    my $url;
    if ($args{url} =~ /\?/) {
		$url = "$args{url}&oauth2_access_token=$args{token}";
    } else {
		$url = "$args{url}?oauth2_access_token=$args{token}";
    }
    my $r = $self->{class}->get($url);
    if (!$r->is_success){
        my $j = XML::Hash->new();
        my $error = $j->fromXMLStringtoHash($r->content());
    }
    my $j = JSON::Any->new;
    return $j->jsonToObj( $r->content() );
}

1;

