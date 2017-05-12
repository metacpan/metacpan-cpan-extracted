use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'SVN::Notify::Filter::Watchers',
    AUTHOR              => 'Larry Shatzer, Jr. <larrysh@cpan.org>',
    VERSION_FROM        => 'lib/SVN/Notify/Filter/Watchers.pm',
    ABSTRACT_FROM       => 'lib/SVN/Notify/Filter/Watchers.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'SVN::Notify' => "2.72",
	'File::Spec' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'SVN-Notify-Filter-Watchers-*' },
);
