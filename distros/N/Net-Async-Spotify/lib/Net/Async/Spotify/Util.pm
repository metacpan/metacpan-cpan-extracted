package Net::Async::Spotify::Util;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION
our $AUTHORITY = 'cpan:VNEALV'; # AUTHORITY

use utf8;

use Log::Any qw($log);
use Syntax::Keyword::Try;
use List::Util qw(first);
use Data::Dumper;
use Data::Dumper::AutoEncode;
use Perl::Tidy;

use Exporter 'import';
our @EXPORT_OK = qw(response_object_map hash_to_string);

=encoding utf8

=head1 NAME

    Net::Async::Spotify::Util - Helper class for some common functions.

=head1 DESCRIPTION

Helper class that will have some functions that are general and can be used across library.

=cut

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

It uses smart matching mechanism; meaning that it will check C<@$expected> passed by
trying to find for the exact Object name, if not  found it will get the first object that includes the passed name
as part of it's own name.
It will return the Object class name if found, and `undef` when it can't find a suitable object.

=cut

sub response_object_map {
    my ($available_types, $expected) = @_;
    my @available_types = $available_types->@*;

    return undef if scalar(@$expected) == 0;

    my $possible_name;
    my $possible_t = $expected->[0];
    #my $type = ($possible_t =~ /^[^\s]+/);
    my @type = split ' ', $possible_t;
    # Search for exact first, then check composite ones.
    $possible_name = first { /^$type[0]$/i } @available_types;
    $possible_name = first { /$type[0]/gi } @available_types unless defined $possible_name;

    return undef unless defined $possible_name;
    return join '::', 'Net::Async::Spotify::Object', $possible_name;
}

=head2 hash_to_string

Not so proper way to stringify a Hash.
Used to make Hash printable and readable to human.

=cut

sub hash_to_string {
        local $Data::Dumper::Terse    = 1;
        local $Data::Dumper::Indent   = 0;
        local $Data::Dumper::Sortkeys = sub {
            [sort {
                if ( $b eq 'type' )        {1}
                elsif ( $a eq 'type' )     {-1}
                elsif ( $b eq 'position' ) {1}
                elsif ( $a eq 'position' ) {-1}
                else                       { $a cmp $b }
            } keys %{ $_[0] }];
        };
        my $source = eDumper(@_);
        my $result;
        Perl::Tidy::perltidy(
                source      => \$source,
                destination => \$result,
                argv        => [qw(-pbp -nst)]
        );
        return $result;
}

1;
