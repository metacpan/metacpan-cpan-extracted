use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

#generate a Githun friendly README as per
# http://blogs.perl.org/users/michal_wojciechowski/2011/11/github-friendly-readme-files-with-extutils-makemaker-and-module-build.html

my $preop =
    'perldoc -uT $(VERSION_FROM) | tee $(DISTVNAME)/README.pod > README.pod;' .
    'pod2text README.pod | tee $(DISTVNAME)/README > README';


WriteMakefile(
    NAME                => 'Storage::Nexsan::NMP',
    AUTHOR              => q{John Constable <john.constable@sanger.ac.uk>},
    VERSION_FROM        => 'lib/Storage/Nexsan/NMP.pm',
    ABSTRACT_FROM       => 'lib/Storage/Nexsan/NMP.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', PREOP => $preop, },
    clean               => { FILES => 'Storage-Nexsan-NMP-*' },
);
