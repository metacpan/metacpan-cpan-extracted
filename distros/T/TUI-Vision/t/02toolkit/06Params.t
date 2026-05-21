=pod

=head1 PURPOSE

Using the test cases from Type::Params

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  if ( eval { require TUI::toolkit::Types } ) {
    note 'use TUI::toolkit::Types';
    use_ok 'TUI::toolkit::Types', qw( 
      Any Int ArrayRef HashRef ClassName Str Object Num Ref is_HashRef
    );
  }
  elsif ( eval { require Types::Standard } ) {
    note 'use Types::Standard';
    use_ok 'Types::Standard', qw(
      Any Int ArrayRef HashRef ClassName Str Object Num Ref is_HashRef
    );
  } 
  else {
    plan skip_all => 'Test irrelevant without a Type constraint library';
  }
  # use_ok 'Type::Params', qw( compile signature );
  use_ok 'TUI::toolkit::Params', qw( signature );
}

#
# Check that people doing silly things with *::Params get
#
subtest '/t/20-modules/Type-Params/badsigs.t' => sub {
  throws_ok {
    signature(
      pos => [
        Int, { optional => 1 },
        Int,
      ]
    )
  } qr{^Non-Optional parameter following Optional parameter},
      "Cannot follow an optional parameter with a required parameter";

  throws_ok {
    signature(
      pos => [
        ArrayRef[Int], { slurpy   => 1 },
        Int,           { optional => 1 },
      ]
    )
  } qr{^Parameter following slurpy parameter},
      "Cannot follow a slurpy parameter with anything";

  lives_ok {
    signature( pos => [ Int, { slurpy => 1 } ] )
  } "This makes no sense, but no longer throws an exception";
};

#
# Test C<*::Params> interaction with L<Carp>:
#
{ 
my $check;

subtest '/t/20-modules/Type-Params/carping.t' => sub {

  sub testsub1 {
    $check ||= signature( pos => [ Int ] );
    [ $check->( @_ ) ];
  }

  sub testsub2 {
    testsub1( @_ );
  }
  
  eval {
    testsub2( 1.1 );
  };
  like(
    $@,
    qr{^Value "1\.1" did not pass type constraint "Int" \(in \$_\[0\]\)},
    do { $@ =~ /\bline (\d+)\b/, "croak at line $1" || '' }
  );

}}

#
# Test C<compile> support defaults for parameters.
#
subtest '/t/20-modules/Type-Params/defaults.t' => sub {
  my @rv;

  lives_ok { @rv = signature( pos => [ Int, { default => 42 } ] )->() }
    'no exception thrown because of defaulted argument';

  is_deeply(
    \@rv,
    [42],
    'default applied correctly'
  );

  @rv = ();
  lives_ok {
    @rv = signature( pos => [ Int, { default => sub { 42 } } ] )->()
  } 'no exception thrown because of defaulted argument via coderef';

  is_deeply(
    \@rv,
    [42],
    'default applied correctly via coderef'
  );

  @rv = ();
  lives_ok { @rv = signature( pos => [ Int, { default => \'(40+2)' } ] )->() }
    'no exception thrown because of defaulted argument via Perl source code';

  is_deeply(
    \@rv,
    [42],
    'default applied correctly via Perl source code'
  );

  @rv = ();
  lives_ok { @rv = signature( pos => [ ArrayRef, { default => [] } ] )->() }
    'no exception thrown because of defaulted argument via arrayref';

  is_deeply(
    \@rv,
    [ [] ],
    'default applied correctly via arrayref'
  );

  @rv = ();
  lives_ok { @rv = signature( pos => [ HashRef, { default => {} } ] )->() }
    'no exception thrown because of defaulted argument via hashref';

  is_deeply(
    \@rv,
    [ {} ],
    'default applied correctly via hashref'
  );

  @rv = ();

  lives_ok { @rv = signature( pos => [ Any, { default => undef } ] )->() }
    'no exception thrown because of defaulted argument via undef';

  is_deeply(
    \@rv,
    [undef],
    'default applied correctly via undef'
  );

  throws_ok { signature( pos => [ HashRef, { default => \*STDOUT } ] ) }
    qr/Default expected to be/,
      'exception because bad default';
};

