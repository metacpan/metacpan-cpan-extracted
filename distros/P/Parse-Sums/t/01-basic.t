#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Parse::Sums qw(parse_sums);

subtest "basics" => sub {
    my $content = <<'_';
a14ce3f6c428695e95567979d9cc70a1  1

5bbf5a52328e7439ae6e719dfe712200  file 2)

_
    my $res = parse_sums(content => $content, filename=>"MD5SUMS");
    is_deeply(
        $res,
        [200, "OK", [
            {linenum=>1, algorithm=>'md5', file=>'1', digest=>'a14ce3f6c428695e95567979d9cc70a1'},
            {linenum=>3, algorithm=>'md5', file=>'file 2)', digest=>'5bbf5a52328e7439ae6e719dfe712200'},
        ], {}],
    ) or diag explain $res;
};

subtest "BSD format" => sub {
    my $content = <<'_';
MD5 (1) = a14ce3f6c428695e95567979d9cc70a1

MD5 (file 2)) = 5bbf5a52328e7439ae6e719dfe712200

_
    my $res = parse_sums(content => $content, filename=>"MD5SUMS");
    is_deeply(
        $res,
        [200, "OK", [
            {linenum=>1, algorithm=>'md5', file=>'1', digest=>'a14ce3f6c428695e95567979d9cc70a1'},
            {linenum=>3, algorithm=>'md5', file=>'file 2)', digest=>'5bbf5a52328e7439ae6e719dfe712200'},
        ], {}],
    ) or diag explain $res;
};

subtest "unknown algo from guess" => sub {
    my $content = <<'_';
a14c  1

_
    my $res = parse_sums(content => $content);
    is_deeply(
        $res,
        [200, "OK", [
        ], {'func.warning' => '1 line is improperly formatted'}],
    ) or diag explain $res;
};

subtest "guessed algo doesn't match algo hint from filename" => sub {
    my $content = <<'_';
a14ce3f6c428695e95567979d9cc70a1  1

_
    my $res = parse_sums(content => $content, filename => 'SHA1SUMS');
    is_deeply(
        $res,
        [200, "OK", [
        ], {'func.warning' => '1 line is improperly formatted'}],
    ) or diag explain $res;
};

subtest "mixed algos allowed when filename doesn't contain algo hint" => sub {
    my $content = <<'_';
a14ce3f6c428695e95567979d9cc70a1  1

1e7720a3460b8a84ac4ba27880d64526a3872f1c  file 2)

_
    my $res = parse_sums(content => $content);
    is_deeply(
        $res,
        [200, "OK", [
            {linenum=>1, algorithm=>'md5', file=>'1', digest=>'a14ce3f6c428695e95567979d9cc70a1'},
            {linenum=>3, algorithm=>'sha1', file=>'file 2)', digest=>'1e7720a3460b8a84ac4ba27880d64526a3872f1c'},
        ], {}],
    ) or diag explain $res;
};

subtest "mixed algos not allowed when filename contains algo hint" => sub {
    my $content = <<'_';
a14ce3f6c428695e95567979d9cc70a1  1

1e7720a3460b8a84ac4ba27880d64526a3872f1c  file 2)

_
    my $res = parse_sums(content => $content, filename=>'SHA1SUMS');
    is_deeply(
        $res,
        [200, "OK", [
            {linenum=>3, algorithm=>'sha1', file=>'file 2)', digest=>'1e7720a3460b8a84ac4ba27880d64526a3872f1c'},
        ], {'func.warning' => '1 line is improperly formatted'}],
    ) or diag explain $res;
};

done_testing;
