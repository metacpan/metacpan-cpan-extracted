use Mojo::Base -strict;
use Test::More;
use Test::Exception;
use Mojolicious::Lite;

throws_ok
    { plugin ModeHelpers => { modes => undef } }
    qr/modes must be an arrayref/,
    'undef modes throws';

throws_ok
    { plugin ModeHelpers => { modes => 0 } }
    qr/modes must be an arrayref/,
    '0 modes throws';

throws_ok
    { plugin ModeHelpers => { modes => 'string' } }
    qr/modes must be an arrayref/,
    'string modes throws';

throws_ok
    { plugin ModeHelpers => { modes => {} } }
    qr/modes must be an arrayref/,
    'hash modes throws';

throws_ok
    { plugin ModeHelpers => { modes => [undef] } }
    qr/empty value for mode/,
    'undef modes item throws';

throws_ok
    { plugin ModeHelpers => { modes => [''] } }
    qr/empty value for mode/,
    'empty string modes item throws';

lives_ok
    { plugin ModeHelpers => { modes => [0] } }
    'false but non-empty mode lives';

throws_ok
    { plugin ModeHelpers => { modes => [{}] } }
    qr/helper name and mode pair must be a hashref with exactly one key and one value/,
    'hash modes item with no keys throws';

throws_ok
    { plugin ModeHelpers => { modes => [{key1 => 'value1', key2 => 'value2'}] } }
    qr/helper name and mode pair must be a hashref with exactly one key and one value/,
    'hash modes item with two keys throws';

throws_ok
    { plugin ModeHelpers => { modes => [{'' => 'value1'}] } }
    qr/empty value for helper name in key-value pair/,
    'hash modes item with empty helper name throws';

lives_ok
    { plugin ModeHelpers => { modes => [{0 => 'value1'}] } }
    'hash modes item with false but non-empty helper name lives';

throws_ok
    { plugin ModeHelpers => { modes => [{my_helper => undef}] } }
    qr/empty value for mode in key-value pair/,
    'hash modes item with undef mode throws';

throws_ok
    { plugin ModeHelpers => { modes => [{my_helper => ''}] } }
    qr/empty value for mode in key-value pair/,
    'hash modes item with empty mode throws';

lives_ok
    { plugin ModeHelpers => { modes => [{my_helper => 0}] } }
    'hash modes item with false but non-empty mode lives';

throws_ok
    { plugin ModeHelpers => { modes => [[]] } }
    qr/mode must be a scalar \(valid subroutine name\) or a hashref with one key-value pair/,
    'arrayref modes item throws';

app->mode('production');
plugin ModeHelpers => { modes => ['alpha'] };

ok app->in_prod, 'in_prod true when app in production and custom scalar mode exists';
ok !app->in_dev, 'in_dev false when app in production and custom scalar mode exists';

ok !app->in_alpha, 'in_alpha false when app in production and custom scalar mode exists';
ok !app->in_alpha, 'in_alpha false a second time when app in production and custom scalar mode exists';

app->mode('alpha');
plugin ModeHelpers => { modes => ['alpha'] };

ok !app->in_prod, 'in_prod false when app in alpha mode and custom scalar mode exists';
ok app->in_dev, 'in_dev true when app in alpha mode and custom scalar mode exists';

ok app->in_alpha, 'in_alpha true when app in alpha mode and custom scalar mode exists';
ok app->in_alpha, 'in_alpha true a second time when app in alpha mode and custom scalar mode exists';

app->mode('my-custom mode!');
plugin ModeHelpers => { modes => ['my-custom mode!'] };

ok !app->in_prod, 'in_prod false when app in in mode with non-word characters';
ok app->in_dev, 'in_dev true when app in mode with non-word characters';

ok app->in_my_custom_mode, 'custom mode with non-word characters generates valid perl method name and is true for non-word character mode';
ok app->in_my_custom_mode, 'custom mode with non-word characters generates valid perl method name and is true for non-word character mode a second time';

app->mode('alpha_mode');
plugin ModeHelpers => { modes => ['alpha_mode'] };

ok app->in_alpha_mode, 'scalar helper name keeps underscores';

app->mode('alpha');
plugin ModeHelpers => { modes => [{ in_alpha_mode => 'alpha' }] };

ok app->in_alpha_mode, 'key-value pair true when in mode';
ok app->in_alpha_mode, 'key-value pair true when in mode a second time';

app->mode('not alpha');
plugin ModeHelpers => { modes => [{ in_alpha_mode => 'alpha' }] };

ok !app->in_alpha_mode, 'key-value pair false when not in mode';
ok !app->in_alpha_mode, 'key-value pair false when not in mode a second time';

app->mode('alpha');
plugin ModeHelpers => { modes => [{ in_alpha_mode => 'alpha' }, 'beta'] };

ok app->in_alpha_mode, 'key-value mode true when used with custom scalar mode and key-value mode is set';
ok app->in_alpha_mode, 'key-value mode true when used with custom scalar mode and key-value mode is set a second time';

ok !app->in_beta, 'custom scalar mode false when used with key-value mode and key-value mode is set';
ok !app->in_beta, 'custom scalar mode false when used with key-value mode and key-value mode is set a second time';

app->mode('beta');
plugin ModeHelpers => { modes => [{ in_alpha_mode => 'alpha' }, 'beta'] };

ok !app->in_alpha_mode, 'key-value mode false when used with custom scalar mode and custom scalar mode is set';
ok !app->in_alpha_mode, 'key-value mode false when used with custom scalar mode and custom scalar mode is set a second time';

ok app->in_beta, 'custom scalar mode true when used with key-value mode and custom scalar mode is set';
ok app->in_beta, 'custom scalar mode true when used with key-value mode and custom scalar mode is set a second time';

app->mode('alpha');
plugin ModeHelpers => { modes => [{ 'modes.alpha' => 'alpha' }] };

ok app->modes->alpha, 'dot notation works with key-value pair';
ok app->modes->alpha, 'dot notation works with key-value pair a second time';

done_testing;
