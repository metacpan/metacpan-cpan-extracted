#!perl -w
use strict;
use blib;
use POE::XS::Queue::Array ();
use POE::Queue::Array ();
use Benchmark;

# 1000 items to queue
my @items = map [ $_, $_ ], map rand(1000), 1..1000;

# test queues for timing adjust_priority
my %adjust;
my %adjust_ids;
my @adjust_val;
for my $impl (qw(POE::XS::Queue::Array POE::Queue::Array)) {
  my $queue = $impl->new;

  my @ids = map $queue->enqueue(@$_), @items;

  $adjust{$impl} = $queue;
  $adjust_ids{$impl} = \@ids;
}
for my $index (0..999) {
  $adjust_val[$index] = rand(100) - 50;
}

timethese(-10,
	  {
	   xs_big => sub { big('POE::XS::Queue::Array') },
	   perl_big => sub { big('POE::Queue::Array') },
	   xs_enqueue => sub { enqueue('POE::XS::Queue::Array') },
	   perl_enqueue => sub { enqueue('POE::Queue::Array') },
	   xs_adjust => sub { adjust('POE::XS::Queue::Array') },
	   perl_adjust => sub { adjust('POE::Queue::Array') },
	  });

# does general queue work
sub big {
  my $class = shift;

  my $queue = $class->new;

  my @ids = map $queue->enqueue(@$_), @items;

  for my $id (@ids[1..100]) {
    $queue->adjust_priority($id, sub { 1 }, -5);
  }
  my %remove = map { $_ => 1 } @ids[-100..-1];
  $queue->remove_items(sub { $remove{$_[0]} });

  for my $id (@ids[-200..-101]) {
    $queue->remove_item($id, sub { 1 });
  }

  $queue->remove_items(sub { 0 });

  $queue->dequeue_next while $queue->get_item_count;
}

# enqueue a bunch
sub enqueue {
  my $class = shift;

  my $queue = $class->new;

  my @ids = map $queue->enqueue(@$_), @items;
}

# adjust the priorities on a bunch of items
sub adjust {
  my $class = shift;

  my $queue = $adjust{$class};

  my $index = 0;
  for my $id (@{$adjust_ids{$class}}) {
    $queue->adjust_priority($id, sub { 1 }, $adjust_val[$index]);
    ++$index;
  }
}
