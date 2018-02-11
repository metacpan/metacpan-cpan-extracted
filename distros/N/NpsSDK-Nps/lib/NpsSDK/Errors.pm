################################################
package NpsSDK::TimeoutException;

our $VERSION = '1.4'; # VERSION
sub new { 
    my $self = {};
    bless ($self, "NpsSDK::TimeoutException");
    print "Timeout Error \n";
    return $self;
}

sub get_message_error {
    my $self = shift;
    return "A timeout error has ocurred \n";
}

1;

################################################
package NpsSDK::ConnectionException;

sub new { 
    my $self = {};
    bless ($self, "NpsSDK::ConnectionException");
    print "Connection Error \n";
    return $self;
}

sub get_message_error {
    my $self = shift;
    return "Cannot connect to the server \n";
}

1;

################################################
package NpsSDK::UnknownError;

sub new{
    my $self = shift;
    bless ($self, "NpsSDK::UnknownError");
    print "Unknown Error \n";
    return $self;
}

sub get_message_error {
    my $self = shift;
    return "An unknown error has ocurred \n";
}

1;

################################################
package NpsSDK::LogException;

sub error { 
    die "DEBUG level is not allowed on PRODUCTION ENVIRONMENT \n";
}

################################################
package NpsSDK::EnvironmentNotFound;

sub error {
    die "
        The chosen environment is incorrect.
        The right environments are the following:
        0: PRODUCCION
        1: STAGING
        2: SANDBOX        
        \n";
}

1;

################################################
package NpsSDK::IndexError;

sub error {
    die "The environment's index cannot be less than 0 \n";
}

1;

