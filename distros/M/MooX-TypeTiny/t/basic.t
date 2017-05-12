use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Type::Tiny;
use Sub::Quote qw(quote_sub);
use Types::Standard qw(Int Num);

my $int;
BEGIN {
  $int = Int->plus_coercions(Num,=> quote_sub(q{ int $_ }));
}

BEGIN {
  package MooClassMXTT;
  use Moo;
  use MooX::TypeTiny;

  has attr_isa        => (is => 'rw', isa => $int );
  has attr_coerce     => (is => 'rw', coerce => $int->coercion );
  has attr_isa_coerce => (is => 'rw', isa => $int, coerce => $int->coercion );
}

BEGIN {
  package MooClass;
  use Moo;

  has attr_isa        => (is => 'rw', isa => $int );
  has attr_coerce     => (is => 'rw', coerce => $int->coercion );
  has attr_isa_coerce => (is => 'rw', isa => $int, coerce => $int->coercion );
}

my $goto = MooClassMXTT->new;
my $wanto = MooClass->new;

for my $attr (qw(attr_isa attr_coerce attr_isa_coerce)) {
  for my $value (1, 1.2, "welp") {
    my $want;
    my $want_e = exception { $want = $wanto->$attr($value) };
    my $got;
    my $got_e = exception { $got = $goto->$attr($value) };
    defined and s/\(eval \d+\)//, s/ line \d+//
      for $want_e, $got_e;

    is $got_e, $want_e,
      "inlined code has same exception as base $attr check with $value";
    is $got, $want,
      "inlined code has same result as base $attr check with $value";
  }
}

done_testing;
