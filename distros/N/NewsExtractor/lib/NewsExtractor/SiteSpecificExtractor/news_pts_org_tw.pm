package NewsExtractor::SiteSpecificExtractor::news_pts_org_tw;
use utf8;
use Moo;

extends 'NewsExtractor::JSONLDExtractor';
with 'NewsExtractor::Role::ContentTextExtractor';

use HTML::ExtractContent;
use Importer 'NewsExtractor::TextUtil' => ('html2text', 'reformat_dateline');
use Importer 'Ref::Util' => ('is_hashref');

sub journalist {
    my ($self) = @_;
    my $name;
    my $author = $self->schema_ld->{author};
    if (is_hashref($author) && exists($author->{"name"})) {
        $name = $author->{"name"};
    } else {
        $name = $author;
    }
    return $name;
}

around dateline => sub {
    my $orig = shift;
    my $ret = $orig->(@_);
    return reformat_dateline($ret, '+08:00');
};

around '_build_content_text', sub {
    my $orig = shift;
    my ($self) = @_;

    if (my $el = $self->dom->at('article.post-article')) {
        my $extractor = HTML::ExtractContent->new;
        my $html = $extractor->extract("$el")->as_html;
        my $text = html2text( $html );
        return $text;
    }

    return $orig->($self);
};

1;
