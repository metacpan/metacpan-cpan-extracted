# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.88;

my $mod = 'Sub::Chain::Group';
require_ok($mod);
my $chain = $mod->new(
  chain_class => 'Sub::Chain::Named',
  chain_args  => {subs => {
    'define' => sub { !defined $_[0] ? ' ~ ' : $_[0] },
    'no_undefs' => sub { die "I said no!" if !defined $_[0]; },
    'trim' => sub { (my $s = $_[0]) =~ s/(^\s+|\s+$)//g; $s },
    'squeeze' => sub { (my $s = $_[0]) =~ s/\s+/ /g; $s },
    'exchange' => sub { my ($s, $h) = @_; $h->{$s}; }
  }},
);

$chain->append('trim', fields => [qw(name address)]);
$chain->append('squeeze', fields => 'name');
$chain->append('exchange', fields => 'emotion', args => [{h => 'Happy'}]);
$chain->append('define', fields => 'silly', opts => {on_undef => 'proceed'});
$chain->append('no_undefs', fields => 'serious', opts => {on_undef => 'skip'});

my $in = {
  name => "\t Mr.   Blarh  ",
  address => "\n123    Street\tRoad ",
  emotion => 'h',
  silly => undef,
  serious => undef,
};
my $exp = {
  name => 'Mr. Blarh',
  address => "123    Street\tRoad",
  emotion => 'Happy',
  silly => ' ~ ',
  serious => undef,
};
my @keys = keys %$in;

foreach my $field ( @keys ){
  is($chain->call($field, $in->{$field}), $exp->{$field}, "single value ($field) transformed");
}

is_deeply($chain->call($in), $exp, 'hash transformed');
is_deeply($chain->call(\@keys, [@$in{@keys}]), [@$exp{@keys}], 'array transformed');

done_testing;
