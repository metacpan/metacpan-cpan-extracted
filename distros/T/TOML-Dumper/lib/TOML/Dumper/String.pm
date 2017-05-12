package TOML::Dumper::String;
use strict;
use warnings;

sub escape {
    for (@_) {
        s!\x5C!\\!xmgo;  # backslash       (U+005C)
        s!\x08!\\b!xmgo; # backspace       (U+0008)
        s!\x09!\\t!xmgo; # tab             (U+0009)
        s!\x0A!\\n!xmgo; # linefeed        (U+000A)
        s!\x0C!\\f!xmgo; # form feed       (U+000C)
        s!\x0D!\\r!xmgo; # carriage return (U+000D)
        s!\x22!\\"!xmgo; # quote           (U+0022)
        s!\x2F!\\/!xmgo; # slash           (U+002F)
    }
    return wantarray ? @_ : $_[-1];
}

sub quote {
    my $value = shift;
    $value = escape($value);
    return qq{"""\n$value"""} if $value =~ s/\\n/\x0A/msg;
    return qq{"$value"};
}

1;
__END__
