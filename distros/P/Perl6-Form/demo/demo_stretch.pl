use Perl6::Form;

my @proc = qw(csh    csh       /bin/perl tcsh       ls);
my @time = qw(05:05  11:02:23  00:02     1238:00:12 00:01);
my @pid  = qw(1230   15245     15672     987        15778);

print form {interleave=>1}, <<'.',
Proc            Time      PID    Elapsed
==============  ========  =====  =======
{[[[[[[[[[[[[}  {]]]]]+}  {[[[}  {[{8+}[} |
.
\@proc,         \@time,   \@pid, [@time];
