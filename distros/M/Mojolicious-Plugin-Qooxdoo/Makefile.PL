use 5.010001;

use strict;
use warnings;
use ExtUtils::MakeMaker;
use FindBin;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::Qooxdoo',
  VERSION_FROM => 'lib/Mojolicious/Plugin/Qooxdoo.pm',
  ABSTRACT     => 'Qooxdoo JSON-RPC support for the Mojolicious Perl framework',
  AUTHOR       => 'Tobias Oetiker <tobi@oetiker.ch>',
  LICENSE      => 'artistic_2',
  PREREQ_PM    => {
    'Mojolicious' => '8'
  },
  BUILD_REQUIRES => {
    'CPAN::Uploader' => 0
  },
  META_MERGE   => {
    requires  => {perl => '5.010001'},
    resources => {
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => 'https://github.com/oetiker/Mojolicious-Plugin-Qooxdoo',
      bugtracker  => 'https://github.com/oetiker/Mojolicious-Plugin-Qooxdoo/issues'
    },
    no_index => {directory => ['t','example','setup']}
  },
# EXE_FILES => ['script/hypnotoad', 'script/mojo', 'script/morbo'],
  test => {TESTS => 't/*.t'}
);

sub MY::postamble {
   my $self = shift;
   my %r = (%{ $self->{PREREQ_PM} || {} }, %{ $self->{BUILD_REQUIRES} || {} }, %{ $self->{TEST_REQUIRES} || {} } );
   my $modules = join " ", grep !/^perl\~/, map { $r{$_} ? $_ .'~'. $r{$_} : $_ } keys %r;
   my $tpd = "$FindBin::RealBin/thirdparty";
   warn "** call 'make thirdparty' to build missing dependencies ...\n";
   return <<"EOF";

#all:: README.md README

#README.md: $self->{VERSION_FROM}
#       \$(PERL) -I$tpd/lib/perl5 -MPod::Markdown::Github -e 'binmode(STDOUT, ":utf8");Pod::Markdown::Github->new->filter(q{$self->{VERSION_FROM}})' > README.md

#README: README.md
#       cp README.md README

thirdparty: $tpd/touch
	mkdir -p $tpd

$tpd/touch: Makefile
	\$(NOECHO) \$(ECHO) "*** INSTALLING MISSING BITS FOR TESTING ***"
	curl -L https://cpanmin.us | PERL_CPANM_HOME=$tpd \$(PERL) - -q --notest --local-lib-contained $tpd $modules && touch $tpd/touch
EOF
}