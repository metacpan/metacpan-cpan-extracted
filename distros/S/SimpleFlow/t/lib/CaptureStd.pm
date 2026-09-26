package CaptureStd;
#
# capture { ... } for the test suite: runs the block with STDOUT and STDERR
# on temporary files and returns (stdout, stderr, what the block returned).
# It stands in for Capture::Tiny's capture(), which the tests used before 0.18
# and which was then their only reason to need Capture::Tiny; the calling
# convention is that one's, from the Capture::Tiny 0.50 documentation: the
# block runs in list context, an exception from it propagates once the
# handles are restored, and $? is left as the block left it.
#
# It deliberately works differently from SimpleFlow::_capture, which it is
# used to test. That redirects descriptors 1 and 2 with POSIX::dup2; this
# reopens the STDOUT and STDERR globs, and relies on perl reopening a handle
# whose descriptor is at or below $^F (2) onto that same descriptor -- the
# fd <= PL_maxsysfd case in doio.c's open code, checked here on perl 5.10.1
# and 5.44.0, both of which keep STDOUT on fd 1 even with fd 0 closed.
# A bug in the module's capture therefore cannot be hidden by the same bug in
# the harness measuring it.
#
# Only what the tests need is here: no tee, no merge, no layers beyond
# undoing MSWin32's CR LF (every capture compared is ASCII), no tied or closed
# standard handles.
#
use strict;
use warnings FATAL => 'all';
require 5.010;
use Exporter 'import';
use File::Temp ();

our @EXPORT = ('capture');

# Setting $| true flushes at once; its previous value is put back.
sub _flush {
	my $fh = shift;
	my $previously_selected = select $fh;
	my $autoflush = $|;
	$| = 1;
	$| = $autoflush;
	select $previously_selected;
	return;
}

sub _slurp {
	my $fh = shift;
	seek $fh, 0, 0 or die "cannot rewind a capture file: $!";
	local $/;
	my $text = <$fh>;
	return '' if not defined $text;
	# On MSWin32 the standard handles carry :crlf, so "\n" reaches the file as
	# CR LF, and File::Temp opens the file in binary mode, so it is read back
	# as CR LF. Undo it, as reading through the handle's own layers would:
	# 0.18's t/01.t failed on Strawberry Perl 5.42.2 comparing a captured
	# line with "...\r\n" against the same line with "\n".
	$text =~ s/\015\012/\012/g if $^O eq 'MSWin32';
	return $text;
}

sub capture (&) {
	my $code = shift;
	my %file = (out => File::Temp->new, err => File::Temp->new);
	_flush(\*STDOUT);
	_flush(\*STDERR);
	open my $saved_out, '>&', \*STDOUT or die "cannot save STDOUT: $!";
	open my $saved_err, '>&', \*STDERR or die "cannot save STDERR: $!";
	open STDOUT, '>&', $file{out} or die "cannot redirect STDOUT: $!";
	open STDERR, '>&', $file{err} or die "cannot redirect STDERR: $!";
	my @result;
	my $ok = eval { @result = $code->(); 1 };
	my ($error, $status) = ($@, $?);
	_flush(\*STDOUT);
	_flush(\*STDERR);
	open STDOUT, '>&', $saved_out or die "cannot restore STDOUT: $!";
	open STDERR, '>&', $saved_err or die "cannot restore STDERR: $!";
	close $saved_out;
	close $saved_err;
	die $error if not $ok;
	$? = $status;
	return (_slurp($file{out}), _slurp($file{err}), @result);
}

1;
