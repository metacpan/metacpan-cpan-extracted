package NewsExtractor::SiteSpecificExtractor::news_cts_com_tw;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

use Importer 'NewsExtractor::TextUtil' => 'normalize_whitespace';

sub journalist {
    my ($self) = @_;

    my @patterns = (
        qr{^(.+?\s*報導\s*/\s*\S+)\s?\n},
        qr<\A (\p{Letter}+? \s+ 採訪/撰稿 \s+ \p{Letter}+? \s+ 攝影/剪輯) \s+ />x,
    );

    my $content_text = $self->content_text;
    my @matched;
    for my $pat (@patterns) {
        @matched = $content_text =~ m/$pat/;
        last if @matched;
    }

    return $matched[0];
}

1;
