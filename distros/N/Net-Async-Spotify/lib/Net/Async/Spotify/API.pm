package Net::Async::Spotify::API;

use strict;
use warnings;

our $VERSION = '0.001'; # VERSION
our $AUTHORITY = 'cpan:VNEALV'; # AUTHORITY

use Future::AsyncAwait;

use Scalar::Util qw(isweak weaken);
use Module::Runtime qw(require_module);

=encoding utf8

=head1 NAME

    Net::Async::Spotify::API - Common Wrapper Package for Spotify API Classes.

=head1 SYNOPSIS

Created to give you back Generic Spotify API wrapper.
Not to be used by itself, as in Net::Async::Spotify object must be present.

    use Net::Async::Spotify;
    use Net::Async::Spotify::API;

    my $spotify = Net::Async::Spotify->new;
    my $api = Net::Async::Spotify::API->new(
        spotify => Net::Async::Spotify->new, # Required
        apis    => [qw(albums tracks)],      # optional
    );

    ref($api->albums); # Net::Async::Spotify::API::Albums

    # However the way it should be used is the following:

    my $spotify = Net::Async::Spotify->new(..., apis =>  [qw(albums tracks)]);
    # With apis being optional, and if not set all APIs classes will be present.
    $spotify->api->player->skip_users_playback_to_next_track->get();

=head1 DESCRIPTION

Common Wrapper class to be used in order to give you access for all available Spotify APIs
It will create an instance for the requested API when invoked.
also you can limit which APIs you want to be available by passing them in C<apis>

=head1 METHODS

=head2 new

Initiate Spotify API Common wrapper. Accepts:

=over 4

=item spotify

C<Net::Async::Spotify> object must be passed.

=item apis

arrayref of the needed Spotify APIs to be availabe, if not passed will define all available APIs.

=back

=cut

sub new {
    my ($class, %args) = @_;
    die "Net::Async::Spotify has to be provided" unless $args{spotify} and $args{spotify}->isa('Net::Async::Spotify');
    my $apis = delete $args{apis} || [qw(albums artists browse episodes follow library markets personalization player playlists search shows tracks users)];
    my $self = bless \%args, $class;
    weaken($self->{spotify}) unless isweak($self->{spotify});
    $self->prepare_apis($apis);

    return $self;
}

sub spotify { shift->{spotify} }

sub prepare_apis {
    my ($self, $apis) = @_;

    for ( @$apis ) {
        my $api = lc $_;
        my $accessor = join '::', ref($self), $api;
        {
            no strict 'refs';
            *{$accessor} = sub {
                my $self = shift;
                # Define when called. And then cache it.
                return $self->{$api} //= do {
                    my $class = join '::', 'Net::Async::Spotify::API', ucfirst $api;
                    require_module($class);
                    # Note its not weak anymore, since passing a copy.
                    $class->new(spotify => $self->spotify);
                };
            };
        }
    }
}

1;

=head1 APIs

List of available APIs for Spotify. Official list found here L<https://developer.spotify.com/documentation/web-api/reference/#reference-index>
These are the defined classes for them:

=over 4

=item *

L<Net::Async::Spotify::API::Albums>

=item *

L<Net::Async::Spotify::API::Artists>

=item *

L<Net::Async::Spotify::API::Base>

=item *

L<Net::Async::Spotify::API::Browse>

=item *

L<Net::Async::Spotify::API::Episodes>

=item *

L<Net::Async::Spotify::API::Follow>

=item *

L<Net::Async::Spotify::API::Library>

=item *

L<Net::Async::Spotify::API::Markets>

=item *

L<Net::Async::Spotify::API::Personalization>

=item *

L<Net::Async::Spotify::API::Player>

=item *

L<Net::Async::Spotify::API::Playlists>

=item *

L<Net::Async::Spotify::API::Search>

=item *

L<Net::Async::Spotify::API::Shows>

=item *

L<Net::Async::Spotify::API::Tracks>

=item *

L<Net::Async::Spotify::API::Users>

=back

=cut
