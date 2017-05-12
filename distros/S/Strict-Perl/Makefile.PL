use strict;
use ExtUtils::MakeMaker;

# this tips via Jcode module http://search.cpan.org/dist/Jcode/
my @EXTRA = (
    'NORECURS' => 1,
    'PL_FILES' => {
    },
    'PM' => {
        'Strict/Perl.pm' => '$(INST_LIB)/Strict/Perl.pm',
    },
);

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'             => 'Strict::Perl',
    'VERSION_FROM'     => 'Strict/Perl.pm', # finds $VERSION
    ($] >= 5.005 ?                          # Add these new keywords supported since 5.005
      ('PREREQ_PM'     => {},               # e.g., Module::Name => 1.1
       'ABSTRACT_FROM' => 'Strict/Perl.pm', # retrieve abstract from module
       'AUTHOR'        => 'ina <ina@cpan.org> in a CPAN',
      )
      :
      ()
    ),
    @EXTRA,
);

__END__
