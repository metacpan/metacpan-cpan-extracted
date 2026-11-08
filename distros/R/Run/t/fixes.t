#! perl
# Fixes in 0.05: a one-element command is a program, not a shell string;
# {filename, mode} opens literal names as sh does; $data->{result} is the
# status of the last command; readpipe reaps its kid.  Each check runs with
# redirections applied in the kid (fork) and in the parent ($Run::Forkless).
use strict; use warnings;
use Test::More;
use POSIX ();
use File::Temp qw(tempdir);
use Run ':NEW';

my $dir = tempdir(CLEANUP => 1);
chdir $dir or die;
sub slurp { open my $f, '<', $_[0] or return; local $/; scalar <$f> }
sub put { open my $f, '>', $_[0] or die; print $f $_[1]; close $f }
sub perl { new_system($^X, '-e', @_) }
sub to { new_redir([1 => {filename => $_[0], mode => $_[1] // '>'}], $_[2]) }

put('my prog', "#!/bin/sh\necho ran \"\$@\"\n"); chmod 0755, 'my prog';

for my $wrap (0, 1) {
  local $Run::Forkless = $wrap;
  my $m = $wrap ? 'forkless' : 'fork';
  unlink glob '* .*';
  put('my prog', "#!/bin/sh\necho ran \"\$@\"\n"); chmod 0755, 'my prog';

  # R1
  ok to('out', undef, new_system("$dir/my prog"))->run({errs => []}), "$m: R1 one-element name with a blank runs";
  is slurp('out'), "ran\n", "$m: R1 ... it is the program 'my prog'";
  my %d = (errs => []);
  ok !new_system("touch shell-ran; true")->run(\%d), "$m: R1 metacharacters do not reach a shell";
  ok !-e 'shell-ran', "$m: R1 ... nothing ran";
  is $d{result}, -1, "$m: R1 ... result -1 (not started)";
  like "@{$d{errs}}", qr/^exec `touch shell-ran; true': No such file/, "$m: R1 ... one message, with the reason";
  %d = (errs => []);
  ok !to('out', undef, new_system('no-such-prog-xyz'))->run(\%d), "$m: R1 missing program with a redirection";
  is scalar @{$d{errs}}, 1, "$m: R1 ... reported once";

  # R2
  for my $name ('-', '&1', ' lead', 'a|') {
    unlink $name;
    to($name, '>', perl('print "x\n"'))->run;
    is slurp($name), "x\n", "$m: R2 file named '$name' created by mode >";
  }
  to('-', '>>', perl('print "y\n"'))->run;
  is slurp('-'), "x\ny\n", "$m: R2 >> appends";
  to('-', '>|', perl('print "z\n"'))->run;
  is slurp('-'), "z\n", "$m: R2 >| truncates";
  ok new_redir([0 => {filename => '-', mode => '<'}], to('out', '>', perl('print <STDIN>')))->run,
    "$m: R2 < reads";
  is slurp('out'), "z\n", "$m: R2 ... the file's contents";
  unlink 'rw';
  ok new_redir([0 => {filename => 'rw', mode => '<>'}], perl('1'))->run, "$m: R2 <> on a missing file";
  ok -e 'rw', "$m: R2 ... creates it";
  put('rw', "keep\n");
  new_redir([0 => {filename => 'rw', mode => '<>'}], perl('1'))->run;
  is slurp('rw'), "keep\n", "$m: R2 <> does not truncate";
  %d = (errs => []);
  ok !new_redir([0 => {filename => 'missing', mode => '<'}], perl('1'))->run(\%d), "$m: R2 < missing file fails";
  like "@{$d{errs}}", qr/Cannot open `missing'/, "$m: R2 ... with a message";
  is $d{result}, -1, "$m: R2 ... result -1";
  %d = (errs => []);
  ok !new_redir([1 => {filename => 'f', mode => '>&'}], perl('1'))->run(\%d), "$m: R2 unknown mode";
  like "@{$d{errs}}", qr/unknown mode `>&'/, "$m: R2 ... reported";

  # R3
  %d = (errs => []);
  perl('exit 1')->run(\%d);
  is $d{result}, 256, "$m: R3 result after a failure";
  perl('exit 0')->run(\%d);
  is $d{result}, 0, "$m: R3 result reset by a success";
  is_deeply [map scalar new_chain(map perl("exit $_"), @$_)->run({errs => []}), [1, 0], [0, 1]],
    [1, undef], "$m: R3 chain: the last command decides";
  %d = (errs => []);
  new_or(perl('exit 2'), perl('exit 3'))->run(\%d);
  is $d{result}, 3 << 8, "$m: R3 or: status of the last command run";
  %d = (errs => []);
  new_and(perl('exit 0'), perl('exit 5'), perl('exit 0'))->run(\%d);
  is $d{result}, 5 << 8, "$m: R3 and: status of the failing command";
  like "@{$d{errs}}", qr/rc=1280\z/, "$m: minor: no stale \$! after rc=";

  # R4
  %d = ();
  is new_readpipe(perl('print "a\n\n"; exit 7'))->run(\%d), "a\n\n", "$m: R4 readpipe output (unchanged: newlines kept)";
  is $d{result}, 7 << 8, "$m: R4 ... its status";
  is waitpid(-1, POSIX::WNOHANG()), -1, "$m: R4 ... no unreaped kid";
  is_deeply [new_readpipe_split(perl('print "1 2\n3"'))->run], [1, 2, 3], "$m: R4 readpipe_split";
  is waitpid(-1, POSIX::WNOHANG()), -1, "$m: R4 ... no unreaped kid";
}

# The exported spawn() keeps the builtin system's meaning of one string.
unlink 'sh-ran';
my $pid = Run::spawn("echo x >sh-ran");
waitpid $pid, 0;
is slurp('sh-ran'), "x\n", "spawn STRING still goes through the shell";

chdir '/';
done_testing;
