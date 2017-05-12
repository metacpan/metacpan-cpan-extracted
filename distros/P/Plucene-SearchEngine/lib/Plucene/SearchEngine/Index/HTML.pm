package Plucene::SearchEngine::Index::HTML;
use base 'Plucene::SearchEngine::Index::Base';
use HTML::TreeBuilder;
__PACKAGE__->register_handler("text/html", ".html");

=head1 NAME

Plucene::SearchEngine::Index::HTML - Backend for simply parsing HTML

=head1 DESCRIPTION

This backend analysis a HTML file for the following Plucene fields:

=over 3

=item text

The text part of the HTML

=item link

A list of links in the HTML

=back

Additionally, any C<META> tags are turned into Plucene fields.

=cut

sub gather_data_from_file {
    my ($self, $filename) = @_;
    my $tree = HTML::TreeBuilder->new;
    $tree->parse_file($filename);
    for($tree->look_down(_tag => "meta")) {
        next if $_->attr("http-equiv");
        next unless $_->attr("value");
        $self->add_data($_->attr("name"), "Text", $_->attr("value"));
    }
    for (@{$tree->extract_links("a")}) {
        $self->add_data("link", "Text", $_->[0]);
    }
    $self->add_data("text", "UnStored", $tree->as_trimmed_text);
    return $self;
}

1;
