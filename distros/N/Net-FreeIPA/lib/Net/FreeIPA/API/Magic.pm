package Net::FreeIPA::API::Magic;
$Net::FreeIPA::API::Magic::VERSION = '3.0.3';
use strict;
use warnings;

use Types::Serialiser; # is used by JSON::XS
use JSON::XS;

use Net::FreeIPA::API::Data;

use Readonly;

use base qw(Exporter);

our @EXPORT_OK = qw(retrieve version);

Readonly my $TRUE => Types::Serialiser::true;
Readonly my $FALSE => Types::Serialiser::false;

# Cache these command keys
Readonly::Array our @CACHE_KEYS => qw(
    name
    takes_args takes_options
);

# Cache these keys from the takes_ CACHE_KEYS
Readonly::Array our @CACHE_TAKES_KEYS => qw(
    name type class
    required autofill multivalue
);

Readonly::Hash our %CACHE_TAKES_DEFAULT => {
    autofill => $FALSE,
    class => 'unknown_class',
    multivalue => $FALSE,
    name => 'unknown_name',
    required => $FALSE,
    type => 'unknown_type',
};

# hashref to store cached command data
my $cmd_cache = {};

=head2 Public functions

=over

=item flush_cache

Reset the cache

=cut

sub flush_cache
{
    $cmd_cache = {};
    return $cmd_cache;
}

=item cache

Given C<data> command hashref, cache (and return) the relevant
(filtered) command data.

C<data> is typically the decoded JSON command response.

=cut

sub cache
{
    my ($data) = @_;

    my $name = $data->{name};

    foreach my $key (sort keys %$data) {
        if ($key =~ m/^takes_/) {
            my $newdata = [];
            foreach my $tdata (@{$data->{$key}}) {
                if (ref($tdata) eq '') {
                    my $value = $tdata;
                    $value =~ s/[*+?]$//;
                    $tdata = {%CACHE_TAKES_DEFAULT};
                    $tdata->{name} = $value;
                } else {
                    # Arrayref of command hashrefs
                    foreach my $tkey (sort keys %$tdata) {
                        delete $tdata->{$tkey} if (! grep {$tkey eq $_} @CACHE_TAKES_KEYS);
                    }
                }
                push(@$newdata, $tdata);
            }
            $data->{$key} = $newdata;
        } else {
            delete $data->{$key} if (! grep {$key eq $_} @CACHE_KEYS);
        }
    }

    $cmd_cache->{$name} = $data;

    return $data;
}

=item version

Return the API version from C<Net::FreeIPA::API::Data>

=cut

sub version
{
    return $Net::FreeIPA::API::Data::VERSION;
}

=item retrieve

Retrieve the command data for command C<name>.

(For now, the data is loaded from the C<Net::FreeIPA::API::Data> that is
distributed with this package and is a fixed version only).

Returns the cache command hashref and undef errormessage on SUCCESS,
an emptyhashref and actual errormessage otherwise.
If the command is already in cache, return the cached version
(and undef errormessage).

=cut

sub retrieve
{
    my ($name) = @_;

    # Return already cached data
    return ($cmd_cache->{$name}, undef) if defined($cmd_cache->{$name});

    # Get the JSON data from Net::FreeIPA::API::Data
    # TODO: get the JSON data from the JSON api

    my $data;
    my $json = $Net::FreeIPA::API::Data::API_DATA{$name};
    if (! $json) {
        return {}, "retrieve name $name failed: no JSON data";
    }

    local $@;
    eval {
        $data = decode_json($json);
    };

    if ($@) {
        return {}, "retrieve name $name failed decode_json with $@";
    } else {
        return cache($data), undef;
    };
}

=item all_command_names

Return all possible commandsnames sorted.

Does not update cache.

=cut

# Used mainly to generate the API::Function exports

sub all_command_names
{

    # Get the JSON data from Net::FreeIPA::API::Data
    # TODO: get the JSON data from the JSON api
    # If the JSON API doesn't allow to just get the names,

    return sort keys %Net::FreeIPA::API::Data::API_DATA;
}

=pod

=back

=cut


1;
