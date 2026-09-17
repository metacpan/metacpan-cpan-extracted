#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Punk::App;
use Punk::Model;

# The model tier without a database: the six-method contract over an
# in-memory backend, the app-level registry, and create/update validation
# compiled from the field specs.

# ---- a tiny in-memory backend honouring the contract ------------------------
{
    package T::Backend::Memory;
    sub new {
        my ($class, %a) = @_;
        bless { table => $a{table}, primary => $a{primary} || 'id',
                col => { map { $_ => 1 } @{ $a{columns} || [] } },
                dsn => $a{database}{dsn},   # which database it was handed
                rows => {}, seq => 0 }, $class;
    }
    sub get { my ($s, %k) = @_; my $r = $s->{rows}{ $k{ $s->{primary} } }; $r ? { %$r } : undef }
    sub search {
        my ($s, $filter, $opts) = @_;
        $filter ||= {}; $opts ||= {};
        my $limit = $opts->{limit} || 20;
        my @rows = map { $s->{rows}{$_} }
                   sort { $a <=> $b } keys %{ $s->{rows} };
        @rows = grep {
            my $r = $_; !grep { ($r->{$_} // '') ne $filter->{$_} } keys %$filter
        } @rows;
        @rows = grep { $_->{ $s->{primary} } > $opts->{after} } @rows
            if defined $opts->{after};
        my $more = @rows > $limit ? 1 : 0;
        @rows = @rows[0 .. $limit - 1] if $more;
        return { rows => [ map { +{ %$_ } } @rows ],
                 has_more_data => $more,
                 next => $more ? $rows[-1]{ $s->{primary} } : undef };
    }
    sub all { $_[0]->search({}, {}) }
    sub create {
        my ($s, $data) = @_;
        my $id = ++$s->{seq};
        my $row = { %$data, $s->{primary} => $id };
        $s->{rows}{$id} = $row;
        return { %$row };
    }
    sub update {
        my ($s, $data) = @_;
        my $id = $data->{ $s->{primary} };
        my $row = $s->{rows}{$id} or return undef;
        %$row = (%$row, %$data);
        return { %$row };
    }
    sub delete { my ($s, %k) = @_; delete $s->{rows}{ $k{ $s->{primary} } } ? 1 : 0 }
}

# ---- a model class ----------------------------------------------------------
{
    package T::Model::Widget;
    use Punk::Model;
    table 'widgets';
    field id   => { type => 'integer', primary => 1 };
    field name => { type => 'string', required => 1, minLength => 1 };
    field tag  => { type => 'string' };
}

my $m = T::Model::Widget->_instantiate({ backend => 'T::Backend::Memory' });
isa_ok($m, 'Punk::Model', 'instance');
isa_ok($m, 'T::Model::Widget', 'blessed into the model class');
isa_ok($m->backend, 'T::Backend::Memory', 'the chosen backend');
is($m->meta->{table}, 'widgets', 'meta carries the table');
is($m->meta->{primary}, 'id', 'primary key resolved');

# ---- the contract -----------------------------------------------------------
my $a = $m->create({ name => 'alpha', tag => 'x' });
is($a->{id}, 1, 'create returns the stored row with its key');
is($a->{name}, 'alpha', 'and the data');
$m->create({ name => 'beta' });
$m->create({ name => 'gamma' });

is($m->get(id => 1)->{name}, 'alpha', 'get by key');
is($m->get(id => 99), undef, 'get miss is undef');

my $page = $m->all;
is(scalar @{ $page->{rows} }, 3, 'all returns every row');
ok(exists $page->{has_more_data}, 'with the pagination shape');

my $filtered = $m->search({ name => 'beta' }, {});
is(scalar @{ $filtered->{rows} }, 1, 'search filters by equality');
is($filtered->{rows}[0]{id}, 2, 'the right row');

my $u = $m->update({ id => 1, tag => 'y' });
is($u->{tag}, 'y', 'update returns the changed row');
is($m->get(id => 1)->{tag}, 'y', 'and it persisted');

is($m->delete(id => 3), 1, 'delete returns a count');
is($m->get(id => 3), undef, 'and the row is gone');

# ---- pagination shape through the contract ----------------------------------
{
    my $p1 = $m->search({}, { limit => 1 });
    is(scalar @{ $p1->{rows} }, 1, 'limit honoured');
    is($p1->{has_more_data}, 1, 'has_more_data set when a page follows');
    ok(defined $p1->{next}, 'a continuation token is offered');
    my $p2 = $m->search({}, { limit => 1, after => $p1->{next} });
    isnt($p2->{rows}[0]{id}, $p1->{rows}[0]{id}, 'after continues past page 1');
}

# ---- validation compiled from the field specs -------------------------------
{
    # These assert the LOCATION as well as the failure, and that is the
    # point of them. Matching only qr/validation failed/ passed for years
    # against a message that had lost every useful part of itself:
    # pm_validate mortalised the error copy inside the scope it then freed,
    # so the field was never named and nobody noticed.
    ok($m->meta->{should_validate}, 'constraints turn validation on');
    eval { $m->create({ tag => 'no name' }) };
    like($@, qr/validation failed/, 'create croaks on a missing required field');
    unlike($@, qr/does not match the field schema/,
        'and the error is the validator\'s own, not the fallback');
    eval { $m->create({ name => '' }) };
    like($@, qr{validation failed at /name}, 'a minLength violation names the field');
    my $ok = eval { $m->create({ name => 'delta' }); 1 };
    ok($ok, 'a valid create passes');

    # update validates only the changes - a missing required name is fine
    my $up = eval { $m->update({ id => 1, tag => 'z' }); 1 };
    ok($up, 'update does not require the whole row');
    eval { $m->update({ id => 1, name => '' }) };
    like($@, qr{validation failed at /name}, 'and an update names it too');
}

# ---- a model with no constraints does not validate --------------------------
{
    package T::Model::Loose;
    use Punk::Model;
    table 'loose';
    field id  => { type => 'integer', primary => 1 };
    field any => { type => 'string' };
}
{
    my $loose = T::Model::Loose->_instantiate({ backend => 'T::Backend::Memory' });
    ok(!$loose->meta->{should_validate}, 'no constraints, no validation');
}

# ---- the app-level registry -------------------------------------------------
{
    my $app = Punk::App->new(caller => 'T');
    $app->database(backend => 'T::Backend::Memory');
    $app->model_class('Widget');
    $app->_compile_models;

    my $inst = $app->model_instance('Widget');
    isa_ok($inst, 'T::Model::Widget', 'registry resolves Name -> Caller::Model::Name');
    is($app->model_instance('Widget'), $inst, 'cached per worker');

    eval { $app->model_instance('Nope') };
    like($@, qr/no model 'Nope' registered/, 'unknown model croaks');
}

# ---- an unregistered app croaks helpfully -----------------------------------
{
    my $bare = Punk::App->new(caller => 'T');
    eval { $bare->model_instance('Widget') };
    like($@, qr/no model registered/, 'no models at all croaks with guidance');
}

# ---- several databases, each model on its own -------------------------------
{
    # a model that lives in a named, non-default database
    package T::Model::Report;
    use Punk::Model;
    table 'reports';
    database 'analytics';
    field id => { type => 'integer', primary => 1 };
}
{
    my $app = Punk::App->new(caller => 'T');
    $app->database(dsn => 'PRIMARY', backend => 'T::Backend::Memory');
    $app->database(analytics => { dsn => 'ANALYTICS',
                                  backend => 'T::Backend::Memory' });
    $app->model_class('Widget', 'Report');
    $app->_compile_models;

    is($app->model_instance('Widget')->backend->{dsn}, 'PRIMARY',
        'a model with no database keyword uses the default');
    is($app->model_instance('Report')->backend->{dsn}, 'ANALYTICS',
        'a model selects its named database');
}

# ---- a model pointing at an unconfigured database croaks --------------------
{
    my $app = Punk::App->new(caller => 'T');
    $app->database(dsn => 'PRIMARY', backend => 'T::Backend::Memory');
    $app->model_class('Report');           # wants 'analytics', not configured
    $app->_compile_models;
    eval { $app->model_instance('Report') };
    like($@, qr/selects database 'analytics'/,
        'selecting an unconfigured database croaks at first use');
}

# ---- auto-discovery from the symbol table ------------------------------------
{
    {
        package T::Model::Gadget;
        use Punk::Model;
        table 'gadgets';
        field id => { type => 'integer' };
        package T::Model::Bystander;    # in the namespace, not a model
        sub assist { 1 }
    }
    my $app = Punk::App->new(caller => 'T');
    $app->database(backend => 'T::Backend::Memory');
    $app->_compile_models;
    isa_ok($app->model_instance('Gadget'), 'T::Model::Gadget',
        'an in-memory ${caller}::Model:: class is discovered by default');
    isa_ok($app->model_instance('Widget'), 'T::Model::Widget',
        'and so are its siblings');
    eval { $app->model_instance('Bystander') };
    like($@, qr/no model 'Bystander'/,
        'a non-model package in the namespace is skipped, not fatal');
}

# ---- bare model; forces discovery on next to named registrations -------------
{
    my $app = Punk::App->new(caller => 'T');
    $app->database(backend => 'T::Backend::Memory');
    $app->model_class('Widget');    # naming one would switch discovery off
    $app->model_class();            # the bare form switches it back on
    is($app->model_auto, 1, 'bare model; sets the auto flag');
    $app->_compile_models;
    isa_ok($app->model_instance('Gadget'), 'T::Model::Gadget',
        'bare model; discovers the rest even alongside a named model');
}

# ---- a model class may be subclassed ---------------------------------------
#
# `table` and `field` are statements in the package body, so they run when the
# class loads - long after `use Punk::Model` decided what the class knew. The
# metadata is therefore merged at lookup, not seeded at import: a subclass
# seeded at import time would copy a parent that was still empty.

{
    package TBase;
    use Punk::Model;
    table 'widgets';
    field id   => { type => 'integer', primary => 1 };
    field name => { type => 'string' };

    package TPlain;                     # inherits everything, declares nothing
    our @ISA = ('TBase');

    package TAdds;                      # adds a field
    our @ISA = ('TBase');
    use Punk::Model;
    field colour => { type => 'string' };

    package TTable;                     # same fields, its own table
    our @ISA = ('TBase');
    use Punk::Model;
    table 'other_widgets';

    package TRetype;                    # redeclares one field's spec
    our @ISA = ('TBase');
    use Punk::Model;
    field name => { type => 'integer' };

    package TDeep;                      # two levels
    our @ISA = ('TAdds');
    use Punk::Model;
    field extra => { type => 'string' };
}

sub meta_of { Punk::Model::_punk_model_meta($_[0]) }

{
    my $m = meta_of('TPlain');
    ok($m, 'a subclass that declares nothing still has metadata');
    is($m->{table}, 'widgets', '  the parent table');
    is_deeply($m->{fields}, [qw(id name)], '  and the parent fields');
}

{
    my $m = meta_of('TAdds');
    is($m->{table}, 'widgets', 'a subclass that adds a field keeps the table');
    is_deeply($m->{fields}, [qw(id name colour)],
        '  and its field comes after the inherited ones');
}

{
    my $m = meta_of('TTable');
    is($m->{table}, 'other_widgets', 'a subclass may name its own table');
    is_deeply($m->{fields}, [qw(id name)], '  and still inherit the fields');
}

{
    my $m = meta_of('TRetype');
    is($m->{field}{name}{type}, 'integer', 'a redeclared field wins');
    is_deeply($m->{fields}, [qw(id name)],
        '  and keeps the position the parent gave it, so the column order '
      . 'does not shift');
}

{
    my $m = meta_of('TDeep');
    is_deeply($m->{fields}, [qw(id name colour extra)],
        'inheritance is transitive');
}

{
    my $m = meta_of('TBase');
    is_deeply($m->{fields}, [qw(id name)],
        'and none of it disturbed the parent');
    is($m->{field}{name}{type}, 'string', '  including a field a child retyped');
}

done_testing();

