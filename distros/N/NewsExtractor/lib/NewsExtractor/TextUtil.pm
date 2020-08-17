package NewsExtractor::TextUtil;
use strict;
use warnings;
use Encode qw(is_utf8 decode_utf8);
use Mojo::DOM;

our @EXPORT = (
    'u',
    'normalize_whitespace',
    'html2text',
    'is_empty',
    'parse_dateline_ymdhms',
    'reformat_dateline',
);

sub u($) {
    defined($_[0]) or return undef;

    my $v = "".$_[0];
    return is_utf8($v) ? $v : decode_utf8($v);
}

sub is_empty {
    (! defined($_[0])) || $_[0] eq '';
}

sub normalize_whitespace {
    local $_ = $_[0];
    s/\h+/ /g;
    s/\r\n/\n/g;
    s/\A\s+//;
    s/\s+\z//;
    return $_;
}

sub remove_control_characters {
    local $_ = $_[0];
    s/\p{PosixCntrl}//g;
    return $_;
}

sub html2text {
    my $html = $_[0];

    my $content_dom = Mojo::DOM->new('<body>' . $html . '</body>');
    $content_dom->find('br')->map(replace => "\n");
    $content_dom->find('div,p')->map(append => "\n\n");

    my @paragraphs = grep { $_ ne '' } map { remove_control_characters($_) } map { normalize_whitespace($_) } split /\n\n+/, $content_dom->all_text;

    return join "\n\n", @paragraphs;
}

sub reformat_dateline {
    my ($text, $offset) = @_;
    $offset //= '';

    my @t = $text =~ m/([0-9]+)/g;
    return undef unless 3 <= @t;

    my $format_date = '%04d-%02d-%02d';
    my $format_time = '%02d:%02d:%02d';

    if (@t == 3) {
        my $format = $format_date . '%s';
        return u(sprintf($format, $t[0], $t[1], $t[2], $offset));
    }

    $t[5] //= 0;
    $t[6] //= 0;

    my $format = $format_date . 'T' . $format_time . '%s';
    return u(sprintf($format, $t[0], $t[1], $t[2], $t[3], $t[4], $t[5], $offset));
}

sub parse_dateline_ymdhms {
    my ($text, $offset) = @_;

    $offset //= '';

    my @t = $text =~ m/([0-9]+)/g;
    $t[3] //= 23;
    $t[4] //= 59;
    $t[5] //= 59;

    return u(
        sprintf(
            '%04d-%02d-%02dT%02d:%02d:%02d%s',
            $t[0], $t[1], $t[2], $t[3], $t[4], $t[5], $offset
        )
    );
}

1;
