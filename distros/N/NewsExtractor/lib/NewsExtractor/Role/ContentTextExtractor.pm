package NewsExtractor::Role::ContentTextExtractor;
use utf8;
use Moo::Role;

use Types::Standard qw(Str Maybe);
use List::Util qw(max);
use HTML::ExtractContent;

use Importer 'NewsExtractor::TextUtil'  => qw( html2text );
use Importer 'NewsExtractor::Constants' => qw( %RE );

has site_name => (
    is => "lazy",
    isa => Maybe[Str],
);

has content_text => (
    is => "lazy",
    isa => Maybe[Str],
);

sub _build_site_name {
    my ($self) = @_;

    my $el = $self->dom->at("meta[property='og:site_name']");
    if ($el) {
        return $el->attr('content');
    }

    return undef;
}

sub _build_content_text {
    my ($self) = @_;
    my ($el, $html);

    # Cleanup some noisy elements that are known to interfere.
    $self->dom->find('script, style, p.appE1121, div.sexmask, div.cat-list, div#marquee, #setting_weather')->map('remove');

    my $extractor = HTML::ExtractContent->new;
    if ($el = $self->dom->at('article')) {
        $html = $extractor->extract("$el")->as_html;
    } else {
        $html = $extractor->extract( $self->dom->to_string )->as_html;
    }

    my $text = html2text( $html );

    my @paragraphs = split(/\n\n/, $text) or return undef;

    if (my $site_name = $self->site_name) {
        $paragraphs[-1] =~ s/\A \s* \p{Punct}? \s* ${site_name} \s* \p{Punct}? \s* \z//x;
        $paragraphs[-1] =~ s/${site_name}//x;
    }

    $paragraphs[-1] =~ s/\A \s* \p{Punct}? \s* $RE{newspaper_names} \s* \p{Punct}? \s* \z//x;

    if (max( map { length($_) } @paragraphs ) < 30) {
        # err "[$$] Not enough contents";
        return undef;
    }

    return join "\n\n", @paragraphs;
}

1;
