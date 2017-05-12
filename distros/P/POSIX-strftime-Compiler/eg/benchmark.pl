use Benchmark qw/:all/;
use POSIX qw//;
use POSIX::strftime::Compiler;

my $fmt = '%d/%b/%Y:%T';

my @abbr = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
my $t = time;
my @lt = localtime($t);

sub with_sprintf {
    sprintf '%02d/%s/%04d:%02d:%02d:%02d', $_[3], $abbr[$_[4]], $_[5]+1900, 
        $_[2], $_[1], $_[0];
}
my $psc = POSIX::strftime::Compiler->new($fmt);
cmpthese(timethese(-1, {
    'compiler' => sub {
        $psc->to_string(@lt);
    },
    'compiler_function' => sub {
        POSIX::strftime::Compiler::strftime($fmt, @lt);
    },
    'posix_and_locale' => sub {
        my $old_locale = POSIX::setlocale(&POSIX::LC_ALL);
        POSIX::setlocale(&POSIX::LC_ALL, 'C');
        POSIX::strftime($fmt,@lt);
        POSIX::setlocale(&POSIX::LC_ALL, $old_locale);
    },
    'posix' => sub {
        POSIX::strftime($fmt,@lt);
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
Benchmark: running compiler, compiler_function, posix_and_locale, sprintf for at least 1 CPU seconds...
  compiler:  2 wallclock secs ( 1.01 usr +  0.00 sys =  1.01 CPU) @ 454208.91/s (n=458751)
compiler_function:  2 wallclock secs ( 1.14 usr +  0.00 sys =  1.14 CPU) @ 431157.02/s (n=491519)
posix_and_locale:  1 wallclock secs ( 1.11 usr +  0.00 sys =  1.11 CPU) @ 70446.85/s (n=78196)
   sprintf:  1 wallclock secs ( 1.06 usr +  0.00 sys =  1.06 CPU) @ 618264.15/s (n=655360)
                      Rate posix_and_locale compiler_function compiler   sprintf
posix_and_locale   70447/s               --              -84%     -84%      -89%
compiler_function 431157/s             512%                --      -5%      -30%
compiler          454209/s             545%                5%       --      -27%
sprintf           618264/s             778%               43%      36%        --
