package Plucene::SearchEngine::Index::RSS;
use base 'Plucene::SearchEngine::Index::Base';
__PACKAGE__->register_handler(qw( rss rdf application/rss+xml application/rdf+xml ));
use 5.006;
use strict;
use warnings;
use XML::RSS;
use Date::Parse;
our $VERSION = '0.02';

sub gather_data_from_file {
    my ($self, $filename) = @_;
    my $xml = XML::RSS->new;
    eval{  $xml->parsefile($filename) }; return if $@;
    my @articles;
    my $x;
    for my $art_xml (@{$xml->{'items'}}) {
        my $art = (ref $self)->new; 
        $art->add_data("modified", "Date", 
            Time::Piece->new(str2time(
                $art_xml->{dc}{date} || $xml->{dc}{date} ||
                $xml->channel("pubDate")
            ))
        );
        if ($art_xml->{dc}{creator}) {
            $art->add_data("creator", "Text", $art_xml->{dc}{creator});
        }
        $art->add_data("feed", "Text", $xml->channel("title"));
        $art->add_data("id", "Keyword", $art_xml->{link}." in ".$self->{id}{data}[0]);
        $art->add_data("text", "UnStored", $art_xml->{description}
            || $art_xml->{"http://purl.org/rss/1.0/modules/content/"}{encoded}
        );
        $art->add_data("title", "Text", $art_xml->{title});
        push @articles, $art;
    }
    return @articles;
}

=head1 NAME

Plucene::SearchEngine::Index::RSS - Index RSS files

=head1 SYNOPSIS

    my @articles = Plucene::SearchEngine::Index::URL->(
        "http://planet.perl.org/rss10.xml"
    );
    $indexer->index($_->document) for @articles;

=head1 DESCRIPTION

This examines RSS files and creates document hashes for individual items
in the feed. The objects have the following Plucene fields:

=over 3

=item modified

The date that this article was published.

=item creator

The creator, if one was specified.

=item feed

The name of the feed from which this was taken.

=item id

The URL that the article links to, and the URL of the feed.

=item text

The text of the article.

=item title

The title of the article.

=back

=head1 WARNING

Since C<Plucene::SearchEngine::Index> uses MIME types to determine the
type of a file, this module doesn't work particularly well using the
C<File> frontend. It works OK with the C<URL> frontend if the webserver
sends the right content type header. If not, you may have to fudge it by
registering your own handlers:

    Plucene::SearchEngine::Index::RSS->register_handler("text/xml");
    # For instance

=head1 SEE ALSO

L<Plucene::SearchEngine::Index>.

=head1 AUTHOR

Simon Cozens, E<lt>simon@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Simon Cozens

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
