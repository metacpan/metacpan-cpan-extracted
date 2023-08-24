use strict;
use warnings;
use 5.006;

my %META = (
  name => 'Mozilla-CA',
  license => 'open_source',
  author => [ 'Gisle Aas <gisle@activestate.com>' ],
  prereqs => {
    configure => { requires => {
      'ExtUtils::MakeMaker' => 0,
    } },
    test => { requires => {
      'Test::More'  => '0.94',
    } },
  },
  resources => {
    license => [ 'https://www.mozilla.org/media/MPL/2.0/index.txt' ],
    bugtracker => {
      web => 'https://github.com/libwww-perl/Mozilla-CA/issues',
    },
    repository => {
      url => 'https://github.com/libwww-perl/Mozilla-CA.git',
      web => 'https://github.com/libwww-perl/Mozilla-CA',
      type => 'git',
    },
    x_IRC => 'irc://irc.perl.org/#lwp',
  },
  no_index => {
    directory => [ 't', 'xt' ]
  },
  dynamic_config => 0,
);

my %MM_ARGS = (
  dist => {
    TAR => '$(PERL) ./maint/make-tarball',
    TARFLAGS => (
      -e '.git'
        ? '-cv --git-time -f'
        : '-cv --mtime=' . (stat(__FILE__))[9] . ' -f',
    ),
    COMPRESS => 'gzip --no-name --best',
  },
);

## BOILERPLATE ###############################################################
require ExtUtils::MakeMaker;

# have to do this since old EUMM dev releases miss the eval $VERSION line
my $eumm_version  = eval $ExtUtils::MakeMaker::VERSION;
my $mymeta        = $eumm_version >= 6.57_02;
my $mymeta_broken = $mymeta && $eumm_version < 6.57_07;

($MM_ARGS{NAME} = $META{name}) =~ s/-/::/g;
($MM_ARGS{VERSION_FROM} = "lib/$MM_ARGS{NAME}.pm") =~ s{::}{/}g;
$MM_ARGS{ABSTRACT_FROM} = $MM_ARGS{VERSION_FROM}
  unless defined $MM_ARGS{ABSTRACT};
$META{license} = [ $META{license} ]
  if $META{license} && !ref $META{license};
$MM_ARGS{LICENSE} = $META{license}[0]
  if $META{license} && $eumm_version >= 6.30;
$MM_ARGS{NO_MYMETA} = 1
  if $mymeta_broken;
$MM_ARGS{META_ADD} = { 'meta-spec' => { version => 2 }, %META }
  unless -f 'META.yml';
$MM_ARGS{PL_FILES} ||= {};
$MM_ARGS{NORECURS} = 1
  if not exists $MM_ARGS{NORECURS};

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
