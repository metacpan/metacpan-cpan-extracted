use strict;
use ExtUtils::MakeMaker;

# remove here to PASS test of ActiveState Code. (this software no longer contains warnings.pm)
# http://code.activestate.com/ppm/Fake-Our/
# # Bug #97866 for Modern-Open: Prevent from installing on newer perls
# # https://rt.cpan.org/Public/Bug/Display.html?id=97866
# if ($] >= 5.006) {
#     warn "This distribution is only for perl 5.005.\n";
#     exit 0;
# }

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'             => 'Modern-Open',
    'VERSION_FROM'     => 'Modern/Open.pm', # finds $VERSION
    ($] >= 5.005 ?                          # Add these new keywords supported since 5.005
      ('PREREQ_PM'     => {},               # e.g., Module::Name => 1.1
       'ABSTRACT_FROM' => 'Modern/Open.pm', # retrieve abstract from module
       'AUTHOR'        => 'ina <ina@cpan.org>',
      )
      :
      ()
    ),
);
__END__
