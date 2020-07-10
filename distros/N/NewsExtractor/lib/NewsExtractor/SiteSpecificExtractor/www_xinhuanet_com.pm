package NewsExtractor::SiteSpecificExtractor::www_xinhuanet_com;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

use Importer 'NewsExtractor::TextUtil'  => qw(u normalize_whitespace);

sub dateline {
    my ($self) = @_;
    my $el = $self->dom->at('.h-info > .h-time') or return;

    my @t = split /[^0-9]+/, normalize_whitespace($el->all_text);
    return u(
        sprintf(
            '%04d-%02d-%02dT%02d:%02d:%02d+08:00',
            $t[0], $t[1], $t[2], $t[3], $t[4], $t[5]
        )
    );
}

1;
