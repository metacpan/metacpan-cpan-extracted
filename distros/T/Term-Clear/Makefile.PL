use strict;
use warnings;
use ExtUtils::MakeMaker;

# eval q{
#     use File::ShareDir::Install 0.07;
#     delete_share '.'; # delete it all first
#     install_share 'share'; # install the current version second
#     *MY::postamble = \&File::ShareDir::Install::postamble;
# };
# warn "-- share/ will not be installed --\n\t$@\n-- end sharedir error --\n" if $@;

WriteMakefile(
    NAME          => 'Term::Clear',
    AUTHOR        => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    VERSION_FROM  => 'lib/Term/Clear.pm',
    ABSTRACT_FROM => 'lib/Term/Clear.pm',
    PL_FILES      => {},
    PREREQ_PM     => {                                                    # Do not add POSIX, its a best effort if you want it and have it sort of situation
        'Term::Cap'        => 0,
        'Test::Spec'       => 0,
        'Test::MockModule' => 0,
        'Test::Mock::Cmd'  => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Term-Clear-*' },
);
