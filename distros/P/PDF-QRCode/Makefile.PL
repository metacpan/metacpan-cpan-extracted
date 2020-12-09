use 5.020001;

use strict;
use warnings;
use ExtUtils::MakeMaker;
use FindBin;
use Data::Dumper;
use lib "$FindBin::RealBin/3rd/lib/perl5";

WriteMakefile(
  NAME         => 'PDF::QRCode',
  VERSION_FROM => 'lib/PDF/QRCode.pm',
  ABSTRACT     => 'Add QRCode method to PDF::API2',
  AUTHOR       => 'Tobias Oetiker <tobi@oetiker.ch>',
  LICENSE      => 'artistic_2',
  PREREQ_PM    =>  {
    'Text::QRCode' => 0,
  },
  BUILD_REQUIRES => {
    'CPAN::Uploader' => 0,
    'PDF::API2' => 0,
    'PDF::Builder' => 0,
    'Pod::Markdown::Github' => 0,
  },
  META_MERGE   => {
    requires  => {perl => '5.020001'},
    resources => {
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => 'https://github.com/oetiker/pdf-qrcode',
      bugtracker  => 'https://github.com/oetiker/pdf-qrcode'
    },
    no_index => {directory => ['t','eg']}
  },
  test => {TESTS => 't/*.t'}
);

sub MY::postamble {
   my $self = shift;
   my %r = (%{ $self->{PREREQ_PM} || {} }, %{ $self->{BUILD_REQUIRES} || {} }, %{ $self->{TEST_REQUIRES} || {} } );
   my $modules = join " ", grep !/^perl\@/, map { $r{$_} ? $_ .'@'. $r{$_} : $_ } keys %r;
   my $tpd = "$FindBin::RealBin/3rd";
   warn "** call 'make 3rd' to build missing dependencies ...\n";
   return <<"EOF";

all:: README.md

README.md: $self->{VERSION_FROM}
	\$(PERL) -I$tpd/lib/perl5 -MPod::Markdown::Github -e "binmode(STDOUT, q(:utf8));Pod::Markdown::Github->new->filter(q($self->{VERSION_FROM}))" > README.md

CHANGES: $self->{VERSION_FROM} Makefile
	echo $self->{VERSION} `date +"%Y-%m-%d %H:%M:%S %z"` `git config user.name` '<'`git config user.email`'>' >> CHANGES.new
	\@echo >> CHANGES.new
	\@echo ' -' >> CHANGES.new
	\@echo >> CHANGES.new
	\@cat CHANGES >> CHANGES.new && mv CHANGES.new CHANGES
	\@\$\$EDITOR CHANGES


3rd: $tpd/touch
	mkdir -p $tpd

$tpd/touch: Makefile
	\$(NOECHO) \$(ECHO) "*** INSTALLING MISSING BITS FOR TESTING ***"
	curl -L http://cpanmin.us | env PERL_CPANM_HOME=$tpd \$(PERL) - -q --notest --local-lib-contained $tpd $modules && touch $tpd/touch
EOF
}
