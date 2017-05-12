use strict;
use warnings;
use utf8;
use lib 'lib', 'eg/KosKos/lib';
use KosKos;

my $app = KosKos->new;
$app->to_psgi;
