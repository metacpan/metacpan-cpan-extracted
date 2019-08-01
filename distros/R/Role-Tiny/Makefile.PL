use strict;
use warnings;
use 5.006;

my %META = (
  name => 'Role-Tiny',
  prereqs => {
    test => { requires => {
      'Test::More' => '0.88',
    } },
    runtime => {
      requires => {
        'perl'     => '5.006',
        'Exporter' => '5.57',
      },
      recommends => {
        'Class::Method::Modifiers' => '1.05',
      },
    },
    develop => { recommends => {
      'Class::Method::Modifiers' => '1.05',
      'namespace::autoclean' => 0,
      'Moo' => 0,
    } },
  },
  resources => {
    repository => {
      url => 'git://github.com/moose/Role-Tiny.git',
      web => 'https://github.com/moose/Role-Tiny',
      type => 'git',
    },
    bugtracker => {
        mailto => 'bug-Role-Tiny@rt.cpan.org',
        web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Role-Tiny',
    },
    x_IRC => 'irc://irc.perl.org/#moose',
    license => [ 'http://dev.perl.org/licenses/' ],
  },
  no_index => {
    directory => [ 't', 'xt' ]
  },
);

my $xt = $ENV{EXTENDED_TESTING};
my %MM_ARGS = (
  PREREQ_PM => {
    ("$]" >= 5.010 ? () : ('MRO::Compat' => 0)),
  },
  ($xt ? (
    TEST_REQUIRES => {
      %{ $META{prereqs}{runtime}{recommends} },
      %{ $META{prereqs}{develop}{recommends} },
    },
    test => { TESTS => 't/*.t xt/*.t' },
  ):()),
);

## BOILERPLATE ###############################################################
require ExtUtils::MakeMaker;
(do './maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

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
