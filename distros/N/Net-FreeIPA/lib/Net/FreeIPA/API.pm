package Net::FreeIPA::API;
$Net::FreeIPA::API::VERSION = '3.0.3';
use strict;
use warnings;

use Net::FreeIPA::API::Convert qw(process_args);
use Net::FreeIPA::API::Magic qw(retrieve);

our $AUTOLOAD;

use Readonly;

Readonly our $API_METHOD_PREFIX => 'api_';

# This will add all AUTOLOADable functions as methods calls
# So only AUTOLOAD method with command name prefixed
# with api_, returns a C<$api_method> call

sub AUTOLOAD
{
    my $called = $AUTOLOAD;

    # Don't mess with garbage collection!
    return if $called =~ m{DESTROY};

    my $called_orig = $called;
    $called =~ s{^.*::}{};

    my ($cmd, $fail);
    my $api_pattern = "^$API_METHOD_PREFIX";
    if ($called =~ m/$api_pattern/) {
        $called =~ s{$api_pattern}{};

        ($cmd, $fail) = retrieve($called);
    } else {
        $fail = "only $API_METHOD_PREFIX methods supported";
    }

    if ($fail) {
        die "Unknown Net::FreeIPA::API method: $called failed $fail (from original $called_orig)";
    } else {
        # Run the expected method.
        # AUTOLOAD with glob assignment and goto defines the autoloaded method
        # (so they are only autoloaded once when they are first called),
        # but that breaks inheritance.

        # The method name is in the name attribute
        my ($self, @args) = @_;
        return $self->rpc(process_args($cmd, @args));
    }
}


1;
