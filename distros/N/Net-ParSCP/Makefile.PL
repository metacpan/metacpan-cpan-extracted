use ExtUtils::MakeMaker;
use warnings;
use strict;

# the contents of the Makefile that is written.

my $MACHINES;

if (defined($ENV{DEVELOPER}) && ($ENV{DEVELOPER} eq 'casiano')) {
  if (-r 'makepods') {
    system('make -f makepods') and die "Can't build pods!";
  }
  else {
    warn "makepods not found!. Skipping creation of pods\n";
  }
  $MACHINES = $ENV{MACHINES} || '127.0.0.1 127.0.0.2';
}

my @exe_files = map { "script/$_" } qw{parpush};

WriteMakefile(
    NAME              => 'Net::ParSCP',
    VERSION_FROM      => 'lib/Net/ParSCP.pm', # finds $VERSION
    PREREQ_PM         => { 'Set::Scalar' => '0' }, # e.g., Module::Name => 1.1
    EXE_FILES         => [ @exe_files ],
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/ParSCP.pod', # retrieve abstract from module
       AUTHOR         => 'Casiano Rodriguez-Leon <casiano.rodriguez.leon@gmail.com>') : ()),
);

sub MY::postamble {

  return '' unless defined($ENV{DEVELOPER}) && ($ENV{DEVELOPER} eq 'casiano');

  $_ = targets();
  s/<<MACHINES>>/$MACHINES/g;

  return $_;
}

sub targets {
  return <<'EOSQT';

PLTAGS=/usr/share/vim/vim71/tools/pltags.pl

coverage:
	 cover -delete
	make HARNESS_PERL_SWITCHES=-MDevel::Cover test
	cover

.PHONY: tags
tags: 
	${PLTAGS} script/parpush lib/Net/ParSCP.pm lib/Net/HostLanguage.pm
	ctags -a --exclude=examples --exclude=t --exclude=doc --exclude=tt2

remotetest:
	remotetest.pl ${DISTVNAME}.tar.gz <<MACHINES>>

EOSQT

}

__END__

=head1 INSTRUCTIONS FOR THE DEVELOPER

=over 2

=item * Set the environment variables:

  $ source etc/setenvforeu

=item * Before building anything, run 
   
   make -f makepods

=back
