package NewsExtractor::SiteSpecificExtractor::yimedia_com_tw;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

use Importer 'NewsExtractor::TextUtil' => 'normalize_whitespace', 'u';

before 'content_text', sub {
    my ($self) = @_;
    $self->dom->find('figure.fbyt-block')->map('remove');
    if (my $el = $self->dom->at('#penci-post-entry-inner > p:last-of-type')) {
        print $el->content() ."\n";
        if ($el->content() =~ /\A看更多<br>/) {
            $el->remove();
        }
    }
};

sub journalist {
    my $self = $_[0];
    my $ret;
    if (my $el = $self->dom->at('#penci-post-entry-inner > p:nth-child(1)')) {
        if ($el->content() =~ /文字撰稿：(?<name> \p{Letter}+ )<br>/x) {
            ($ret) = $+{"name"};
        }

    }
    return $ret;
}

1;
