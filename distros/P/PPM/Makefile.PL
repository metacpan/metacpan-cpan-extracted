use ExtUtils::MakeMaker;
use Config;
use strict;

my @program = qw(ppm.pl);

WriteMakefile(
    'NAME'          => 'PPM',
    'VERSION_FROM'  => 'bin/ppm.pl', # finds $VERSION
    'ABSTRACT_FROM' => 'bin/ppm.pl',
    'EXE_FILES'     => [ "bin/ppm.pl" ],
    'AUTHOR'        => 'Murray Nesbitt &lt;murray@cpan.org&gt;',
    'PREREQ_PM'     => { 'Archive::Tar'   => 0,
                         'Compress::Zlib' => 0,
                         'XML::Parser'    => 2.09,
                         'LWP::UserAgent' => 0,
                         'LWP::Simple'    => 0,
                         'SOAP::Lite'     => 0,
                       },
    'dist'          =>  { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);

ppm_config();

sub MY::postamble {

my $copy = $^O eq 'MSWin32' ? 'copy ppm.xml blib\lib' : 'cp ppm.xml blib/lib';
my $postamble = '
all ::';

$postamble .= '
	mv blib/script/ppm.pl blib/script/ppm
	mv blib/man1/ppm.pl.1 blib/man1/ppm.1' unless ($^O eq 'MSWin32');

$postamble .= "
	$copy" unless -f "$Config{sitelib}/ppm.xml";

    $postamble;
}

sub ppm_config {
   my $ppm = 'ppm.xml';
   my $copy = $ppm . '.in';
   my $location = ($] < 5.008) ?
       'http://ppm.ActiveState.com/cgibin/PPM/ppmserver.pl?urn:/PPMServer' :
           'http://ppm.ActiveState.com/cgibin/PPM/ppmserver-5.8-windows.pl?urn:/PPMServer';
   my $codebase = ($] < 5.008) ?
       'http://ppm.ActiveState.com/PPMPackages/5.6plus/MSWin32-x86-multi-thread' :
           'http://ppm.activestate.com/PPMPackages/5.8-windows/MSWin32-x86-multi-thread-5.8';
   rename $ppm, $copy unless (-f $copy);
   my %subs = ( '%OSNAME%'    => $Config{osname},
                '%OSVERSION%' => '4,0,0,0',
                '%TEMP%'      => $ENV{TMP} || $ENV{TEMP},
                '%SITELIB%'   => $Config{sitelib},
                '%PERLDIR%'   => $Config{prefix},
                '%LOCATION%'  => $location,
                '%CODEBASE%'  => $codebase,
              );
   open(OLD, $copy) or die "Cannot open $copy: $!";
   open(NEW, ">$ppm") or die "Cannot open $ppm: $!";
   while(<OLD>) {
      foreach my $key (keys %subs) {
         s/$key/$subs{$key}/g;
      }
      print NEW $_;
   }
   close OLD;
   close NEW;
}

