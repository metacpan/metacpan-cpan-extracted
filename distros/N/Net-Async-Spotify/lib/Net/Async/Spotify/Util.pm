package Net::Async::Spotify::Util;

use strict;
use warnings;

our $VERSION = '0.001'; # VERSION
our $AUTHORITY = 'cpan:VNEALV'; # AUTHORITY

use Log::Any qw($log);
use Syntax::Keyword::Try;

use Exporter 'import';
our @EXPORT_OK = qw(response_object_map);

=encoding utf8

=head1 NAME

    Net::Async::Spotify::Util - Helper class for some common functions.

=head1 DESCRIPTION

Helper class that will have some functions that are general and can be used across library.

=cut

# TODO: Make it our, and allow permenant type set.
my %uri_responses = (
    'https://api.spotify.com/v1/artists/{id}/albums' => 'Album',
    'https://api.spotify.com/v1/me/player/devices'   => 'Devices',
);

=head1 METHODS

=head2 response_object_map

Due to the unstructured response details in Spotify documentation page in regards they type of response for every request.
This method will act as a reliable mapping for Spotify API responses to their desired Objects type.
Takes:

=over 4

=item available_types

which consists of the availabe Object types that are loaded by Caller.

=item response_hash

which consists of possible `response_objs` types and `uri` that was  called for this response.

=back

It uses smart matching mechanism; meaning that first it will check if that Spotify uri has a specific retun type
set in C<%uri_responses> hash, if nothing is set for the uri. It will check C<@$possible_types> passed by
trying to find for the exact Object name, if not  found it will get the first object that includes the passed name
as part of it's own name.
It will return the Object class name if found, and `undef` when it can't find a suitable object.

=cut

sub response_object_map {
    my ($available_types, $res_hash) = @_;

    my $possible_types = $res_hash->{response_objs};
    my $for_uri = $res_hash->{uri};
    $log->tracef('Got response object to map. Possible_types: %s | for_uri: %s', $possible_types, $for_uri);
    return undef if scalar(@$possible_types) == 0 and !exists $uri_responses{$for_uri};

    my $possible_name;
    unless ( exists $uri_responses{$for_uri} ) {
        my $possible_t = $possible_types->[0];
        #my $type = ($possible_t =~ /^[^\s]+/);
        my @type = split ' ', $possible_t;
        # Search for exact first, then check composite ones.
        ($possible_name) = grep { /^$type[0]$/i } @$available_types;
        ($possible_name) = grep { /$type[0]/gi } @$available_types unless defined $possible_name;
    } else {
       $possible_name = $uri_responses{$for_uri};
    }

    return undef unless defined $possible_name;
    return join '::', 'Net::Async::Spotify::Object', $possible_name;
}

1;
