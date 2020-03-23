use Test2::V0;

use FindBin '$Bin';
use Importer 'NewsExtractor::TextUtil' => 'u';

subtest "Read from a plain file handle" => sub {
    open my $fh, '<', $Bin . '/data/strs.txt';

    while (<$fh>) {
        chomp;
        my $s1 = $_;
        my $s2 = u($_);

        ok ! utf8::is_utf8($s1);
        ok utf8::is_utf8($s2);
    }

    close($fh);
};

subtest "Read from a file handle with utf8 mode" => sub {
    open my $fh, '<:utf8', $Bin . '/data/strs.txt';

    while (<$fh>) {
        chomp;
        my $s1 = $_;
        my $s2 = u($_);
        ok utf8::is_utf8($s1);
        ok utf8::is_utf8($s2);
    }

    close($fh);
};

subtest "string literals under the scope of utf8 pragma." => sub {
    use utf8;
    ok utf8::is_utf8( u("你好") );
    ok utf8::is_utf8( u("123")  );
    ok utf8::is_utf8( u(u("123")) );

    for my $v (qw(你好 Hello 123)) {
        ok utf8::is_utf8($v);
        my $s = u($v);
        ok utf8::is_utf8($s);
        ok utf8::is_utf8(u($s));
    }
};

subtest "string literals under the scope without utf8 pragma." => sub {
    no utf8;
    ok utf8::is_utf8( u("你好") );
    ok utf8::is_utf8( u("123")  );
    ok utf8::is_utf8( u(u("123")) );
    for my $v (qw(你好 Hello 123)) {
        ok ! utf8::is_utf8($v);
        my $s = u($v);
        ok utf8::is_utf8($s);
        ok utf8::is_utf8(u($s));
    }
};

done_testing;
