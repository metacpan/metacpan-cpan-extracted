use lib 't'; use share; guard my $guard;


system('narada-lock bash -c "exit 2"');
is $? >> 8, 2, 'narada-lock keep exit status 2';
system('narada-lock true');
is $? >> 8, 0, 'narada-lock keep exit status 0';
system('narada-lock-exclusive bash -c "exit 3"');
is $? >> 8, 3, 'narada-lock-exclusive keep exit status 3';
system('narada-lock-exclusive true');
is $? >> 8, 0, 'narada-lock-exclusive keep exit status 0';
ok `narada-lock echo ok` =~ /ok/,
    'single shared_lock passes';
ok `narada-lock-exclusive echo ok` =~ /ok/,
    'single exclusive_lock passes';
my $cmd = 'bash -c \'echo 1; sleep 1; echo 2\'';
ok `narada-lock $cmd & narada-lock $cmd & wait` =~ /1\n1\n2\n2\n/,
    'two shared_lock passes simultaneously';
ok `narada-lock-exclusive $cmd & narada-lock-exclusive $cmd & wait` =~ /1\n2\n1\n2\n/,
    'two exclusive_lock passes sequentially (in any order)';
SKIP: {
    skip 'unstable on CPAN Testers', 1 if !$ENV{RELEASE_TESTING} && ($ENV{AUTOMATED_TESTING} || $ENV{PERL_CPAN_REPORTER_CONFIG});
    my $cmd2 = 'bash -c \'echo 1x; sleep 1; echo 2x\'';
    my $s = "narada-lock $cmd & sleep 0.2; narada-lock-exclusive $cmd2 & sleep 0.2; narada-lock $cmd & wait";
    ok `$s` =~ /1\n2\n1x\n2x\n1\n2\n/,
        'single shared_lock, then exclusive_lock, then shared_lock passes sequentially (in order)';
}
ok `narada-lock-exclusive narada-lock-exclusive narada-lock echo ok` =~ /ok/,
    '$NARADA_SKIP_LOCK';


done_testing();
