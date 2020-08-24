package NewsExtractor::CSSExtractor;
use v5.18;
use utf8;
use Moo;
extends 'NewsExtractor::TXExtractor';
use Importer 'NewsExtractor::TextUtil'  => qw( normalize_whitespace remove_control_characters );

use Types::Standard qw( InstanceOf );

has css_selector => (
    required => 1,
    is => 'ro',
    isa => InstanceOf['NewsExtractor::CSSRuleSet']
);

sub _take {
    my ($self, $sel) = @_;

    $self->dom->find("$sel style, $sel script")->map('remove');
    my $txt = "". $self->dom->find( $sel )->map('all_text')->join("\n\n");
    return undef if $txt eq '';

    $txt = normalize_whitespace(remove_control_characters($txt));
    $txt =~ s/\s+$//;
    $txt =~ s/^\s+//;
    $txt =~ s/\n\n+/\n\n/g;
    return $txt;
}

sub headline {
    my ($self) = @_;
    my $ret = $self->_take($self->css_selector->headline) or return;
    $ret =~ s/\n/ /g;
    return normalize_whitespace($ret);
}

sub dateline {
    my ($self) = @_;
    my $ret = $self->_take($self->css_selector->dateline) or return;
    $ret =~ s/\n/ /g;
    return normalize_whitespace($ret);
}

sub journalist {
    my ($self) = @_;
    my $ret = $self->_take( $self->css_selector->journalist ) or return;
    $ret =~ s/\n/ /g;
    return normalize_whitespace($ret);
}

sub content_text {
    my ($self) = @_;
    return $self->_take( $self->css_selector->content_text );
}

1;
