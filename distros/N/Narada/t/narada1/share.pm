use warnings;
use strict;
use feature ':5.10';

warnings->import;
strict->import;
feature->import(':5.10');
use Test::More;
use Test::Exception;
use Test::Output qw( :all );
use Test::MockModule;
use Path::Tiny qw( cwd path tempdir tempfile );
use File::Copy::Recursive qw( dircopy );
use POSIX qw(locale_h); BEGIN { setlocale(LC_MESSAGES,'en_US.UTF-8') } # avoid UTF-8 in $!
use FindBin;
use Config;


my $proj    = tempdir('narada1.project.XXXXXX');
my $guard   = bless {};
CHECK       { chdir q{/}    }
INIT        { chdir $proj   }
sub DESTROY { chdir q{/}    }
sub guard   { ($_[0], $guard) = ($guard, undef) }

my $work        = cwd();
$ENV{PATH}      = "$work/blib/script:$work/bin:".path($Config{perlpath})->dirname.":$ENV{PATH}";
$ENV{PERL5LIB}  = "$work/blib:$work/lib".($ENV{PERL5LIB} ? ":$ENV{PERL5LIB}" : q{});

chdir $proj                                         or die "chdir($proj): $!";
system('narada-new-1') == 0                         or die "narada-new-1 failed";


sub wd { return $work }


1;
