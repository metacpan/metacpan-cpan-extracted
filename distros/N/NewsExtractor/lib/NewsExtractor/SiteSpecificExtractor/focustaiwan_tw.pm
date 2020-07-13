package NewsExtractor::SiteSpecificExtractor::focustaiwan_tw;
use utf8;
use Moo;
extends 'NewsExtractor::GenericExtractor';

use Importer 'NewsExtractor::TextUtil' => qw(u normalize_whitespace);

sub dateline {
    my ($self) = @_;

    # Example: <div class="updatetime">07/10/2020 10:59 PM</div>
    my $dateline = $self->dom->at('div.updatetime')->all_text;
    my @t = $dateline =~ m/([0-9]+)/g;
    $t[3] += 12 if $dateline =~ /PM\z/;

    return u(sprintf(
        '%04d-%02d-%02dT%02d:%02d:%02d+08:00',
        $t[2], # year
        $t[0], # month
        $t[1], # mday
        $t[3], # hour
        $t[4], # minute
        59,    # sec
    ));
}

sub journalist {
    my ($self) = @_;
    my $el = $self->dom->at('div.author > p') or return;
    return $el->all_text =~ s/\s*\(By\s+(.+)\)\s*/$1/r;
}

1;
