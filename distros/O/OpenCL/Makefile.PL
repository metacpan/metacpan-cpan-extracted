use ExtUtils::MakeMaker;

print <<EOF;

*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***


OpenCL does not have good backwards compatibility - for example, the only
way to create a 2D image in OpenCL 1.1 is clCreateImage2D, which is not
available anymore with OpenCL 1.2.

The OpenCL module can often emulate OpenCL 1.1 functions using OpenCL 1.2
functions, but even though your OpenCL library might contain the OpenCL
1.2 functions, they might be nonfunctional and crash.

Do you want to prefer the OpenCL 1.1 API over the 1.2 API where possible?

EOF

my $DEFINE .= " -DPREFER_1_1=" . (0 + (prompt ("Prefer OpenCL 1.1 over 1.2 functions (y/n)?", "y") =~ /[yY]/));

WriteMakefile(
    dist	=> {
	            PREOP	=> 'pod2text OpenCL.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    PREREQ_PM => {
       common::sense    => 3,
       Async::Interrupt => 1.1,
    },
    DEFINE => $DEFINE,
    NAME => "OpenCL",
    VERSION_FROM => "OpenCL.pm",
    LIBS => ["-lOpenCL -lpthread"],
);

