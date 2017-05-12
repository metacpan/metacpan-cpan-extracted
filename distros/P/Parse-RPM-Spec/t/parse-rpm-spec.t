use Test::More tests => 11;
BEGIN { use_ok('Parse::RPM::Spec') };

ok($spec = Parse::RPM::Spec->new( { file => 't/file.spec' } ));
isa_ok($spec, 'Parse::RPM::Spec');

is($spec->name, 'perl-Array-Compare');
is($spec->summary, 'Perl extension for comparing arrays');
is($spec->epoch, 1);

is($spec->version, '1.16');
$spec->version('1.17');
is($spec->version, '1.17');
is($spec->buildarch, 'noarch');
is(@{$spec->buildrequires}, 2);
is($spec->buildrequires->[0], 'perl >= 1:5.6.0');
