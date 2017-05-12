## checking google-code
use warnings;
use strict;
use ExtUtils::MakeMaker;

# treereg is the compiler for the tree transformation language
my @exe_files = qw{eyapp treereg};

if (defined($ENV{DEVELOPER}) && ($ENV{DEVELOPER} eq 'casiano')) {
 system(q{
   yapp -n -m 'Parse::Eyapp::Parse' -o 'lib/Parse/Eyapp/Parse.pm' lib/Parse/Eyapp/Parse.yp;
   eyapp -l -n -m Parse::Eyapp::Treeregparser -o lib/Parse/Eyapp/Treeregexp.pm lib/Parse/Eyapp/Treeregexp.yp
  }
 );
}
WriteMakefile(
    'NAME'         => 'Parse::Eyapp',
    'VERSION_FROM' => 'lib/Parse/Eyapp.pm', # finds $VERSION
    'PREREQ_PM'    => { 
    'List::Util'   => "1.0", 
    'Data::Dumper' => "1.0",
    'Pod::Usage'   => "1.0", 
    },
    'EXE_FILES'    => \@exe_files,
    ABSTRACT_FROM  => 'lib/Parse/Eyapp.pod', 
    AUTHOR         => 'Casiano Rodriguez-Leon <casiano@ull.es>',
);

sub MY::postamble {

  return '' unless defined($ENV{DEVELOPER}) && ($ENV{DEVELOPER} eq 'casiano');

  require File::Basename;
  
  my $listwithsuffix = sub {
    my $suffix = shift;
    my $lws =  "@_";

    $lws =~ s/(\S+)/$1$suffix/xg;
    return  $lws;
  };

  ### Configuration variables: Change them if you change machine ####
  ### Depend on environment variables set via "source etc/setperl5lib" ##

  my ($PUBLIC_PLACE, $MACHINES, $REMOTETEST);

  ################# END configuration variables #####################

  my ($manifest, @PODS, @BASES, @NOEXT);

  open($manifest ,'<', 'MANIFEST') or die "Can't find MANIFEST";

    @PODS = grep { m{lib/Parse/.*\.pod$}x } <$manifest>;

  close($manifest) or return '';

  chomp(@PODS); # i.e. ( lib/Parse/Eyapp/Base.pod, lib/Parse/Eyapp/debuggingtut.pod, lib/Parse/Eyapp/Driver.pod ... )

  return '' unless @PODS;

  my ($PODS, $TEXS, $DVIS, $PDFS, $HTMLS);

  # Directory where to publish documentation.
  $PUBLIC_PLACE = $ENV{PUBLIC_PLACE} || "/home/$ENV{USER}/public_html/perlexamples/";

  # Run 'make test' in those machines via SSH
  $MACHINES = $ENV{MACHINES} || '127.0.0.1 127.0.0.2';

  # Where the remote.pl program is:
  # Be sure is in the path
  $REMOTETEST = $ENV{REMOTETEST} || 'remotetest.pl';

  @BASES = map { File::Basename::basename($_, '.pod') } @PODS; # i. e. ( Base.pod, debuggingtut.pod, ... )
  @NOEXT = map { m{(.*)\.pod$}; $1 } @PODS;    # i. e. ( lib/Parse/Eyapp/Base, lib/Parse/Eyapp/debuggingtut, lib/Parse/Eyapp/Driver ... )

  $PODS = "@PODS";

  $TEXS =  $listwithsuffix->(".tex", @BASES);

  $DVIS =  $listwithsuffix->(".dvi", @BASES);

  $PDFS =  $listwithsuffix->(".pdf", @BASES);

  $HTMLS = $listwithsuffix->(".html", @NOEXT);

  $_ = targets(
    PODS         => $PODS, 
    TEXS         => $TEXS, 
    DVIS         => $DVIS, 
    PDFS         => $PDFS, 
    HTMLS        => $HTMLS, 
    PUBLIC_PLACE => $PUBLIC_PLACE, 
    MACHINES     => $MACHINES,
    REMOTETEST   => $REMOTETEST
  );


  return $_;
}

