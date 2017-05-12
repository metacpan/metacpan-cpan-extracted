use t::narada1::share; guard my $guard;


plan skip_all => 'OS Inferno not installed'  if !grep {-x "$_/emu-g" && /inferno/} split /:/, $ENV{PATH};
plan skip_all => 'OS Inferno not configured' if `emu-g echo ok 2>/dev/null` !~ /ok/ms;


# get rid of nasty "Killed" message from bash
$ENV{PATH} = "./tmp:$ENV{PATH}";
chomp(my $orig = `which emu-g`);
open my $f, '>', 'tmp/emu-g'                or die "open: $!";
printf {$f} "%s\n", '#!/usr/bin/env bash';
printf {$f} "%s\n", '[ -r /dev/stdin ] && stdin=/dev/stdin || stdin=/dev/null';
printf {$f} "%s %s\n", $orig, '"$@" <$stdin &';
printf {$f} "%s\n", 'wait 2>/dev/null';
close $f                                    or die "close: $!";
chmod 0755, 'tmp/emu-g'                     or die "chmod: $!";

is scalar `narada-emu a b                   2>&1`, "sh: a: './a' file does not exist\n";
is scalar `echo shutdown -h | narada-emu    2>&1`, "shutdown -h\n; ";
is scalar `narada-emu "echo hello inferno"  2>&1`, "hello inferno\n";
is scalar `narada-emu "os -d . pwd"         2>&1`, scalar `pwd`;
is scalar `narada-emu -c0 "cat /dev/jit"    2>&1`, '0';
is scalar `narada-emu -c1 "cat /dev/jit"    2>&1`, '1';


done_testing();
