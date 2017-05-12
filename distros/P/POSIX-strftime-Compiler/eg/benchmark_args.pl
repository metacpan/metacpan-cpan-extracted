use Benchmark qw/:all/;
use POSIX qw//;
use POSIX::strftime::Compiler;

my $fmt = $ARGV[0] || '%d/%b/%Y:%T';

my $t = time;
my @lt = localtime($t);

my $psc = POSIX::strftime::Compiler->new($fmt);
print "sample: " . $psc->to_string(@lt) ."\n";

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
}));
