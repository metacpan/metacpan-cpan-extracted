{
  package MooX::Types::MooseLike::Test;
  use strict;
  use warnings FATAL => 'all';
  use Moo;
  use MooX::Types::MooseLike::Base qw/
    ArrayRef Int HashRef Str ScalarRef Maybe AnyOf Undef
    /;

  has an_array_of_integers => (
    is  => 'ro',
    isa => ArrayRef [Int],
    );
  has an_array_of_hash => (
    is  => 'ro',
    isa => ArrayRef [HashRef],
    );
  has a_hash_of_strings => (
    is  => 'ro',
    isa => HashRef [Str],
    );
  has an_array_of_hash_of_int => (
    is  => 'ro',
    isa => ArrayRef [ HashRef [Int] ],
    );
  has a_scalar_ref_of_int => (
    is  => 'ro',
    isa => ScalarRef [Int],
    );
  has maybe_an_int => (
    is  => 'ro',
    isa => Maybe [Int],
    );
  has array_maybe_a_hash => (
    is  => 'ro',
    isa => ArrayRef [ Maybe [HashRef] ],
    );
  has array_maybe_a_hash_of_int => (
    is  => 'ro',
    isa => ArrayRef [ Maybe [ HashRef [Int] ] ],
    );
  has maybe_an_int_or_hash => (
    is  => 'ro',
    isa => AnyOf[Int, HashRef, Undef],
    );
}

package main;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Fatal;
use IO::Handle;

# ArrayRef[Int]
ok(MooX::Types::MooseLike::Test->new(an_array_of_integers => [ 6, 7, 10, -1 ]),
  'ArrayRef[Int]');
like(
  exception {
    MooX::Types::MooseLike::Test->new(an_array_of_integers => [ 1.5, 2 ]);
  },
  qr/is not an integer/,
  'an ArrayRef of Floats is an exception when we want an ArrayRef[Int]'
  );

# ArrayRef[HashRef]
ok(
  MooX::Types::MooseLike::Test->new(
    an_array_of_hash => [ { a => 1 }, { b => 2 } ]
    ),
  'ArrayRef[HashRef]'
  );
ok(
  MooX::Types::MooseLike::Test->new(
    an_array_of_hash => [ { a => 1 }, { b => undef } ]
    ),
  'ArrayRef[HashRef] with undef'
  );
like(
  exception {
    MooX::Types::MooseLike::Test->new(
      an_array_of_hash => [ { x => 1 }, [ 1, 2, 3 ] ]);
  },
  qr/is not a HashRef/,
  'an ArrayRef of integers is an exception when we want an ArrayRef[HashRef]'
  );

# HashRef[Str]
ok(MooX::Types::MooseLike::Test->new(a_hash_of_strings => { a => 1, b => 'x' }),
  'HashRef[Str]');
ok(MooX::Types::MooseLike::Test->new(a_hash_of_strings => {}),
  'Empty HashRef');
like(
  exception {
    MooX::Types::MooseLike::Test->new(a_hash_of_strings =>
        { a => MooX::Types::MooseLike::Test->new(), b => 'x' });
  },
  qr/is not a string/,
  'an HashRef with Objects is an exception when we want an HashRef[Str]'
  );

# ArrayRef[HashRef[Int]]
ok(
  MooX::Types::MooseLike::Test->new(
    an_array_of_hash_of_int => [ { a => 1 }, { b => 2 } ]
    ),
  'ArrayRef[HashRef[Int]]'
  );
like(
  exception {
    MooX::Types::MooseLike::Test->new(
      an_array_of_hash_of_int => [ { x => 1 }, { x => 1.1 } ]);
  },
  qr/is not an integer/,
  'an ArrayRef of HashRef of Floats is an exception when we want an ArrayRef[HashRef[Int]]'
  );

# ScalarRef[Int]
ok(MooX::Types::MooseLike::Test->new(a_scalar_ref_of_int => \1),
  'ScalarRef[Int]');
like(
  exception { MooX::Types::MooseLike::Test->new(a_scalar_ref_of_int => \'x') },
  qr/is not an integer/,
  'a ScalarRef of Str is an exception when we want an ScalarRef[Int]'
  );

# Maybe[Int]
ok(MooX::Types::MooseLike::Test->new(maybe_an_int => 41),
  'Maybe[Int] as an integer');
ok(MooX::Types::MooseLike::Test->new(maybe_an_int => undef),
  'Maybe[Int] as undef');
ok(MooX::Types::MooseLike::Test->new(maybe_an_int => -24),
  'Maybe[Int] as undef');
like(
  exception { MooX::Types::MooseLike::Test->new(maybe_an_int => 'x') },
  qr/is not an integer/,
  'a Str is an exception when we want a Maybe[Int]'
  );

# AnyOf[Int, HashRef, Undef] - a stand in for Maybe[Int, HashRef]
ok(MooX::Types::MooseLike::Test->new(maybe_an_int_or_hash => {nbr => 41} ),
  'Maybe[Int, HahsRef, Undef] as a HashRef');
ok(MooX::Types::MooseLike::Test->new(maybe_an_int_or_hash => 41 ),
  'Maybe[Int, HahsRef, Undef] as an integer');
ok(MooX::Types::MooseLike::Test->new(maybe_an_int_or_hash => undef ),
  'Maybe[Int, HahsRef, Undef] as an undef');
like(
  exception { MooX::Types::MooseLike::Test->new(maybe_an_int_or_hash => [] ) },
  qr/is not any of/,
  'an ArrayRef is an exception when we want a AnyOf[Int, HashRef, Undef]'
  );
like(
  exception { MooX::Types::MooseLike::Test->new(maybe_an_int_or_hash => sub {} ) },
  qr/is not any of/,
  'a CodeRef is an exception when we want a AnyOf[Int, HashRef, Undef]'
  );

# ArrayRef[Maybe[HashRef]]
ok(MooX::Types::MooseLike::Test->new(array_maybe_a_hash => [ { a => 41 } ]),
  'ArrayRef[Maybe[HashRef]] as an HashRef');
ok(
  MooX::Types::MooseLike::Test->new(
    array_maybe_a_hash => [ undef, { a => 41 } ]
    ),
  'ArrayRef[Maybe[HashRef]] with an undef'
  );
like(
  exception { MooX::Types::MooseLike::Test->new(array_maybe_a_hash => ['x']) },
  qr/is not a HashRef/,
  'a Str is an exception when we want a Maybe[HashRef]'
  );

# ArrayRef[Maybe[HashRef[Int]]]
ok(
  MooX::Types::MooseLike::Test->new(
    array_maybe_a_hash_of_int => [ { a => 41 } ]
    ),
  'ArrayRef[Maybe[HashRef]] as a HashRef[Int]'
  );
ok(
  MooX::Types::MooseLike::Test->new(
    array_maybe_a_hash_of_int => [ undef, { a => -1 } ]
    ),
  'ArrayRef[Maybe[HashRef]] with an undef'
  );
like(
  exception {
    MooX::Types::MooseLike::Test->new(
      array_maybe_a_hash_of_int => [ { b => 'x' } ]);
  },
  qr/is not an integer/,
  'a Str is an exception when we want a Maybe[HashRef[Int]]'
  );

done_testing;
