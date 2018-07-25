our $VERSION = '1.9'; # VERSION

################################################
package NpsSDK::TimeoutException;

sub new { 
    my $self = {};
    bless ($self, "NpsSDK::TimeoutException");
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

