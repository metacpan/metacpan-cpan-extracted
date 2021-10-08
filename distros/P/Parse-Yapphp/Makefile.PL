use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Parse::Yapphp',
    # CORRELATION #py001: $VERSION must be changed in both Parse::Yapphp & Parse::Yapphp::Driver
    'VERSION_FROM' => 'lib/Parse/Yapphp/Driver.pm',
    'MAN3PODS' => { 'lib/Parse/Yapphp.pm' => '$(INST_MAN3DIR)/Parse::Yapphp.3' },
    'PM' => {
              'lib/Parse/Yapphp.pm' => '$(INST_LIBDIR)/Yapphp.pm',
              'lib/Parse/Yapphp/Options.pm' => '$(INST_LIBDIR)/Yapphp/Options.pm',
              'lib/Parse/Yapphp/Driver.pm' => '$(INST_LIBDIR)/Yapphp/Driver.pm',
              'lib/Parse/Yapphp/Driver.php' => '$(INST_LIBDIR)/Yapphp/Driver.php',
              'lib/Parse/Yapphp/Grammar.pm' => '$(INST_LIBDIR)/Yapphp/Grammar.pm',
              'lib/Parse/Yapphp/Lalr.pm' => '$(INST_LIBDIR)/Yapphp/Lalr.pm',
              'lib/Parse/Yapphp/LexerInterface.php' => '$(INST_LIBDIR)/Yapphp/LexerInterface.php',
              'lib/Parse/Yapphp/Output.pm' => '$(INST_LIBDIR)/Yapphp/Output.pm',
              'lib/Parse/Yapphp/Parse.pm' => '$(INST_LIBDIR)/Yapphp/Parse.pm'
            },
	'EXE_FILES' => [ 'yapphp' ],
);

sub MY::postamble {
<<'EOT';
YAPPPARSE = lib/Parse/Yapphp/Parse.pm

$(YAPPPARSE) :: YappParse.yp
	$(PERL) -I./lib yapp -m 'Parse::Yapphp::Parse' -o 'lib/Parse/Yapphp/Parse.pm' YappParse.yp
EOT
}
