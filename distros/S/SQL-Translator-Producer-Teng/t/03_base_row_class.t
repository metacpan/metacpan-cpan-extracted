use strict;
use warnings;
use utf8;
use Test::More;
use SQL::Translator;

my $translator = SQL::Translator->new;
$translator->parser('MySQL') or die $translator->error;
$translator->translate('t/data/mysql.sql') or die $translator->error;

$translator->producer('Teng', package => 'MyApp::DB::Schema', base_row_class => 'MyApp::DB::Row' );
my $translate = $translator->translate;

ok $translate;
note $translate;

done_testing;
