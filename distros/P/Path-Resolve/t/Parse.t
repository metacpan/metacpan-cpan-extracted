use strict;
use warnings;
use lib './lib';
use Path::Resolve;
use Data::Dumper;
use Test::More;

my $isWindows = $^O eq 'MSWin32';
my $path = Path::Resolve->new();

my $tests;
my $paths;
my $SpecialCaseFormatTests;

if ($isWindows) {
	$tests = 43;
	$paths = [
		'C:\\path\\dir\\index.html',
		'C:\\another_path\\DIR\\1\\2\\33\\index',
		'another_path\\DIR with spaces\\1\\2\\33\\index',
		'\\foo\\C:',
		'file',
		'.\\file',
		# unc
		'\\\\server\\share\\file_path',
		'\\\\server two\\shared folder\\file path.zip',
		'\\\\teela\\admin$\\system32',
		'\\\\?\\UNC\\server\\share'
	];

	$SpecialCaseFormatTests = [
		[{dir => 'some\\dir'}, 'some\\dir\\'],
		[{base => 'index.html'}, 'index.html'],
		[{}, '']
	];

} else {
	$tests = 39;
	$paths = [
		'/home/user/dir/file.txt',
		'/home/user/a dir/another File.zip',
		'/home/user/a dir//another&File.',
		'/home/user/a$$$dir//another File.zip',
		'user/dir/another File.zip',
		'file',
		'.\\file',
		'./file',
		'C:\\foo'
	];

	$SpecialCaseFormatTests = [
		[{dir => 'some/dir'}, 'some/dir/'],
		[{base => 'index.html'}, 'index.html'],
		[{}, '']
	];
}

foreach my $element (@{$paths}) {
	my $output = $path->parse($element);
	is($path->format($output), $element);
	is($output->{dir}, $output->{dir} ? $path->dirname($element) : '');
	is($output->{base}, $path->basename($element));
	is($output->{ext}, $path->extname($element));
}

foreach my $testCase (@{$SpecialCaseFormatTests}){
	is($path->format($testCase->[0]), $testCase->[1]);
}

done_testing($tests);
