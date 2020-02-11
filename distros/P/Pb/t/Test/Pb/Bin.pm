package Test::Pb::Bin;

use 5.14.0;
use autodie ':all';

use Exporter 'import';
our @EXPORT = qw< pb_basecmd pb_run pb_run_interactive check_output check_error _slurp %ERRNO >;


use Test::Most;

use Errno				();
use File::Temp			qw< tempdir >;
use File::Path			qw< make_path >;
use File::Spec;
use File::Basename;


my $TMPDIR = tempdir( TMPDIR => 1, CLEANUP => 1 );
my $BASE;


# this is how PerlX::bash does it
{
    my $devnull = File::Spec->devnull;
    my $msg = 'successful';
    `bash -c "echo $msg" 2>$devnull` eq "$msg\n" or plan skip_all => "no bash available!";
}


# This helps us avoid errors in non-English locales.  See
# https://github.com/barefootcoder/leadpipe/issues/2 for the discussion which led to this.  Thx to
# Slaven Rezić (a.k.a. SREZIC, a.k.a. eserte) for the suggestion.
our %ERRNO =
(
	ENOENT		=> do { $! = Errno::ENOENT;    "$!" },	# No such file or directory
);


# helpers

# poor man's slurp, compressed, mostly courtesy of:
# https://www.perl.com/article/21/2013/4/21/Read-an-entire-file-into-a-string/
sub _slurp { return undef unless -r "$_[0]"; local @ARGV=shift; local $/ unless wantarray; <> }


# testing stuff

sub pb_basecmd
{
	my ($name, $cmd) = @_;
	open my $out, ">$TMPDIR/$name";
	say $out "#! $^X";
	print $out $cmd;
	close $out;
	$BASE = "$TMPDIR/$name";
	chmod 0700, $BASE;
	return $BASE;
}

sub pb_flowpm
{
	my ($name, $file) = @_;
	my $pmname = $name =~ s{::}{/}gr . '.pm';
	make_path(dirname($pmname));
	open my $out, ">$TMPDIR/$pmname";
	print $out $file;
	close $out;
	return "$TMPDIR/$pmname";
}


use Test::Trap qw< :output(systemsafe) >;

sub pb_run
{
	my @args = @_;

	trap { system($BASE, @args) };
	return $trap;
}

sub pb_run_interactive
{
	my $answers = pop;
	my @args = @_;
	die("answers must be all 'y' or 'n'") unless $answers =~ /^[yn]+$/;
	$answers = join("\n", split(//, $answers));

	trap { system("echo '$answers' | $BASE --interactive @args") };
	return $trap;
}

sub _diag_trap
{
	my ($trap, $testname) = @_;
	diag "\nFailing test: $testname";
	diag ''; $trap->diag_all_once;
	diag "\n$BASE:\n", _slurp($BASE) =~ s/^(\t+)/'    ' x length($1)/egmr =~ s/\t+#/ #/gr;
}

sub check_output
{
	my $testname = pop;
	my ($trap, @lines) = @_;
	local $Test::Builder::Level = $Test::Builder::Level + 1;

	subtest $testname => sub
	{
		local $Test::Builder::Level = $Test::Builder::Level + 5;		# `5` determined by good ol' trial and error ...
		$trap->did_return("clean exit")
				or _diag_trap($trap, $testname);
		$trap->stderr_is( '', "no errors" );
		$trap->stdout_is( join('', map { "$_\n" } @lines), "good output" );
	};
}

sub check_error
{
	my $testname = pop;
	my $trap = shift;
	my $exit = $_[0] =~ /^\d+$/ ? shift : $_[0] eq '?' ? (shift, qr/[12]\d*/) : 1;
	my @lines = @_;
	local $Test::Builder::Level = $Test::Builder::Level + 1;

	subtest $testname => sub
	{
		local $Test::Builder::Level = $Test::Builder::Level + 5;		# `5` determined by good ol' trial and error ...
		$trap->die_like(qr/unexpectedly returned exit value $exit\b/, "error exit")
				or _diag_trap($trap, $testname);
		if (@lines == 1 and ref $lines[0] eq 'Regexp')
		{
			$trap->stderr_like( $lines[0], "good error pattern" );
		}
		else
		{
			$trap->stderr_is( join('', map { "$_\n" } @lines), "good error" );
		}
	};
}


1;
