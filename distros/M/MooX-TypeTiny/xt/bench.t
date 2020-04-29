use strict;
use warnings;
use Test::More;
use Dumbbench;
use Dumbbench::Instance::PerlSub;
use Types::Standard qw(Int Num);
use B::Deparse;

# benchmarking in a test isn't entirely sane, but since this module is meant to
# be an optimization we want to make sure it's actually doing its job.  This
# will occasionally fail, but it's an xt test so it shouldn't get in the way
# of anything.

my $int = Int->plus_coercions(Num,=> q{ int $_ });
my $add_attrs = sub {
  my ($package) = @_;
  my $has = $package->can('has');
  $has->(attr_isa        => (is => 'rw', isa => $int));
  $has->(attr_coerce     => (is => 'rw', coerce => $int->coercion));
  $has->(attr_isa_coerce => (is => 'rw', isa => $int, coerce => $int->coercion));
};

my @objects = (
  [ original => do {
    package MooClass;
    use Moo;
    __PACKAGE__->$add_attrs;
    __PACKAGE__->new;
  } ],
  [ optimized => do {
    package MooClassMXTT;
    use Moo;
    use MooX::TypeTiny;
    __PACKAGE__->$add_attrs;
    __PACKAGE__->new;
  } ],
);

my $deparse = B::Deparse->new;

for my $attr (qw(attr_isa attr_coerce attr_isa_coerce)) {
  my $slow;
  my $tries;
  for my $value (1, 1.2, 'welp') {
    my $need_eval = grep !eval { $_->[1]->$attr($value) }, @objects;

    my $bench = Dumbbench->new(
      target_rel_precision => 0.005,
      initial_runs         => 200,
    );

    for my $op (@objects) {
      my ($name, $o) = @$op;
      my $code = '$o->'.$attr.'($value)';
      $code = "eval { $code }"
        if $need_eval;

      my $sub = eval 'sub () { '.join(';', ($code) x 50 ) . '}' or die ":( $@";
      # make sure it works
      $sub->();

      $bench->add_instances(
        Dumbbench::Instance::PerlSub->new( name => $name, code => $sub )
      );
    }

    $bench->run;

    my %results = map { $_->name => $_->result->number } $bench->instances;

    my $last_name;
    my $last_result;

    for my $name (map $_->[0], @objects) {
      my $result = $results{$name};
      if (defined $last_name) {
        cmp_ok $result, '<=', $last_result,
          "$name improved speed over $last_name checking $attr with $value" or $slow++;
      }
      ($last_name, $last_result) = ($name, $result);
    }
  }

  if ($slow) {
    for my $op (@objects) {
      my ($name, $object) = @$op;
      my $code = $deparse->coderef2text($object->can($attr));
      $code =~ s{
        \A
        \s* \{ [ \t]* \n
        (?:
            ^[ \t]* package [ \t]+ \S+;\n
          |
            ^[ \t]* BEGIN [ \t]* \{ [ \t]* \$\{\^WARNING_BITS\} [ \t]* = [ \t]* "[^"]+" [ \t] *\} [ \t]* \n
          |
            ^[ \t]* '[^']*';\n
          |
            ^[ \t]*use [ \t]+ (?:strict|warnings)[^;]*;\n
        )*
      }{\{\n}mx;

      diag "sub $name $code";
    }
  }
}

done_testing;
