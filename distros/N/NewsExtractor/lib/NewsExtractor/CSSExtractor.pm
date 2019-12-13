package NewsExtractor::CSSExtractor;
use v5.18;
use utf8;
use Moo;
extends 'NewsExtractor::TXExtractor';

use Types::Standard qw( InstanceOf );

has css_selector => (
    required => 1,
    is => 'ro',
    isa => InstanceOf['NewsExtractor::CSSRuleSet']
);

sub _take {
    my ($self, $sel) = @_;
    my $txt = "". $self->dom->find( $sel )->map('all_text')->join("\n\n");
    $txt =~ s/\s+$//;
    $txt =~ s/^\s+//;
    return $txt;
}

sub headline {
    my ($self) = @_;
    return $self->_take($self->css_selector->headline);
}

sub dateline {
    my ($self) = @_;
    return $self->_take( $self->css_selector->dateline );
}

sub journalist {
    my ($self) = @_;
    return $self->_take( $self->css_selector->journalist );
}

sub content_text {
    my ($self) = @_;
    return "". $self->_take( $self->css_selector->content_text );
}

1;
