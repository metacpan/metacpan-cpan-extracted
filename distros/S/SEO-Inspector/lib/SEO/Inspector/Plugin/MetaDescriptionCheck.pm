package SEO::Inspector::Plugin::MetaDescriptionCheck;

use strict;
use warnings;
use HTML::TreeBuilder;

sub new { bless {}, shift }

sub name { 'MetaDescriptionCheck' }

sub run {
    my ($self, $html) = @_;

    my $tree = HTML::TreeBuilder->new;
    $tree->parse_content($html);

    # Find <meta name="description"> safely
    my $meta_content;
    for my $el ($tree->find_by_tag_name('meta')) {
        next unless defined $el->attr('name') && $el->attr('name') eq 'description';
        $meta_content = $el->attr('content');
        last;
    }

    $tree->delete;

    if ($meta_content) {
        return { status => 'ok', notes => 'meta description present' };
    }

    return { status => 'warn', notes => 'missing meta description' };
}

1;
