#!/usr/bin/perl -w

my $test   = $0;
$test      =~ s,.*/,,;

use Test::Inter;
$t = new Test::Inter "$test";

$ENV{'SHELL_CMD_TESTING'} = 1;

use Shell::Cmd;
use Cwd;
my $vers;
if ($ENV{'RELEASE_TESTING'}) {
   my $dir  = getcwd;
   $dir     =~ /Shell-Cmd-([0-9.]+)/;
   $vers    = $1;
} else {
   # We'll only test the directory/version on my machine.
   # In some instances elsewhere, the install directory in renamed
   # unpredicatbly, so we won't do this test there.
   $vers    = $Shell::Cmd::VERSION;
}

my $obj;
$obj  = new Shell::Cmd;

sub test {
  ($op,@args)=@_;

  if ($op eq 'version') {
     return $obj->version();

  } elsif ($op eq 'dire') {
     return $obj->dire(@args);

  } elsif ($op eq 'flush') {
     return $obj->flush(@args);

  } elsif ($op eq 'env') {
     return $obj->env(@args);

  } elsif ($op eq 'mode') {
     return $obj->mode(@args);

  } elsif ($op eq 'opts') {
     if (@args) {
        return $obj->options(@args);
     } else {
        return ($$obj{'g'}{'mode'},$$obj{'g'}{'echo'},$$obj{'g'}{'failure'});
     }

  } elsif ($op eq 'cmd') {
     $obj->cmd(@args);
     my $err = $$obj{'err'};
     $$obj{'err'} = '';
     return $err;
  }
}

$tests="

version                => $vers

### dire

dire                   => ''

dire /tmp              => 0

dire                   => /tmp

dire /var              => 0

dire                   => /var

flush                  => 

dire                   => ''

### env

env                    => 

env FOO 1 BAR 2        =>

env                    => FOO 1 BAR 2

flush                  =>

env                    => 

env FOO 1 BAR 2        =>

flush env              =>

env                    =>

### opts

opts                   => run noecho exit

opts mode script       => 0

opts                   => script noecho exit

opts echo failed failure continue      => 0

opts                   => script failed continue

flush opts             =>

opts                   => run noecho exit

opts mode script       => 0

flush                  =>

opts                   => run noecho exit

opts mode script       => 0

flush commands         =>

opts                   => script noecho exit

flush                  =>

opts output stdout     => 0

opts output foo        => 1

opts script script     => 0

opts script baz        => 1

opts echo failed       => 0

opts echo ick          => 1

opts failure display   => 0

opts failure yuck      => 1

opts ssh:user myself   => 0

opts ssh_num 3         => 0

opts ssh_sleep 4       => 0

opts tmp_script a      => 0

opts tmp_script_keep a => 0

opts ssh_script a      => 0

opts ssh_script_keep a => 0

opts aaaa 1            => 1

flush                  =>

### mode

mode                   => run

mode script            => 0

mode                   => script

flush                  =>

mode foo               => 1

### cmd

cmd 'echo 1'               => ''

cmd [ 'echo 1' 'echo 2' ]  => ''

cmd {}                     => 'cmd must be a string or listref'

cmd 'echo 1' { dire /tmp } => ''

cmd 'echo 1' { foo /tmp }  => 'Invalid cmd option: foo'

";

$t->tests(func  => \&test,
          tests => $tests);
$t->done_testing();

#Local Variables:
#mode: cperl
#indent-tabs-mode: nil
#cperl-indent-level: 3
#cperl-continued-statement-offset: 2
#cperl-continued-brace-offset: 0
#cperl-brace-offset: 0
#cperl-brace-imaginary-offset: 0
#cperl-label-offset: 0
#End:
