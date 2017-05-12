#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 223;

my $CLASS;
BEGIN {
    $CLASS = 'Pg::Priv';
    use_ok $CLASS or die;
}

ok my $priv = $CLASS->new(
    to    => 'david',
    by    => 'postgres',
    privs => 'arwdxt',
), 'Create a priv object';

is $priv->to, 'david', 'It should have proper grantee';
is $priv->by, 'postgres', 'It should have the proper grantor';
is $priv->privs, 'arwdxt', 'It should have the proper privs';
is_deeply [sort $priv->labels], [sort qw(UPDATE SELECT INSERT REFERENCE DELETE TRIGGER)],
    'It should return the proper labels';
is_deeply [ sort @{ $priv->labels } ], [sort qw(UPDATE SELECT INSERT REFERENCE DELETE TRIGGER)],
    'It should return labels as an arrayref in scalar context';

my @has = qw(a r w d x t);
ok $priv->can(@has), 'eye can(@has)';
for my $perm (@has) {
    ok $priv->can($perm), "can($perm) should return true";
}

my @hasnt = qw(D X U C c T);
ok !$priv->can(@hasnt), 'eye cant(@hasnt)';
for my $perm (@hasnt) {
    ok !$priv->can($perm), "can($perm) should return false";
}
ok !$priv->can(@has, @hasnt), 'eye cant(@has, @hasnt)';

my @labels = qw(
    INSERT
    UPDATE
    DELETE
    SELECT
    REFERENCE
    TRIGGER
);

ok $priv->can(@labels), 'eye can(@labels)';
for my $label (@labels) {
    ok $priv->can($label), "can($label) should return true";
}

my @not_labels = qw(
    TRUNCATE
    EXECUTE
    USAGE
    CREATE
    CONNECT
    TEMPORARY
    TEMP
);

ok !$priv->can(@not_labels), 'eye cant(@not_labels)';
for my $label (@not_labels) {
    ok !$priv->can($label), "can($label) should return false";
}
ok !$priv->can(@labels, @not_labels), 'eye cant(@labels, @not_labels)';

ok $priv->can_select,     'Yes we can select';
ok $priv->can_read,       'Yes we can read';
ok $priv->can_update,     'Yes we can update';
ok $priv->can_write,      'Yes we can write';
ok $priv->can_insert,     'Yes we can insert';
ok $priv->can_append,     'Yes we can append';
ok $priv->can_delete,     'Yes we can delete';
ok $priv->can_reference,  'Yes we can reference';
ok $priv->can_trigger,    'Yes we can trigger';
ok !$priv->can_execute,   'No we cannot execute';
ok !$priv->can_usage,     'No we cannot usage';
ok !$priv->can_create,    'No we cannot create';
ok !$priv->can_connect,   'No we cannot connect';
ok !$priv->can_temporary, 'No we cannot temporary';
ok !$priv->can_temp,      'No we cannot temp';

for my $word (qw(
    all
    analyse
    analyze
    and
    any
    array
    as
    asc
    asymmetric
    both
    case
    cast
    check
    collate
    column
    constraint
    create
    current_catalog
    current_date
    current_role
    current_time
    current_timestamp
    current_user
    default
    deferrable
    desc
    distinct
    do
    else
    end
    except
    false
    fetch
    for
    foreign
    from
    grant
    group
    having
    in
    initially
    intersect
    into
    leading
    limit
    localtime
    localtimestamp
    new
    not
    null
    off
    offset
    old
    on
    only
    or
    order
    placing
    primary
    references
    returning
    select
    session_user
    some
    symmetric
    table
    then
    to
    trailing
    true
    union
    unique
    user
    using
    variadic
    when
    where
    window
    with
)) {
    ok Pg::Priv::_is_reserved $word, "$word should be reserved";
    is Pg::Priv::_quote_ident $word, qq{"$word"}, "$word should be quoted";
}

for my $spec (
    [ users   => 'users'   ],
    [ _user   => '_user'   ],
    [ us_er   => 'us_er'   ],
    [ user_   => 'user_'   ],
    [ us3r    => 'us3r'    ],
    [ '1user' => '"1user"' ],
    [ Bob     => '"Bob"'   ],
    [ '-fred' => '"-fred"' ],
    [ '?fred' => '"?fred"' ],
    [ User    => '"User"'  ],
    [ a       => 'a'       ],
    [ _       => '_'       ],
) {
    is Pg::Priv::_quote_ident $spec->[0], $spec->[1],
        "$spec->[0] should be quoted as $spec->[1]";
}
