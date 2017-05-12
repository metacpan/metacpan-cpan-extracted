# Before `make install' is performed this script should be runnable with
# `make test'.
# After `make install' it should work as `perl Parse-Readelf-Debug-Line.t'
# Without Makefile it could be called with `perl -I../lib
# Parse-Readelf-Debug-Line.t'.  This is also the command needed to
# find out what specific tests failed in a `make test' as the later
# only gives you a number and not the description of the test.

#########################################################################

use strict;

use Test::More tests => 132;

use File::Spec;

require_ok 'Parse::Readelf::Debug::Line';

# for successful run with test coverage use:
# cover -delete
# HARNESS_PERL_SWITCHES=-MDevel::Cover=-silent,on,-summary,off make test
# cover

#########################################################################
# identical part of messages:
my $re_msg_tail = qr/at .*Parse-Readelf-Debug-Line\.(?:t|pm) line \d{2,}\.?$/;
use constant MODULE => 'StructureLayoutTest.cpp';

#########################################################################
# import tests:
sub reset_globals()
{
    local $_;
    foreach (qw(command re_section_start re_dwarf_version
		re_directory_table
		re_file_name_table re_file_name_table_header))
    { delete $main::{$_} if defined *$_ }
}
sub test_globals($%)
{
    my ($export, $globals) = @_;
    local $_;
    foreach (keys %$globals)
    {
	if ($globals->{$_})
	{
	    ok(eval($_), $_.' is exported with "'.$export.'"');
	    if ($_ =~ m/^\$/)
	    {
		is(eval($_), $globals->{$_},
		   $_.' has correct value in "'.$export.'"')
	    }
	    else
	    {
		is_deeply([eval($_)], $globals->{$_},
		   $_.' has correct value in "'.$export.'"')
	    }
	}
	else
	{ ok(! eval($_), $_.' is not exported with "'.$export.'"') }
    }
}

eval { import Parse::Readelf::Debug::Line ':command' };
is($@, '', "import with ':command'");
test_globals(':command',
	     {'$command' => 'readelf --debug-dump=line',
	      '$re_section_start' => undef,
	      '$re_dwarf_version' => undef,
	      '@re_directory_table' => undef,
	      '@re_file_name_table' => undef,
	      '@re_file_name_table_header' => undef});
reset_globals();

eval { import Parse::Readelf::Debug::Line qw($command) };
is($@, '', "import with '\$command'");
test_globals('$command',
	     {'$command' => 'readelf --debug-dump=line',
	      '$re_section_start' => undef,
	      '$re_dwarf_version' => undef,
	      '@re_directory_table' => undef,
	      '@re_file_name_table' => undef,
	      '@re_file_name_table_header' => undef});
reset_globals();

eval { import Parse::Readelf::Debug::Line ':fixed_regexps' };
is($@, '', "import with ':fixed_regexps'");
test_globals(':fixed_regexps',
	     {'$command' => undef,
	      '$re_section_start'
	      => qr(^(?:raw )?dump of debug contents of section \.debug_line:)i,
	      '$re_dwarf_version' => qr(^\s*DWARF Version:\s+(\d+)\s*$)i,
	      '@re_directory_table' => undef,
	      '@re_file_name_table' => undef,
	      '@re_file_name_table_header' => undef});
reset_globals();

eval { import Parse::Readelf::Debug::Line ':versioned_regexps' };
is($@, '', "import with ':versioned_regexps'");
test_globals(':versioned_regexps',
	     {'$command' => undef,
	      '$re_section_start' => undef,
	      '$re_dwarf_version' => undef,
	      '@re_directory_table'
	      => [undef, undef, qr(^\s*The Directory Table)i],
	      '@re_file_name_table'
	      => [undef, undef, qr(^\s*The File Name Table:)i],
	      '@re_file_name_table_header'
	      => [undef, undef, qr(^\s*Entry\s+Dir\s+Time\s+Size\s+Name)i]});
reset_globals();

eval { import Parse::Readelf::Debug::Line ':all' };
is($@, '', "import with ':all'");
test_globals(':all',
	     {'$command' => 'readelf --debug-dump=line',
	      '$re_section_start'
	      => qr(^(?:raw )?dump of debug contents of section \.debug_line:)i,
	      '$re_dwarf_version' => qr(^\s*DWARF Version:\s+(\d+)\s*$)i,
	      '@re_directory_table'
	      => [undef, undef, qr(^\s*The Directory Table)i],
	      '@re_file_name_table'
	      => [undef, undef, qr(^\s*The File Name Table:)i],
	      '@re_file_name_table_header'
	      => [undef, undef, qr(^\s*Entry\s+Dir\s+Time\s+Size\s+Name)i]});
