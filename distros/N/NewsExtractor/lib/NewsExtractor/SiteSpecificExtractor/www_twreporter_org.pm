package NewsExtractor::SiteSpecificExtractor::www_twreporter_org;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

use Importer 'NewsExtractor::TextUtil' => 'u';

sub dateline {
    my ($self) = @_;
    my $el = $self->dom->at('meta[itemprop=dateModified][content]') or return;

    my $dateline;
    if (my ($y,$m,$d) = $el->attr('content') =~ m/([0-9]{4})\.([0-9]{1,2})\.([0-9]{1,2})/) {
        $dateline = u(sprintf('%04d-%02d-%02d', $1, $2, $3));
    }

    return $dateline;
}

sub journalist {
    my ($self) = @_;
    my $txt = $self->dom->find('span[class^="metadata__AuthorName"]')->map('all_text')->uniq()->join('、');
    return u($txt);
}

1;
