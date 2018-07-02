#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 3;
use Perl::Critic;
use Perl::Critic::Config;
use Perl::Critic::TestUtils 'pcritique';

Perl::Critic::TestUtils::block_perlcriticrc();

my @a_tests = (
    {
        code => q/
sub test{ my ($self, $inv_foo)= @_; return 1 }
sub test_2{ my ($self, $obj_foo)= @_; return 1 }
/,
        violations => 0,
        comment    => 'custom call test run'
    },
    {
        code => q/
sub test{ my ($self, $i_foo)= @_; return 1 }
sub test_2{ my ($self, $s_foo)= @_; return 1; }
sub test_3{ my ($self, $s_foo, $ar_foo)= @_; return 1 }
/,
        violations => 0,
        comment    => 'scalar call test run'
    },
    {
        code => q/
sub test{ my ($self, $foo)= @_; return 1 }
sub test_2{ my ($self, $s_foo)= @_; return 1; }
sub test_3{ my ($self, $s_foo, $foo)= @_; return 1 }
/,
        violations => 2,
        comment    => 'scalar call test fails'
    },
);

is( pcritique( 'Variables::RequireHungarianNotation', \$_->{code}, { custom => 'inv obj' } ),
    $_->{violations}, $_->{comment} )
  for @a_tests;

exit 0;

__END__
