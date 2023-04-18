use strict;
use Test;
BEGIN { plan tests => 6; }
use FindBin;
use File::Spec::Functions qw( catfile tmpdir );
use Cwd qw( abs_path getcwd );
use Proc::Background;

=head1 DESCRIPTION

This tests the option 'cwd' that runs the child in a different directory.

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

my $script_fname= catfile(tmpdir, "$tmp_prefix-echodir-$$.pl");
writefile($script_fname, <<'END');
use strict;
use Cwd;
print STDOUT getcwd()."\n";
END

my $stdout_fname= catfile(tmpdir, "$tmp_prefix-stdout-$$.txt");

# Run the script in the current directory
my $proc= Proc::Background->new({
  stdout  => open_or_die('>', $stdout_fname),
  cwd     => '.',
  command => [ $^X, '-w', $script_fname ],
});
ok( !!$proc, 1, 'started child' );  # 1
$proc->wait;
ok( $proc->exit_code, 0, 'exit_code' ); # 2
ok( readfile($stdout_fname), getcwd()."\n", 'stdout content' ); # 3

# Now run the script in the tmp directory
$proc= Proc::Background->new({
  stdout  => open_or_die('>', $stdout_fname),
  cwd     => abs_path(tmpdir),
  command => [ $^X, '-w', $script_fname ],
});
ok( !!$proc, 1, 'started child' );  # 1
$proc->wait;
ok( $proc->exit_code, 0, 'exit_code' ); # 2
ok( readfile($stdout_fname), abs_path(tmpdir)."\n", 'stdout content' ); # 3

unlink $stdout_fname;
unlink $script_fname;
