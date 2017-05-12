#!perl -T

use Test::More tests => 4;

BEGIN {
	use_ok( 'Sub::Starter' );
}

my ( $name, $sub, $test, $expected );
my @template = map { "$_\n" } split /\n/, <<EOD;
=head2 [1m(name)[0m()

=head3 Usage

  [1m(usage)[0m

=head3 Parameters

(none)[1m(parameters arenot)[0m
=over 4[1m(parameters are \\n)[0m
=item [1m(parameters each %s\\n\\nTBD\\n)[0m
=back[1m(parameters are)[0m

=head3 Returns

(none)[1m(returns arenot)[0m
=over 4[1m(returns are \\n)[0m
=item [1m(returns each %s\\n\\nTBD\\n)[0m
=back[1m(returns are)[0m

EOD

# --------------------------------------
$name = 'foo';
$sub = Sub::Starter->new();
$sub->parse_usage( 'foo' );
$test = $sub->fill_out( \@template );
$expected = '=head2 foo()

=head3 Usage

  foo();

=head3 Parameters

(none)

=head3 Returns

(none)
';
is_deeply( $test, $expected, $name );

# --------------------------------------
$name = 'trim';
$sub = Sub::Starter->new();
$sub->parse_usage( '$text | @text = trim( @text );' );
$test = $sub->fill_out( \@template );
$expected = '=head2 trim()

=head3 Usage

  $text | @text = trim( @text );

=head3 Parameters

=over 4

=item @text

TBD

=back

=head3 Returns

=over 4

=item $text

TBD

=item @text

TBD

=back
';
is_deeply( $test, $expected, $name );

# --------------------------------------
$name = 'get_options';
$sub = Sub::Starter->new();
$sub->parse_usage( '\%options = $object->get_options( ; @option_names );' );
$test = $sub->fill_out( \@template );
$expected = '=head2 get_options()

=head3 Usage

  \\%options = $object->get_options( ; @option_names );

=head3 Parameters

=over 4

=item @option_names

TBD

=back

=head3 Returns

=over 4

=item \\%options

TBD

=back
';
is_deeply( $test, $expected, $name );


__END__
