use Benchmark qw/:all/;
use POSIX qw//;
use POSIX::strftime::Compiler;
use Time::TZOffset;

my $fmt = '%d/%b/%Y:%T %z';

my @abbr = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
my $t = time;
my @lt = localtime($t);

sub with_sprintf {
    sprintf '%02d/%s/%04d:%02d:%02d:%02d %s', $_[3], $abbr[$_[4]], $_[5]+1900, 
        $_[2], $_[1], $_[0], Time::TZOffset::tzoffset(@_);
}

my $psc = POSIX::strftime::Compiler->new($fmt);
cmpthese(timethese(-1, {
    'compiler' => sub {
        $psc->to_string(@lt);
    },
    'compiler_function' => sub {
        POSIX::strftime::Compiler::strftime($fmt, @lt);
    },
    'posix' => sub {
        POSIX::strftime($fmt,@lt);
    },
    'posix_and_locale' => sub {
        my $old_locale = POSIX::setlocale(&POSIX::LC_ALL);
        POSIX::setlocale(&POSIX::LC_ALL, 'C');
        POSIX::strftime($fmt,@lt);
        POSIX::setlocale(&POSIX::LC_ALL, $old_locale);
    },
#    'compiler_wo_cache' => sub {
#        my $compiler2 = POSIX::strftime::Compiler->new($fmt);
#        $compiler2->to_string(localtime($t));
#    },
    'sprintf' => sub {
        with_sprintf(@lt);
    },
}));


__END__
compiler_function:  1 wallclock secs ( 1.04 usr +  0.00 sys =  1.04 CPU) @ 183794.23/s (n=191146)
posix_and_locale:  1 wallclock secs ( 1.05 usr +  0.00 sys =  1.05 CPU) @ 68265.71/s (n=71679)
   sprintf:  1 wallclock secs ( 1.03 usr +  0.00 sys =  1.03 CPU) @ 208775.73/s (n=215039)
                      Rate posix_and_locale compiler_function compiler   sprintf
posix_and_locale   68266/s               --              -63%     -64%      -67%
compiler_function 183794/s             169%                --      -3%      -12%
compiler          189253/s             177%                3%       --       -9%
sprintf           208776/s             206%               14%      10%        --

