use t::share; guard my $guard;
use Time::HiRes qw( time sleep );
use Fcntl qw(:DEFAULT :flock F_SETFD FD_CLOEXEC);
use Errno;

use Narada::Lock qw( shared_lock exclusive_lock unlock_new unlock child_inherit_lock );
use constant LOCKNEW    => Narada::Lock::LOCKNEW;
use constant LOCKFILE   => Narada::Lock::LOCKFILE;


plan skip_all => 'unstable on CPAN Testers' if !$ENV{RELEASE_TESTING} && ($ENV{AUTOMATED_TESTING} || $ENV{PERL_CPAN_REPORTER_CONFIG});


sub between;

sysopen my $F_lock, LOCKFILE, O_RDWR|O_CREAT or die "open: $!";


# unlock() - no error if no lock
# unlock_new() - no error if no lock
lives_ok { unlock()     } 'unlock without lock';
lives_ok { unlock_new() } 'unlock_new without lock';

# shared_lock() - set lock immediately
# unlock() - unlock ok
ok !has_sh(),   'no  shared lock before shared_lock()';
between 0, 0.5, sub { ok shared_lock(), 'shared_lock() successful' };
ok has_sh(),    'has shared lock after shared_lock()';
unlock();
ok !has_sh(),   'no  shared lock after unlock()';

# shared_lock(0) - set lock immediately
# shared_lock(2) - set lock immediately
between 0, 0.5, sub { ok shared_lock(0), 'shared_lock(0) successful' };
between 0, 0.5, sub { ok shared_lock(2), 'shared_lock(2) successful' };

# shared_lock()  with `narada-lock-exclusive sleep 1` in background
#   - set lock in 1 second
unlock(); system('narada-lock-exclusive sleep 1 &'); sleep 0.2;
between 0.5, 1.5, sub { ok shared_lock(), 'shared_lock() successful after exclusive' };
# shared_lock(0)  with `narada-lock-exclusive sleep 1` in background
#   - return error immediately
unlock(); system('narada-lock-exclusive sleep 1 &'); sleep 0.2;
between 0, 0.5, sub { ok !shared_lock(0), 'shared_lock(0) failed while exclusive' };
shared_lock();  # wait for narada-lock-exclusive finish
# shared_lock(2)  with `narada-lock-exclusive sleep 1` in background
#   - set lock in 1 second
unlock(); system('narada-lock-exclusive sleep 1 &'); sleep 0.2;
between 0.5, 1.5, sub { ok shared_lock(2), 'shared_lock(2) successful after exclusive' };
# shared_lock(1)  with `narada-lock-exclusive sleep 2` in background
#   - return error in 1 second
unlock(); system('narada-lock-exclusive sleep 2 &'); sleep 0.2;
between 0.5, 1.5, sub { ok !shared_lock(1), 'shared_lock(1) failed while exclusive' };
shared_lock();  # wait for narada-lock-exclusive finish
unlock();

# exclusive_lock() - set lock immediately, create file LOCKNEW
# unlock_new() - remove file LOCKNEW, keep lock
# unlock() - unlock
ok !has_ex(),   'no  exclusive lock before exclusive_lock()';
ok !-e LOCKNEW, 'no  LOCKNEW file   before exclusive_lock()';
between 0, 0.5, sub { exclusive_lock() };
ok has_ex(),    'has exclusive lock after exclusive_lock()';
ok -e LOCKNEW,  'has LOCKNEW file   after exclusive_lock()';
unlock_new();
ok has_ex(),    'has exclusive lock after unlock_new()';
ok !-e LOCKNEW, 'no  LOCKNEW file   after unlock_new()';
unlock();
ok !has_ex(),   'no  exclusive lock after unlock()';

# exclusive_lock()  with `narada-lock sleep 1` in background
#   - set lock in 1 second
unlock_new(); unlock(); system('narada-lock sleep 1 &'); sleep 0.2;
between 0.5, 1.5, sub { exclusive_lock() };
# exclusive_lock()  with `narada-lock-exclusive sleep 1` in background
#   - set lock in 1 second, create file LOCKNEW
unlock_new(); unlock(); system('narada-lock-exclusive sleep 1 &'); sleep 0.2;
between 0.5, 1.5, sub { exclusive_lock() };
ok -e LOCKNEW, 'has LOCKNEW file after exclusive_lock()';
# exclusive_lock(), unlock()
#   * shared_lock(0)
#       - return error immediately
#   * unlock_new(), shared_lock(0)
#       - set lock immediately
unlock_new(); unlock();
exclusive_lock();
unlock();
between 0, 0.5, sub { ok !shared_lock(0), 'shared_lock(0) failed with LOCKNEW' };
unlock_new();
between 0, 0.5, sub { ok shared_lock(0), 'shared_lock(0) successful without LOCKNEW' };

# run process, which will do shared_lock(), run sleep 1 & and exits
#   - there should be no lock
my @I = map {"-I$_"} @INC;
unlock_new(); unlock(); system($^X,@I,'-MNarada::Lock=shared_lock,child_inherit_lock','-e',
    'shared_lock(); system("sleep 1 &")');
ok !has_sh(), 'no  shared lock without child_inherit_lock(1)';
# run process, which will do shared_lock(), child_inherit_lock(1),
# run sleep 1 & sleep 2 & and exits
#   - there should be lock, and it should be unlocked in 2 seconds
unlock_new(); unlock(); system($^X,@I,'-MNarada::Lock=shared_lock,child_inherit_lock','-e',
    'shared_lock(); child_inherit_lock(1); system("sleep 1 & sleep 2 &")');
ok has_sh(),  'has shared lock with child_inherit_lock(1)';
sleep 2.5;
ok !has_sh(), 'no  shared lock after childs exit';
# run process, which will do shared_lock(), child_inherit_lock(1),
# run sleep 1 &, will do child_inherit_lock(0), run sleep 2 & and exits
#   - there should be lock, and it should be unlocked in 1 second
unlock_new(); unlock(); system($^X,@I,'-MNarada::Lock=shared_lock,child_inherit_lock','-e',
    'shared_lock(); child_inherit_lock(1); system("sleep 1 &");
     child_inherit_lock(0); system("sleep 2 &")');
ok has_sh(),  'has shared lock with child_inherit_lock(1)';
sleep 1.5;
ok !has_sh(), 'no  shared lock after first child exit';


done_testing();


sub has_sh {
    my $has_sh = !flock $F_lock, LOCK_EX|LOCK_NB;
    flock $F_lock, LOCK_UN;
    return $has_sh;
}

sub has_ex {
    my $has_ex = !flock $F_lock, LOCK_SH|LOCK_NB;
    flock $F_lock, LOCK_UN;
    return $has_ex;
}

sub between {
    my ($min, $max, $code) = @_;
    my $t = time();
    $code->();
    $t = time()-$t;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    ok $min <= $t && $t <= $max, "... done in $min .. $max sec ($t sec)";
    return;
}