sub targets {
  my %var = @_;

  $_ = <<'EOSQT';

PLTAGS=/usr/share/vim/vim71/tools/pltags.pl

PODS=<<PODS>>

TEXS=<<TEXS>>

DVIS=<<DVIS>>

PDFS=<<PDFS>>

HTMLS=<<HTMLS>>

publicdist: docclean release forcepods publichtml publicpdf dist 
	chmod a+r Parse-Eyapp-*.tar.gz
	cp Parse-Eyapp-*.tar.gz <<PUBLIC_PLACE>>Parse-Eyapp.tar.gz
	cp Parse-Eyapp-*.tar.gz /tmp/
	chmod a+r <<PUBLIC_PLACE>>Parse-Eyapp.tar.gz

release: lib/Parse/Eyapp/Parse.yp
	   yapp -n -m 'Parse::Eyapp::Parse' -o 'lib/Parse/Eyapp/Parse.pm' lib/Parse/Eyapp/Parse.yp
	   eyapp -ln -m 'Parse::Eyapp::Parse' -o 'lib/Parse/Eyapp/Parse.pm' lib/Parse/Eyapp/Parse.yp
	   $(PERL) -I./lib eyapp -l -n -m Parse::Eyapp::Treeregparser -o lib/Parse/Eyapp/Treeregexp.pm lib/Parse/Eyapp/Treeregexp.yp
	   rm -fR Parse-Eyapp-*.tar.gz

       # as release but line numbers info. No -n option
debug: lib/Parse/Eyapp/Parse.yp
	   yapp -m 'Parse::Eyapp::Parse' -o 'lib/Parse/Eyapp/Parse.pm' lib/Parse/Eyapp/Parse.yp

coverage:
	cover -delete
	make HARNESS_PERL_SWITCHES=-MDevel::Cover test
	cover

remotetest: ${DISTVNAME}.tar.gz
	<<REMOTETEST>> ${DISTVNAME}.tar.gz <<MACHINES>>

docclean:
	rm -f *.tex *.dvi *.pdf *.toc *.ind *.ilg *.aux *.html *.log *.idx

lib/Parse/Eyapp.pod: tt2/Eyapp.tt2
	cd tt2; tpage  Eyapp.tt2 > ../lib/Parse/Eyapp.pod

lib/Parse/Eyapp/%.pod:tt2/%.tt2 tt2/defaultactions tt2/grammarreuseviainheritance tt2/seealso tt2/authorandcopyright
	cd tt2; tpage  $*.tt2 > ../$@

pods: ${PODS}

forcepods: 
	touch tt2/*.tt2
	make pods

%.dvi:%.tex
	latex $*.tex; makeindex $*; latex $*.tex

dvis: ${DVIS}

Eyapp.tex:lib/Parse/Eyapp.pod
	pod2latex -full lib/Parse/Eyapp.pod

%.tex:lib/Parse/Eyapp/%.pod
	pod2latex -full -prefile preamble lib/Parse/Eyapp/$*.pod

texs: ${TEXS}

treereg.html:treereg
	pod2cpanhtml treereg  $@

eyapp.html:eyapp
	pod2cpanhtml eyapp $@

%.html:%.pod
	pod2cpanhtml $*.pod $@
	#perl -e 's/^Cannot find .*//gi; s/\A\s+//' -p -i.bak $@

htmls: ${HTMLS} eyapp.html treereg.html 

<<PUBLIC_PLACE>>%.pdf:%.pdf
	cp $*.pdf <<PUBLIC_PLACE>>
	chmod a+r <<PUBLIC_PLACE>>*.pdf

%.pdf:%.dvi
	dvipdfm $*.dvi 
	#rm -f $*.aux  $*.dvi  $*.idx  $*.ilg  $*.ind  $*.log  $*.tex  $*.toc

pdfs: ${PDFS}

publicpdf: pdfs
	cp ${PDFS} <<PUBLIC_PLACE>>
	chmod a+r <<PUBLIC_PLACE>>*.pdf

publichtml: htmls
	cp ${HTMLS} eyapp.html treereg.html <<PUBLIC_PLACE>>
	chmod a+r <<PUBLIC_PLACE>>/*.html
	
commit:
	svn commit -mm --username casiano.rodriguez.leon

.PHONY: tags
tags: 
	${PLTAGS} eyapp treereg lib/Parse/Eyapp/*.pm lib/Parse/Eyapp/*.yp lib/Parse/Eyapp.pm 
	ctags -a --exclude=examples --exclude=t --exclude=doc --exclude=tt2

wiki:
	#Pod::Simple::Wiki::Googlecode
	pod2wiki --style googlecode lib/Parse/Eyapp/debuggingtut.pod | ./filter.pl > debuggingtut.wiki

EOSQT

  # Replace variables
  # TODO: Check that all <<variables>> are present in @_
  for my $k (keys(%var)) {
	  my $r = $var{$k};
    s/<<$k>>/$r/ge;
  }

  return $_;
}

__END__

=head1 NAME 

Makefile.PL - Makefile generator for Parse::Eyapp. Developer notes

=head1 SYNOPSIS

=over 2

=item * When working as a developer run

           source etc/myscript

to set the appropriate environment variables. Some variables to set are:

  PATH                  to execute eyapp, treereg, etc.
  PERL5LIB              to find any modules required
  DEVELOPER             used by many skip tests
  MACHINES              a white space string containing the machines
                        for the 'remotetest' target
  PUBLIC_PLACE          A dir to save the pdf files

=item * After you checked out from the svn repository this project, and set the environment variables,
try to produce a C<Makefile>. You will surely get a warning:

  pl@nereida:~/src/perl/Parse-Eyapp$ perl Makefile.PL
  Checking if your kit is complete...
  Warning: the following files are missing in your kit:
          lib/Parse/Eyapp/Parse.pm
          lib/Parse/Eyapp/Treeregexp.pm
  Please inform the author.
  Writing Makefile for Parse::Eyapp

This is because the files C<lib/Parse/Eyapp/Parse.pm> and C<lib/Parse/Eyapp/Treeregexp.pm> are derived
from the respective grammars (C<lib/Parse/Eyapp/Parse.yp> and C<lib/Parse/Eyapp/Treeregexp.yp>). 

It will also complain about the absence of the pods

  Warning: the following files are missing in your kit:
        lib/Parse/Eyapp/MatchingTrees.pod
        lib/Parse/Eyapp/translationschemestut.pod
        lib/Parse/Eyapp/YATW.pod

The pods are built from the templates in C<tt2/>.

Compile the grammars and produce the pods using the makefile C<makepods>:

  Parse-Eyapp$ make -f makepods
  yapp -n -m 'Parse::Eyapp::Parse' -o 'lib/Parse/Eyapp/Parse.pm' lib/Parse/Eyapp/Parse.yp
  PERL5LIB=lib; eyapp -n -m 'Parse::Eyapp::Parse' -o 'lib/Parse/Eyapp/Parse.pm' lib/Parse/Eyapp/Parse.yp
  PERL5LIB=lib; perl eyapp -v -n -m Parse::Eyapp::Treeregparser -o lib/Parse/Eyapp/Treeregexp.pm lib/Parse/Eyapp/Treeregexp.yp
  rm -fR Parse-Eyapp-*.tar.gz
  cd tt2; tpage  Base.tt2 > ../lib/Parse/Eyapp/Base.pod
  cd tt2; tpage  datagenerationtut.tt2 > ../lib/Parse/Eyapp/datagenerationtut.pod
  cd tt2; tpage  debuggingtut.tt2 > ../lib/Parse/Eyapp/debuggingtut.pod
  cd tt2; tpage  defaultactionsintro.tt2 > ../lib/Parse/Eyapp/defaultactionsintro.pod
  cd tt2; tpage  Driver.tt2 > ../lib/Parse/Eyapp/Driver.pod
  cd tt2; tpage  eyappintro.tt2 > ../lib/Parse/Eyapp/eyappintro.pod
  cd tt2; tpage  eyapplanguageref.tt2 > ../lib/Parse/Eyapp/eyapplanguageref.pod
  cd tt2; tpage  MatchingTrees.tt2 > ../lib/Parse/Eyapp/MatchingTrees.pod
  cd tt2; tpage  Node.tt2 > ../lib/Parse/Eyapp/Node.pod
  cd tt2; tpage  Parse.tt2 > ../lib/Parse/Eyapp/Parse.pod
  cd tt2; tpage  Scope.tt2 > ../lib/Parse/Eyapp/Scope.pod
  cd tt2; tpage  TokenGen.tt2 > ../lib/Parse/Eyapp/TokenGen.pod
  cd tt2; tpage  translationschemestut.tt2 > ../lib/Parse/Eyapp/translationschemestut.pod
  cd tt2; tpage  Treeregexp.tt2 > ../lib/Parse/Eyapp/Treeregexp.pod
  cd tt2; tpage  YATW.tt2 > ../lib/Parse/Eyapp/YATW.pod


This target uses L<Parse::Yapp> to make a first compilation. Then it uses bootstrap
and C<eyapp> compiles itself. Be sure you have installed L<Parse::Yapp>.

=item * Before realising a distribution in CPAN via PAUSE do:

  make publicdist

Remember to change the version number in L<Parse::Eyapp::Driver>
and L<Parse::Eyapp>

=item * To build the *.html files:

   make html 

=item * To build pdf files:

   make pdfs

=item * To build dvi files:

   make dvis

=item * To make public the *.html files:

   make publichtml 

=item * To make public pdf files:

   make publicpdf

=item * To delete generated docs (*.html, *.pdf, etc.)

   make docclean

=item * To run the tests on remote machines

   make remotetest

(Set the environment variable C<MACHINES>). The module L<GRID::Machine> 
must be available.

=item * To use L<Devel::Cover> to study test coverage:

   make coverage

=item * Run C<./make_eyapp_c_tests.pl> if the clean tests fail 
and are you in a hurry.  This program builds the files in C<t/cleanok/> and C<t/cleanvok/>
used to test the behavior of eyapp when executed with option C<'-c'>
(See tests C<t/68cleangrammar> and C<t/69cleanwithvgrammar>

=back

=head1 DEPENDENCIES

To use this C<Makefile.PL> as developer is convenient to have installed:

=over 2

=item * Template toolkit

=item * Pod2LaTeX

=item * LaTeX

=item * pod2cpanhtml

=item * Devel::Cover

=item * Parse::Yapp

=item * GRID::Machine

=back

=head1 AUTHOR
 
Casiano Rodriguez-Leon (casiano@ull.es)

=head1 LICENCE AND COPYRIGHT
 
Copyright (c) 2006-2009 Casiano Rodriguez-Leon (casiano@ull.es). All rights reserved.

These modules are free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
 
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 



