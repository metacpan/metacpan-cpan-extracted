# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.88;

my $mod = 'Sub::Chain::Group';
require_ok($mod);
my $chain = $mod->new();
isa_ok($chain, $mod);

my $filter = '';
sub filter {
  my ($name, $sub) = @_;
  return ($name, sub { $filter .= "$name|"; &$sub(@_) });
}

$chain = $mod->new(chain_class => 'Sub::Chain::Named',
  chain_args => {subs => {filter('no-op', sub { $_[0] }), filter('razzberry' => sub { ":-P $_[0]" })}});
isa_ok($chain, $mod);

my @fruit1 = qw(apple orange kiwi);
my @fruit2 = qw(banana grape);
my @fruits = (@fruit1, @fruit2);

$chain->group(fruit => \@fruit1);
is_deeply($chain->groups->groups('fruit')->{fruit}, \@fruit1, 'group');
$chain->group(fruit => \@fruit2);
is_deeply($chain->groups->groups('fruit')->{fruit}, \@fruits, 'group');

my $tr_ref = 'Sub::Chain';

$chain->append('no-op', field => [qw(tree)]);
isa_ok($chain->chain('tree'), $tr_ref);

# white box hacks to test functions
{
  my ($k, $v) = filter('multi' => sub { $_[0] x $_[1] });
  $chain->{chain_args}{subs}{$k} = $v;
}
is($chain->{chain_args}{subs}{multi}->('boo', 2), 'booboo', 'test func');
$filter = '';

my $APPLECHAIN; # increment APPLECHAIN for each transformation to 'apple' field; we'll test later
my $FRUITCHAIN; # increment FRUITCHAIN for each transformation to 'fruit' group; we'll test later

$chain->append('multi', field => 'apple', args => [2]); ++$APPLECHAIN;

$chain->append('no-op', groups => 'fruit'); ++$APPLECHAIN; ++$FRUITCHAIN;
isa_ok($chain->chain('apple'), $tr_ref);
is_deeply($chain->chain('orange'), $chain->chain('grape'), 'two chains from one group the same');

# white box testing for the queue

my $razz = sub { map { ['razzberry', {fields => [ ref $_ ? @$_ : $_ ], args => [], opts => {}}] } @_ };

is($chain->{queue}, undef, 'queue empty');
$chain->append('razzberry', field => 'tree');
is_deeply($chain->{queue}, [ $razz->('tree') ], 'queue has entry');
$chain->dequeue;
is($chain->{queue}, undef, 'queue empty');

my @fields = qw(apple orange grape); ++$APPLECHAIN;
for (my $i = 0; $i < @fields; ++$i ){
  $chain->append('razzberry', field => $fields[$i]);
  is_deeply($chain->{queue}, [ $razz->(@fields[0 .. $i ]) ], "queue has ${\($i + 1)}");
}

$chain->dequeue;

$chain->append('razzberry', group => 'fruit'); ++$APPLECHAIN; ++$FRUITCHAIN;
# want to test the resultant chains...
ok((grep { $_ } map { $chain->chain($_) } @fruits) == @fruits, 'chain foreach field in group');

push(@fruits, 'strawberry');
$chain->group(qw(fruit strawberry));
$chain->dequeue;
ok((grep { $_ } map { $chain->chain($_) } @fruits) == @fruits, 'chain foreach field in group');

ok(@{$chain->chain('apple')->{chain}} == $APPLECHAIN, 'apple chain has expected subs');
is($chain->call('apple', 'pear'), ':-P :-P pearpear', 'transformed');
is($filter, 'multi|no-op|razzberry|razzberry|', 'filter names');

$filter = '';
ok(@{$chain->chain('strawberry')->{chain}} == $FRUITCHAIN, 'strawberry chain has expected subs w/o explicit append()');
is($chain->call('strawberry', 'pear'), ':-P pear', 'transformed');
is($filter, 'no-op|razzberry|', 'filter names');

SKIP: {
  my $testwarn = 'Test::Warn';
  eval "use $testwarn; 1";
  skip "$testwarn required for testing warnings" if $@;

  $chain->append('no-op', field => 'blue');
  warning_is(sub { $chain->call( 'blue',  'yellow' ) }, undef, 'no warning for specified field');
  warning_is(sub { $chain->call( 'green', 'orange' ) }, q/No subs chained for 'green'/, 'warn single');
  warning_is(sub { $chain->call({'green', 'orange'}) }, undef, 'no warn multi');

  no strict 'refs';
  $chain->{warn_no_field} = 'always';
  warning_is(sub { $chain->call({'green', 'orange'}) }, q/No subs chained for 'green'/, 'warn always');
  $chain->{warn_no_field} = 'never';
  warning_is(sub { $chain->call( 'green', 'orange' ) }, undef, 'warn never');
}

{
  # NOTE: dropped Test::Exception because I randomly got this weird stack ref count bug:
  # "Bizarre copy of HASH in sassign at /usr/share/perl/5.10/Carp/Heavy.pm"
  # possibly because Test::Exception uses Sub::Uplevel?
  # Regardless, we aren't testing very much (one live and one die), so just do it manually.

  foreach my $wnf ( qw(always single never) ){
    my $chain;
    ok(eval { $chain = $mod->new(warn_no_field => $wnf); 1 }, 'expected to live');
    is($@, '', 'no death');
    isa_ok($chain, $mod);
  }
  is(eval { $mod->new(warn_no_field => 'anything else'); 1 }, undef, 'died');
  like($@, qr/cannot be set to/i, 'die with invalid value');
}

my @items = $chain->groups->items;
$chain->fields('peach');
is_deeply([$chain->groups->items], ['peach', @items], 'fields added to dynamic-groups');

{
  # test example from POD:
  my $chain = $mod->new;

  $chain->group(some => {not => [qw(primary secondary)]});
  $chain->fields(qw(primary secondary this that));
  is_deeply($chain->groups->groups('some')->{some}, [qw(this that)], 'POD example of group exclusion');

  $chain->fields('another');
  is_deeply($chain->groups->groups('some')->{some}, [qw(this that another)], 'POD example of group exclusion');
}

done_testing;
