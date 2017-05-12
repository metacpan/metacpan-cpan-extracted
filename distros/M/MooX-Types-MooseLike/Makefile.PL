use strict;
use warnings FATAL => 'all';
use 5.008001;

my %META = (
  name => 'MooX-Types-MooseLike',
  license => 'perl_5',
  prereqs => {
    configure => { requires => {
      'ExtUtils::MakeMaker'   => 0,
    } },
    build => { requires => {
    } },
    test => {
      requires => {
        'Test::More' => 0.96,
        'Test::Fatal' => 0.003,
        'Moo' => 1.004002, 
      },
      recommends => {
        'CPAN::Meta' => 0,
        'CPAN::Meta::Requirements' => 0,
      },
    },
    runtime => {
      requires => {
        'Module::Runtime' => 0.014,
      },
      recommends => {
        'strictures' => 2,
      },
    },
    develop   => {
      requires => {
        'strictures' => 2,
        'indirect' => 0,
        'multidimensional' => 0,
        'bareword::filehandles' => 0,
        'Moo' => 1.004002,
      },
    },
  },
  resources => {
    repository => {
      url => 'https://github.com/mateu/MooX-Types-MooseLike.git',
      web => 'https://github.com/mateu/MooX-Types-MooseLike',
      type => 'git',
    },
    x_IRC => 'irc://irc.perl.org/#web-simple',
    bugtracker => {
      web => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooX-Types-MooseLike',
    },
    license => [ 'http://dev.perl.org/licenses/' ],
  },
  x_authority => 'cpan:MATEU',
);

my %MM_ARGS = ('DISTNAME' => 'MooX-Types-MooseLike');

## BOILERPLATE ###############################################################
require ExtUtils::MakeMaker;
(do 'maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

# have to do this since old EUMM dev releases miss the eval $VERSION line
my $eumm_version  = eval $ExtUtils::MakeMaker::VERSION;
my $mymeta        = $eumm_version >= 6.57_02;
my $mymeta_broken = $mymeta && $eumm_version < 6.57_07;

($MM_ARGS{NAME} = $META{name}) =~ s/-/::/g;
($MM_ARGS{VERSION_FROM} = "lib/$MM_ARGS{NAME}.pm") =~ s{::}{/}g;
$META{license} = [ $META{license} ]
  if $META{license} && !ref $META{license};
$MM_ARGS{LICENSE} = $META{license}[0]
  if $META{license} && $eumm_version >= 6.30;
$MM_ARGS{NO_MYMETA} = 1
  if $mymeta_broken;
$MM_ARGS{META_ADD} = { 'meta-spec' => { version => 2 }, %META }
  unless -f 'META.yml';

for (qw(configure build test runtime)) {
  my $key = $_ eq 'runtime' ? 'PREREQ_PM' : uc $_.'_REQUIRES';
  my $r = $MM_ARGS{$key} = {
    %{$META{prereqs}{$_}{requires} || {}},
    %{delete $MM_ARGS{$key} || {}},
  };
  defined $r->{$_} or delete $r->{$_} for keys %$r;
}

$MM_ARGS{MIN_PERL_VERSION} = delete $MM_ARGS{PREREQ_PM}{perl} || 0;

delete $MM_ARGS{MIN_PERL_VERSION}
  if $eumm_version < 6.47_01;
$MM_ARGS{BUILD_REQUIRES} = {%{$MM_ARGS{BUILD_REQUIRES}}, %{delete $MM_ARGS{TEST_REQUIRES}}}
  if $eumm_version < 6.63_03;
$MM_ARGS{PREREQ_PM} = {%{$MM_ARGS{PREREQ_PM}}, %{delete $MM_ARGS{BUILD_REQUIRES}}}
  if $eumm_version < 6.55_01;
delete $MM_ARGS{CONFIGURE_REQUIRES}
  if $eumm_version < 6.51_03;

ExtUtils::MakeMaker::WriteMakefile(%MM_ARGS);
## END BOILERPLATE ###########################################################
