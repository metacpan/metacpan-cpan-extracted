package NewsExtractor::Extractor;
use Moo;
use Mojo::Transaction::HTTP;
use Mojo::URL;
use Types::Standard qw(InstanceOf);
use NewsExtractor::ExtractableWithCSS;
use NewsExtractor::CSSExtractor;
use NewsExtractor::GenericExtractor;

has tx => ( required => 1, is => 'ro', isa => InstanceOf['Mojo::Transaction::HTTP'] );

has extractor => (
    required => 0,
    is => 'lazy',
    isa => InstanceOf["NewsExtractor::CSSExtractor",
                      "NewsExtractor::GenericExtractor"],
    builder => 1,
    handles => [qw( headline dateline journalist content_text )],
);

use constant CSSSelectorByHost => {
    'www.enewstw.com' =>  NewsExtractor::ExtractableWithCSS->new(
        headline     => 'td.blog_title > strong',
        dateline     => 'td.blog_title tr:nth-child(2) > td.blog',
        journalist   => 'td.blog_title tr:nth-child(1) > td.blog',
        content_text => 'td.new_t p',
    )
};

sub _build_extractor {
    my ($self) = @_;
    my $url = $self->tx->req->url;
    my $host = $url->host;
    my $extractor;
    if (my $sel = CSSSelectorByHost->{$host}) {
        $extractor = NewsExtractor::CSSExtractor->new(
            css_selector => $sel,
            tx => $self->tx
        );
    } else {
        $extractor = NewsExtractor::GenericExtractor->new( tx => $self->tx );
    }
    return $extractor;
}

1;
