use v5.36;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use RT::Extension::AwayMode;

my $class = 'RT::Extension::AwayMode';

# Defaults (no configured list passed) come from @DEFAULT_TRANSACTION_TYPES.
ok( $class->IsHandledTransactionType('Correspond'),
    'Correspond is handled by default' );
ok( $class->IsHandledTransactionType('Comment'),
    'Comment is handled by default' );
ok(
    !$class->IsHandledTransactionType('Status'),
    'other transaction types are not handled'
);
ok( !$class->IsHandledTransactionType('Create'), 'Create is not handled' );

ok( !$class->IsHandledTransactionType(undef), 'undef type => not handled' );
ok( !$class->IsHandledTransactionType(q{}),   'empty type => not handled' );

# RT stores transaction types capitalized, but don't depend on it.
ok(
    $class->IsHandledTransactionType('correspond'),
    'type comparison is case insensitive'
);
ok(
    $class->IsHandledTransactionType( 'Comment', ['comment'] ),
    'configured types are matched case insensitively too'
);

# An explicitly configured list narrows the default.
ok( $class->IsHandledTransactionType( 'Correspond', ['Correspond'] ),
    'Correspond-only config still handles Correspond' );
ok( !$class->IsHandledTransactionType( 'Comment', ['Correspond'] ),
    'Correspond-only config ignores Comment' );
ok( $class->IsHandledTransactionType( 'Comment', ['Comment'] ),
    'Comment-only config handles Comment' );
ok( !$class->IsHandledTransactionType( 'Correspond', ['Comment'] ),
    'Comment-only config ignores Correspond' );

ok(
    !$class->IsHandledTransactionType( 'Correspond', [] ),
    'empty config list disables the handoff entirely'
);

# A site config that sets a bare string instead of an arrayref shouldn't blow up.
ok(
    $class->IsHandledTransactionType( 'Comment', 'Comment' ),
    'a plain string config value is treated as a one-element list'
);
ok(
    !$class->IsHandledTransactionType( 'Correspond', 'Comment' ),
    'a plain string config value still excludes other types'
);

ok(
    !$class->IsHandledTransactionType( 'Correspond', [undef] ),
    'undef entries in the config list are skipped'
);

done_testing();
