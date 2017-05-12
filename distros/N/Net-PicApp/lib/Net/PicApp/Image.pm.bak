package Net::PicApp::Image;

use strict;
use base qw(Class::Accessor);

my @FIELDS = qw(authorId category imageTitle color description imageHeight imageWidth horizontal illustration imageId panoramic photographerName thumbnailHeight thumbnailWidth urlImageFullSize urlImageThumbnail vertical);

Net::PicApp::Image->mk_accessors(@FIELDS);

sub new {
    my $class = shift;
    my ($xml) = @_;
    my $self = {};
    $self->{struct} = $xml;
    foreach (@FIELDS) {
        $self->{$_} = $xml->{$_};
    }
    bless $self, $class;
    return $self;
}

sub urlImageThumbnail {
    my $self = shift;
    return $self->{struct}->{urlImageThumnail};
}

sub thumbnails {
    my $self = shift;
    my @thumbs;
    foreach (@{$self->{struct}->{urlImageDefinedThumbnails}}) {
        push @thumbs, $_->{content};
    }
    return \@thumbs;
}

1;
