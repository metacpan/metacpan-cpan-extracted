use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;
use PDL::Core::Dev;

##############################
# Try to use Alien::FFTW3 - but if it's not present
# fall back to pkg-config.  This is so that 
# a Debian package won't have to include Alien::FFTW3.
my $cflags;
my $libs;

if( eval "require Alien::FFTW3" ) {
    ## Ensure at least version 3.3; die if we can't get it.
    Alien::FFTW3->VERSION(3.3);
    my $p = Alien::FFTW3->precision;
    unless($p->{'d'} and $p->{'f'}) {
	die "PDL::FFTW3 - needs both double-precision and single-precision fftw3 libraries\n\t(libfftw3 and libfftw3f). Alien::FFTW3 found only ".(join(",",keys %$p))."\n";
    }
    $cflags = Alien::FFTW3->cflags;
    $libs   = Alien::FFTW3->libs;
} else {
    print "Alien::FFTW3 not found.  Using pkg-config instead...\n";

    require IPC::Run;
    $cflags = '';
    $libs   = '';
    my $err = '';
    IPC::Run::run( ['pkg-config',
                    '--cflags',
                    'fftw3f >= 3.3', 'fftw3 >= 3.3'],
                   \undef,
                   \$cflags, \$err ) or die "Couldn't get the fftw flags: '$err'";

    IPC::Run::run( ['pkg-config',
                    '--libs',
                    'fftw3f >= 3.3', 'fftw3 >= 3.3'],
                   \undef,
                   \$libs, \$err ) or die "Couldn't get the fftw libs: '$err'";

    chomp($cflags, $libs);
}

my @package = (qw(fftw3.pd FFTW3 PDL::FFTW3), undef, 1);
my %descriptor = pdlpp_stdargs(\@package);

$descriptor{VERSION_FROM} = 'fftw3.pd';

# I support single and double precision FFTW calls, so both fftw and fftw3f
push @{$descriptor{LIBS}  },  $libs;

$descriptor{INC} = '' unless defined $descriptor{INC};
$descriptor{INC} .= " $cflags";

$descriptor{PREREQ_PM} = {
  'PDL' => '2.097', # fixed type-selecting
};
$descriptor{CONFIGURE_REQUIRES} = {
  'PDL' => '2.097',
  'IPC::Run'       =>0,
#  'Alien::FFTW3'   =>0,
};
$descriptor{BUILD_REQUIRES} = {'PDL::PP'=>0};
$descriptor{TEST_REQUIRES} = {'Test::More'=>'0.88'};
$descriptor{AUTHOR} = "Dima Kogan <dima\@secretsauce.net>, Craig DeForest <deforest\@boulder.swri.edu>";
$descriptor{ABSTRACT} = "PDL interface to the Fastest Fourier Transform in the West";
$descriptor{LICENSE}  = "perl";
$descriptor{MIN_PERL_VERSION}  = "5.016";

$descriptor{META_MERGE} = {
  "meta-spec" => { version => 2 },
  resources => {
    bugtracker => { web => 'https://github.com/PDLPorters/pdl-fftw3/issues' },
    repository  => {
      web => 'https://github.com/PDLPorters/pdl-fftw3',
      url => 'git://github.com/PDLPorters/pdl-fftw3.git',
      type => 'git',
    },
    x_IRC => 'irc://irc.perl.org/#pdl',
  },
  prereqs => {
    develop => {
      requires => {
        'CPAN::Changes' => 0,
      },
    },
    test => {
      requires => {
        'Test::More' => '0.98',
      },
    },
  },
};

WriteMakefile( %descriptor );

sub MY::postamble {
  return <<'FOO' . pdlpp_postamble(\@package);

install ::
	@echo "Updating PDL documentation database...";
	@$(PERL) -e "exit if $$ENV{DESTDIR}; use PDL::Doc; eval { PDL::Doc::add_module(q{PDL::FFTW3}); }; ";
FOO
}
