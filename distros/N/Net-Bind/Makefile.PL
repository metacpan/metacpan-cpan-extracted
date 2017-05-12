#!/usr/bin/perl

use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME => 'Net::Bind',
	      VERSION_FROM => 'lib/Net/Bind.pm',
	      DISTNAME => 'Net-Bind',
	      'dist' => { COMPRESS => 'gzip', SUFFIX => '.gz' },
	     );

package MY;

sub test {
  q{
TEST_VERBOSE=0

test:
	$(FULLPERL) t/TEST $(TEST_VERBOSE)
};
}

sub processPL {
  my $self = shift;
  my $block = $self->SUPER::processPL(@_);
  # "Version:" in spec needs to match
  # "$VERSION" from VERSION_FROM
  $block =~ s%(spec.PL\s*)$%$1 \$\(VERSION_FROM\)%m;
  $block;
}
