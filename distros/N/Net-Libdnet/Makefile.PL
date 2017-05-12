#
# $Id: Makefile.PL 57 2012-11-02 16:39:39Z gomor $
#
use ExtUtils::MakeMaker;

my $libs = qx{dnet-config --libs 2>/dev/null}
   || ['-L/lib -L/usr/lib -L/usr/local/lib -ldnet'];

my $inc = qx{dnet-config --cflags 2>/dev/null}
   || '-I/include -I/usr/include -I/usr/local/include';

WriteMakefile(
   NAME          => 'Net::Libdnet',
   VERSION_FROM  => 'lib/Net/Libdnet.pm',
   LICENSE       => 'bsd',
   ABSTRACT_FROM => 'lib/Net/Libdnet.pm',
   AUTHOR        => 'GomoR <gomor-cpan_at_gomor.org>',
   LIBS          => $libs,
   INC           => $inc,
   DEFINE        => '',
   EXE_FILES     => [ @{[glob('bin/*.pl')]} ],
   PREREQ_PM     => {
      Class::Gomor => 0,
   },
   MIN_PERL_VERSION => '5.6.1',
);
