use strict;
use warnings;
use ExtUtils::MakeMaker;
use PDL::Core::Dev;

sub MY::libscan
{
    package MY;

    my ($self, $file) = @_;

    # Don't install the README.pod or any .pl file
    return undef if $file =~ /\.pl$|^README.pod/;
    return $self->SUPER::libscan ($file);
}

sub MY::postamble { pdldoc_add() }

my %prereq = (
  'PDL' => '2.105', # pdldoc_add
  'File::Temp'  => 0,
  'Time::HiRes' => 0
);
my %min_version = (
  'PDL::Graphics::Gnuplot' => '2.029', # Gnuplot 6 warnings fixes
);
for my $opt_dep (sort keys %min_version) {
  (my $file = $opt_dep) =~ s#::#/#g;
  next if !eval { require "$file.pm"; 1 }; # not installed, fine
  next if eval { $opt_dep->VERSION($min_version{$opt_dep}); 1 };
  $prereq{$opt_dep} = $min_version{$opt_dep};
}

WriteMakefile(
    NAME                => 'PDL::Graphics::Simple',
    AUTHOR              => ['Craig DeForest <craig@deforest.org>'],
    VERSION_FROM        => 'lib/PDL/Graphics/Simple.pm',
    ABSTRACT_FROM       => 'lib/PDL/Graphics/Simple.pm',
    LICENSE=> 'perl',
    PREREQ_PM => \%prereq,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '7.12', # working .g.c
        'PDL' => '2.105', # pdldoc_add
    },
    TEST_REQUIRES => {
        'Test::More'  => '0.88',
    },
    META_ADD => {
	resources => {
	    homepage => 'https://github.com/PDLPorters/PDL-Graphics-Simple',
	    repository => 'git://github.com/PDLPorters/PDL-Graphics-Simple.git',
	    bugtracker => 'https://github.com/PDLPorters/PDL-Graphics-Simple/issues'
	}
    },

    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'PDL-Graphics-Simple-*' },
	);

# reroute the main POD into a separate README.pod if requested. This is here
# purely to generate a README.pod for the github front page
my $POD_header = <<EOF;
    =head1 OVERVIEW

    PDL::Graphics::Simple is a unified plotting interface for PDL.  The
    main distribution site is CPAN; the development repository is on
    github.com.

    =cut

EOF
$POD_header =~ s{^    }{}gm;

if(exists $ARGV[0] && $ARGV[0] eq 'README.pod')
{
  open MOD, 'lib/PDL/Graphics/Simple.pm' or die "Couldn't open main module";
  open README, '>README.pod'              or die "Couldn't open README.pod";

  print README $POD_header;

  while (<MOD>)
  {
    if (/^=/../^=cut/)
    { print README; }
  }
}

