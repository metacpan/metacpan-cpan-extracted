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

my @package = qw(FFTW3.pd FFTW3 PDL::FFTW3);
my %descriptor = pdlpp_stdargs(\@package);

$descriptor{VERSION_FROM} = 'FFTW3.pd';
$descriptor{OPTIMIZE}  = ($Config{ccname} =~ m/gcc/) ? '-O2' : $Config{optimize};
$descriptor{CCFLAGS} .= ( ($Config{ccname} =~ m/gcc/) ? '--std=gnu99 ' : '' ) . $Config{ccflags};

# I support single and double precision FFTW calls, so both fftw and fftw3f
push @{$descriptor{LIBS}  },  $libs;

$descriptor{INC} = '' unless defined $descriptor{INC};
$descriptor{INC} .= $cflags;

$descriptor{depend} = { 'FFTW3.pm' => join(' ', qw(template_complex.c template_real.c
                                                   compute_plan_template.xs
                                                   FFTW3_header_include.pm)) };

$descriptor{PREREQ_PM} = {
  'PDL' => '2.030', # working $type->real method
};
$descriptor{CONFIGURE_REQUIRES} = {
  'PDL::Core::Dev' =>0,
  'IPC::Run'       =>0,
#  'Alien::FFTW3'   =>0,
};
$descriptor{BUILD_REQUIRES} = {'PDL::PP'=>0};
$descriptor{NO_MYMETA} = 0;

$descriptor{NAME}   = "PDL::FFTW3";
$descriptor{AUTHOR} = "Dima Kogan <dima\@secretsauce.net>, Craig DeForest <deforest\@boulder.swri.edu>";
$descriptor{ABSTRACT} = "PDL interface to the Fastest Fourier Transform in the West";
$descriptor{LICENSE}  = "gpl_3";

$descriptor{META_MERGE} = {
  "meta-spec" => { version => 2 },
  resources => {
    web => 'http://github.com/PDLPorters/pdl-fftw3',
    bugtracker => { web => 'http://github.com/PDLPorters/pdl-fftw3/issues' },
    url => 'git://github.com/PDLPorters/pdl-fftw3.git',
    type => 'git',
    x_IRC => 'irc://irc.perl.org/#pdl',
  },
  prereqs => {
    develop => {
      requires => {
        'CPAN::Changes' => 0,
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
