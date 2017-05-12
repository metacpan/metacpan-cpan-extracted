use ExtUtils::MakeMaker;
use File::Spec;

sub catfile {
    return File::Spec->catfile(@_)
}


# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME                => 'Net::MovableType',
    VERSION_FROM	    => 'MovableType.pm',
    PREREQ_PM		    => {
        'SOAP::Lite'        => undef
    },
    EXE_FILES => [ catfile('bin', 'mt'), catfile('bin', 'mt-upload') ],
    ABSTRACT_FROM       => 'MovableType.pm',
    AUTHOR              => 'Sherzod B. Ruzmetov <sherzodr@handalak.com>'
);

