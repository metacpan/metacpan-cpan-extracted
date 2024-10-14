package Storage::Abstract::Test;

use v5.14;
use warnings;

use Storage::Abstract::Driver;
use File::Spec;

use Exporter qw(import);
our @EXPORT = qw(
	get_testfile
	get_testfile_size
	get_testfile_handle
	slurp_handle
);

my @testdir = qw(t testfiles);

sub get_testfile
{
	my ($name) = @_;
	$name //= 'page.html';

	return File::Spec->catdir(@testdir, $name);
}

sub get_testfile_size
{
	my ($name) = @_;

	my $file = get_testfile($name);
	return -s $file;
}

sub get_testfile_handle
{
	my ($name) = @_;

	my $file = get_testfile($name);
	open my $fh, '<:raw', $file
		or die "$file error: $!";

	return $fh;
}

sub slurp_handle
{
	my ($fh) = @_;
	seek $fh, 0, 0;

	my $slurped = do {
		local $/;
		readline $fh;
	};

	die $! || 'no error - handle EOF?'
		unless defined $slurped;

	return $slurped;
}

1;

