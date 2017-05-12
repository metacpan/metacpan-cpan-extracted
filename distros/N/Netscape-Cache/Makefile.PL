# -*- perl -*-

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile
  (	
   'NAME'	=> 'Netscape::Cache',
   ($] < 5.005 ? () : 
    ('AUTHOR' => 'Slaven Rezic (eserte@cs.tu-berlin.de)',
     'ABSTRACT_FROM' => 'Cache.pm')
   ),
   'VERSION_FROM' => 'Cache.pm', # finds $VERSION
   'PREREQ_PM'  => {'DB_File' => 0 },
   'LIBS'	=> [''],   # e.g., '-lm' 
   'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
   'INC'	=> '',     # e.g., '-I/usr/include/other' 
   'dist'      => {'COMPRESS'=>'gzip -9f', 'SUFFIX' => '.gz',
		   'POSTOP'=>'-$(CHMOD) 644 $(DISTVNAME).tar$(SUFFIX)'},
  );

sub MY::postamble {
    my $postamble = "";

    if (defined $ENV{USER} && $ENV{USER} eq 'eserte' && $^O =~ /bsd/i && -f "../../perl.release.mk") {
	$postamble .= <<'EOF';

.include "../../perl.release.mk"
.include "../../perl.cvs.mk"

EOF
    }

    $postamble;
}
