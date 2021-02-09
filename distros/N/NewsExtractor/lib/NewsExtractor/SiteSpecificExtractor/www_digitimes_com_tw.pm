package NewsExtractor::SiteSpecificExtractor::www_digitimes_com_tw;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

use Importer 'NewsExtractor::TextUtil'  => qw(u);

sub journalist {
    my ($self) = @_;
    my $el = $self->dom->at('li > time') or return;
    $el = $el->parent->previous->at('span > span');
    return $el->all_text;
}

sub dateline {
    my ($self) = @_;
    my $el = $self->dom->at('li > time') or return;

    my @t = $el->all_text =~ m/([0-9]+)/g;
    return u(
        sprintf(
            '%04d-%02d-%02dT%02d:%02d:%02d+08:00',
            $t[0], $t[1], $t[2], 23, 59, 59
        )
    );
}

1;
