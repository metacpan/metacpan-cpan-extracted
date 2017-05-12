#!/usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $prereqs = {'LWP' => 0,
               'XML::SAX::ExpatXS' => 0,
               'PAR' => 0,
               'PAR::Packer' => 0,
               'Module::Signature' => 0,
               'File::Which' => 0,
               'Archive::Zip' => 1.02,
              };
my @exe_files = map {"scripts/$_"} qw(perlws.pl make_par.pl);
push @exe_files, 'scripts/pnlp_registry.pl' if ($^O eq 'MSWin32');

my $dir = [];
push @$dir, qw(lib);
eval {require Apache2::RequestRec;};
unless ($@) {
  push @$dir, qw(Apache2);
}

my %opts = (
            NAME              => 'PAR::WebStart',
            VERSION_FROM      => 'lib/PAR/WebStart.pm', # finds $VERSION
            EXE_FILES => \@exe_files,
            PL_FILES => {},
            DIR => $dir,
            dist   => {
                        SUFFIX   => 'gz',
                        COMPRESS => 'gzip -9f',
                    },
            PREREQ_PM => $prereqs,
           );

my $eu_version = $ExtUtils::MakeMaker::VERSION;
if ($eu_version >= 5.43) {
  $opts{ABSTRACT} = q{Perl implementation of Java's WebStart};
  $opts{AUTHOR} = 'Randy Kobes <r.kobes@uwinnipeg.ca>';
}
if ($eu_version > 6.11 ) {
  $opts{NO_META} = 1;
}

WriteMakefile(%opts);
