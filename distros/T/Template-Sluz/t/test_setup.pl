use strict;
use warnings;
use 5.016;

use File::Basename qw(dirname);
use Template::Sluz;
use Test::More;

# -------------------------------------------------------------------
# Inject test helper functions into main:: namespace
# (so they're found by the modifier/expression eval machinery)
# -------------------------------------------------------------------
BEGIN {
    no strict 'refs';
    *{'main::truncate'}     = sub { substr($_[0], 0, $_[1]) };
    *{'main::join_comma'}   = sub { my $s = $_[1] // ', '; join $s, @{$_[0]} };
    *{'main::hello_world'}  = sub { "Hello world" };
    *{'main::return_false'} = sub { 0 };
    *{'main::return_null'}  = sub { undef };
}

# -------------------------------------------------------------------
# setup_sluz - creates a pre-configured Template::Sluz object
# -------------------------------------------------------------------
sub setup_sluz {
    my (%opts) = @_;

    my $sluz = Template::Sluz->new();

    # Core variables
    $sluz->assign('x'            => '7');
    $sluz->assign('y'            => [2, 4, 6]);
    $sluz->assign('key'          => 'val');
    $sluz->assign('first'        => 'Scott');
    $sluz->assign('last'         => 'Baker');
    $sluz->assign('animal'       => 'Kitten');
    $sluz->assign('word'         => 'cRaZy');
    $sluz->assign('debug'        => 1);
    $sluz->assign('array'        => ['one', 'two', 'three']);
    $sluz->assign('cust'         => {first => 'Scott', last => 'Baker'});
    $sluz->assign('number'       => 15);
    $sluz->assign('zero'         => 0);
    $sluz->assign('members'      => [{first => 'Scott', last => 'Baker'}, {first => 'Jason', last => 'Doolis'}]);
    $sluz->assign('subarr'       => {one => [2, 4, 6], two => [3, 6, 9]});
    $sluz->assign('arrayd'       => [[1, 2], [3, 4], [5, 6]]);
    $sluz->assign('empty'        => []);
    $sluz->assign('empty_string' => '');
    $sluz->assign('null'         => undef);
    $sluz->assign('true'         => 1);
    $sluz->assign('false'        => 0);
    $sluz->assign('conf'         => {main => 1, debug => 0});
    $sluz->assign('colors'       => {a => 'red', b => 'green', c => 'blue'});
    $sluz->assign('scores'       => {math => 95, science => 88, art => 76});
    $sluz->assign('inc_file'     => 'tpls/extra.stpl');
    $sluz->assign({color => 'yellow', age => 43, book => 'Dark Tower'});

    # Raw hash assigns
    my %data = (
        car     => 'Honda',
        ltuae   => 42,
        console => 'Nintendo',
        milk    => ['goat', 'cow', 'soy'],
    );
    $sluz->assign(%data);

    # Template file directory
    $sluz->{perl_file_dir} = dirname(__FILE__);

    # Extra assigns from caller
    if (my $extra = $opts{extra}) {
        while (my ($key, $val) = each %$extra) {
            $sluz->assign($key => $val);
        }
    }

    return $sluz;
}

# -------------------------------------------------------------------
# sluz_test - test a template string against expected output
# -------------------------------------------------------------------
sub sluz_test {
    my ($sluz, $input, $expected, $name) = @_;

    my $got = $sluz->parse_string($input);

    my $is_regex;
    if ($expected =~ m|^/(.+)/$|) {
        $is_regex = 1;
    } else {
        $is_regex = 0;
    }

    if ($is_regex) {
        my $pat = $1;
        if ($got =~ /$pat/) {
            pass($name);
        } else {
            fail("$name -- expected pattern $expected, got " . explain($got));
        }
    } else {
        is($got, $expected, $name);
    }
}

# -------------------------------------------------------------------
# sluz_fetch_test - test fetching a template file
# -------------------------------------------------------------------
sub sluz_fetch_test {
    my ($sluz, $files, $pattern, $name) = @_;

    my $child  = $files->[0];
    my $parent = $files->[1];
    my $str = $sluz->fetch($child, $parent);

    if ($str =~ /$pattern/) {
        pass($name);
    } else {
        fail("$name -- expected $pattern, got " . explain($str));
    }
}

1;
