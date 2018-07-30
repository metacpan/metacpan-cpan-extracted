# -*-CPerl-*-
use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

use lib './t';
use MyTest;

our @urls = ();
push @MyTest::browser_open_cb, sub { push @urls, $_[0] };
our @stacks = ();

sub _stack {
    my @s = ();
    for (my $i = 5 ; my @c = caller($i) ; ++$i) {
        push @s, "$c[3] from $c[0], line $c[2] ($c[1])";
    }
    return @s;
}

# push @MyTest::browser_open_cb, sub { push @stacks, [$_[0], _stack()] };

plugin 'Loco';

get '/' => {text => "works"};

my $t = Test::Mojo->new;
$t->get_ok('/');
is scalar @urls, 0, 'Browser::Open once'
#  or diag($t->ua->{server}->{port} . ' =? ' . $t->ua->{server}->{nb_port})
;
$t->status_is(200)->content_is('works');
# like $urls[0], qr!\Qhttp://127.0.0.1/hb/init?s=\E[0-9a-f]+$!,
#   'Browser::Open right url';

done_testing();
