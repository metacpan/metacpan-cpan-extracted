use strict;
use warnings;
use Test::More;
use Dumbbench;
use Dumbbench::Instance::PerlSub;
use Types::Standard qw(Int Num);

# benchmarking in a test isn't entirely sane, but since this module is meant to
# be an optimization we want to make sure it's actually doing its job.  This
# will occasionally fail, but it's an xt test so it shouldn't get in the way
# of anything.

my $int;
sub add_attrs {
  $int ||= Int->plus_coercions(Num,=> q{ int $_ });
  my $package = caller;
  my $has = $package->can('has');
  $has->(attr_isa        => (is => 'rw', isa => $int));
  $has->(attr_coerce     => (is => 'rw', coerce => $int->coercion));
  $has->(attr_isa_coerce => (is => 'rw', isa => $int, coerce => $int->coercion));
}

my %objects = (
  Original => do {
    package MooClass;
    use Moo;
    ::add_attrs;
    __PACKAGE__->new;
  },
  Optimized => do {
    package MooClassMXTT;
    use Moo;
    use MooX::TypeTiny;
    ::add_attrs;
    __PACKAGE__->new;
  },
);

my $deparse;

for my $attr (qw(attr_isa attr_coerce attr_isa_coerce)) {
  my $slow;
  for my $value (1, 1.2, "welp") {
    my $eval = grep { !eval { $_->$attr($value); 1 } } values %objects;
    my $sub = 'sub () { '.($eval ? 'eval { ' : '') . '$o->'.$attr.'($value)'.($eval ? ' }' : '').' }';

    my $bench = Dumbbench->new(
      target_rel_precision => 0.005,
      initial_runs         => 20,
    );
    $bench->add_instances(
      map {
        my $o = $objects{$_};
        Dumbbench::Instance::PerlSub->new( name => $_, code => eval $sub );
      } keys %objects,
    );
    $bench->run;

    my %results = map { $_->name => $_->result->number } $bench->instances;

    cmp_ok $results{'Optimized'}, '<=', $results{'Original'},
      "improved speed checking $attr with $value" or $slow++;
  }
  if ($slow) {
    $deparse ||= do {
      require B::Deparse;
      my $b = B::Deparse->new;
      $b->ambient_pragmas(strict => 'all', warnings => 'all');
      $b;
    };
    diag "sub $_ ".B::Deparse->new->coderef2text($objects{$_}->can($attr))
      for reverse sort keys %objects;
  }
}

done_testing;
