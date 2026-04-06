#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Object::Proto;

# ==== Setup Test Classes ====

Object::Proto::define('Person',
    'name:Str:required',
    'age:Int:default(0)',
    'email:Str:readonly',
    'bio:Str:lazy:builder(_build_bio)',
    'tags:ArrayRef:default([])',
);

package Person;
sub _build_bio { "Default bio for " . shift->name }
package main;

Object::Proto::define('Simple', 'foo', 'bar', 'baz');

# ==== Object::Proto::clone() Tests ====

# clone() basic functionality
{
    my $p = new Person name => 'Alice', age => 30, email => 'alice@example.com';
    my $clone = Object::Proto::clone($p);

    isa_ok($clone, 'Person', 'Clone is same class');
    isnt($clone, $p, 'Clone is different reference');
    is($clone->name, 'Alice', 'Clone has same name');
    is($clone->age, 30, 'Clone has same age');
    is($clone->email, 'alice@example.com', 'Clone has same email');
}
# clone() shallow copy semantics
{
    my $p = new Person name => 'Carol', age => 35, email => 'carol@example.com';
    push @{$p->tags}, 'original';

    my $clone = Object::Proto::clone($p);

    # Both should see the same array reference
    is_deeply($p->tags, ['original'], 'Original has tag');
    is_deeply($clone->tags, ['original'], 'Clone shares same array');

    # Modify original's array
    push @{$p->tags}, 'added';

    # Deep clone: clone has its own copy, does not see the change
    is_deeply($clone->tags, ['original'],
        'Deep copy does not share references');
}
# clone() does not copy frozen state
{
    my $p = new Person name => 'Dave', age => 40, email => 'dave@example.com';
    Object::Proto::freeze($p);
    ok(Object::Proto::is_frozen($p), 'Original is frozen');

    my $clone = Object::Proto::clone($p);
    ok(!Object::Proto::is_frozen($clone), 'Clone is not frozen');

    # Clone should be mutable
    $clone->age(41);
    is($clone->age, 41, 'Clone can be modified');
}
# clone() does not copy locked state
{
    my $p = new Person name => 'Eve', age => 28, email => 'eve@example.com';
    Object::Proto::lock($p);
    ok(Object::Proto::is_locked($p), 'Original is locked');

    my $clone = Object::Proto::clone($p);
    ok(!Object::Proto::is_locked($clone), 'Clone is not locked');
}
# clone() with undef slots
{
    my $s = new Simple foo => 'x';
    # bar and baz are undef
    my $clone = Object::Proto::clone($s);

    is($clone->foo, 'x', 'Clone has foo value');
    ok(!defined $clone->bar, 'Clone bar is undef');
    ok(!defined $clone->baz, 'Clone baz is undef');
}
# clone() accepts non-objects: scalars return as-is, refs are deep copied
{
    my $s = Object::Proto::clone("not an object");
    is($s, "not an object", 'clone returns plain string as-is');

    my $aref = Object::Proto::clone([1,2,3]);
    is_deeply($aref, [1,2,3], 'clone deep copies plain arrayref');
    isnt($aref, [1,2,3], 'clone plain arrayref is a distinct reference');
}
# ==== Object::Proto::properties() Tests ====

# properties() list context
{
    my @props = Object::Proto::properties('Person');
    is(scalar @props, 5, 'Person has 5 properties');
    ok((grep { $_ eq 'name' } @props), 'name in list');
    ok((grep { $_ eq 'age' } @props), 'age in list');
    ok((grep { $_ eq 'email' } @props), 'email in list');
    ok((grep { $_ eq 'bio' } @props), 'bio in list');
    ok((grep { $_ eq 'tags' } @props), 'tags in list');
}
# properties() scalar context
{
    my $count = Object::Proto::properties('Person');
    is($count, 5, 'Person has 5 properties (scalar)');
}
# properties() simple class
{
    my @props = Object::Proto::properties('Simple');
    is(scalar @props, 3, 'Simple has 3 properties');
    is_deeply([sort @props], ['bar', 'baz', 'foo'], 'Simple properties correct');
}
# properties() non-existent class
{
    my @props = Object::Proto::properties('NonExistent');
    is(scalar @props, 0, 'Empty list for non-existent class');

    my $count = Object::Proto::properties('NonExistent');
    is($count, 0, 'Zero count for non-existent class');
}
# ==== Object::Proto::slot_info() Tests ====

# slot_info() required typed property
{
    my $info = Object::Proto::slot_info('Person', 'name');
    is(ref $info, 'HASH', 'Returns hashref');
    is($info->{name}, 'name', 'name field correct');
    is($info->{index}, 1, 'index field correct (first property is slot 1)');
    is($info->{type}, 'Str', 'type field correct');
    is($info->{is_required}, 1, 'is_required is true');
    is($info->{is_readonly}, 0, 'is_readonly is false');
    is($info->{is_lazy}, 0, 'is_lazy is false');
}
# slot_info() property with default
{
    my $info = Object::Proto::slot_info('Person', 'age');
    is($info->{has_default}, 1, 'age has_default is true');
    is($info->{default}, 0, 'age default is 0');
    is($info->{type}, 'Int', 'age type is Int');
    is($info->{is_required}, 0, 'age is not required');
}
# slot_info() readonly property
{
    my $info = Object::Proto::slot_info('Person', 'email');
    is($info->{is_readonly}, 1, 'email is_readonly is true');
    is($info->{is_required}, 0, 'email is not required');
    is($info->{type}, 'Str', 'email type is Str');
}
# slot_info() lazy builder property
{
    my $info = Object::Proto::slot_info('Person', 'bio');
    is($info->{is_lazy}, 1, 'bio is_lazy is true');
    is($info->{has_builder}, 1, 'bio has_builder is true');
    is($info->{builder}, '_build_bio', 'builder name correct');
    is($info->{type}, 'Str', 'bio type is Str');
}
# slot_info() array default property
{
    my $info = Object::Proto::slot_info('Person', 'tags');
    is($info->{has_default}, 1, 'tags has_default is true');
    is($info->{type}, 'ArrayRef', 'tags type is ArrayRef');
    is(ref $info->{default}, 'ARRAY', 'tags default is arrayref');
}
# slot_info() simple untyped property
{
    my $info = Object::Proto::slot_info('Simple', 'foo');
    is($info->{name}, 'foo', 'name is foo');
    is($info->{is_required}, 0, 'not required');
    is($info->{is_readonly}, 0, 'not readonly');
    is($info->{has_type}, 0, 'no type');
    ok(!exists $info->{type}, 'type key not present for untyped');
}
# slot_info() non-existent property
{
    my $info = Object::Proto::slot_info('Person', 'nonexistent');
    ok(!defined $info, 'Returns undef for missing property');
}
# slot_info() non-existent class
{
    my $info = Object::Proto::slot_info('NonExistent', 'prop');
    ok(!defined $info, 'Returns undef for missing class');
}
# slot_info() all boolean flags present
{
    my $info = Object::Proto::slot_info('Simple', 'bar');

    # All boolean flags should be present
    for my $key (qw(is_required is_readonly is_lazy has_default
                    has_trigger has_coerce has_builder has_clearer
                    has_predicate has_type)) {
        ok(exists $info->{$key}, "$key exists in info");
        is($info->{$key}, 0, "$key is 0 for simple untyped slot");
    }
}
done_testing;
