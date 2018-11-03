package Net::OpenStack::Client::API;
$Net::OpenStack::Client::API::VERSION = '0.1.4';
use strict;
use warnings;

use Net::OpenStack::Client::API::Convert qw(process_args);
use Net::OpenStack::Client::API::Magic qw(retrieve);

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

    my ($self, @args) = @_;

    my ($cmd, $fail);
    my $api_pattern = "^${API_METHOD_PREFIX}([^_]+)_(.*)\$";
    if (!defined($self->{versions})) {
        $fail = "no versions specified";
    } elsif ($called =~ m/$api_pattern/) {
        ($cmd, $fail) = retrieve($1, $2, $self->{versions}->{$1});
    } else {
        # TODO:
        #    Add support for guessing the service based on service + API version attribute
        my $versions_txt = join(",", map {"$_=$self->{versions}->{$_}"} sort keys %{$self->{versions}});
        $fail = "only $API_METHOD_PREFIX methods supported versions $versions_txt";
    }

    if ($fail) {
        die "Unknown Net::OpenStack::Client::API method: '$called' failed $fail (from original $called_orig)";
    } else {
        # Run the expected method.
        # AUTOLOAD with glob assignment and goto defines the autoloaded method
        # (so they are only autoloaded once when they are first called),
        # but that breaks inheritance.

        if (ref($cmd->{code}) eq 'CODE') {
            return $cmd->{code}->($self, @args);
        } else {
            return $self->rest(process_args($cmd, @args));
        }
    }
}


1;
