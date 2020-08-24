package NewsExtractor::SiteSpecificExtractor::www_bbc_com;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

use Importer 'NewsExtractor::TextUtil' => 'normalize_whitespace', 'u';

use POSIX qw(strftime);

sub journalist {
    my $self = $_[0];
    my $ret;
    if (my $el = $self->dom->at('div.story-body > div.byline > span.byline__name')) {
        $ret = $el->text;
    }
    return $ret;
}

sub dateline {
    my $self = $_[0];
    my $dateline;
    if (my $el = $self->dom->at('div.date[data-seconds]')) {
        my $epoch = $el->attr("data-seconds");
        $dateline = u(strftime(q(%Y-%m-%dT%H:%M:%S+08:00), gmtime($epoch)));
    }
    return $dateline;
}

1;
