package Net::Async::Spotify::Object::Generated::LinkedTrack;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION
our $AUTHORITY = 'cpan:VNEALV'; # AUTHORITY

use mro;
use parent qw(Net::Async::Spotify::Object::Base);

=encoding utf8

=head1 NAME

Net::Async::Spotify::Object::Generated::LinkedTrack - Package representing Spotify LinkedTrack Object

=head1 DESCRIPTION

Autogenerated module.
Based on https://developer.spotify.com/documentation/web-api/reference/#objects-index
Check C<crawl-api-doc.pl> for more information.

=head1 PARAMETERS

Those are Spotify LinkedTrack Object attributes:

=over 4

=item external_urls

Type:ExternalUrlObject
Description:Known external URLs for this track.

=item href

Type:String
Description:A link to the Web API endpoint providing full details of the track.

=item id

Type:String
Description:The Spotify ID for the track.

=item type

Type:String
Description:The object type: “track”.

=item uri

Type:String
Description:The Spotify URI for the track.

=back

=cut

sub new {
    my ($class, %args) = @_;

    my $fields = {
        external_urls => 'ExternalUrlObject',
        href => 'String',
        id => 'String',
        type => 'String',
        uri => 'String',
    };

    my $obj = next::method($class, $fields, %args);

    return $obj;
}

1;
