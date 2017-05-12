package bq7hh_i42k;
use Mojo::Base -base;

use Mojar::ClassShare 'have';

have 'a';
have b => 'B';
have c => sub { 'C' };

package main;
use Mojo::Base -strict;
use Test::More;

my ($a1, $a2);

subtest q{Object attr} => sub {
  ok $a1 = bq7hh_i42k->new(a => 'A1'), 'constructor';
  ok $a2 = bq7hh_i42k->new(a => 'A2'), 'constructor';

  is $a1->a, 'A1', 'new-time attr';
  is $a2->a, 'A2', 'new-time attr';
  is $a1->c, 'C', 'dynamic default';

  ok $a1->b('B1')->a('A10'), 'chainable';
  is $a1->b, 'B1', 'expected value';
  is $a1->a, 'A10', 'expected value';
  is $a2->b, 'B', 'no interference';

  ok $a2->b('B2')->a('A20'), 'chainable';
  is $a2->b, 'B2', 'expected value';
  is $a2->a, 'A20', 'expected value';
  is $a1->b, 'B1', 'no interference';
};

subtest q{Class attr} => sub {
  ok ! +(bq7hh_i42k->a), 'a undef';
  is +(bq7hh_i42k->b), 'B', 'b still has default';
  is +(bq7hh_i42k->c), 'C', 'c has default';


  ok $a1->b('B1')->a('A10'), 'chainable';
  is $a1->b, 'B1', 'expected value';
  is $a1->a, 'A10', 'expected value';
  is $a2->b, 'B2', 'no interference';

  ok $a2->b('B2')->a('A20'), 'chainable';
  is $a2->b, 'B2', 'expected value';
  is $a2->a, 'A20', 'expected value';
  is $a1->b, 'B1', 'no interference';

  ok +(bq7hh_i42k->b), 'scalar';
  ok +(bq7hh_i42k->a('A')), 'assignment';
  ok +(bq7hh_i42k->c), 'call';
};

subtest q{Mixed attr} => sub {
  ok +(bq7hh_i42k->a('A class')), 'set class attr';
  is $a1->a, 'A10', 'no interference on object';

  ok $a1->a('another'), 'set object attr';
  is $a1->a, 'another', 'expected value';
  is +(bq7hh_i42k->a), 'A class', 'no interference on class';
};

done_testing();
__END__

package bq7hh_i42k;
use Mojo::Base -strict;

sub attr {
  my ($class, $attrs, $default) = @_;
  return unless ($class = ref $class || $class) && $attrs;

  Carp::croak 'Default has to be a code reference or constant value'
    if ref $default && ref $default ne 'CODE';

  for my $attr (@{ref $attrs eq 'ARRAY' ? $attrs : [$attrs]}) {
    Carp::croak qq{Attribute "$attr" invalid} unless $attr =~ /^[a-zA-Z_]\w*$/;

    # Header (check arguments)
    my $code = "package $class;\nsub $attr {no strict 'refs';\n  if (\@_ == 1) {\n";

    # No default value (return value)
    unless (defined $default) { $code .= "    return \$_[0]{'$attr'};" }

    # Default value
    else {

      # Return value
      $code .= "    return \$_[0]{'$attr'} if exists \$_[0]{'$attr'};\n";

      # Return default value
      $code .= "    return \$_[0]{'$attr'} = ";
      $code .= ref $default eq 'CODE' ? '$default->($_[0]);' : '$default;';
    }

    # Store value
    $code .= "\n  }\n  \$_[0]{'$attr'} = \$_[1];\n";

    # Footer (return invocant)
    $code .= "  \$_[0];\n}";

    warn "-- Attribute $attr in $class\n$code\n\n" if $ENV{MOJO_BASE_DEBUG};
    Carp::croak "Mojo::Base error: $@" unless eval "$code;1";
  }
}

BEGIN {
  no strict 'refs';
  *{__PACKAGE__ .'::has'} = sub { attr(__PACKAGE__, @_) };
}
has 'a';
has b => 'B';
has c => sub { 'C' };


package main;
use Mojo::Base -strict;
use Test::More;

subtest q{Class attr} => sub {
  ok +(bq7hh_i42k->b), 'scalar';
  ok +(bq7hh_i42k->a('A')), 'assignment';
  ok +(bq7hh_i42k->c), 'call';
};

done_testing();
