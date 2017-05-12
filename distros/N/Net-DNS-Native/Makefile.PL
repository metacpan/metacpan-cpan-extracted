use v5.6;
use ExtUtils::MakeMaker;
use Config;

unless ($Config{usethreads} || $Config{osname} =~ /darwin|win32|linux/i || $Config{libs} =~ /-l?pthread\b/ || $Config{ldflags} =~ /-l?pthread\b/) {
	die "***This perl may crash while using this module. To avoid this compile your perl linked with pthreads***\n",
	    "   Configure: ./Configure -A prepend:libswanted=\"pthread \"\n",
	    "   perlbrew: perlbrew -A prepend:libswanted=\"pthread \" install perl-5.20.1\n"
}

my @additional;
if ($^O eq 'MSWin32') {
	push @additional, INC    => '-Ipthreads-win32/include';
	push @additional, DEFINE => '-DPTW32_STATIC_LIB';
	my ($arch) = $Config{archname} =~ /mswin32-([^-]+)/i;
	push @additional, LIBS   => [":nosearch -Lpthreads-win32/lib/$arch -lpthread"];
}

WriteMakefile(
	NAME           => 'Net::DNS::Native',
	LICENSE        => 'perl',
	VERSION_FROM   => 'lib/Net/DNS/Native.pm',
	META_MERGE     => {resources => {repository => 'https://github.com/olegwtf/p5-Net-DNS-Native'}},
	ABSTRACT_FROM  => 'lib/Net/DNS/Native.pm',
	AUTHOR         => 'Oleg G <oleg@cpan.org>',
	LIBS           => ['-lpthread'],
	PREREQ_PM      => { 'Socket' => 1.94 },
	BUILD_REQUIRES => { 'Test::More' => 0.88 },
	@additional
);
