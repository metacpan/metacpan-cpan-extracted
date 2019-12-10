use strict;

use Devel::Peek;
use FindBin '$Bin';
use Importer 'NewsExtractor::TextUtil' => 'u';

use Test2::V0;

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

done_testing;
