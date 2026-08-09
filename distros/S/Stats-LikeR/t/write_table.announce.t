#!/usr/bin/env perl
# write_table's "wrote <file>" confirmation line.
#
# The contract under test:
#   * every format announces the file it wrote -- delimited, LaTeX and .xlsx
#     alike, not just the two that used to;
#   * the file name is wrapped in the same SGR codes throughout (black on
#     cyan, then reset), so the line looks identical whatever was written;
#   * nothing is announced when no file was produced.
#
# The line goes to fd 1 through PerlIO_stdout(), not through Perl's STDOUT
# glob, so `local *STDOUT; open STDOUT, '>', \$buf` does not see it. Every
# check therefore runs write_table in a child perl and reads its real stdout.
require 5.010;
use strict;
use warnings FATAL => 'all';
use File::Temp qw(tempdir);
use Test::More;

my $dir = tempdir(CLEANUP => 1);

# Run $code in a child perl that has this build of Stats::LikeR loaded, and
# return everything it printed to fd 1.
sub child_stdout {
	my ($code) = @_;
	my @inc = map { "-I$_" } grep { !ref $_ } @INC;
	open my $ph, '-|', $^X, @inc, '-MStats::LikeR', '-e', $code
		or die "cannot run a child perl: $!";
	my $out = do { local $/; <$ph> };
	close $ph;
	return defined $out ? $out : '';
}

# The exact bytes write_table emits for $file: black fg (30) on cyan bg (46),
# the name, then a reset (0).
sub announcement {
	my ($file) = @_;
	return "wrote \033[30;46m" . $file . "\033[0m\n";
}

# A tiny AoH is enough for every writer.
sub write_code {
	my ($file, @opts) = @_;
	my $opts = join ', ', map { "'$_'" } @opts;
	$opts = ", $opts" if length $opts;
	return "write_table([{ gene => 'TP53', n => 12 }], '$file'$opts);";
}

# ---------------------------------------------------------------------------
# every format announces itself, in the same shape
# ---------------------------------------------------------------------------
my %by_format = (
	'csv'  => "$dir/a.csv",
	'tsv'  => "$dir/a.tsv",
	'tex'  => "$dir/a.tex",
	'xlsx' => "$dir/a.xlsx",
);

for my $fmt (sort keys %by_format) {
	my $file = $by_format{$fmt};
	my $out  = child_stdout(write_code($file));
	is($out, announcement($file),
		"$fmt: announces the file it wrote, and nothing else");
	ok(-e $file, "$fmt: the file really was written");
}

# the delimited formats are the ones this used to skip -- pin them explicitly
{
	my $file = "$dir/explicit.csv";
	my $out  = child_stdout(write_code($file));
	like($out, qr/\Awrote \e\[30;46m/,
		'delimited output is coloured, not plain');
	like($out, qr/\e\[0m\n\z/,
		'delimited output resets the colour and ends the line');
	like($out, qr/\Q$file\E/, 'delimited output names the file');
}

# ---------------------------------------------------------------------------
# the LaTeX and .xlsx lines are byte-identical in form to the delimited one
# ---------------------------------------------------------------------------
{
	my ($csv, $tex) = ("$dir/same.csv", "$dir/same.tex");
	my $c = child_stdout(write_code($csv));
	my $t = child_stdout(write_code($tex));
	(my $c_norm = $c) =~ s/\Q$csv\E/FILE/;
	(my $t_norm = $t) =~ s/\Q$tex\E/FILE/;
	is($c_norm, $t_norm, 'delimited and LaTeX announce in exactly the same form');
}

# ---------------------------------------------------------------------------
# tex => 1 / xlsx => 1 on a name that does not carry the extension
# ---------------------------------------------------------------------------
{
	my $file = "$dir/forced_tex.out";
	my $out  = child_stdout(write_code($file, 'tex', 1));
	is($out, announcement($file), 'tex => 1 announces the name it was given');
}
{
	my $file = "$dir/forced_xlsx.out";
	my $out  = child_stdout(write_code($file, 'xlsx', 1));
	is($out, announcement($file), 'xlsx => 1 announces the name it was given');
}

# ---------------------------------------------------------------------------
# nothing written, nothing announced
# ---------------------------------------------------------------------------
{
	# An empty frame returns before a file is ever opened.
	my $file = "$dir/never.csv";
	my $out  = child_stdout("write_table([], '$file');");
	is($out, '', 'an empty frame announces nothing');
	ok(!-e $file, 'an empty frame writes no file');

	my $ehash = "$dir/never2.csv";
	my $out2  = child_stdout("write_table({}, '$ehash');");
	is($out2, '', 'an empty hash announces nothing');
}

{
	# A path that cannot be opened croaks before anything is announced.
	my $bad = "$dir/no_such_dir/x.csv";
	# the croak goes to stderr; silence it so it does not litter the suite
	my $out = child_stdout(
		"close STDERR; eval { write_table([{ a => 1 }], '$bad') };");
	is($out, '', 'a write that croaks announces nothing');
}

# ---------------------------------------------------------------------------
# The announcement is flushed as it is made.
#
# PerlIO_stdout() has its own buffer. When fd 1 is a pipe that buffer is block
# buffered, so an unflushed announcement waits there until exit -- and its
# eventual flush lands wherever the program happens to be, in the middle of
# another writer's line if that writer holds a separate handle on fd 1.
# Test::More is exactly such a writer: it prints TAP through a dup of STDOUT
# with autoflush on. That is how a smoker saw write_table.t emit spliced,
# out-of-sequence TAP while every assertion in it passed.
#
# Each check below runs in a child whose stdout is a pipe, and prints its
# markers through a dup with autoflush on, mirroring Test::More. The dup is
# unbuffered through select and $|, not $fh->autoflush: IO::Handle is not
# autoloaded for handle method calls before 5.14.
# ---------------------------------------------------------------------------
{
	my $file = "$dir/flushed.csv";
	my $out  = child_stdout(
		  q{open my $d, '>&', \*STDOUT or die; my $o = select $d; $| = 1; select $o;}
		. qq{print \$d "BEFORE\\n";}
		. qq{write_table([{ a => 1 }], '$file');}
		. q{print $d "AFTER\n";}
	);
	is($out, "BEFORE\n" . announcement($file) . "AFTER\n",
		'the announcement is flushed where it is made, not held until exit');
}

{
	# Many announcements: unflushed, these overrun the buffer and the flush
	# cuts one in half around another handle's line. Every line must arrive
	# whole, and the two streams must stay in step.
	my @files = map { "$dir/interleave_$_.csv" } 1 .. 40;
	my $writes = join '', map {
		qq{write_table([{ a => 1 }], '$files[$_]'); print \$d "MARK $_\\n";}
	} 0 .. $#files;
	my $out = child_stdout(
		q{open my $d, '>&', \*STDOUT or die; my $o = select $d; $| = 1; select $o;} . $writes);
	my $expected = join '', map {
		announcement($files[$_]) . "MARK $_\n"
	} 0 .. $#files;
	is($out, $expected,
		'40 announcements stay whole and in step with a second handle on fd 1');
}

done_testing();
