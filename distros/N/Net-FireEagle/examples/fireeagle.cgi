#!/usr/local/bin/perl -w

use strict;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use Net::FireEagle;
use JSON::Any;

my $cgi = CGI->new;

# Obviously this bit is horrifically insecure
# and you would never do it like this
my $user   = $cgi->param('user') || 'simon';
my $file   = ".fireeagle";


my %tokens = Net::FireEagle->load_tokens($file);
my $fe     = Net::FireEagle->new(%tokens);

if ($fe->authorized) {
    my $method = $cgi->param('method') || 'location';
    eval "$method";
}

# We haven't authorized yet so get the authorization url
unless ($cgi->param('oauth_token')) {
    # First get the request token
    my $url = $fe->get_authorization_url();
    # We could pass a param to the callback
    #my $url = $fe->get_authorization_url( oauth_callback => $cgi->url."?rand=".rand() );

    my @cookies;
    foreach my $name (qw(request_token request_token_secret)) {
        my $cookie = $cgi->cookie(-name => $name, -value => $fe->$name);
        push @cookies, $cookie;
    }

    # You could just set the cookies and redirect directly to the url
    print $cgi->header(-cookie=>\@cookies);
    print head("Authorize");
    print "<a href='$url'>Authorize</a>\n";
    print foot();
    exit 0;
# We've been given the request token
} elsif ($cgi->param('oauth_token')) {
    foreach my $name (qw(request_token request_token_secret)) {
        my $value = $cgi->cookie($name);
        $fe->$name($value);
    }
    # Paranoid checking
    die "Request tokens don't match\n" 
        unless $fe->request_token eq $cgi->param('oauth_token');

    # Set the verifier
    $fe->verifier($cgi->param('oauth_verifier'));


    # Get the access token and save the values
    $fe->request_access_token;
    my %tokens = $fe->tokens;
    # Again, this is horrifically insecure
    Net::FireEagle->save_tokens($file, %tokens);

    # Redirect to clear the cruft from the headers
    #print $cgi->redirect($cgi->url);
    location();
}

die "We should never get here\n";

sub recent {
    print $cgi->header;
    print head("Your location");
    my $json = $fe->recent(undef, format => 'json');
    my $obj  = parse_json($json);
    use Data::Dumper;
    print "<pre>".Dumper($obj)."</pre>";
    print foot();
    exit 0;
}

sub location {
    print $cgi->header;
    print head("Your location");
    my $json = $fe->location(format => 'json');
    my $obj  = parse_json($json);
    my $what = $obj->{user}->{location_hierarchy}->[0];
    printf("%s (accuracy level: %s)<br />", $what->{name}, $what->{level_name});
    print foot();
    exit 0;
} 

sub head {
    my $title = shift;
    return "<html>\n<head>\n\t<title>FireEagle - $title</title>\n</head>\n<body>\n"
}

sub foot {
    return "</body>\n</html>\n";
}


sub parse_json {
    my $json = shift;
    die "Couldn't parse blank JSON" unless defined $json and $json !~ m!^\s*$!;
    my $obj  = eval { JSON::Any->new->from_json($json) };
    die $@ if $@;
    die "Couldn't parse JSON for some reason" unless defined $obj;
    return $obj;
}

