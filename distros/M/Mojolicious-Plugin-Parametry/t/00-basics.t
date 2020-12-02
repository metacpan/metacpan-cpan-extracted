#!perl

use Test::More;
use Test::Mojo;
use Mojolicious;

my $t = Test::Mojo->new( Mojolicious->new );
$t->app->plugin('Parametry');
$t->app->routes->get("/$_" => $_) for qw/the_p
    the_pp_str  the_pp_strv  the_pp_str_strip  the_pp_str_stripv
    the_pp_str_hash  the_pp_str_strip_hash

    the_pp_re   the_pp_rev   the_pp_re_strip   the_pp_re_stripv
    the_pp_rev_hash  the_pp_re_strip_hash
/;

sub t {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $path = shift;
    my $re = join '\s*', map quotemeta, @_;
    $t = $t->get_ok($path)->status_is(200)->content_like(qr/^\s*$re\s*$/m)
}

t '/the_p' => qw/P[]/;
t '/the_p?meow_meow=   42   ' => qw/P[42]/;

t '/the_pp_str' => qw/PP[]/;
t '/the_pp_str?bar=42' => qw/PP[bar]/;
t '/the_pp_str?bar=42&mewbar=100' => qw/PP[bar]/;
t '/the_pp_str?bar=42&barmew=100' => qw/PP[bar, barmew]/;
t '/the_pp_strv?bar=42&barmew=100' => qw/PP[42, 100]/;
t '/the_pp_str_hash?bar=42&barmew=100' => qw/PP[bar,42|barmew,100]/;

t '/the_pp_str_strip?bar=42&barmew=100' => qw/PP[r, rmew]/;
t '/the_pp_str_stripv?bar=42&barmew=100' => qw/PP[42, 100]/;
t '/the_pp_str_strip_hash?bar=42&barmew=100' => qw/PP[r,42|rmew,100]/;

t '/the_pp_re?bar=42&mewbar=100' => qw/PP[bar, mewbar]/;
t '/the_pp_re?bar=42&barmew=100' => qw/PP[bar, barmew]/;
t '/the_pp_rev?bar=42&barmew=100' => qw/PP[42, 100]/;
t '/the_pp_rev_hash?bar=42&barmew=100' => qw/PP[bar,42|barmew,100]/;

t '/the_pp_re_strip?bar=42&barmew=100' => qw/PP[r, rmew]/;
t '/the_pp_re_stripv?bar=42&barmew=100' => qw/PP[42, 100]/;
t '/the_pp_re_strip_hash?bar=42&barmew=100' => qw/PP[r,42|rmew,100]/;


done_testing();

__DATA__

@@ the_p.html.ep

P[<%= P->meow_meow %>]


@@ the_pp_str.html.ep

PP[<%= PP->matching('bar')->join(', ') %>]

@@ the_pp_strv.html.ep

PP[<%= PP->matching('bar', vals => 1)->join(', ') %>]

@@ the_pp_str_hash.html.ep

% my $h = PP->matching('bar', as_hash=> 1);
PP[<%= join '|', map "$_,$h->{$_}", sort keys %$h %>]


@@ the_pp_str_strip.html.ep

PP[<%= PP->matching('ba', strip => 1)->join(', ') %>]

@@ the_pp_str_stripv.html.ep

PP[<%= PP->matching('ba', strip => 1, vals => 1)->join(', ') %>]

@@ the_pp_str_strip_hash.html.ep

% my $h = PP->matching('ba', strip => 1, as_hash=> 1);
PP[<%= join '|', map "$_,$h->{$_}", sort keys %$h %>]



@@ the_pp_re.html.ep

PP[<%= PP->matching(qr/b.r/)->join(', ') %>]

@@ the_pp_rev.html.ep

PP[<%= PP->matching(qr/b.r/, vals => 1)->join(', ') %>]

@@ the_pp_rev_hash.html.ep

% my $h = PP->matching(qr/b.r/, as_hash=> 1);
PP[<%= join '|', map "$_,$h->{$_}", sort keys %$h %>]


@@ the_pp_re_strip.html.ep

PP[<%= PP->matching(qr/b./, strip => 1)->join(', ') %>]

@@ the_pp_re_stripv.html.ep

PP[<%= PP->matching(qr/b./, strip => 1, vals => 1)->join(', ') %>]

@@ the_pp_re_strip_hash.html.ep

% my $h = PP->matching(qr/b./, strip => 1, as_hash=> 1);
PP[<%= join '|', map "$_,$h->{$_}", sort keys %$h %>]
