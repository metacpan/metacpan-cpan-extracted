use 5.010001;

use strict;
use warnings;
use ExtUtils::MakeMaker;
use FindBin;

WriteMakefile(
  NAME         => 'Mojolicious::Command::Author::generate::automake_app',
  VERSION_FROM => 'lib/Mojolicious/Command/Author/generate/automake_app.pm',
  ABSTRACT     => 'An app generator for Mojolicious providing app skeletons with automake infrastructure.',
  AUTHOR       => 'Tobias Oetiker <tobi@oetiker.ch>',
  LICENSE      => 'mit',
  PREREQ_PM    => {
    'Mojolicious' => '8'
  },
  BUILD_REQUIRES => {
    'CPAN::Uploader' => 0,
    'Devel::Confess' => 0
  },
  META_MERGE   => {
    requires  => {perl => '5.024001'},
    resources => {
      license     => 'http://opensource.org/licenses/MIT',
      repository  => 'https://github.com/oposs/mojolicious-automake',
      bugtracker  => 'https://github.com/oposs/mojolicious-automake/issues'
    },
    no_index => {
      directory => [
        't',
        'example',
        'setup',
        'lib/Mojolicious/Command/Author/generate/automake_app',
        'lib/Mojolicious/Command/Author/generate/automake_app/lib/App/Controller',
        'lib/Mojolicious/Command/Author/generate/callbackery_app'
      ]
    }
  },
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
#	\$(PERL) -I$tpd/lib/perl5 -MPod::Markdown::Github -e 'binmode(STDOUT, ":utf8");Pod::Markdown::Github->new->filter(q{$self->{VERSION_FROM}})' > README.md

#README: README.md
#	cp README.md README

thirdparty: $tpd/touch
	mkdir -p $tpd

CHANGES: $self->{VERSION_FROM} Makefile
	echo $self->{VERSION} `date +"%Y-%m-%d %H:%M:%S %z"` `git config user.name` '<'`git config user.email`'>' >> CHANGES.new
	\@echo >> CHANGES.new
	\@echo ' -' >> CHANGES.new
	\@echo >> CHANGES.new
	\@cat CHANGES >> CHANGES.new && mv CHANGES.new CHANGES
	\@\$\$EDITOR CHANGES

$tpd/touch: Makefile
	\$(NOECHO) \$(ECHO) "*** INSTALLING MISSING BITS FOR TESTING ***"
	curl -L https://cpanmin.us | env PERL_CPANM_HOME=$tpd \$(PERL) - -q --notest --local-lib-contained $tpd $modules && touch $tpd/touch
EOF
}
