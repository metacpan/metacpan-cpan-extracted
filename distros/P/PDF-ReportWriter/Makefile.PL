use 5.008000;
use ExtUtils::MakeMaker;

WriteMakefile(
                NAME                => 'PDF::ReportWriter',
                VERSION_FROM        => 'lib/PDF/ReportWriter.pm',
                PREREQ_PM           => {
                                            'PDF::API2'         => 0.3,
                                            'Image::Size'       => 2.0,
                                            'XML::Simple'       => 0
                                       },
                ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
                                        (AUTHOR => 'Daniel Kasak <dan@entropy.homelinux.org>') : ()),
);
