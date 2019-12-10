package NewsExtractor::Download;
use v5.18;
use Moo;
use Types::Standard qw< InstanceOf >;

has tx => ( required => 1, is => 'ro', isa => InstanceOf['Mojo::Transaction::HTTP']);

use NewsExtractor::Article;
use NewsExtractor::Extractor;
use NewsExtractor::Error;
use Importer 'NewsExtractor::TextUtil' => qw(u);

use Try::Tiny;

sub parse {
    my $self = $_[0];
    my ($err, $o);

    my $x = NewsExtractor::Extractor->new( tx => $self->tx );
    my %article;
    $article{headline}     = $x->headline;
    $article{article_body} = $x->content_text;

    for my $it (qw(dateline journalist)) {
        my $v = $x->$it;
        if (defined($v)) {
            $article{$it} = $v;
        }
    }

    for my $it (qw(headline article_body)) {
        unless(defined($article{$it})) {
            $err = NewsExtractor::Error->new(
                message => u("Failed to extract: $it")
            )
        }
    }
    return ($err, undef) if $err;

    try {
        $o = NewsExtractor::Article->new(%article);
    } catch {
        my $e = $_;

        if (ref($e) && $e->isa('Error::TypeTiny::Assertion')) {
            $e = $e->message;
        }

        $err = NewsExtractor::Error->new(
            message => u($e),
            debug   => { articleArgs => \%article },
        );
    };

    return ($err, $o);
}

1;