#
# Test C<*::Params> usage for method calls.
#
{
  package Silly::String;

  my %chk;

  sub new {
    $chk{new} ||= ::signature( pos => [ ::ClassName, ::Str ] );
    my ( $class, $str ) = $chk{new}->( @_ );
    bless \$str, $class;
  }

  sub repeat {
    $chk{repeat} ||= ::signature( pos => [ ::Object, ::Int ] );
    my ( $self, $n ) = $chk{repeat}->( @_ );
    $self->get x $n;
  }

  sub get {
    $chk{get} ||= ::signature( pos => [ ::Object ] );
    my ( $self ) = $chk{get}->( @_ );
    $$self;
  }

  sub set {
    $chk{set} ||= ::signature( 
      pos => [ 
        sub { ::Object || ::ClassName },
        ::Str
      ]
    );
    my ( $proto, $str ) = $chk{set}->( @_ );
    ::Object->check( $proto ) ? ( $$proto = $str ) : $proto->new( $str );
  }
}

subtest '/t/20-modules/Type-Params/methods.t' => sub {

  lives_ok {
    my $o = Silly::String->new( "X" );

    is( $o->get, "X", 'get()' );
    is( $o->repeat( 4 ), "XXXX", 'repeat(4)' );

    $o->set( "Y" );
    is( $o->repeat( 4 ), "YYYY", 'repeat(4) after set("Y")' );

    my $p = Silly::String->set( "Z" );
    is( $p->repeat( 4 ), "ZZZZ", 'repeat(4) after set("Z")' );
  } 'clean operation';

  throws_ok { Silly::String::new() }
    qr{^Wrong number of parameters.*?; got 0; expected 2},
      'exception calling new() with no args';

  throws_ok { Silly::String->new() }
    qr{^Wrong number of parameters.*?; got 1; expected 2},
      'exception calling ->new() with no args';

  throws_ok { Silly::String::set() }
    qr{^Wrong number of parameters.*?; got 0; expected 2},
      'exception calling set() with no args';

};

#
# Test L<*::Params> usage with optional parameters.
#
{
my $chk1 = signature(
  pos => [
    Num,
    Int,      { optional => 1 },
    ArrayRef, { optional => 1 },
    HashRef,  { optional => 1 },
  ]
);
my $chk5 = signature(
  pos => [
    Num,      { optional => 0 },
    Int,      { optional => 1 },
    ArrayRef, { optional => 1 },
    HashRef,  { optional => 1 },
  ]
);

subtest '/t/20-modules/Type-Params/optional.t' => sub {

  for my $chk ( $chk1, $chk5 ) {
    is_deeply(
      [ $chk->( 1.1, 2, [], {} ) ],
      [ 1.1, 2, [], {} ],
      '(1.1, 2, [], {})',
    );

    is_deeply(
      [ $chk->( 1.1, 2, [] ) ],
      [ 1.1, 2, [] ],
      '(1.1, 2, [])',
    );

    is_deeply(
      [ $chk->( 1.1, 2 ) ],
      [ 1.1, 2 ],
      '(1.1, 2)',
    );

    is_deeply(
      [ $chk->( 1.1 ) ],
      [ 1.1 ],
      '(1.1)',
    );

    throws_ok { $chk->( 1.1, 2, {} ) }
      qr{^Reference \S+ did not pass type constraint "\S+?" \(in \$_\[2\]\)};

    throws_ok { $chk->() }
      qr{^Wrong number of parameters; got 0; expected 1 to 4};

    throws_ok  { $chk->( 1 .. 5 ) }
      qr{^Wrong number of parameters; got 5; expected 1 to 4};

    throws_ok { $chk->( 1, 2, undef ) }
      qr{^Undef did not pass type constraint};
  }

  my $chk99 = signature( 
    pos => [
      Any, { optional => 0 },
      Any, { optional => 1 },
      Any, { optional => 1 },
    ]
  );
  throws_ok { $chk99->() }
    qr{^Wrong number of parameters; got 0; expected 1 to 3};

}}

