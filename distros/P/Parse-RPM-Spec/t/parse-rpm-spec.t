use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN { use_ok('Parse::RPM::Spec') };

ok(my $spec = Parse::RPM::Spec->new( { file => 't/file.spec' } ),
  'Got an object');
isa_ok($spec, 'Parse::RPM::Spec');

is($spec->name, 'perl-Array-Compare', 'Correct name');
is($spec->summary, 'Perl extension for comparing arrays', 'Correct summary');
is($spec->epoch, 1, 'Correct epoch');

is($spec->version, '1.16', 'Correct version');
$spec->version('1.17');
is($spec->version, '1.17', 'Changed version correctly');
is($spec->buildarch, 'noarch', 'Correct build architecture');
is(@{$spec->buildrequires}, 2, 'Correct number of build requirements');
is($spec->buildrequires->[0], 'perl >= 1:5.6.0',
  'First build requirement is correct');

is($spec->exclusivearch, 'megaCPU', 'Correct exclusive architecture');
is($spec->excludearch, 'crapCPU', 'Correct excluded architecture');

dies_ok { Parse::RPM::Spec->new }
  'No spec file given';
dies_ok { Parse::RPM::Spec->new( file => 'not-there') }
  'Missing spec file given';
dies_ok { Parse::RPM::Spec->new( file => 'empty.spec') }
  'Empty spec file given';

done_testing;