reset_globals();

eval { import Parse::Readelf::Debug::Line };
is($@, '', "import with '<empty import list>'");
test_globals('<empty import list>',
	     {'$command' => undef,
	      '$re_section_start' => undef,
	      '$re_dwarf_version' => undef,
	      '@re_directory_table' => undef,
	      '@re_file_name_table' => undef,
	      '@re_file_name_table_header' => undef});

#########################################################################
# prepare testing with recorded data:
my ($volume, $directories, ) = File::Spec->splitpath($0);
$directories = '.' unless $directories;
my $path = File::Spec->catpath($volume, $directories, '');
$Parse::Readelf::Debug::Line::command = $^O eq 'MSWin32' ? 'type' : 'cat';

#########################################################################
# failing tests:
eval { my $x = Parse::Readelf::Debug::Line::new() };
like($@,
     qr/^bad call to new of Parse::Readelf::Debug::Line $re_msg_tail/,
     'bad creation fails');
eval {
    my $filepath = File::Spec->catfile($path, 'data', 'xxx.xxx');
    my $x = new Parse::Readelf::Debug::Line($filepath);
};
like($@,
     qr|^Parse::Readelf::Debug::Line can't find .* $re_msg_tail|, #'
     'bad file name fails');
my $stderr = '';
$SIG{__WARN__} = sub { $stderr .= join('', @_) };
eval {
    local $Parse::Readelf::Debug::Line::command	= 'failing-test-expected-here';
    my $filepath = File::Spec->catfile($path, 'data', 'debug_info_1.lst');
    my $x = new Parse::Readelf::Debug::Line($filepath);
};
delete $SIG{__WARN__};
like($@,
     qr!^can't parse .* with ".*" in Parse::Readelf::Debug::Line: .* $re_msg_tail|^error while attempting to parse .* \(maybe not an object file\?\) $re_msg_tail!,
     'non-existing command fails');
like($stderr,
     qr/^(?:TODO: Is there some possible message here\?)?/,
     'non-existing command may have error message on stderr');
eval {
    no warnings 'once';
    local @Parse::Readelf::Debug::Line::re_directory_table =
	(undef, undef, undef);
    my $filepath = File::Spec->catfile($path, 'data', 'debug_info_1.lst');
    my $x = new Parse::Readelf::Debug::Line($filepath);
};
like($@,
     qr|^DWARF version 2 not supported in Parse::Readelf::Debug::Line .* $re_msg_tail|s,
     'bad @re_directory_table fails');
eval {
    no warnings 'once';
    local @Parse::Readelf::Debug::Line::re_file_name_table =
	(undef, undef, undef);
    my $filepath = File::Spec->catfile($path, 'data', 'debug_info_1.lst');
    my $x = new Parse::Readelf::Debug::Line($filepath);
};
like($@,
     qr|^DWARF version 2 not supported in Parse::Readelf::Debug::Line .* $re_msg_tail|s,
     'bad @re_file_name_table fails');
eval {
    no warnings 'once';
    local @Parse::Readelf::Debug::Line::re_file_name_table_header =
	(undef, undef, undef);
    my $filepath = File::Spec->catfile($path, 'data', 'debug_info_1.lst');
    my $x = new Parse::Readelf::Debug::Line($filepath);
};
like($@,
     qr|^DWARF version 2 not supported in Parse::Readelf::Debug::Line .* $re_msg_tail|s,
     'bad @re_file_name_table_header fails');
eval {
    my $filepath = File::Spec->catfile($path, 'data', 'broken_info-1.lst');
    my $x = new Parse::Readelf::Debug::Line($filepath);
};
like($@,
     qr|^aborting: head line of file name table not recognised in .* $re_msg_tail|s,
     'missing file name table header fails');
eval {
    local $Parse::Readelf::Debug::Line::command = 'perl -e "exit(-1);"';
    my $filepath = File::Spec->catfile($path, 'data', 'debug_info_1.lst');
    my $x = new Parse::Readelf::Debug::Line($filepath);
};
like($@,
     qr|^error while attempting to parse .* $re_msg_tail|,
     'command returning -1 fails');

#########################################################################
# first "real" tests:
my $filepath = File::Spec->catfile($path, 'data', 'debug_info_1.lst');
my $line_info = new Parse::Readelf::Debug::Line($filepath);
is(ref($line_info), 'Parse::Readelf::Debug::Line',
   'created Parse::Readelf::Debug::Line object');
