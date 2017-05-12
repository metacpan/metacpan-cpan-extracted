use ExtUtils::MakeMaker;

my $prereqs = check_prereqs();

WriteMakefile(
    NAME => 'Ogre::BetaGUI',
    AUTHOR => 'Scott Lanning <slanning@cpan.org>',
    VERSION_FROM => 'lib/Ogre/BetaGUI.pm',
    MAN3PODS => {},
    PREREQ_PM => $prereqs,
);


sub check_prereqs {
    my %prereqs = (
        'Ogre' => 0.37,
        'Test::More' => 0,
    );

    # Check if optional Perl modules are installed
    my $OIS_REQ_VERSION = 0.04;
    unless (eval { require OIS && $OIS::VERSION >= $OIS_REQ_VERSION }) {
        my $msg = "\nNote: the optional Perl module OIS >= $OIS_REQ_VERSION is not installed.\n"
          . "Installing OIS would be a very good idea\n"
          . "unless you have some other way to handle keyboard and mouse input.\n"
          . "It's fine to install it after installing Ogre::BetaGUI.\n\n"
          . "Do you want to install OIS now?";

        my $val = ExtUtils::MakeMaker::prompt($msg, 'y');
        if ($val =~ /^y/i) {
            $prereqs{'OIS'} = $OIS_REQ_VERSION;
            print "\nOIS >= $OIS_REQ_VERSION added to prerequisites.\n";
        }
    }

    return \%prereqs;
}