#
# Test L<*::Params> positional parameters
#
{
my $check;

subtest '/t/20-modules/Type-Params/optional.t' => sub {

  throws_ok { signature( pos => [] )->(1) }
    qr{^Wrong number of parameters; got 1; expected 0}, 'empty compile()';

  sub nth_root {
    $check ||= signature( pos => [ Num, Num ] );
    [ $check->( @_ ) ];
  }

  is_deeply(
    nth_root( 1, 2 ),
    [ 1, 2 ],
    '(1, 2)',
  );

  is_deeply(
    nth_root( "1.1", 2 ),
    [ "1.1", 2 ],
    '(1.1, 2)',
  );

  throws_ok { nth_root() }
    qr{^Wrong number of parameters.*?; got 0; expected 2}, '(1)';

  throws_ok { nth_root( 1 ) }
    qr{^Wrong number of parameters.*?; got 1; expected 2}, '(1)';

  throws_ok { nth_root( undef, 1 ) }
    qr{^Undef did not pass type constraint "Num" \(in \$_\[0\]\)}, '(undef, 1)';

  throws_ok { nth_root( 1, 2, 3 ) }
    qr{^Wrong number of parameters.*?; got 3; expected 2}, '(1)';

}}

#
# Test L<*::Params> usage with slurpy parameters
#
subtest '/t/20-modules/Type-Params/slurpy.t' => sub {

  my $chk = signature( pos => [ Str, HashRef[Int], { slurpy => 1 } ] );

  is_deeply(
    [ $chk->( "Hello", foo => 1, bar => 2 ) ],
    [ "Hello", { foo => 1, bar => 2 } ],
    'simple test',
  );

  is_deeply(
    [ $chk->( "Hello", { foo => 1, bar => 2 } ) ],
    [ "Hello", { foo => 1, bar => 2 } ],
    'simple test with ref',
  );

  throws_ok { $chk->( "Hello", foo => 1, bar => 2.1 ) }
    qr{did not pass type constraint "HashRef\[Int\]" \(in \$SLURPY\)},
      'simple test failing type check';

  sub xyz2 {
    my $check = signature( pos => [ Int, HashRef, { slurpy => 1 } ] );
    my ( $num, $hr ) = $check->( @_ );
    return [ $num, $hr ];
  }

  subtest "HashRef { slurpy => 1 } works" => sub {

    is_deeply(
      xyz2( 5, foo => 1, bar => 2 ),
      [ 5, { foo => 1, bar => 2 } ],
      'simple test',
    );

    is_deeply(
      xyz2( 5, { foo => 1, bar => 2 } ), 
      [ 5, { foo => 1, bar => 2 } ],
      'simple test with ref',
    );
  };

  throws_ok {
    signature(
      positional => [ ArrayRef, { slurpy => 1 }, ArrayRef ],
    );
  }
  qr/Parameter following slurpy parameter/,
    'Exception thrown for parameter after a slurpy in positional signature';

  throws_ok {
    signature(
      positional => [ ArrayRef, { slurpy => 1 }, ArrayRef, { slurpy => 1 }  ],
    );
  }
  qr/Parameter following slurpy parameter/,
    'Exception thrown for slurpy param after a slurpy in positional signature';

};

#
# Check that Type::Params v2 default coderefs get passed an invocant.
#
{
  package Local::FooBar;

	sub foo { 42 }
	my $check;
	sub bar {
		$check ||= ::signature(
			method     => 1,
			positional => [
				::Int, { default => sub { shift->foo } },
			],
		);
		my ( $self, $num ) = &$check;
		return $num / 2;
	}
}
subtest '/t/20-modules/Type-Params/v2-defaults.t' => sub {
  my $object = bless {}, 'Local::FooBar';

  is( $object->bar(), 21 );

  is( $object->bar(666), 333 );
};

#
# Slurpy parameter tests for modern Type::Params v2 API.
#
subtest '/t/20-modules/Type-Params/v2-positional-plus-slurpy.t' => sub {

  my $sig = signature(
    positional => [
      Str,
      Str,
      Any, { slurpy => 1 },
    ],
  );
  my ( $in, $out, $slurpy ) = $sig->( qw/ IN OUT FOO BAR / );
  is( $in,  'IN' );
  is( $out, 'OUT' );
  is_deeply( $slurpy, [ 'FOO', 'BAR' ] );

  my $sig2;
  my $e = do { eval {
      $sig2 = signature pos => [ Int, { slurpy => 1 } ];
      $sig2->( 42 );
    };
    $@;
  };
  isnt $e, undef;

};

done_testing();
