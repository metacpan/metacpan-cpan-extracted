use strict;
use warnings;
use Config;
use Test::More;

BEGIN {
    plan skip_all => 'perl is not built with ithreads' unless $Config{useithreads};
    plan skip_all => 'threads.pm not available' unless eval { require threads; 1 };
}
use Term::Ghostty;

my $term = Term::Ghostty->new(on_bell => sub { 1 });
$term->feed("main");

my $in_thread = threads->create(sub {
    my $t = Term::Ghostty->new;
    $t->feed("thread");
    my $parent_usable = eval { $term->cols; 1 } ? 1 : 0;
    return join ',', $t->get_text, $parent_usable;
})->join;

is($in_thread, 'thread,0', 'thread gets its own terminal; the parent one is not shared');
is($term->get_text, 'main', 'parent terminal intact after the thread exits');

done_testing;
