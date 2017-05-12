#!perl -T

use Test::More tests => 4;

BEGIN {
	use_ok( 'Sub::Starter' );
}

my ( $name, $sub, $test, $expected );
my @template = map { "$_\n" } split /\n/, <<EOD;
# --------------------------------------
#       Name: [1m(name)[0m
#      Usage: [1m(usage)[0m
#    Purpose: TBD
# Parameters: (none)[1m(parameters arenot)[0m
# Parameters: [1m(parameters first %*s)[0m -- TBD
#             [1m(parameters rest %*s)[0m -- TBD
#    Returns: (none)[1m(returns arenot)[0m
#    Returns: [1m(returns first %*s)[0m -- TBD
#             [1m(returns rest %*s)[0m -- TBD
#
sub [1m(name)[0m {
  my [1m(definitions %-*s\s=\s%s)[0m;

  return[1m(returns expression)[0m;
}

EOD

# --------------------------------------
$name = 'foo';
$sub = Sub::Starter->new();
$sub->parse_usage( 'foo' );
$test = $sub->fill_out( \@template );
$expected = '# --------------------------------------
#       Name: foo
#      Usage: foo();
#    Purpose: TBD
# Parameters: (none)
#    Returns: (none)
#
sub foo {

  return;
}
';
is_deeply( $test, $expected, $name );

# --------------------------------------
$name = 'trim';
$sub = Sub::Starter->new();
$sub->parse_usage( '$text | @text = trim( @text );' );
$test = $sub->fill_out( \@template );
$expected = '# --------------------------------------
#       Name: trim
#      Usage: $text | @text = trim( @text );
#    Purpose: TBD
# Parameters: @text -- TBD
#    Returns: $text -- TBD
#             @text -- TBD
#
sub trim {
  my @texts=s@_;
  my $texts=s\'\';

  return wantarray ? @text : $text;
}
';
is_deeply( $test, $expected, $name );

# --------------------------------------
$name = 'get_options';
$sub = Sub::Starter->new();
$sub->parse_usage( '\%options = $object->get_options( ; @option_names );' );
$test = $sub->fill_out( \@template );
$expected = '# --------------------------------------
#       Name: get_options
#      Usage: \\%options = $object->get_options( ; @option_names );
#    Purpose: TBD
# Parameters: @option_names -- TBD
#    Returns:     \\%options -- TBD
#
sub get_options {
  my $self        s=sshift @_;
  my @option_namess=s@_;
  my $options     s=s{};

  return $options;
}
';
is_deeply( $test, $expected, $name );


__END__
