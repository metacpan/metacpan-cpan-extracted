use Test2::V0 -no_utf8 => 1;

use Importer 'NewsExtractor::TextUtil' => qw(u);
use NewsExtractor::Types qw(is_Text);

subtest "Strings without control characters" => sub {
    for my $v ("123", "中央社", "123 中央社", "你好\n世界") {
        utf8::upgrade($v);
        ok is_Text($v), "is Text: $v";
        utf8::downgrade($v);
        ok !is_Text($v), "is not Text: $v";
    }
};

subtest "String with control characters" => sub {
    for my $v ("你好\t世界", "你好\x07世界") {
        utf8::upgrade($v);
        ok !is_Text($v), "is not Text: $v";
        utf8::downgrade($v);
        ok !is_Text($v), "is not Text: $v";
    }
};

subtest "In combination with `u`" => sub {
    subtest "... without utf8 pragma" => sub {
        no utf8;

        ok is_Text(u("世界"));
        ok is_Text(u("World"));

        for my $v (qw(你好 Hello 123)) {
            ok ! is_Text($v);
            ok is_Text(u($v));
        }
    };

    subtest "... with utf8 pragma" => sub {
        use utf8;

        for my $v (qw(你好 Hello 123)) {
            ok is_Text($v);
            ok is_Text(u($v));
        }
    };
};

done_testing;
