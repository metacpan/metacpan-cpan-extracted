package Net::PicApp::Image;

use strict;
use base qw(Class::Accessor);

my @FIELDS =
  qw(authorId category imageTitle color description imageHeight imageWidth horizontal illustration imageId panoramic photographerName thumbnailHeight thumbnailWidth urlImageFullSize vertical imageDate imageContributorName contributorUrl categoryName publishPageLink available_thumbnails);

Net::PicApp::Image->mk_accessors(@FIELDS);

sub new {
    my $class = shift;
    my ($xml) = @_;
    my $self  = {};
    $self->{struct} = $xml;
    foreach (@FIELDS) {
        if ($xml->{$_}) {
            $self->{$_} = $xml->{$_};
        }
    }
    $self->{'description'} = $xml->{'imageDescription'} if $xml->{'imageDescription'};
    $self->{'category'} = $xml->{'categoryId'} if $xml->{'categoryId'};
    if ($xml->{'keyword_En_Us'}) {
        my $keys = $xml->{'keyword_En_Us'}->{'keyword'};
        my @kws = ref $keys eq 'ARRAY' ? @{ $keys } : ( $keys );
        $self->{'keywords'} = \@kws;
    }
    if ($xml->{'urlImageDefinedThumbnails'} && $xml->{'urlImageDefinedThumbnails'}->{'imagethumbnails'} ne 'missing thumbnails') {
        my $thumbs;
        foreach my $t (@{$xml->{'urlImageDefinedThumbnails'}->{'imagethumbnails'}}) {
            $thumbs->{ $t->{'ThumbSize'} } = $t->{'content'};
        }
        $self->{'available_thumbnails'} = $thumbs; 
    }
    bless $self, $class;
    return $self;
}

sub keywords {
    my $self = shift;
    if ($_[0]) {
        $self->{'keywords'} = @_;
    }
    my @kws = @{ $self->{'keywords'} };
    return wantarray ? @kws : $kws[0];
}

sub urlImageThumbnail {
    my $self = shift;
    return $self->{struct}->{urlImageThumnail};
}

sub thumbnails {
    my $self = shift;
    my @thumbs;
    foreach ( @{ $self->{struct}->{urlImageDefinedThumbnails} } ) {
        push @thumbs, $_->{content};
    }
    return \@thumbs;
}

1;
