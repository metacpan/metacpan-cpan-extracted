use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Net::SPOCP',
    'VERSION_FROM'	=> 'SPOCP.pm', # finds $VERSION
    'PREREQ_PM'		=> {
      Authen::SASL::Cyrus => 0,
      MIME::Base64 => 0,
      Parse::Yapp => 0,
      IO::Socket::SSL => 0,
    },
    'PM' => {
      'SPOCP.pm' => '$(INST_LIBDIR)/SPOCP.pm',
      'SPOCP/Protocol.pm' => '$(INST_LIBDIR)/SPOCP/Protocol.pm',
      'SPOCP/SExpr.pm' => '$(INST_LIBDIR)/SPOCP/SExpr.pm',
      'SPOCP/SExpr/Parser.pm' => '$(INST_LIBDIR)/SPOCP/SExpr/Parser.pm'
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'SPOCP.pm', # retrieve abstract from module
       AUTHOR     => 'Leif Johansson <leifj@it.su.se>') : ()),
);

sub MY::postamble {
<<'EOT';
YAPPPARSE = SPOCP/SExpr/Parser.pm
$(YAPPPARSE) :: SPOCP/SExpr/Parser.y
	yapp -m 'Net::SPOCP::SExpr::Parser' -o 'SPOCP/SExpr/Parser.pm' SPOCP/SExpr/Parser.y
EOT
}
