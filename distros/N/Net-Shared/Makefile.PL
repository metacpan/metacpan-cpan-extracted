use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile
(
    'NAME'		=> 'Net::Shared',
    'VERSION_FROM'	=> 'Shared.pm',
    'PREREQ_PM'		=> {}, ($] >= 5.005 ? (
                                               ABSTRACT_FROM => 'Shared.pm', 
                                               AUTHOR        => 'Joseph F. Ryan <ryan.311@osu.edu>') : ()),
);
