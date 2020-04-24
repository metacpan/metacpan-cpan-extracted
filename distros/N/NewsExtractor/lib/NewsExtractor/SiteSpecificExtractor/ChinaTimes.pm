package NewsExtractor::SiteSpecificExtractor::ChinaTimes;
use utf8;
use Moo;
extends 'NewsExtractor::JSONLDExtractor';

use Importer 'NewsExtractor::TextUtil'  => qw( html2text );

sub content_text {
    my ($self) = @_;
    # my $text = $self->schema_ld->{articleBody} // $self->schema_ld->{description} // '';
    my $body = $self->tx->result->dom->at("div.article-body");
    $body->find(".article-hash-tag")->map('remove');
    my $text = html2text( $body->content );
    return $text;
}

1;
