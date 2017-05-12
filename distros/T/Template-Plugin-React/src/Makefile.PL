use ExtUtils::MakeMaker;

sub error {
    my ($msg) = @_;
    print STDERR "ERROR: $msg\n";
    exit 0;
}

error "SWIG needs to be installed" unless `which swig`;
error "SpiderMonkey needs to be installed" unless `which js-config`;

WriteMakefile(
    NAME         => 'Template::Plugin::React::RESimple',
    VERSION      => '0.008',
    CCFLAGS      => `js-config --cflags`,
    LIBS         => `js-config --libs`,
    OBJECT       => 'RESimple.o RESimple_wrap.o',
    PM           => {
        'RESimple.pm' => '$(INST_LIBDIR)/RESimple.pm'
    },
    clean        => {
        FILES => ['RESimple.pm', 'RESimple_wrap.cxx']
    }
);

sub MY::postamble {
    <<EOF;
RESimple_wrap.cxx RESimple.pm: RESimple.i
	swig -c++ -perl -shadow \$<
EOF
}
