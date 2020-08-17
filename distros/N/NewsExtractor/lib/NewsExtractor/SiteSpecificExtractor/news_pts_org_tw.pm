package NewsExtractor::SiteSpecificExtractor::news_pts_org_tw;
use utf8;
use Moo;

extends 'NewsExtractor::JSONLDExtractor';
with 'NewsExtractor::Role::ContentTextExtractor';

use Importer 'NewsExtractor::TextUtil' => ('html2text', 'reformat_dateline');

sub journalist {
    my ($self) = @_;
    return $self->schema_ld->{author};
}

around content_text => sub {
    my $orig = shift;
    my $ret = $orig->(@_);
    return html2text($ret);
};

around dateline => sub {
    my $orig = shift;
    my $ret = $orig->(@_);
    return reformat_dateline($ret, '+08:00');
};

1;
