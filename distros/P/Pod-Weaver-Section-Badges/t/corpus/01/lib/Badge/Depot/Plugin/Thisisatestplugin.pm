use 5.10.1;
use strict;
use warnings;

package Badge::Depot::Plugin::Thisisatestplugin;

# VERSION

use Moose;
use Types::Standard qw/Str HashRef/;
use Path::Tiny;
with 'Badge::Depot';

has user => (
    is => 'ro',
    isa => Str,
);
has repo => (
    is => 'ro',
    isa => Str,
);
has version => (
    is => 'ro',
    isa => Str,
    lazy => 1,
    default => sub {
        my $self = shift;
        if($self->get_meta('version')) {
            return $self->_meta->{'version'};
        }
    },
);
has _meta => (
    is => 'ro',
    isa => HashRef,
    lazy => 1,
    traits => ['Hash'],
    builder => '_build_meta',
    handles => {
        get_meta => 'get',
    },
);

sub _build_meta {
    my $self = shift;

    if($self->has_zilla) {
        return {
            dist => $self->zilla->name,
            version => $self->zilla->version,
        };
    }

    return {} if !path('META.json')->exists;

    my $json = path('META.json')->slurp_utf8;
    my $data = decode_json($json);

    return {} if !exists $data->{'name'} || !exists $data->{'version'};

    return {
        dist => $data->{'name'},
        version => $data->{'version'},
    };
}
sub BUILD {
    my $self = shift;

    $self->link_url(sprintf 'https://example.com/%s/%s/%s' => $self->user, $self->repo, $self->version);
    $self->image_url(sprintf 'https://example.com/%s/%s.svg' => $self->user, $self->repo);
}

1;
