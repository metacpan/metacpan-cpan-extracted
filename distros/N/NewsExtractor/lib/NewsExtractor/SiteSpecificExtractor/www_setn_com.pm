package NewsExtractor::SiteSpecificExtractor::www_setn_com;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

use Importer 'NewsExtractor::TextUtil' => 'normalize_whitespace';

sub journalist {
    my ($self) = @_;
    my $content_text = $self->content_text;

    my @patterns = (
        qr{\b記者\s*([\p{Letter}、]+?)\s*／\s*(?:\p{Letter}+?)報導\b},
        qr{\b文／([\p{Letter}、]+)\b},
        qr{\b (?:三立準氣象 | \p{Letter}{2} 中心) ／ (\p{Letter}+?) 報導\b}x,
    );

    my $name;

    for my $pat (@patterns) {
        ($name) = $content_text =~ $pat;
        last if defined $name;
    }

    return $name && normalize_whitespace($name);
}

1;
