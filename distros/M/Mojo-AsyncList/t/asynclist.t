use Mojo::Base -strict;
use Mojo::AsyncList;
use Test::More;
use Time::HiRes 'tv_interval';

my $item_cb = sub {
  my ($async_list, $username, $gather_cb) = @_;
  Mojo::IOLoop->timer(
    rand(0.5) => sub { $gather_cb->(undef, "got:$username", "foo") });
};

my @res;
my @items      = qw(supergirl superman batman);
my $async_list = Mojo::AsyncList->new($item_cb, sub { shift; @res = @_ });

$async_list->concurrent(2);
$async_list->process(\@items);
is $async_list->stats('done'), 0, 'nothing is done';

my ($finish, $item, $result) = (0, 0, 0);
$async_list->on(finish => sub { $finish++ });
$async_list->on(item   => sub { $item++ });
$async_list->on(result => sub { $result++ });

$async_list->wait;

diag sprintf 'asyncList ran for %ss', tv_interval($async_list->stats->{t0});
is $async_list->stats('done'),      3, 'all is done';
is $async_list->stats('remaining'), 0, 'nothing remaining';

is $finish, 1, 'finished once';
is $item,   int @items, 'item';
is $result, int @items, 'result';
is_deeply \@res, [map { ["got:$_", "foo"] } @items], 'res';

# Check that concurrent can be higher than int(@items)
my @got;
@items = qw(supergirl);
Mojo::AsyncList->new(sub { push @got, $_[1]; pop->($_[1]); })->concurrent(10)
  ->process(\@items)->wait;
is_deeply \@got, \@items, 'item event got items';

done_testing;
