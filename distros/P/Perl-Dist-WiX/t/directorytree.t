#!/usr/bin/perl

use strict;
use Perl::Dist::WiX::DirectoryTree;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
BEGIN {
	if ( $^O eq 'MSWin32' ) {
		plan tests => 14;
	} else {
		plan skip_all => 'Not on Win32';
	}
}

# Test 1.

my $tree = Perl::Dist::WiX::DirectoryTree->new(
    app_dir => 'C:\\test', 
    app_name => 'Test Perl', 
#    sitename => 'www.test.site.invalid',
#    trace    => 0,
);
ok($tree, '->new returns true');

# Test 2.
              
my $string = $tree->as_string;

is($string, q{    <Directory Id='TARGETDIR' Name='SourceDir' />}, 'Stringifies correctly when uninitialized');    

my $string_test = '    <Directory Id=\'TARGETDIR\' Name=\'SourceDir\'>
      <Directory Id=\'INSTALLDIR\'>
        <Directory Id=\'D_Perl\' Name=\'perl\'>
          <Directory Id=\'D_PerlSite\' Name=\'site\'>
            <Directory Id=\'D_PerlSiteBin\' Name=\'bin\' />
            <Directory Id=\'D_PerlSiteLib\' Name=\'lib\'>
              <Directory Id=\'D_MTc3MjI4NDcwOQ\' Name=\'auto\' />
            </Directory>
          </Directory>
          <Directory Id=\'D_ODE2MzcxND\' Name=\'bin\' />
          <Directory Id=\'D_ODY0MDczNj\' Name=\'lib\'>
            <Directory Id=\'D_MjA0Nzk3NDQyNQ\' Name=\'auto\' />
          </Directory>
          <Directory Id=\'D_MzYxNTg0NT\' Name=\'vendor\'>
            <Directory Id=\'D_MzI0NzU5MzEyNA\' Name=\'lib\'>
              <Directory Id=\'D_OTk4ODIxMD\' Name=\'auto\'>
                <Directory Id=\'D_MTAzMTczNDQzNA\' Name=\'share\'>
                  <Directory Id=\'D_NzI1MjE0Nz\' Name=\'dist\' />
                  <Directory Id=\'D_NDEzNzIyNTIyMQ\' Name=\'module\' />
                </Directory>
              </Directory>
            </Directory>
          </Directory>
        </Directory>
        <Directory Id=\'D_Toolchain\' Name=\'c\'>
          <Directory Id=\'D_NTU4MTI5MT\' Name=\'bin\' />
          <Directory Id=\'D_MzcxMjY2ODc3Nw\' Name=\'include\' />
          <Directory Id=\'D_NTc3NTE5Mz\' Name=\'lib\' />
          <Directory Id=\'D_NzE3MjA0MD\' Name=\'libexec\' />
          <Directory Id=\'D_NDE3MzU1OT\' Name=\'mingw32\' />
          <Directory Id=\'D_MzEzMzQ4ODMzNQ\' Name=\'share\' />
        </Directory>
        <Directory Id=\'D_License\' Name=\'licenses\' />
        <Directory Id=\'D_Cpan\' Name=\'cpan\'>
          <Directory Id=\'D_CpanSources\' Name=\'sources\' />
        </Directory>
        <Directory Id=\'D_Win32\' Name=\'win32\' />
        <Directory Id=\'D_Cpanplus\' Name=\'cpanplus\' />
      </Directory>
      <Directory Id=\'ProgramMenuFolder\'>
        <Directory Id=\'D_App_Menu\' Name=\'Test Perl\'>
          <Directory Id=\'D_App_Menu_Tools\' Name=\'Tools\' />
          <Directory Id=\'D_App_Menu_Websites\' Name=\'Related Websites\' />
        </Directory>
      </Directory>
    </Directory>';
# Test 3

$tree->initialize_tree('589', 32, 3); $string = $tree->as_string;

# This is here for data collection when the tree contents change.
# require Data::Dumper;
# my $d = Data::Dumper->new([$string], [qw(string)]);
# print $d->Indent(1)->Dump();
# exit;

is($string, $string_test, 'Stringifies correctly once initialized');    

# Tests 4-7 are successful finds.

my @tests_1 = (
    [
        {
            path_to_find => 'C:\\test\\perl\\site\\bin',
            exact => 1,
            descend => 1,
        },
        'C:\\test\\perl\\site\\bin',
        'descend=1 exact=1'
    ],
    [
        {
            path_to_find => 'C:\\test\\win32',
            exact => 1,
            descend => 0,
        },
        'C:\\test\\win32',
        'descend=0 exact=1'
    ],
    [
        {
            path_to_find => 'C:\\test\\perl\\site\\bin\\x',
            exact => 0,
            descend => 1,
        },
        'C:\\test\\perl\\site\\bin',
        'descend=1 exact=0'
    ],
    [
        {
            path_to_find => 'C:\\test\\win32\\x',
            exact => 0,
            descend => 0,
        },
        'C:\\test\\win32',
        'descend=0 exact=0'
    ],
);

foreach my $test (@tests_1)
{
    my $dir = $tree->search_dir(%{$test->[0]});
    is($dir->get_path, $test->[1], "Successful search, $test->[2]");
}

my @tests_2 = (
    [
        {
            path_to_find => 'C:\\xtest\\perl\\site\\bin\\x',
            exact => 1,
            descend => 1,
        },
        'descend=1 exact=1'
    ],
    [
        {
            path_to_find => 'C:\\test\\win32\\x',
            exact => 1,
            descend => 0,
        },
        'descend=0 exact=1'
    ],
    [
        {
            path_to_find => 'C:\\xtest\\perl\\site\\bin\\x',
            exact => 0,
            descend => 1,
        },
        'descend=1 exact=0'
    ],
    [
        {
            path_to_find => 'C:\\xtest\\win33',
            exact => 0,
            descend => 0,
        },
        'descend=0 exact=0'
    ],
);

foreach my $test (@tests_2)
{
    my $dir = $tree->search_dir(%{$test->[0]});
    ok((not defined $dir), "Unsuccessful search, $test->[1]");
}

my $dirobj = $tree->get_directory_object('D_Win32');
isa_ok( $dirobj, 'Perl::Dist::WiX::Tag::Directory', 'A directory object retrieved from the tree');

$dirobj = $tree->get_directory_object('Win32');
is($dirobj, undef, 'Directory object with invalid id is not defined.');

is($tree, Perl::Dist::WiX::DirectoryTree->instance(), 'Directory tree is a singleton.');
