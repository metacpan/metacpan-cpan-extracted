package NewsExtractor::SiteSpecificExtractor::talk_ltn_com_tw;
use utf8;
use Moo;
extends 'NewsExtractor::JSONLDExtractor';

with 'NewsExtractor::Role::ContentTextExtractor';

sub journalist {
    my ($self) = @_;
    my $el = $self->dom->at('div.writer > a:nth-child(1)') or return;
    return $el->attr('data-desc');
}

1;
