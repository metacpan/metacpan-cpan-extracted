package SEO::Inspector::Plugin::TitleCheck;

use strict;
use warnings;
use HTML::TreeBuilder;

sub new { bless {}, shift }

sub name { 'TitleCheck' }

sub run {
    my ($self, $html) = @_;

    my $tree = HTML::TreeBuilder->new;
    $tree->parse_content($html);

    # Find the <title> element safely
    my $title;
    for my $el ($tree->find_by_tag_name('title')) {
        $title = $el->as_text;
        last;
    }

    $tree->delete;

    if ($title && length $title) {
        return { status => 'ok', notes => 'title present' };
    }

    return { status => 'error', notes => 'missing title' };
}

1;
