package NewsExtractor::SiteSpecificExtractor::newtalk_tw;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

use Importer 'NewsExtractor::TextUtil' => 'u';

sub dateline {
    my ($self) = @_;
    my ($el, $dateline);
    if ($el = $self->dom->at('meta[property="article:published_time"]')) {
        $dateline = $el->attr('content');
    } elsif ($el = $self->dom->at('div.contentBox div.content_date')) {
        my @t = $el->all_text =~ m/([0-9]+)/g;
        $dateline = u(sprintf('%04d-%02d-%02dT%02d:%02d:%02d+08:00',
                            $t[0], $t[1], $t[2], $t[3], $t[4], 59));
    }
    return $dateline;
}

1;
