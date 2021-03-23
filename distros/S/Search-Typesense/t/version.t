#!/usr/bin/env perl

use lib 't/lib';
use Test::Most 'bail';
use Test::Search::Typesense;
use Search::Typesense::Version;

my $test      = Test::Search::Typesense->new;
my $typesense = $test->typesense;
my $version   = $typesense->typesense_version;

like $version->version_string, qr/^\d+\.\d+\.\d+$/a,
  'We should be able to fetch the Typesense version';
like $version->major, qr/^\d+$/a,
  'We should be able to fetch the major Typesense version';
like $version->minor, qr/^\d+$/a,
  'We should be able to fetch the minor Typesense version';
like $version->patch, qr/^\d+$/a,
  'We should be able to fetch the patch Typesense version';

$version = Search::Typesense::Version->new( version_string => '1.2.3' );
is $version->major, 1, 'Major version number should be correct';
is $version->minor, 2, 'Minor version number should be correct';
is $version->patch, 3, 'Patch version number should be correct';

throws_ok { Search::Typesense::Version->new( version_string => '0.01' ) }
qr/\QInvalid version string: 0.01/,
'Trying to create a version number from an invalid version string should fail';

done_testing;
