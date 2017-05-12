use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use lib qw(lib);

WriteMakefile
  NAME          => "Net::DNAT",
  AUTHOR        => "Rob Brown",
  ABSTRACT_FROM => "lib/Net/DNAT.pm",
  VERSION_FROM	=> "lib/Net/DNAT.pm", # finds $VERSION
  PREREQ_PM    => { # e.g., Module::Name => 1.1
    'Net::Server' => 0.85,
    'IO::Multiplex' => 1.02,
    'mod_perl' => 0,
  },
  dist => {
    COMPRESS => "gzip -9 -vf",
  },
  ;

package MY;

sub processPL {
  my $self = shift;
  my $block = $self->SUPER::processPL(@_);
  # "Version:" in spec needs to match
  # "$VERSION" from VERSION_FROM
  $block =~ s%(spec.PL\s*)$%$1 \$\(VERSION_FROM\)%m;
  $block;
}

sub libscan {
  my $self = shift;
  my $path = shift;
  ($path =~ / \bCVS\b | \~$ /x) ? undef : $path;
}

sub postamble {
  return qq^

pm_to_blib: README

README: \$(VERSION_FROM)
	pod2text \$(VERSION_FROM) > README
^;
}

1;
