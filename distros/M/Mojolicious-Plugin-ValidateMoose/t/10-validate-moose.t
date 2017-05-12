use warnings;
use strict;
use lib qw(lib);
use Test::More;
use Mojolicious::Plugin::ValidateMoose;

plan tests => 15;

{
    my $plugin = Mojolicious::Plugin::ValidateMoose->new;
    my $validator = \&Mojolicious::Plugin::ValidateMoose::validate_moose;
    my $app = mock_app();
    my $obj;

    $plugin->register($app, {});
    is_deeply($app->{'helper'}, [validate_moose => $validator], 'validate_moose() was registered');

    eval { $validator->($app, 'TestClass') };
    like($@, qr{forgot to load}, 'class need to be loaded');

    mock_class();
    $validator->($app, 'TestClass');
    is_deeply($app->{'invalid_form_elements'}, { req => 'required' }, 'required attribute missing');

    $app->{'req'} = '';
    $validator->($app, 'TestClass');
    is_deeply($app->{'invalid_form_elements'}, { req => 'required' }, 'required attribute missing (empty string)');

    $app->{'req'} = 123;
    isa_ok($obj = $validator->($app, 'TestClass'), 'TestClass');
    is($obj->req, 123, 'req attribute got value');

    $app->{'num'} = 'bar';
    $app->{'int'} = 'foo';
    $validator->($app, 'TestClass');
    like($app->{'invalid_form_elements'}{'int'}, qr{Validation failed for.*Int.*foo}, 'int has invalid value');
    like($app->{'invalid_form_elements'}{'num'}, qr{Validation failed for.*Num.*bar}, 'num has invalid value');

    $app->{'num'} = 2.54;
    $app->{'int'} = 123;
    $app->{'ro'} = 'foo';
    $obj = $validator->($app, 'TestClass');
    is($obj->int, 123, 'int has value');
    is($obj->num, 2.54, 'num has value');
    is($obj->ro, 'foo', 'ro has value');

    $app->{'int'} = 42;
    $app->{'ro'} = 'bar';
    is($validator->($app, $obj), $obj, 'obj was updated');
    is($obj->int, 42, 'int was updated');
    is($obj->ro, 'foo', 'ro was not updated (ro)');
}

{
    local $TODO = 'test coercion';
    ok(0, 'attribute got coerced');
}

sub mock_class {
    eval q/
        package TestClass;
        use Moose;
        has int => (is => 'rw', isa => 'Int');
        has num => (is => 'rw', isa => 'Num');
        has req => (is => 'rw', required => 1);
        has ro => (is => 'ro');
        1;
    / or die $@;
}

sub mock_app {
    eval q/
        package TestApp;
        sub helper { my $o = shift; $o->{'helper'} = [@_] }
        sub param { $_[0]->{$_[1]} }
        sub stash { $_[0]->{$_[1]} = $_[2] }
        1;
    / or die $@;
    return bless {}, 'TestApp';
}
