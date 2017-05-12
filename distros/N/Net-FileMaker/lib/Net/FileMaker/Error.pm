package 
    Net::FileMaker::Error;

use strict;
use warnings;

=head1 NAME

Net::FileMaker::Error - Error strings and codes

=head1 SYNOPSIS

Classes within this namespace store the applicable error codes, and the
localised strings for them. You don't call these modules yourself directly. To
enable them, the key "error" must be defined as an ISO 639 short code when you
construct your objects with L<Net::FileMaker> or a subclass that handles
individual interface types like so:

    use Net::FileMaker;
    my $fms = Net::FileMaker->new(host => $host, error => 'en');

=head1 LANGUAGES SUPPORTED

English, Italian, Japanese and German are presently supported with the aims of
covering all languages documented by FileMaker in the future.

=cut

# new( lang => $lang, type => $type)
#
# Creates a new object. There is no inheritance in the Error classes, mearly
# factory objects.  Both the language (in ISO 639) and type (XML/XSLT/IWP etc)
# needs be defined. Returns undef if fails to load the strings.
sub new
{
    my($class, %args) = @_;

    if($args{lang} ne '' && $args{type} ne '')
    {
        #TODO: Look at Module::Load instead?
        my $class   = "Net/FileMaker/Error/".uc($args{lang})."/".uc($args{type}).'.pm';
        my $package = "Net::FileMaker::Error::".uc($args{lang})."::".uc($args{type});
        require $class;
        #TODO: try/catch if the sub class exists?
        return $package->new;
    }
    else
    {
        return;
    }
    
}

1; # End of Net::FileMaker::Error
