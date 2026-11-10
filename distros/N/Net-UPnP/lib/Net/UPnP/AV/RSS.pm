package Net::UPnP::AV::RSS;

use strict;
use warnings;
use Encode qw(decode FB_CROAK);

sub _text {
    my ($value) = @_;
    return '' unless defined $value;
    return $value if utf8::is_utf8($value);
    return decode('UTF-8', $value, FB_CROAK);
}

# XML 1.0 text and quoted attributes share these escaping requirements.
# Invalid XML characters have no representable numeric entity: replace them.
sub _escape {
    my ($value) = @_;
    $value = _text($value);
    $value =~ s/[^\x09\x0a\x0d\x20-\x{d7ff}\x{e000}-\x{fffd}\x{10000}-\x{10ffff}]/?/g;
    $value =~ s/&/&amp;/g;
    $value =~ s/</&lt;/g;
    $value =~ s/>/&gt;/g;
    $value =~ s/"/&quot;/g;
    $value =~ s/'/&apos;/g;
    $value =~ s/\r/&#13;/g;
    $value =~ s/\n/&#10;/g;
    $value =~ s/\t/&#9;/g;
    return $value;
}

sub _entity {
    my ($entity) = @_;
    my %named = (amp => '&', lt => '<', gt => '>', quot => '"', apos => "'");
    return $named{$entity} if exists $named{$entity};
    my $hex = $entity =~ s/\A#x//i;
    $entity =~ s/\A#//;
    $entity =~ s/\A0+//;
    return '?' if length($entity) > ($hex ? 6 : 7);
    my $number = $hex ? hex($entity || '0') : 0 + ($entity || '0');
    return '?' if $number > 0x10ffff;
    return chr($number);
}

sub header {
    my (%args) = @_;
    my ($title, $language, $description, $link) =
        map { _escape($args{$_}) } qw(title language description link);
    return <<"RSS";
<?xml version="1.0" encoding="utf-8"?>
<rss xmlns:itunes="http://www.itunes.com/DTDs/Podcast-1.0.dtd" version="2.0">
<channel>
<title>$title</title>
<language>$language</language>
<description>$description</description>
<link>$link</link>
RSS
}

sub item {
    my (%args) = @_;
    # ContentDirectory titles retain one layer of DIDL entities after the
    # outer SOAP Result is decoded. Decode exactly once, then escape as data.
    my $title = _text($args{title});
    $title =~ s/&(#x[0-9a-fA-F]+|#[0-9]+|amp|lt|gt|quot|apos);/_entity($1)/ge;
    $title = _escape($title);
    my $link = _escape($args{link});
    my $size = _escape($args{size});
    return <<"RSS";
<item>
<title>$title</title>
<guid isPermalink="false">$link</guid>
<enclosure url="$link" length="$size" type="video/mp4" />
</item>
RSS
}

1;