foreach (0..3)
{
    my $name = $line_info->object_name($_);
    ok($name, 'found name for object ID '.$_);
    my $id = $line_info->object_id($name);
    ok(defined $id, 'found object ID for '.$name);
    is($id, $_, 'ID for '.$name.' is '.$_);
    is($line_info->file($id, 1), $name, $name.' is file #1');
}
is($line_info->object_id('not_found'), -1, 'ID for not existing object is -1');
is($line_info->object_name(4), '', "ID for not existing object is ''");

my $id = $line_info->object_id(MODULE);
is($line_info->file($id, 0), '', "file($id, 0) is empty");
is($line_info->file($id, 2), 'iostream', "file($id, 2) is 'iostream'");
is($line_info->file($id, 135), 'istream.tcc',
   "file($id, 135) is 'istream.tcc'");
is($line_info->file($id, 136), '<built-in>', "file($id, 136) is '<built-in>'");
is($line_info->file($id, 137), '', "file($id, 137) is empty");
is($line_info->file(4, 1), '', "file(4, 1) is empty");
is($line_info->directory($id, 0), '', "directory($id, 0) is empty");
is($line_info->directory($id, 1), '.', "directory($id, 1) is '.'");
is($line_info->directory($id, 2),
   '/usr/lib/gcc/x86_64-linux-gnu/4.1.2/../../../../include/c++/4.1.2',
   "directory($id, 2) is '/usr/.../include/c++/4.1.2'");
is($line_info->directory($id, 135),
   '/usr/lib/gcc/x86_64-linux-gnu/4.1.2/../../../../include/c++/4.1.2/bits',
   "directory($id, 135) is '/usr/.../include/c++/.../bits'");
is($line_info->directory($id, 137), '', "directory($id, 137) is empty");
is($line_info->directory(4, 1), '', "file(5, 1) is empty");
is($line_info->path($id, 0), '', "path($id, 0) is empty");
is($line_info->path($id, 1), './'.MODULE, "path($id, 1) is './".MODULE."'");
is($line_info->path($id, 2),
   '/usr/lib/gcc/x86_64-linux-gnu/4.1.2/../../../../include/c++/4.1.2/iostream',
   "path($id, 2) is '/usr/.../include/c++/4.1.0/iostream'");
is($line_info->path($id, 135),
   '/usr/lib/gcc/x86_64-linux-gnu/4.1.2/../../../../include/c++/4.1.2/bits/istream.tcc',
   "path($id, 135) is '/usr/.../include/c++/.../bits/istream.tcc'");
is($line_info->path($id, 137), '', "path($id, 137) is empty");
is($line_info->path(4, 1), '', "file(5, 1) is empty");

my @list = $line_info->files(0);
is_deeply(\@list, ['init.c'], 'files(0) in list context');
my $scalar = $line_info->files($id);
is($scalar, 136, 'files($id) in scalar context');
@list = $line_info->files(4);
is_deeply(\@list, [], 'files(4) in list context (empty)');
$scalar = $line_info->files(4);
is($scalar, 0, 'files(4) in scalar context (0)');

@list = $line_info->directories(0);
is_deeply(\@list, ['.'], 'directories(0) in list context');
$scalar = $line_info->directories($id);
is($scalar, 136, 'directories($id) in scalar context');
@list = $line_info->directories(4);
is_deeply(\@list, [], 'directories(4) in list context (empty)');
$scalar = $line_info->directories(4);
is($scalar, 0, 'directories(4) in scalar context (0)');

@list = $line_info->paths(0);
is_deeply(\@list, ['./init.c'], 'paths(0) in list context');
$scalar = $line_info->paths($id);
is($scalar, 136, 'paths($id) in scalar context');
@list = $line_info->paths(4);
is_deeply(\@list, [], 'paths(4) in list context (empty)');
$scalar = $line_info->paths(4);
is($scalar, 0, 'paths(4) in scalar context (0)');

#########################################################################
# finally some tests with a cloned object:
$stderr = '';
$SIG{__WARN__} = sub { $stderr .= join('', @_) };
$line_info = $line_info->new($filepath);
delete $SIG{__WARN__};
like($stderr,
     qr/^cloning of a Parse::Readelf::Debug::Line object is not supported $re_msg_tail/,
     'cloning gives a warning');
is(ref($line_info), 'Parse::Readelf::Debug::Line',
   'created Parse::Readelf::Debug::Line object');
foreach (0..3)
{
    my $name = $line_info->object_name($_);
    ok($name, 'found name for object ID '.$_);
    my $id = $line_info->object_id($name);
    ok(defined $id, 'found object ID for '.$name);
    is($id, $_, 'ID for '.$name.' is '.$_);
    is($line_info->file($id, 1), $name, $name.' is file #1');
}
