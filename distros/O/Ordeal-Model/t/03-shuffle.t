use strict;
use Test::More;
use Test::Exception;
use Path::Tiny;
use Ouch;
use 5.020;
use experimental qw< postderef >;
no warnings qw< experimental::postderef >;

use Ordeal::Model;
use Ordeal::Model::Backend::PlainFile;
use Ordeal::Model::Shuffle;

my $dir   = path(__FILE__)->parent->child('ordeal-data');
my $model = Ordeal::Model->new(
   backend => Ordeal::Model::Backend::PlainFile->new(
      base_directory => $dir->absolute
   )
);

isa_ok $model, 'Ordeal::Model';

throws_ok { $model->evaluate(undef) }
qr{undefined input expression}, 'no input expression';

my $shuffled;
lives_ok {
   $shuffled = $model->evaluate(
      '"group1-02-all"@[#5]',
      seed       => 9111972,
     )
} ## end lives_ok
'valid deck is found and shuffled';
isa_ok $shuffled, 'Ordeal::Model::Shuffle';

my @got = $shuffled->draw;
is scalar(@got), 5, 'cards in shuffled deck';

my @shuffled = $model->evaluate(
   '"group1-02-all"@[#5]',
   seed       => 9111972,
)->draw;
is scalar(@shuffled), 5, 'same number of cards in list invocation';

@got      = map { $_->id } @got;
@shuffled = map { $_->id } @shuffled;
is_deeply \@shuffled, \@got, 'same result with same seed';

#diag $_ for @got;

is_deeply \@got, [
   qw<
     public-01-bleh.png
     group1-03-wtf.svg
     group1-02-whateeeevah.jpg
     group1-01-whatevah.png
     public-00-bah.png
     >
  ],
  'cards in expected order';

my $shfl = Ordeal::Model::Shuffle->new(
   deck           => $model->get_deck('group1-02-all'),
   seed           => 9111972,
   default_n_draw => 3,
);

my @three = $shfl->draw;
is scalar(@three), 3, 'set different default for draw';

done_testing;
