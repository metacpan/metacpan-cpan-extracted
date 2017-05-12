use strict;
use warnings;
use ExtUtils::MakeMaker;

my $module = 'PIX::Walker';
my ($name, $dir);
($name = $module) =~ s/.*::(\w+)/$1.pm/;
($dir = $module) =~ s/::/-/g;

WriteMakefile(
    NAME                => 'PIX::Walker',
    AUTHOR              => 'Jason Morriss <lifo@liche.net>',
    VERSION_FROM        => 'lib/PIX/Walker.pm',
    ABSTRACT_FROM       => 'lib/PIX/Walker.pm',
    PL_FILES            => {},
    PREREQ_PM => {
	'Test::More' => 0,
    },
    dist                => { 
	COMPRESS => 'gzip -9f', 
	SUFFIX => 'gz', 
	PREOP => ("rm -f README; cp INSTALL README; pod2text -80 < lib/PIX/$name >> README; cp -f README $dir-\$(VERSION);"),
    },
    clean               => { FILES => 'PIX-Walker-*' },
);
