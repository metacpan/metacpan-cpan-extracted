#!/usr/bin/perl -w -*- mode: cperl -*-
use 5.006001; # just being cautious, I did use "our" at least
use strict;
use ExtUtils::MakeMaker qw(:DEFAULT);
use File::Path;
eval { require File::Spec; };
my $HAVE_FILE_SPEC = !$@;
use vars qw($VERSION);

my $Id = q$Id: Makefile.PL 314 2011-03-26 16:49:14Z k $;
$VERSION = sprintf "%.3f", 1 + substr(q$Rev: 314 $,4)/1000;

my $version_diff = 0; # we'll have to die if this becomes true
my $version_from;
{
  local $^W;
  $ExtUtils::MakeMaker::VERSION = eval $ExtUtils::MakeMaker::VERSION;
  warn "Your MakeMaker is a bit dated[$ExtUtils::MakeMaker::VERSION].\nYou should get a new one\n"
        if $ExtUtils::MakeMaker::VERSION < 6.0;
}
if ($HAVE_FILE_SPEC) {
  $version_from = File::Spec->catfile(qw(lib Perl Repository APC.pm));
  my $version_set_manually = 0;

  if ($ARGV[0] && $ARGV[0] eq "--setversion") {
    die "Your perl is a bit dated[$]].\nDo not make a release with it\n" if $] < 5.008;
    die "Your MakeMaker is a bit dated[$ExtUtils::MakeMaker::VERSION].\nDo not make a release with it\n"
        if $ExtUtils::MakeMaker::VERSION < 6.3004;
    die "Your MakeMaker doesn't do the sign woodoo" unless
        MM->can("signature_target");
    shift @ARGV;
    my $st;
    $ENV{LANG} = "C";
    open $st, "svn st -u|" or die;
    my $dirty = 0;
    while (<$st>) {
      next if /^\?/;
      next if /^Head revision:/;
      next if /^Status against revision:/;
      print;
      $dirty++;
    }
    close $st;
    die "Not everything checked in or out?" if $dirty;

    # $re parses the upper boundary of the output of svnversion
    my $re;
    eval q{ $re = qr/(?:\d+:)?(\d+)[SM]*$/; };
    die $@ if $@; # old perl
    my($sv_dot)  = `svnversion .`             =~ $re;
    my($sv_from) = `svn st -u -v $version_from`  =~ /^.{8}\s*(?:\d+)\s*(\d+)/;
    die "Could not determine sv_from or sv_dot"
        unless $sv_from > 0 && $sv_dot > 0;
    if ($version_set_manually) {
      # we must control that the VERSION in CPAN.pm is the same as in the Makefile
      unshift @INC, "lib";
      require $version_from;
      open my $fh, "make the-release-name|" or die;
      my $have_version;
      while (<$fh>) {
        next unless /^version\s+([\d\._]+)/;
        $have_version = eval $1;
      }
      die "could not determine current version from Makefile" unless $have_version;
      eval q{
      no warnings "numeric";
      if ($CPAN::VERSION != $have_version) {
        warn "Not equal: CPAN::VERSION[$CPAN::VERSION] Makefile version[$have_version]";
        $version_diff = 1;
      }
};
      die $@ if $@;
    } else {
      if ($sv_dot > $sv_from) {
        warn "setting some property to make a checkin of this file possible";
        0==system(svn => "propset",
                  "cpan:release",
                  "after_$sv_dot",
                  $version_from) or die;
        warn "checking in to get the version up to the bleading edge";
        0==system(svn => "ci",
                  "-m",
                  "Property set for release after_$sv_dot",
                  $version_from) or die;
        # will have to die after Makefile is rewritten:
        $version_diff = 1;
      }
    }
    exit unless $version_diff;
  }
}

my @exefiles;
for my $f (
           "apc-overview",
           "binsearchaperl",
           "buildaperl",
           "patchaperlup",
           "perlpatch2svn",
           "apc2svn",
          ) {
  push @exefiles, File::Spec->catfile("scripts",$f);
}

