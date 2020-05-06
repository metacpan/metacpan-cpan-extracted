package NewsExtractor;
our $VERSION = v0.20.0;
use Moo;

use Mojo::UserAgent;
use Mojo::UserAgent::Transactor;
use Try::Tiny;

use Types::Standard qw< Str >;
use Types::URI qw< Uri >;

use Importer 'NewsExtractor::TextUtil' => qw(u);
use NewsExtractor::Error;
use NewsExtractor::Download;

has url => ( required => 1, is => 'ro', isa => Uri, coerce => 1 );

has user_agent_string => (
    required => 1,
    is => 'ro',
    isa => Str,
    default => sub {
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.14; rv:75.0) Gecko/20100101 Firefox/75.0'
    }
);

sub download {
    my NewsExtractor $self = shift;

    my $ua = Mojo::UserAgent->new()->transactor(
        Mojo::UserAgent::Transactor->new()->name( $self->user_agent_string )
    )->max_redirects(3);

    my ($error, $download);

    my $tx = $ua->get( "". $self->url );

    my $res;
    try {
        $res = $tx->result
    } catch {
        $error = NewsExtractor::Error->new(
            is_exception => 0,
            message => u($_),
        )
    };

    if ($res) {
        if ($res->is_error) {
            $error = NewsExtractor::Error->new(
                is_exception => 0,
                message => u($res->message),
            );
        } else {
            $download = NewsExtractor::Download->new( tx => $tx );
        }
    }
    return ($error, $download);
}

1;

__END__

=head1 NAME

NewsExtractor - download and extract news articles from Internet.

=head1 SYNOPSIS

    my ($error, $article) = NewsExtractor->new( url => $url )->download->parse;
    die $error if $error;

    # $article is an instance of NewsExtractor::Article
    say "Headline: " . $article->headline;
    say "When: " . ($article->dateline // "(unknown)");
    say "By: " . ($article->journalist // "(unknown)");
    say "\n" . $article->article_body;

=head1 SEE Also

L<NewsExtractor::Article>

=head1 AUTHOR

Kang-min Liu <gugod@gugod.org>

=head1 LICENSE

To the extent possible under law, Kang-min Liu has waived all copyright and related or neighboring rights to NewsExtractor. This work is published from: Taiwan.

https://creativecommons.org/publicdomain/zero/1.0/

=cut
