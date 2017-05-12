use Test2::Tools::Tiny;
use strict;
use warnings;

use Sub::Info qw/sub_info/;

ok(__PACKAGE__->can('sub_info'), "Imported sub_info");

sub named { 'named' }

no warnings 'once';
sub empty_named { }    my $empty_named = __LINE__ + 0;
*empty_anon = sub { }; my $empty_anon = __LINE__ + 0;

sub one_line_named { 1 }    my $one_line_named = __LINE__ + 0;
*one_line_anon = sub { 1 }; my $one_line_anon = __LINE__ + 0;

my $multi_line_named_start = __LINE__ + 1;
sub multi_line_named {
    my $x = 1;
    $x++;
    return $x;
}
my $multi_line_named_end  = __LINE__ - 1;

my $multi_line_anon_start = __LINE__ + 1;
*multi_line_anon = sub {
    my $x = 1;
    $x++;
    return $x;
};
my $multi_line_anon_end = __LINE__ - 1;
use warnings 'once';

my $info;

$info = sub_info(\&empty_named);
like($info->{name}, qr/empty_named$/, "Got name");
is($info->{package}, __PACKAGE__,   "got package");
is($info->{file},    __FILE__,      "got file");
is($info->{ref},     \&empty_named, "got reference");
ok($info->{cobj}, "got cobj");
ok(!defined($info->{start_line}) || $info->{start_line} == $empty_named, "Start line seems right");
ok(!defined($info->{end_line})   || $info->{end_line} == $empty_named,   "End line seems right");

$info = sub_info(\&empty_anon);
like($info->{name}       , qr/__ANON__$/, "Got name");
is($info->{package}    , __PACKAGE__, "got package");
is($info->{file}       , __FILE__, "got file");
is($info->{ref}        , \&empty_anon, "got ref");
ok(!defined($info->{start_line}) || $info->{start_line} == $empty_anon, "Start line seems right");
ok(!defined($info->{end_line})   || $info->{end_line} == $empty_anon,   "End line seems right");

$info = sub_info(\&one_line_named);
like($info->{name}       , qr/one_line_named$/, "Got name");
is($info->{package}    , __PACKAGE__, "got package");
is($info->{file}       , __FILE__, "got file");
is($info->{ref}        , \&one_line_named, "got ref");
ok($info->{cobj}, "got cobj");
is($info->{start_line} , $one_line_named, "got start line");
is($info->{end_line}   , $one_line_named, "got end line");
is_deeply($info->{lines}      , [$one_line_named, $one_line_named], "got lines");
is_deeply($info->{all_lines}  , [$one_line_named], "got all lines");

$info = sub_info(\&one_line_anon);
like($info->{name}       , qr/__ANON__$/, "Got name");
is($info->{package}    , __PACKAGE__, "got package");
is($info->{file}       , __FILE__, "got file");
is($info->{ref}        , \&one_line_anon, "got ref");
ok($info->{cobj}, "got cobj");
is($info->{start_line} , $one_line_anon, "got start line");
is($info->{end_line}   , $one_line_anon, "got end line");
is_deeply($info->{lines}      , [$one_line_anon, $one_line_anon], "got lines");
is_deeply($info->{all_lines}  , [$one_line_anon], "got all lines");

$info = sub_info(\&multi_line_named);
like($info->{name}       , qr/multi_line_named$/, "Got name");
is($info->{package}    , __PACKAGE__, "got package");
is($info->{file}       , __FILE__, "got file");
is($info->{ref}        , \&multi_line_named, "got ref");
ok($info->{cobj}, "got cobj");
is($info->{start_line} , $multi_line_named_start, "got start line");
is($info->{end_line}   , $multi_line_named_end, "got end line");
is_deeply($info->{lines}      , [$multi_line_named_start, $multi_line_named_end], "got lines");
is_deeply($info->{all_lines}  , [$multi_line_named_start + 1, $multi_line_named_start + 2, $multi_line_named_end - 1], "got all lines");

$info = sub_info(\&multi_line_anon);
like($info->{name}       , qr/__ANON__$/, "Got name");
is($info->{package}    , __PACKAGE__, "got package");
is($info->{file}       , __FILE__, "got file");
is($info->{ref}        , \&multi_line_anon, "got ref");
ok($info->{cobj}, "got cobj");
is($info->{start_line} , $multi_line_anon_start, "got start line");
is($info->{end_line}   , $multi_line_anon_end, "got end line");
is_deeply($info->{lines}      , [$multi_line_anon_start, $multi_line_anon_end], "got lines");
is_deeply($info->{all_lines}  , [$multi_line_anon_start + 1, $multi_line_anon_start + 2, $multi_line_anon_end - 1], "got all lines");

$info = sub_info(\&multi_line_named, 1, 1000);
like($info->{name}       , qr/multi_line_named$/, "Got name");
is($info->{package}    , __PACKAGE__, "got package");
is($info->{file}       , __FILE__, "got file");
is($info->{ref}        , \&multi_line_named, "got ref");
ok($info->{cobj}, "got cobj");
is($info->{start_line} , 1, "got start line");
is($info->{end_line}   , 1000, "got end line");
is_deeply($info->{lines}      , [1, 1000], "got lines");
is_deeply($info->{all_lines}  , [1, $multi_line_named_start + 1, $multi_line_named_start + 2, $multi_line_named_end - 1, 1000], "got all lines");

$info = sub_info(\&multi_line_anon, 1000, 1);
like($info->{name}       , qr/__ANON__$/, "Got name");
is($info->{package}    , __PACKAGE__, "got package");
is($info->{file}       , __FILE__, "got file");
is($info->{ref}        , \&multi_line_anon, "got ref");
ok($info->{cobj}, "got cobj");
is($info->{start_line} , 1, "got start line");
is($info->{end_line}   , 1000, "got end line");
is_deeply($info->{lines}      , [1, 1000], "got lines");
is_deeply($info->{all_lines}  , [1, $multi_line_anon_start + 1, $multi_line_anon_start + 2, $multi_line_anon_end - 1, 1000], "got all lines");

done_testing;
