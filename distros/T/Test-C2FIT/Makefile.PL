#use 5.008006;
use ExtUtils::MakeMaker;

{
package MY;

sub metafile {
    my $self = shift;
    my $inject = <<"META_EXTRA";
abstract: $self->{ABSTRACT}
author: 
  - $self->{AUTHOR}
no_index:
  dir:
    - t
    - examples
    - examples-perl
    - spec
    - html
  file:
    - perltidy_glob.BAT
    - perltidy.conf
meta-spec:
  version: 1.2
  url: http://module-build.sourceforge.net/META-spec-v1.2.html
resources:
  homepage: http://fit.c2.com 
META_EXTRA

    $inject = join "\n\t",  map { '$(NOECHO) $(ECHO) "'.$_.'" >>META_new.yml' }
                            split /(?:\012\015?|\015\012?)/, $inject;

    my $t = $self->SUPER::metafile_target(@_);
    my $mvCmd = q|-$(NOECHO) $(MV)|;
    my $pat = quotemeta($mvCmd);
    $t =~ s/$pat/$inject\n\t$mvCmd/s;
    return $t;
}

sub postamble {

    my $result = <<'_Q_';
all :: ReleaseNotes

# Make search.cpan.org happy but still follow GNU standards:
# (Thanks to Graham Barr for the hint)
ReleaseNotes: Changes
	$(ABSPERLRUN) -MExtUtils::Command -e cat Changes >$@

# simple pod 2 html conversion
my_html :
	$(ABSPERLRUN) html/html.pl html

_Q_

    my @paths = qw(
		examples-perl/lib/*.pm
		examples/lib/Test/C2FIT/eg/*.pm
		examples/lib/Test/C2FIT/eg/net/*.pm
		examples/lib/Test/C2FIT/eg/music/*.pm
		spec/fat/Test/C2FIT/fat/*.pm
    );
    my $paths = join("\\\n\t\t",@paths);

my  $TIDY = "perltidy";
    $TIDY = "perltidy_glob" if $^O =~ /MSWin32/;

    $result .= <<"_QQ_";
# development feature: format code using Perl::Tidy
# depending on the plattform, perfom explicit glob()
my_tidy :
	$TIDY -b -pro=perltidy.conf \$(TO_INST_PM) $paths

_QQ_
}

1;
};

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Test::C2FIT',
    VERSION_FROM      => 'lib/Test/C2FIT.pm', # finds $VERSION
    PREREQ_PM         => {
				Test::Unit => 0.24
			}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT       => "A direct Perl port of Ward Cunningham's FIT acceptance test framework for Java",
       AUTHOR         => 'Tony Byrne <fit4perl@byrnehq.com>') : ()),
    # LICENSE => ???,
);
