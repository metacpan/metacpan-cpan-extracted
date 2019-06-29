use Mojo::Base -strict;

BEGIN {
    $ENV{'MOJO_NO_IPV6'} = 1;
    $ENV{'MOJO_REACTOR'} = 'Mojo::Reactor::Poll';
}

use Test::More;
use Mojolicious::Lite;
use Test::Mojo::Trim;

plugin 'BootstrapHelpers', {
    icons => {
        class => 'glyphicon',
        formatter => 'glyphicon-%s',
    },
};

ok 1;

my $test = Test::Mojo::Trim->new;



# test from line 1 in bootstrap-1.stencil

my $expected_bootstrap_1_1 = qq{    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/css/bootstrap.min.css">};

get '/bootstrap_1_1' => 'bootstrap_1_1';

$test->get_ok('/bootstrap_1_1')->status_is(200)->trimmed_content_is($expected_bootstrap_1_1, 'Matched trimmed content in bootstrap-1.stencil, line 1');

# test from line 11 in bootstrap-1.stencil

my $expected_bootstrap_1_11 = qq{    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/css/bootstrap-theme.min.css">};

get '/bootstrap_1_11' => 'bootstrap_1_11';

$test->get_ok('/bootstrap_1_11')->status_is(200)->trimmed_content_is($expected_bootstrap_1_11, 'Matched trimmed content in bootstrap-1.stencil, line 11');

# test from line 22 in bootstrap-1.stencil

my $expected_bootstrap_1_22 = qq{     <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/js/bootstrap.min.js"></script>};

get '/bootstrap_1_22' => 'bootstrap_1_22';

$test->get_ok('/bootstrap_1_22')->status_is(200)->trimmed_content_is($expected_bootstrap_1_22, 'Matched trimmed content in bootstrap-1.stencil, line 22');

# test from line 32 in bootstrap-1.stencil

my $expected_bootstrap_1_32 = qq{    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/css/bootstrap-theme.min.css">
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/js/bootstrap.min.js"></script>};

get '/bootstrap_1_32' => 'bootstrap_1_32';

$test->get_ok('/bootstrap_1_32')->status_is(200)->trimmed_content_is($expected_bootstrap_1_32, 'Matched trimmed content in bootstrap-1.stencil, line 32');

# test from line 44 in bootstrap-1.stencil

my $expected_bootstrap_1_44 = qq{        <script src="https://code.jquery.com/jquery-2.2.4.min.js"></script>
        <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/js/bootstrap.min.js"></script>};

get '/bootstrap_1_44' => 'bootstrap_1_44';

$test->get_ok('/bootstrap_1_44')->status_is(200)->trimmed_content_is($expected_bootstrap_1_44, 'Matched trimmed content in bootstrap-1.stencil, line 44');

# test from line 55 in bootstrap-1.stencil

my $expected_bootstrap_1_55 = qq{    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/css/bootstrap-theme.min.css">
    <script src="https://code.jquery.com/jquery-2.2.4.min.js"></script>
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/js/bootstrap.min.js"></script>};

get '/bootstrap_1_55' => 'bootstrap_1_55';

$test->get_ok('/bootstrap_1_55')->status_is(200)->trimmed_content_is($expected_bootstrap_1_55, 'Matched trimmed content in bootstrap-1.stencil, line 55');

done_testing();

__DATA__

@@ bootstrap_1_1.html.ep

    %= bootstrap

@@ bootstrap_1_11.html.ep

    %= bootstrap 'css'

@@ bootstrap_1_22.html.ep

    %= bootstrap 'js'

@@ bootstrap_1_32.html.ep

    %= bootstrap 'all'

@@ bootstrap_1_44.html.ep

    %= bootstrap 'jsq'

@@ bootstrap_1_55.html.ep

    %= bootstrap 'allq'

