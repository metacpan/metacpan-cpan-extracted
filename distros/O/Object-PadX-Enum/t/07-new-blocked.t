#!perl
use v5.22;
use warnings;

use Test2::V0;

use Object::PadX::Enum;

enum Color {
   item RED;
   item GREEN;
}

# Direct construction is blocked.
{
   my $ok = eval { Color->new; 1 };
   ok( !$ok, 'Color->new croaks' );
   like( $@, qr/Cannot construct new instances/, 'error message identifies the issue' );
   like( $@, qr/'Color'/,                        'error message names the class' );
   like( $@, qr/RED/,                            'error message lists RED' );
   like( $@, qr/GREEN/,                          'error message lists GREEN' );
   like( $@, qr/from_name/,                      'error message suggests from_name' );
   like( $@, qr/from_ordinal/,                   'error message suggests from_ordinal' );
}

# Even with args, still blocked.
{
   my $ok = eval { Color->new( extra => 1 ); 1 };
   ok( !$ok, 'Color->new(args) croaks' );
   like( $@, qr/Cannot construct new instances/, 'same error path for args' );
}

# Singleton accessors still work after the block.
is( Color->RED->name,   'RED',   'RED accessor still works' );
is( Color->GREEN->name, 'GREEN', 'GREEN accessor still works' );

# Lookup helpers still work.
{
   my @vs = Color->values;
   is( scalar @vs, 2, 'values returns 2 items' );
}
is( Color->from_name('RED')->ordinal,    0, 'from_name works' );
is( Color->from_ordinal(1)->name,    'GREEN', 'from_ordinal works' );

# Empty enum gets a graceful message (no items list, no from_* hint).
enum Empty {}

{
   my $ok = eval { Empty->new; 1 };
   ok( !$ok, 'Empty->new croaks' );
   like( $@, qr/Cannot construct new instances of enum class 'Empty'/, 'empty enum error message' );
   unlike( $@, qr/use one of:/, 'empty enum omits item list' );
}

done_testing;
