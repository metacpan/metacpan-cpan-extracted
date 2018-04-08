use lib 't'; use share; guard my $guard;


plan skip_all => 'flock not installed'      if !grep {-x "$_/flock"} split /:/, $ENV{PATH};
plan skip_all => 'pgrep not installed'      if !grep {-x "$_/pgrep"} split /:/, $ENV{PATH};
plan skip_all => 'fuser not installed'      if !grep {-x "$_/fuser"} split /:/, $ENV{PATH};
plan skip_all => 'unstable on CPAN Testers' if !$ENV{RELEASE_TESTING} && ($ENV{AUTOMATED_TESTING} || $ENV{PERL_CPAN_REPORTER_CONFIG});


my $pfx = cwd() . '/' . sprintf 'some_script_%d_%d_', time, $$;
for (1 .. 3) {
    my $script = path($pfx.$_);
    $script->spew("#!/bin/sh\nsleep 30");
    $script->chmod(0755);
}


stderr_like { isnt system('narada-bg'), 0, 'no params' } qr/usage/msi, 'got usage';

is   system("\Q${pfx}\E1 &"),                           0, '1 started';
is   system("narada-bg \Q${pfx}\E2 &"),                 0, '2 started';
is   system("narada-bg \Q${pfx}\E3 &"),                 0, '3 started';
sleep 1;
is   system("pgrep -x -f '/bin/sh ${pfx}1' >/dev/null"),0, '1 is running';
is   system("pgrep -x -f '/bin/sh ${pfx}2' >/dev/null"),0, '2 is running';
is   system("pgrep -x -f '/bin/sh ${pfx}3' >/dev/null"),0, '3 is running';
is   system('narada-bg-killall'),                       0, 'narada-bg-killall';
sleep 1;
is   system("pgrep -x -f '/bin/sh ${pfx}1' >/dev/null"),0, '1 is running';
isnt system("pgrep -x -f '/bin/sh ${pfx}2' >/dev/null"),0, '2 is not running';
isnt system("pgrep -x -f '/bin/sh ${pfx}3' >/dev/null"),0, '3 is not running';
chdir 'tmp' or die "chdir(tmp): $!";
is   system('fuser -k .. >/dev/null 2>&1'),             0, 'kill processes using .';
chdir '..' or die "chdir(..): $!";

stderr_like { isnt system('narada-bg-killall 1'), 0, 'too many params' } qr/usage/msi, 'got usage';


done_testing();
