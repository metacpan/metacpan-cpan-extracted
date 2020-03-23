package NewsExtractor::TextUtil;
use strict;
use warnings;
use Encode qw(is_utf8 decode_utf8);
use Mojo::DOM;

our @EXPORT = (
    'u',
    'normalize_whitespace',
    'html2text',
);

sub u($) {
    my $v = "".$_[0];
    return is_utf8($v) ? $v : decode_utf8($v);
}

sub normalize_whitespace {
    local $_ = $_[0];
    s/\h+/ /g;
    s/\r\n/\n/g;
    s/\A\s+//;
    s/\s+\z//;
    return $_;
}

sub html2text {
    my $html = $_[0];

    my $content_dom = Mojo::DOM->new('<body>' . $html . '</body>');
    $content_dom->find('br')->map(replace => "\n");
    $content_dom->find('div,p')->map(append => "\n\n");

    my @paragraphs = grep { $_ ne '' } map { normalize_whitespace($_) } split /\n\n+/, $content_dom->all_text;

    return join "\n\n", @paragraphs;
}

1;
