#!/usr/bin/perl
use strict; use warnings;
use Data::Dumper;

use Test::More tests => 13;

BEGIN {
    use_ok ('Sub::Auto');
}

autosub /^take_(.*)/ {
    my ($what, @args) = @_;
    return "Took a $what";
};
autosub /^get_([^_]+)_(.*)/ {
    my ($adj, $noun, @args) = @_;
    return "Got a $adj $noun";
};
autosub wibble /^do_the_.*$/ {
    my ($what, @args) = @_;
    return join "," => $what, @args;
};

autosub /^list$/ {
    my (undef, $count) = @_;
    return wantarray ?
        ('x') x $count
      : $count;
};

diag "can tests";
ok (__PACKAGE__->can('take_blah'));
ok (__PACKAGE__->can('get_wet_blanket'));
ok (! (__PACKAGE__->can('drop_blah')));

is (take_foo(), 'Took a foo', 'capture x1');
is (get_green_bar(),  'Got a green bar',  'capture x2');
is (do_the_fandango('grimly'), 'do_the_fandango,grimly', 'All match');

# check that 'wibble' above was installed properly
is (wibble('wobble', 'GRAH'), 'wobble,GRAH', 'sub installation ok normally');
ok (__PACKAGE__->can('wibble'), "Can wibble");

my $list = list(3);
is ($list, 3, 'OK in scalar context');
my @list = list(3);
is_deeply (\@list, ['x','x','x'],   'OK in list context');

eval 'autosub /^rarr/ { "RARR" }';
is (rarr_test(), 'RARR', 'Eval works');
is (take_foo(), 'Took a foo', 'Previously defined sub works after eval');
