use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'Parse::EDID',
    VERSION_FROM   => 'lib/Parse/EDID.pm',
    ABSTRACT_FROM  => 'lib/Parse/EDID.pm',
    LICENSE        => 'GPL_3',
    TEST_REQUIRES  => {
        'Test::More' => '0.93'
    }
);

package MY;

sub postamble {

    return <<'EOF';
SVNPATH = svn+ssh://svn.mageia.org/svn/soft/perl-Parse-EDID

svntag:
	svn cp -m 'version $(VERSION)' $(SVNPATH)/trunk $(SVNPATH)/tags/v$(VERSION)
EOF

}