my @sign = (MM->can("signature_target") ? (SIGN => 1) : ());
# warn "sign[@sign]";
WriteMakefile(
              NAME         => 'Perl::Repository::APC',
              VERSION_FROM => $version_from,
              EXE_FILES    => \@exefiles,
              PREREQ_PM    => {
                               "Digest::MD5"       => 0,
                               "ExtUtils::Manifest"=> '1.50',
                               "File::Spec"        => 0,
                               "List::Util"        => 0,
                               "Module::CoreList"  => '2.13',
                               "Test::More"        => 0,
                               "version"           => '0.74',
                              },
              ($ExtUtils::MakeMaker::VERSION >= 6.3002 ?
               (LICENSE      => "perl") : (),
              ),
              @sign,
              dist => {
                         DIST_DEFAULT => 'setversion README all chlog tardist',
                         COMPRESS => 'gzip -9',
                        },
);

if ($version_diff){
  die "
==> I had to update some \$VERSIONs <==
==> Your Makefile has been rebuilt. <==
==> Please rerun the make command.  <==
";
}

package MY;

sub postamble {
  q{setversion:
	$(PERL) Makefile.PL --setversion

chlog :: 

# got this from http://ch.tudelft.nl/~arthur/svn2cl/
chlog-trad :
	-/home/src/devel/svn/svn2cl/svn2cl-current/svn2cl.sh --strip-prefix trunk --group-by-day https://k75/public-svn/Perl-Repository-APC > ChangeLog

the-release-name :
	$(NOECHO) $(ECHO) 'version ' $(VERSION)
	$(NOECHO) $(ECHO) 'release-name ' $(DISTVNAME).tar$(SUFFIX)

release ::
	/usr/bin/perl -I../../CPAN/SVN/release-lib -S release $(DISTVNAME).tar$(SUFFIX)
	rm -rf $(DISTVNAME)

}
}

sub libscan {
    my $path = $_[1];
    return '' if $path =~ /\B\.svn\b/;
    return $path;
}

sub dist_ci {
  return qq{ci :
	svn ci
};
}

# I want to keep the fresh signature here and not hidden in the
# tarball
sub dist_test {
  return q{
# if we depend on $(DISTVNAME).tar$(SUFFIX), then the rest of the
# Makefile breaks our intent to NOT remake dist
disttest :
	rm -rf $(DISTVNAME)
	tar xvzf $(DISTVNAME).tar$(SUFFIX)
	cd $(DISTVNAME) && $(ABSPERLRUN) Makefile.PL
	cd $(DISTVNAME) && $(MAKE) $(PASTHRU)
	cd $(DISTVNAME) && $(MAKE) test $(PASTHRU)

distdir ::
	$(CP) $(DISTVNAME)/SIGNATURE ./SIGNATURE
	$(CP) $(DISTVNAME)/META.yml  ./META.yml
	$(CP) $(DISTVNAME)/MANIFEST  ./MANIFEST

}
}

sub distdir {
  my $self = shift;
  my $out = $self->SUPER::distdir;
  $out =~ s/distdir :/distdir ::/g;
  return $out;
}

__END__


=head1 Valuable advice I got

http://rgarciasuarez.free.fr/perl/svnmm.html

=head1 In development

Currently I'm developing the mechanism for a convenient 'make dist'.

1. The first thing that 'make dist' has to do is making sure that
   $VERSION is right in at least one module, the VERSION_FROM module.

2. We add a target called 'setversion' to DIST_DEFAULT:

    DIST_DEFAULT => 'setversion all tardist',

3. We define the target in a postamble:

    sub MY::postamble {
      q{setversion:
            $(PERL) Makefile.PL --setversion
    }
    }

4. When the Makefile is called with --setversion, we do the following:

4.1. We verify that everything has been checked in. We allow only '?'
     in the first column of the output of 'svn st -u'. If we have
     something else, we die, halting any pending make targets.

4.2. We compare what svnversion has to say about "." and the
     VERSION_FROM module. If the upper limit of "." has a higher rev
     than the VERSION_FROM module, then we set a "cpan:release"
     property on the VERSION_FROM module and check it in. Otherwise we
     exit immediately and are done.

4.3. Then we write a new Makefile

4.4. And finally we die, so that the calling make also dies. Our
     message says, "...please rerun the make command".

5. As 'make dist' now always starts with the 'setversion' target, we
   call 'Makefile.PL --setversion' early and fail if we either have
   not checked in or our VERSION_FROM module isn't fresh enough.

6. On an immediate second call to 'make dist' the VERSION_FROM module
   is always fresh enough and the Makefile reflects the exact $VERSION
   we have in the VERSION_FROM module.


=cut


