package NewsExtractor::SiteSpecificExtractor::www_hkcna_hk;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

use Importer 'NewsExtractor::TextUtil'  => qw(u normalize_whitespace);

sub dateline {
    my ($self) = @_;
    my $el = $self->dom->at('div#time p:nth-child(1)') or return;
    $el->find('strong')->map('remove');
    my @t = normalize_whitespace($el->all_text) =~ m/([0-9]+)/g;
    return u( sprintf('%04d-%02d-%02dT%02d:%02d:%02d+08:00', $t[0], $t[1], $t[2], $t[3], $t[4], 59) );
}

sub journalist {
    my ($self) = @_;
    my $el = $self->dom->at('div.content div.fdr') or return;
    return normalize_whitespace($el->all_text);
}

1;
