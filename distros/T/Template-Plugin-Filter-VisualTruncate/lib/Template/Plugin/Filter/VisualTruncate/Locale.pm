package Template::Plugin::Filter::VisualTruncate::Locale;

use strict;
use warnings;

use base qw( Template::Plugin::Filter );

use locale;
#use POSIX qw(locale_h);
#setlocale(LC_CTYPE, "ja_JP.eucJP");

use Text::CharWidth qw(mbwidth mbswidth mblen);

sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;

    return $self;
}

sub width {
    shift;
    mbswidth(@_);
}

sub trim {
    my ($self, $text, $len) = @_;

    my $cur  = 0;
    my $trim = "";

    return $text if mbswidth($text) <= $len;

    while (length($text) and $len >= (mbwidth($text) + $cur)) {
        $cur  += mbwidth($text);
        $trim .= substr($text, 0, mblen($text));
        $text =  substr($text, mblen($text));
    }

    return $trim;
}

1;
