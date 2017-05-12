use ExtUtils::MakeMaker;
WriteMakefile(
    NAME            => 'OpenGL::Earth',
    VERSION_FROM    => 'lib/OpenGL/Earth.pm',
    PREREQ_PM       => {
        'OpenGL'                => '0.57',
        # If you so desire, you can control the OpenGL output with a Wiimote
        # but you will need this module, which currently doesn't install
	# out of the box (RT #79833)
        #'Linux::Input::Wiimote' => '0',
    },
	NO_META			=> 1,
    ($] >= 5.005 ?
        (AUTHOR     => 'Cosimo Streppone <cosimo@cpan.org>') : ()),
);
