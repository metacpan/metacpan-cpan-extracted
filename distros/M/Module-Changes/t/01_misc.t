use strict;
use warnings;
use Test::More tests => 22;
use Test::Differences;
use Module::Changes;
use Perl::Version;
use DateTime::Format::W3CDTF;
use DateTime::Format::Mail;
use YAML;

my $changes = Module::Changes->make_object_for_type('entire');
isa_ok($changes, 'Module::Changes::Entire');
$changes->name('Foo-Bar');

my $author = 'Marcel Gruenauer <marcel@cpan.org>';
my $release = Module::Changes->make_object_for_type('release');
isa_ok($release, 'Module::Changes::Release');

$release->version(Perl::Version->new('0.01'));
is($release->version_as_string, '0.01', 'version as string');

$release->author($author);
$release->touch_date;
$release->changes_push('Did this, that and the other');

$changes->releases_unshift($release);
is_deeply($changes->newest_release, $release, 'it is the newest release');

my $date_yaml = DateTime::Format::W3CDTF->new->format_datetime($release->date);
my $expected_yaml = sprintf <<'EOYAML', $author, $date_yaml;
---
global:
  name: Foo-Bar
releases:
  - author: '%s'
    changes:
      - 'Did this, that and the other'
    date: %s
    tags: []
    version: 0.01
EOYAML

my $validator = Module::Changes->make_object_for_type('validator_yaml');
ok($validator->validate(Load($expected_yaml)), 'expected YAML validates');

my $formatter_yaml = Module::Changes->make_object_for_type('formatter_yaml');
isa_ok($formatter_yaml, 'Module::Changes::Formatter::YAML');
eq_or_diff $formatter_yaml->format($changes), $expected_yaml, 'YAML output';

my $date_free = DateTime::Format::Mail->new->format_datetime($release->date);
my $expected_free = sprintf <<'EOFREE', $date_free, $author;
Revision history for Perl extension Foo-Bar

0.01  %s (%s)
     - Did this, that and the other
EOFREE

my $formatter_free = Module::Changes->make_object_for_type('formatter_free');
isa_ok($formatter_free, 'Module::Changes::Formatter::Free');
eq_or_diff $formatter_free->format($changes), $expected_free, 'freeform output';


my $parser = Module::Changes->make_object_for_type('parser_yaml');
my $changes2 = $parser->parse_string($expected_yaml);
is_deeply($changes2, $changes, 'same after formatting and parsing again');

$changes->add_new_subversion;
is($changes->releases_count, 2, 'now two releases');
is($changes->newest_release->author, $author, 'second release author');
is($changes->newest_release->version_as_string, '0.01.01',
    'second release version');

$changes->add_new_alpha;
is($changes->releases_count, 3, 'now three releases');
is($changes->newest_release->author, $author, 'third release author');
is($changes->newest_release->version_as_string, '0.01.01_01',
    'third release version');

$changes->add_new_version;
is($changes->releases_count, 4, 'now four releases');
is($changes->newest_release->author, $author, 'fourth release author');
is($changes->newest_release->version_as_string, '0.02',
    'fourth release version');

$changes->add_new_revision;
is($changes->releases_count, 5, 'now five releases');
is($changes->newest_release->author, $author, 'fifth release author');
is($changes->newest_release->version_as_string, '1.00',
    'fifth release version');

