package 
    Net::FileMaker::Error::EN::XSLT;

use strict;
use warnings;

=head1 NAME

Net::FileMaker::Error::EN::XML - Error strings for FileMaker Server XSLT interface in English.

=head1 INFO

The error codes supported by this module were plucked from the FileMaker documentation on XML/XSLT, and appear valid for FileMaker Server 10.

=head1 SEE ALSO

L<Net::FileMaker::Error>

=cut

my $error_codes = {

    '-1'    => "Unknown error",
    0   => "No error",
    10000   => "Invalid header name",
    10001   => "Invalid HTTP status code",
    10100   => "Unknown session error",
    10101   => "Requested session name is already used",
    10102   => "Session could not be accessed - maybe it does not exist",
    10103   => "Session has timed out",
    10104   => "Specified session object does not exist",
    10200   => "Unknown messaging error",
    10201   => "Message formatting error",
    10202   => "Message SMTP fields error",
    10203   => "Message “To Field” error",
    10204   => "Message “From Field” error",
    10205   => "Message “CC Field” error",
    10206   => "Message “BCC Field” error",
    10207   => "Message “Subject Field” error",
    10208   => "Message “Reply-To Field” error",
    10209   => "Message body error",
    10210   => "Recursive mail error - attempted to call send_email() inside an email XSLT stylesheet",
    10211   => "SMTP authentication error - either login failed or wrong type of authentication provided",
    10212   => "Invalid function usage - attempted to call set_header(), set_status_code() or set_cookie() inside an email XSLT stylesheet",
    10213   => "SMTP server is invalid or is not working.",
    10300   => "Unknown formatting error",
    10301   => "Invalid date time format",
    10302   => "Invalid date format",
    10303   => "Invalid time format",
    10304   => "Invalid day format",
    10305   => "Improperly formatted date time string",
    10306   => "Improperly formatted date string",
    10307   => "Improperly formatted time string",
    10308   => "Improperly formatted day string",
    10309   => "Unsupported text encoding",
    10310   => "Invalid URL encoding",
    10311   => "Regular expression pattern error"
    
};

sub new
{
    my $class = shift;
    $class = ref($class) || $class;

    my $self = { };
    return bless $self, $class;
}

sub get_string
{
    my ($self, $error_code) = @_;
    return $error_codes->{$error_code};
}

1; # End of Net::FileMaker::Error::EN::XSLT
