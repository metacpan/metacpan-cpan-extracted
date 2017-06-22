use 5.010001;

use strict;
use warnings;
use ExtUtils::MakeMaker;
use FindBin;

WriteMakefile(
  NAME         => 'Mojolicious::Command::generate::qx_mojo_app',
  VERSION_FROM => 'lib/Mojolicious/Command/generate/qx_mojo_app.pm',
  ABSTRACT     => 'Mojo generator for a qooxdoo mojolicious app',
  AUTHOR       => 'Tobias Oetiker <tobi@oetiker.ch>',
  LICENSE      => 'artistic_2',
  PREREQ_PM    => {
    'Mojolicious' => '7.26',
    'Mojolicious::Plugin::Qooxdoo' => '0.905',
  },
  BUILD_REQUIRES => {
    'CPAN::Uploader' => 0
  },
  META_MERGE   => {
    requires  => {perl => '5.010001'},
    resources => {
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => 'https://github.com/oetiker/qx-mojo-app',
      bugtracker  => 'https://github.com/oetiker/qx-mojo-app/issues'
    },
    no_index => {directory => ['t','lib/Mojolicious/Command/generate/qx_mojo_app']}
  },
  test => {TESTS => 't/*.t'}
);


sub MY::postamble {
   my $self = shift;
   my %r = (%{ $self->{PREREQ_PM} || {} }, %{ $self->{BUILD_REQUIRES} || {} }, %{ $self->{TEST_REQUIRES} || {} } );
   my $modules = join " ", grep !/^perl\@/, map { $r{$_} ? $_ .'@'. $r{$_} : $_ } keys %r;
   my $tpd = "$FindBin::RealBin/thirdparty";
   warn "** call 'make thirdparty' to build missing dependencies ...\n";
   return <<"EOF";
thirdparty: $tpd/touch
	mkdir -p $tpd

$tpd/touch: Makefile
	\$(NOECHO) \$(ECHO) "*** INSTALLING MISSING BITS FOR TESTING ***"
	curl -L https://raw.githubusercontent.com/miyagawa/cpanminus/devel/cpanm | PERL_CPANM_HOME=$tpd \$(PERL) - -q --notest --local-lib-contained $tpd $modules && touch $tpd/touch
EOF
}
