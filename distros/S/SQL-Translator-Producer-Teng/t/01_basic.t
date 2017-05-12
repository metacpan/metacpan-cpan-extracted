use strict;
use warnings;
use utf8;
use Test::More;
use SQL::Translator;
use SQL::Translator::Producer::Teng;

my $translator = SQL::Translator->new;
$translator->parser('MySQL') or die $translator->error;
$translator->translate('t/data/mysql.sql') or die $translator->error;

my $direct    = SQL::Translator::Producer::Teng::produce($translator);
my $translate = $translator->translate(to => 'Teng');
ok $direct;
is $direct, $translate;

note $direct;

done_testing;
