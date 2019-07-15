use Mojo::Base -strict;
use Test::More;
use Mojo::Promisify qw(promisify promisify_call promisify_patch);

package Some::NonBlockingClass;
use Mojo::Base -base;

sub get_stuff_by_id {
  my ($self, $id, $cb) = @_;
  Mojo::IOLoop->next_tick(sub { $self->$cb($self->{err}, $id) });
  die 'Yikes!' unless $id;
  return $self;
}

package main;

my $nb_obj = Some::NonBlockingClass->new;
my ($err, $res) = ('', '');

$nb_obj->get_stuff_by_id(42,
  sub { shift; ($err, $res) = @_; Mojo::IOLoop->stop });
Mojo::IOLoop->start;
is $err, undef, 'callback err';
is $res, 42,    'callback res';

my $code = promisify $nb_obj, 'get_stuff_by_id';
$code->(43)->then(sub { $res = shift }, sub { $err = shift })->wait;
is $err, undef, 'promisify err';
is $res, 43,    'promisify res';

promisify_call($nb_obj, 'get_stuff_by_id', 44)
  ->then(sub { $res = shift }, sub { $err = shift })->wait;
is $err, undef, 'promisify_call err';
is $res, 44,    'promisify_call res';

$nb_obj->{err} = 'Some error';
promisify_call($nb_obj, 'get_stuff_by_id', 44)->catch(sub { $err = shift })
  ->wait;
is $err, 'Some error', 'promisify_call catch';

promisify_patch 'Some::NonBlockingClass' => 'get_stuff_by_id';
($err, $res, $nb_obj->{err}) = ('', '', '');
$nb_obj->get_stuff_by_id_p(45)
  ->then(sub { $res = shift }, sub { $err = shift })->wait;
is $err, '', 'promisify_patch err';
is $res, 45, 'promisify_patch res';

promisify_call($nb_obj, 'get_stuff_by_id', undef)->catch(sub { $err = shift })
  ->wait;
like $err, qr{^Yikes}, 'promisify_call blocking err';

$nb_obj->get_stuff_by_id_p(0)->catch(sub { $err = shift })->wait;
like $err, qr{^Yikes}, 'promisify_patch blocking err';

done_testing;
