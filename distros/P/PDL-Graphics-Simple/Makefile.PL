use strict;
use warnings;
use ExtUtils::MakeMaker;

sub parseversion
{
    my $version;
  open GP, 'lib/PDL/Graphics/Simple.pm' or die "Couldn't open Simple.pm";
  for(<GP>){
      if(m/our \$VERSION = \'([\d\.]+b?)\'/) {$version = $1;}
      last if($version);
  }
  die "Couldn't parse version from Simple.pm" unless($version);
  close GP;
  return $version;
}

sub MY::libscan
{
    package MY;

    my ($self, $file) = @_;

    # Don't install the README.pod or any .pl file
    return undef if $file =~ /\.pl$|^README.pod/;
    return $self->SUPER::libscan ($file);
}

sub MY::postamble {
    my $text = <<'FOO';
install ::
	@echo "Updating PDL documentation database...";
	@$(PERL) -e 'sub PDL::Doc::add_module {print STDERR "legacy PDL detected.  Cannot install docs.\n"}; eval q{use PDL::Doc; PDL::Doc::add_module(q[PDL::Graphics::Simple];}'

FOO
    return $text;
}

my %prereq = ( 'Test::More'  => 0,
               'PDL'         => 0,
	       'File::Temp'  => 0,
	       'Time::HiRes' => 0);

$prereq{'Win32::Process'} = 0.14 if $^O =~ /MSWin32/i;

WriteMakefile(
    NAME                => 'PDL::Graphics::Simple',
    AUTHOR              => ['Craig DeForest <craig@deforest.org>'],
    VERSION             => parseversion(),
    ABSTRACT_FROM       => 'lib/PDL/Graphics/Simple.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
     ? ('LICENSE'=> 'perl')
     : ()),
    PREREQ_PM => \%prereq,
    META_ADD => {
	resources => {
	    homepage => 'http://github.com/drzowie/PDL-Graphics-Simple',
	    repository => 'git://github.com/drzowie/PDL-Graphics-Simple.git',
	    bugtracker => 'craig@deforest.org'
	}
    },

    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'PDL-Graphics-Simple-*' },
	);

# reroute the main POD into a separate README.pod if requested. This is here
# purely to generate a README.pod for the github front page
my $POD_header = <<EOF;
=head1 OVERVIEW

PDL::Graphics::Simple is a unified plotting interface for PDL.  The
main distribution site is CPAN; the development repository is on
github.com.

=cut

EOF

if(exists $ARGV[0] && $ARGV[0] eq 'README.pod')
{
  open MOD, 'lib/PDL/Graphics/Simple.pm' or die "Couldn't open main module";
  open README, '>README.pod'              or die "Couldn't open README.pod";

  print README $POD_header;

  while (<MOD>)
  {
    if (/^=/../^=cut/)
    { print README; }
  }
}

