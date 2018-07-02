#!perl

use strict;
use warnings;
use Test::More tests => 4;
use Perl::Critic;
use Perl::Critic::Config;
use Perl::Critic::TestUtils 'pcritique';

Perl::Critic::TestUtils::block_perlcriticrc();

my @a_tests = (
    { code => q{ my $a_foo = {}; },          violations => 1, comment => 'scalar with array prefix fail' },
    { code => q{ my @h_foo = (); },          violations => 1, comment => 'array with hash prefix fail' },
    { code => q{ my %a_foo = (); },          violations => 1, comment => 'hash with array prefix fail' },
    { code => q{ my ($self, $a_bar) = @_; }, violations => 1, comment => 'list declarations fail' },
);

is( pcritique( 'Variables::RequireHungarianNotation', \$_->{code} ), $_->{violations}, $_->{comment} ) for @a_tests;

exit 0;

__END__
