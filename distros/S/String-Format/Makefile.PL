use strict;
use ExtUtils::MakeMaker;

my %clean = (
    'FILES' => '$(DISTVNAME).tar$(SUFFIX)'
);

my $eumm_recent_enough = $ExtUtils::MakeMaker::VERSION >= 6.54;

if (!$eumm_recent_enough) {
    *MY::dist_core = sub {
	<<'EOF';
dist :
	$(NOECHO) $(ECHO) "Sorry, use a newer EUMM!"

EOF
    };
}

WriteMakefile(
    'NAME'          => 'String::Format',
    'VERSION_FROM'  => 'Format.pm',
    'clean'         => \%clean,
    'PREREQ_PM'     => {
        'Test::More' => 0.00,
    },
    AUTHOR => ['Slaven Rezic <srezic@cpan.org>', 'darren chamberlain <darren@cpan.org>'],

    ($eumm_recent_enough
     ? (META_MERGE => {
        resources  => {
            repository => 'git://github.com/dlc/string--format.git',
        } }
       )
     : ()
    ),
);
