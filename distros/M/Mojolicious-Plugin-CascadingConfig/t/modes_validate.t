use strict;
use Test::More;
use Test::Mojo;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/lib";

my $t = Test::Mojo->new('MojoliciousTest');

throws_ok { $t->app->plugin('CascadingConfig' => { modes => '' }) } qr/Modes must be a non-empty array reference if provided/, 'empty string non-array modes dies';
throws_ok { $t->app->plugin('CascadingConfig' => { modes => 'I am not empty' }) } qr/Modes must be a non-empty array reference if provided/, 'non-empty string non-array modes dies';
throws_ok { $t->app->plugin('CascadingConfig' => { modes => 0 }) } qr/Modes must be a non-empty array reference if provided/, 'zero non-array modes dies';
throws_ok { $t->app->plugin('CascadingConfig' => { modes => 123 }) } qr/Modes must be a non-empty array reference if provided/, 'int non-array modes dies';
throws_ok { $t->app->plugin('CascadingConfig' => { modes => {} }) } qr/Modes must be a non-empty array reference if provided/, 'hash non-array modes dies';
throws_ok { $t->app->plugin('CascadingConfig' => { modes => [] }) } qr/Modes must be a non-empty array reference if provided/, 'empty array modes dies';

$t->app->moniker('myapp');
$t->app->mode('production');
lives_ok { $t->app->plugin('CascadingConfig' => { modes => ['production'] }) } 'non-empty array with valid config lives';

done_testing;
