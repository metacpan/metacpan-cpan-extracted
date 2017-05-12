#!perl

use Test::More tests => 31;

use Test::Command;

use FindBin;

## write the output files to be used in all later tests

open my $short_data_fh, '>', "$FindBin::Bin/short.txt" or BAIL_OUT("$FindBin::Bin/short.txt: $!");
print $short_data_fh "foo\n";
close $short_data_fh or die BAIL_OUT($!);

open my $stdout_data_fh, '>', "$FindBin::Bin/stdout.txt" or BAIL_OUT("$FindBin::Bin/stdout.txt: $!");
print $stdout_data_fh "foo\nbar\n";
close $stdout_data_fh or die BAIL_OUT($!);

open my $stderr_data_fh, '>', "$FindBin::Bin/stderr.txt" or BAIL_OUT("$FindBin::Bin/stderr.txt: $!");
print $stderr_data_fh "bar\nfoo\n";
close $stderr_data_fh or die BAIL_OUT($!);

## _slurp() tests

my $text = Test::Command::_slurp("$FindBin::Bin/stdout.txt");

is($text, "foo\nbar\n", '_slurp');

## make 10 attempts to find a non-existent file
my $rand_file;

for ( 1 .. 10 )
   {
   $rand_file = rand;
   last if ! -e $rand_file;
   }

SKIP:
   {
   skip 'could not find a non-existent file name', 1
      if -e $rand_file;
   eval { $text = Test::Command::_slurp($rand_file) };
   ok($@, '_slurp - no such file');
   }

eval { Test::Command::_slurp() };
like($@, qr/\$file_name is undefined/, '_slurp - no args');

## _build_name() tests
## use anon sub to avoid uninitialized sub name warning

my $name = sub { Test::Command::_build_name(undef, qw/ potato monkey /) }->();

is($name, "__ANON__: potato, monkey", '_build_name - string');

$name = sub { Test::Command::_build_name('rutabaga', qw/ potato monkey /) }->();

is($name, 'rutabaga', '_build_name - defined - string');

$name = sub { Test::Command::_build_name(undef, [qw/ potato -f monkey /], 'rutabaga') }->();

is($name, '__ANON__: potato -f monkey, rutabaga', '_build_name - array');

$name = sub { Test::Command::_build_name('chicken', [qw/ potato -f monkey /], 'rutabaga') }->();

is($name, 'chicken', '_build_name - defined - array');

eval { Test::Command::_build_name() };
like($@, qr/\$cmd is undefined/, '_build_name - no args');

eval { Test::Command::_get_result() };
like($@, qr/\$cmd is undefined/, '_get_result - no args');

eval { Test::Command::_run_cmd() };
like($@, qr/\$cmd is undefined/, '_run_cmd - no args');

## _compare_files tests

eval { Test::Command::_compare_files() };
like($@, qr/\$got_file is undefined/, '_compare_files - no args');

eval { Test::Command::_compare_files(1) };
like($@, qr/\$exp_file is undefined/, '_compare_files - no exp file');

eval { Test::Command::_compare_files(undef, 1) };
like($@, qr/\$got_file is undefined/, '_compare_files - no got file');

my ($files_ok, $diff_line) = Test::Command::_compare_files("$FindBin::Bin/stdout.txt",
                                                            "$FindBin::Bin/stderr.txt");
ok(!$files_ok, '_compare_files - not ok');
cmp_ok($diff_line, '==', 1, "_compare_files - diff start");

($files_ok, $diff_line) = Test::Command::_compare_files("$FindBin::Bin/stdout.txt",
                                                         "$FindBin::Bin/stdout.txt");
ok($files_ok, '_compare_files - ok');
cmp_ok($diff_line, '==', 2, "_compare_files - no diff start");

($files_ok, $diff_line) = Test::Command::_compare_files("$FindBin::Bin/short.txt",
                                                         "$FindBin::Bin/stdout.txt");
ok(!$files_ok, '_compare_files - not ok');
cmp_ok($diff_line, '==', 2, "_compare_files - diff start");

($files_ok, $diff_line) = Test::Command::_compare_files("$FindBin::Bin/stdout.txt",
                                                         "$FindBin::Bin/short.txt");
ok(!$files_ok, '_compare_files - not ok');
cmp_ok($diff_line, '==', 2, "_compare_files - diff start");

SKIP:
   {
   skip 'could not find a non-existent file name', 2
      if -e $rand_file;

   eval { Test::Command::_compare_files($rand_file,
                                        "$FindBin::Bin/stdout.txt") };
   ok($@, '_compare_files - no such file - got');

   eval { Test::Command::_compare_files("$FindBin::Bin/stdout.txt",
                                        $rand_file) };
   ok($@, '_compare_files - no such file - exp');
   }

my $diff_column = Test::Command::_diff_column();
ok(! defined $diff_column, '_diff_column - no args');

$diff_column = Test::Command::_diff_column("potato");
cmp_ok($diff_column, '==', 1, '_diff_column - first arg');

$diff_column = Test::Command::_diff_column(undef, "potato");
cmp_ok($diff_column, '==', 1, '_diff_column - second arg');

$diff_column = Test::Command::_diff_column("potato", "potato");
ok(! defined $diff_column, '_diff_column - eq args');

$diff_column = Test::Command::_diff_column("potato", "patato");
cmp_ok($diff_column, '==', 2, '_diff_column - col 2(1)');

$diff_column = Test::Command::_diff_column("potato\n", "potato");
cmp_ok($diff_column, '==', 7, '_diff_column - col 7(1)');

$diff_column = Test::Command::_diff_column("potato", "potato\n");
cmp_ok($diff_column, '==', 7, '_diff_column - col 7(2)');

$diff_column = Test::Command::_diff_column("br\n", "bar\n");
cmp_ok($diff_column, '==', 2, '_diff_column - col 2(2)');
