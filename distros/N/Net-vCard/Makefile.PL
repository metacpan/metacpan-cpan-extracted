use ExtUtils::MakeMaker;

our $VERSION="0.5";

open ABSTRACT, "<", "ABSTRACT";
our $ABSTRACT=<ABSTRACT>;
chomp $ABSTRACT;
close ABSTRACT;

WriteMakefile(
    NAME         => 'Net::vCard',
    VERSION      => $VERSION,
    AUTHOR       => 'Jay J. Lawrence',
    ABSTRACT     => $ABSTRACT,
    EXE_FILES    => [
        'bin/vCard2label',
    ],
    PREREQ_PM    => {
    },

);

open VERSION, ">", "VERSION";
print VERSION "$VERSION";
close VERSION;

