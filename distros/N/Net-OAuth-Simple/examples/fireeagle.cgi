#!perl -w

use strict;
use lib qw(lib);
use CGI;
use CGI::Carp qw(fatalsToBrowser);

binmode STDOUT, ":utf8";

my $CONFIG = ".fireeagle_config";
my $cgi    = CGI->new;

# Get the tokens from the params, a config file or wherever
my %tokens = get_tokens();
my $app    = FireEagle->new(%tokens);

location() if $app->authorized;

# We haven't authorized yet so get the authorization url
unless ($cgi->param('oauth_token')) {
    # First get the request token
    my $url = $app->get_authorization_url( callback => $cgi->url."?rand=".rand() );

    my @cookies;
    foreach my $name (qw(request_token request_token_secret)) {
        my $cookie = $cgi->cookie(-name => $name, -value => $app->$name);
        push @cookies, $cookie;
    }

    # You could just set the cookies and redirect directly to the url
    print $cgi->header(-cookie=>\@cookies, -charset=>'utf-8');
    print head("Authorize");
    print "<a href='$url'>Authorize</a>\n";
    print foot();
    exit 0;

# We've been given the request token
} elsif ($cgi->param('oauth_token')) {
    foreach my $name (qw(request_token request_token_secret)) {
        my $value = $cgi->cookie($name);
        $app->$name($value);
    }
    # Paranoid checking
    die "Request tokens don't match\n"
        unless $app->request_token eq $cgi->param('oauth_token');

    # Set the verifier
    $app->verifier($cgi->param('oauth_verifier'));


    # Get the access token and save the values
    $app->request_access_token;

    # Again, this is horrifically insecure
    save_tokens($app);

    # Either redirect to clear the cruft from the headers ...
    #print $cgi->redirect($cgi->url);
    # ... or print the location ...
    location();
}

die "We should never get here\n";


sub location {
    print $cgi->header(-charset=>'utf-8');
    print head("Your location");
    my $obj  = $app->location();
    my $what = $obj->{user}->{location_hierarchy}->[0];
    printf("%s (accuracy level: %s)<br />", $what->{name}, $what->{level_name});
    print foot();
    exit 0;
}

sub head {
    my $title = shift;
    return "<html>\n<head>\n\t<meta http-equiv='Content-Type' content='text/html;charset=utf-8' />\n\t<title>FireEagle - $title</title>\n</head>\n<body>\n"
}

sub foot {
    return "</body>\n</html>\n";
}

sub get_tokens {
    my %tokens = FireEagle->load_tokens($CONFIG);
    foreach my $param ($cgi->param) {
        $tokens{$param} = $cgi->param($param);
    }
    return %tokens;
}

sub save_tokens {
    my $app     = shift;
    my %tokens = $app->tokens;
    FireEagle->save_tokens($CONFIG, %tokens);
}

package FireEagle;

use strict;
use base qw(Net::OAuth::Simple);
use JSON::Any;


sub new {
    my $class  = shift;
    my %tokens = @_;
    return $class->SUPER::new( tokens => \%tokens,
                               protocol_version => '1.0a',
                               urls   => {
                                    authorization_url => 'https://fireeagle.yahoo.net/oauth/authorize',
                                    request_token_url => 'https://fireeagle.yahooapis.com/oauth/request_token',
                                    access_token_url  => 'https://fireeagle.yahooapis.com/oauth/access_token',
                               });
}

sub location{
	my $self = shift;
	my $form = shift || "json";
	my $url  = "https://fireeagle.yahooapis.com/api/0.1/user.${form}";
	my $json = $self->_make_restricted_request($url, 'GET');
	return _parse_json($json);
}

sub _parse_json {
    my $json = shift;
    die "Couldn't parse blank JSON" unless defined $json and $json !~ m!^\s*$!;
    my $obj  = eval { JSON::Any->new->from_json($json) };
    die $@ if $@;
    die "Couldn't parse JSON for some reason" unless defined $obj;
    return $obj;
}

sub _make_restricted_request {
    my $self     = shift;
    my $response = $self->make_restricted_request(@_);
    return $response->content;
}


1;

