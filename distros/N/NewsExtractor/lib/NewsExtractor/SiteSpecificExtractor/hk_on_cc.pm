package NewsExtractor::SiteSpecificExtractor::hk_on_cc;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

use Importer 'NewsExtractor::TextUtil'  => qw(u normalize_whitespace);

sub dateline {
    my ($self) = @_;
    my $el = $self->dom->at('div.toolBar > span.datetime') or return;

    my @t = split /[^0-9]+/, normalize_whitespace($el->all_text);
    return u(
        sprintf(
            '%04d-%02d-%02dT%02d:%02d:%02d+08:00',
            $t[0], $t[1], $t[2], $t[3], $t[4],
            0
        )
    );
}

1;
