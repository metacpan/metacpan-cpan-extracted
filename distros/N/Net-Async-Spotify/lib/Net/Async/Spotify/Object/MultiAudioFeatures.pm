package Net::Async::Spotify::Object::MultiAudioFeatures;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION
our $AUTHORITY = 'cpan:VNEALV'; # AUTHORITY

use mro;
use parent qw(Net::Async::Spotify::Object::Base);

=encoding utf8

=head1 NAME

Net::Async::Spotify::Object::MultiAudioFeatures - Package representing Spotify Multi Audio Features Object

=head1 DESCRIPTION

This Object is added to have an of Audio Features objects.

=head1 PARAMETERS

Those are Spotify Audio Features Object attributes:

=over 4

=item audio_features

Type:Array[AudioFeaturesObject]
Description:A list of 0..n AudioFeatures objects

=back

=cut

sub new {
    my ($class, %args) = @_;

    my $fields = {
        audio_features => 'Array[AudioFeaturesObject]',
    };

    my $obj = next::method($class, $fields, %args);

    return $obj;
}

1;
