

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Template::Plugin::Stash',
    VERSION_FROM => 'lib/Template/Plugin/Stash.pm', # finds \$VERSION
    AUTHOR       => 'D. H. (PodMaster)',
    ABSTRACT     => 'Template::Plugin::Stash - expose the stash, ideal for Dumpering...',
    PREREQ_PM    => {
        'Test::Simple' => 0.44,
        'Template::Plugin' => 0,
    },
);
__END__
perl Makefile.PL && nmake realclean && cls && perl Makefile.PL && nmake disttest
nmake dist TAR=ptar
chmod 7777 *.gz
perl -le" `cpan-upload $_` for( (sort glob q,*.gz,)[-1]) "
