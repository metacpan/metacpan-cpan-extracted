use ExtUtils::MakeMaker;
use strict;

my $PACKAGE = 'Secret::Simple';
(my $PACKAGE_FILE = $PACKAGE) =~ s|::|/|g;

WriteMakefile(
    NAME          => $PACKAGE,
    VERSION_FROM  => "lib/$PACKAGE_FILE.pm",
    PREREQ_PM     => {
                       'Carp'                => 0,
                       'Crypt::CBC'          => 0,
                       'Crypt::Rijndael_PP'  => 0,
                       'MIME::Base64'        => 0,
                     },
    AUTHOR        => 'Adam G. Foust <nospam-agf@cpan.org>',
    ABSTRACT_FROM => "lib/$PACKAGE_FILE.pm",
    EXE_FILES     => [ 'bin/sstool' ],
);
