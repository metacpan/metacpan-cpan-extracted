# PDL interface to FFTW 2.x

use ExtUtils::MakeMaker;
use Config;

our %hash = ();

my $distmeta = {
   'name' => 'PDL-FFTW',
   'abstract' => 'Obsolete FFTW version 2 bindings for PDL',
   'version'  => '2.024',
   'release_status' => 'stable',
   'author'   => [ 'Chris Marshall <chm@cpan.org>', ],
   'license'  => [ 'perl_5' ],
   'prereqs' => {
      'runtime' => {
         'requires' => {
            'perl'   => '5.006',
            'ExtUtils::Install' => '0',
         },
      },
      'build' => {
         'requires' => {
            'Test::More' => '0',
         },
      }
   },
   'dynamic_config' => 1,
   'meta-spec' => {
      'version' => '2',
      'url'     => 'https://metacpan.org/pod/CPAN::Meta::Spec',
   },
   'generated_by' => 'Chris Marshall',
   'provides' => {
      'PDL::FFTW' => {
         'file' => 'FFTW.pm',
         'version' => '2.024',
      },
   },
};

$hash{NAME} = 'PDL::FFTW';
$hash{VERSION_FROM} = 'FFTW.pm';
$hash{clean}->{FILES} .= ' MANIFEST.bak';
$hash{META_MERGE} = $distmeta;

WriteMakefile(%hash);
