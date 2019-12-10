package NewsExtractor::CSSExtractor;
use v5.18;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

use Types::Standard qw( InstanceOf );

has css_selector => (
    required => 1,
    is => 'ro',
    isa => InstanceOf['NewsExtractor::ExtractableWithCSS']
);

sub headline {
    my ($self) = @_;
    return $self->dom->at( $self->css_selector->headline )->text;
}

sub dateline {
    my ($self) = @_;
    return $self->dom->at( $self->css_selector->dateline )->text;
}

sub journalist {
    my ($self) = @_;
    return $self->dom->at( $self->css_selector->journalist )->text;
}

sub content_text {
    my ($self) = @_;
    return $self->dom->at( $self->css_selector->content_text )->text;
}

1;
