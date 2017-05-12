package Net::Google::AuthSub::Response;

use strict;
our $AUTOLOAD;

=head1 NAME

Net::Google::AuthSub::Response - a response from a Net::Google::AuthSub request

=head1 SYNOPSIS

    my $response = $auth->login($user, $pass);
    
    if ($response->is_success) {
        print "Yay!\n";
    } else {
        if ($response->error eq 'CaptchaRequired') {
            print "Captcha Image ".$response->captchaurl;
        }
    }

=head1 METHODS

=cut

=head2 new C<HTTP::Response> C<base url>

Create a new response.

=cut

sub new {
    my ($class, $response, $url, %opts) = @_;

    
    my %values;
    if ($opts{_compat}->{json_response}) {
        eval 'use JSON::Any';
        die "You need to install JSON::Any to use JSON responses" if $@;
        %values = %{JSON::Any->from_json($response->content)};
    } else {
        foreach my $line (split /\n/, $response->content) {
            chomp($line);
            my ($key, $value) = split '=', $line;
            $values{lc($key)} = $value;
        }
    }    

    return bless { _response => $response, _values => \%values, _url => $url }, $class;

}


=head2 is_success 

Returns whether the response was a sucess or not.

=cut

sub is_success {
    my $self = shift;
    return $self->{_response}->is_success;
}

=head1 SUCCESS METHODS

Methods available if the response was a success.

=head2 auth

The authorisation token if the response is a success.

=head2 sid

Not used yet.

=head2 lsid

Not used yet.


=head1 ERROR METHODS

Methods available if the response was an error.

=head2 error

The error code. Can be one of

=over 4

=item BadAuthentication     

The login request used a username or password that is not recognized.

=item NotVerified     

The account email address has not been verified. The user will need to 
access their Google account directly to resolve the issue before logging 
in using a non-Google application.

=item TermsNotAgreed     

The user has not agreed to terms. The user will need to access their 
Google account directly to resolve the issue before logging in using a 
non-Google application.

=item CaptchaRequired     

A CAPTCHA is required. (A response with this error code will also 
contain an image URL and a CAPTCHA token.)

=item Unknown     

The error is unknown or unspecified; the request contained invalid input 
or was malformed.

=item AccountDeleted     

The user account has been deleted.

=item AccountDisabled     

The user account has been disabled.

=item ServiceDisabled     

The user's access to the specified service has been disabled. (The user 
account may still be valid.)

=item ServiceUnavailable     

The service is not available; try again later.

=back

=head2 url

The url of a page describing the error.

=head2 captchatoken

The token required to authenticate a captcha.

=head2 captchaurl

The full url of the captcha image.

=cut

sub captchaurl {
    my $self = shift;
    my $url  = $self->{_values}->{captchaurl};
    return $self->{url}."/accounts/$url";
}

sub AUTOLOAD {
    my $self = shift;

    my $type = ref($self)
            or die "$self is not an object";

    my $name = $AUTOLOAD;
    $name =~ s/.*://;   # strip fully-qualified portion

    if (@_) {
        return $self->{_values}->{$name} = shift;
    } else {
        return $self->{_values}->{$name};
    }
}

sub DESTROY {}  

1;
