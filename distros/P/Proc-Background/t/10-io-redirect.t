use strict;
use Test;
BEGIN { plan tests => 7; }
use FindBin;
use File::Spec::Functions qw( catfile tmpdir );
use Proc::Background;

=head1 DESCRIPTION

This tests the options 'stdin','stdout','stderr' that assign the file
handles of the child process.  It writes a unique string to a temp file,
then runs a child process that reads stdin and echoes to stdout and stderr,
then it checks that stdout and stderr files have the correct content.

=cut

sub open_or_die {
  open my $fh, $_[0], $_[1] or die "open($_[2]): $!";
  $fh;
}
sub readfile {
  my $fh= open_or_die('<', $_[0]);
  local $/= undef;
  scalar <$fh>;
}
sub writefile {
  my $fh= open_or_die('>', $_[0]);
  print $fh $_[1] or die "print: $!";
  close $fh or die "close: $!";
}

my $tmp_prefix= $FindBin::Script;
$tmp_prefix =~ s/-.*//;

my $stdin_fname=  catfile(tmpdir, "$tmp_prefix-stdin-$$.txt" );
my $stdout_fname= catfile(tmpdir, "$tmp_prefix-stdout-$$.txt");
my $stderr_fname= catfile(tmpdir, "$tmp_prefix-stderr-$$.txt");

# Write something to the stdin file.  Then run the script which reads it and echoes to both stdout and stderr.
my ($stdin, $stdout, $stderr);
my $content= "Time = ".time."\n";
writefile($stdin_fname, $content);

my $proc= Proc::Background->new({
  stdin => open_or_die('<', $stdin_fname),
  stdout => open_or_die('>', $stdout_fname),
  stderr => open_or_die('>', $stderr_fname),
  command => [ $^X, '-we', <<'END' ],
use strict;
$/= undef;
my $content= <STDIN>;
print STDOUT $content;
print STDERR $content;
END
});
ok( !!$proc, 1, 'started child' );  # 1
$proc->wait;
ok( $proc->exit_code, 0, 'exit_code' ); # 2
ok( readfile($stdout_fname), $content, 'stdout content' ); # 3
ok( readfile($stderr_fname), $content, 'stderr content' ); # 4

# Test redirection to Win32 NUL or unix /dev/null

$proc= Proc::Background->new({
  stdin => undef,
  stdout => undef,
  stderr => undef,
  command => [ $^X, '-we', <<'END' ],
use strict;
print "Nobody should see this\n";
print STDERR "Nobody should see this\n";
END
});
ok( !!$proc, 1, 'started child' );  # 5
$proc->wait;
ok( $proc->exit_code, 0, 'exit_code' ); # 6

# Let the child process write the final 'ok' message

$|= 1;
$proc= Proc::Background->new({
  stdin  => undef,
  stdout => \*STDOUT,
  stderr => $stderr_fname,
  command => [ $^X, '-we', <<'END' ],
use strict;
print STDERR "appended a line\n";
print "ok 7\n";
END
});
$proc->wait;
$proc->exit_code == 0 or die "Final test exited with ".$proc->exit_code;
my $err= readfile($stderr_fname);
$err eq $content."appended a line\n" or die "Final test wrong stderr: $err";

unlink $stdin_fname;
unlink $stdout_fname;
unlink $stderr_fname;
