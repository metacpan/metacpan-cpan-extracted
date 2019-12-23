package NewsExtractor::TextUtil;
use strict;
use warnings;

our @EXPORT = (
    'u',
    'normalize_whitespace',
);

sub u($) {
    my $v = "".$_[0];
    utf8::upgrade($v) unless utf8::is_utf8($v);
    return $v;
}

sub normalize_whitespace {
    local $_ = $_[0];
    s/\h+/ /g;
    s/\r\n/\n/g;
    s/\A\s+//;
    s/\s+\z//;
    return $_;
}

1;
