#!/usr/local/bin/perl -w
use strict;

#use Test::More 'no_plan';
use Test::More tests => 28;
use Test::Fatal;

my $CLASS;

{

    package Foo;

    sub bar {
        return 'original value';
    }

    sub baz {
        return 'original baz value';
    }
}

BEGIN {
    chdir 't' if -d 't';
    use lib '../lib';
    $CLASS = 'Sub::Override';
    use_ok($CLASS) || die;
}

can_ok( $CLASS, 'new' );

my $override = $CLASS->new;
isa_ok( $override, $CLASS, '... and the object it returns' );

can_ok( $override, 'replace' );

like
  exception { $override->replace( 'No::Such::Sub', '' ) },
  qr/^\QCannot replace non-existent sub (No::Such::Sub)\E/,
  "... and we can't replace a sub which doesn't exist";

like
  exception { $override->replace( 'Foo::bar', 'not a subref' ) },
  qr/\(not a subref\) must be a code reference/,
  '... and only a code reference may replace a subroutine';

ok( $override->replace( 'Foo::bar', sub {'new subroutine'} ),
    '... and replacing a subroutine should succeed'
);
is( Foo::bar(), 'new subroutine',
    '... and the subroutine should exhibit the new behavior'
);

ok( $override->replace( 'Foo::bar' => sub {'new subroutine 2'} ),
    '... and we should be able to replace a sub more than once'
);
is( Foo::bar(), 'new subroutine 2',
    '... and still have the sub exhibit the new behavior'
);

can_ok( $override, 'override' );
ok( $override->override( 'Foo::bar' => sub {'new subroutine 3'} ),
    '... and it should also replace a subroutine'
);
is( Foo::bar(), 'new subroutine 3',
    '... and act just like replace()'
);

can_ok( $override, 'restore' );

like
  exception { $override->restore('Did::Not::Override') },
  qr/^\QCannot restore a sub that was not replaced (Did::Not::Override)/,
  '... and it should fail if the subroutine had not been replaced';

$override->restore('Foo::bar');
is( Foo::bar(), 'original value',
    '... and the subroutine should exhibit the original behavior'
);

like
  exception { $override->restore('Foo::bar') },
  qr/^\QCannot restore a sub that was not replaced (Foo::bar)/,
  '... but we should not be able to restore it twice';

{
    my $new_override = $CLASS->new;
    ok( $new_override->replace( 'Foo::bar', sub {'lexical value'} ),
        'A new override object should be able to replace a subroutine'
    );

    is( Foo::bar(), 'lexical value',
        '... and the subroutine should exhibit the new behavior'
    );
}
is( Foo::bar(), 'original value',
    '... but should revert to the original behavior when the object falls out of scope'
);

{
    my $new_override = $CLASS->new( 'Foo::bar', sub {'lexical value'} );
    ok( $new_override,
        'We should be able to override a sub from the constructor' );

    is( Foo::bar(), 'lexical value',
        '... and the subroutine should exhibit the new behavior'
    );
    ok( $new_override->restore,
        '... and we do not need an argument to restore if only one sub is overridden'
    );
    is( Foo::bar(), 'original value',
        '... and the subroutine should exhibit its original behavior'
    );
    $new_override->replace( 'Foo::bar', sub { } );
    $new_override->replace( 'Foo::baz', sub { } );

    like
      exception { $new_override->restore },
      qr/You must provide the name of a sub to restore: \(Foo::bar, Foo::baz\)/,
      '... but we must explicitly provide the sub name if more than one was replaced';
}

{

    package Temp;
    sub foo {23}
    sub bar {42}

    my $override = Sub::Override->new( 'foo', sub {42} );
    $override->replace( 'bar', sub {'barbar'} );
    main::is( foo(), 42,
        'Not fully qualifying a sub name will assume the current package' );
    $override->restore('foo');
    main::is( foo(), 23, '... and we should be able to restore said sub' );

    $override->restore('Temp::bar');
    main::is( bar(), 42, '... even if we use a full qualified sub name' );
}
