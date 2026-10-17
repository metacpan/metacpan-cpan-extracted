## Name

Test::Consumer::Contract - check a reader against the keys its producer promises

## Synopsis

A distribution declares what its value object promises, who produces it, who
reads it, and why each exception is safe:

```perl
use Test::Consumer::Contract qw(run_consumer_contract);

run_consumer_contract(
    source        => 'Widget::Maker',
    value_object  => {
        class   => 'Widget',
        from    => { latitude => 1, longitude => 2 },
        derives => { x => 1, y => 2 },
    },
    guaranteed  => [qw(x y)],
    conditional => { colour => 'only the painted path sets it' },
    producers   => { 'lib/Widget/Maker.pm' => [qw(x y colour)] },
    consumers   => {
        'Widget-User/lib/Widget/User.pm' => {
            may_rely_on => {
                render => { colour => 'defaults to undef on purpose' },
            },
        },
    },
    ignored     => [['Widget-List/', 'reads its own normalised output']],
    accessors   => [qw(x y)],   # documented accessors a consumer may read
    not_accessors => {          # documented, but not a slot of one result
        new             => 'the constructor',
        ACCURACY_LEVELS => 'a class constant',
    },
    inspection  => [qw(can isa DOES)],
);

done_testing();
```

Then it runs these checks:

- 1. the producers still set the keys the contract claims

    Each file named in `producers` (and `workspace_producers`) is read and each key
    it is responsible for must still be assigned there, so a producer that quietly
    stops stamping a key fails.

- 2. registered consumers read only what every producer sets

    Each file named in `consumers` is scanned for reads of a result.  A read of a
    key in `guaranteed` is fine; a read of anything else is reported with its file,
    line, sub and the reason the key is a problem, unless the read is registered
    under `may_rely_on` keyed by the name of the enclosing sub.  An entry that is no
    longer read is reported as stale, so the registry keeps describing the code.

- 3. every discovered consumer is registered

    Files in sibling distributions that receive a result but are named in neither
    `consumers` nor `ignored` fail the check, so a new consumer cannot slip past
    check 2 unnoticed.

- 4. the accessor lists match the value object, in both directions

    The value object's documented accessors are the `=head2` (and deeper) headings
    of its source and the public subs it defines.  Each one the declaration names in
    `accessors` or `not_accessors` must be an accessor the value object really has,
    and - the direction that matters when a value object grows - each one the value
    object documents must be accounted for in `accessors`, `not_accessors` or
    `conditional`.  `conditional` is where a documented accessor belongs when only
    some results carry it.  So a value object that gains a documented accessor
    cannot leave the declaration behind: the check fails, naming the accessor and the
    three places to put it.

Checks 2 and 3 need the sibling distributions that share a workspace; on a
CPAN-style install they skip with a diagnostic and only check 1 runs.  Check 4
needs the value object's own file, which `include` puts in reach.  This is a
static, lexical check: it reads source, it does not run the producer.

## Requirements

The caller must load a test module ([Test::Most](https://metacpan.org/pod/Test%3A%3AMost) is what this module uses) and
call `done_testing()` after `run_consumer_contract()`; this module adds
subtests but does not end the plan.

### **New**

Takes the declaration above as a list.  `source` and `guaranteed` are
required; every other option has a default:

- `dist_root`

    The distribution being checked.  Defaults to the parent of the directory
    holding the running test file, falling back to the current directory when that
    is not a distribution root.

- `workspace`

    The directory holding the sibling distributions.  Defaults to the parent of
    `dist_root`.

    Every path in a declaration - in `include`, `producers`,
    `workspace_producers`, `consumers` and `ignored` - is written with `/`
    between the directories, whatever separator the platform itself uses, and the
    paths in `consumers` and `ignored` are relative to the workspace.  The checks
    name files the same way, so a path can be copied from a failure message into the
    declaration unchanged.

- `include`

    Workspace-relative lib directories to put at the front of `@INC`, so a value
    object is read from the checkout in the workspace rather than from an installed
    copy.

- `conditional`

    Key => why it is not guaranteed, used in the failure messages.

- `workspace_producers`

    Like `producers`, but paths are relative to the workspace: producers in a
    sibling distribution that this distribution's value object comes from.

- `not_accessors`

    Documented accessors of the value object that are not a slot of one result - the
    constructor, a class constant - as name => why, so that the accessor check can be
    satisfied by saying what a name is instead of listing it as something a consumer
    may read.  A name here that the value object does not document fails, as an entry
    in `accessors` would.

- `methods`

    The calls that hand a result to the caller; `geocode` and `reverse_geocode` by
    default.  A variable bound from one of these is followed, as is a variable passed
    to a sub as its first parameter.

- `require_workspace`

    Sibling distribution names that must exist for checks 2 and 3 to run.  Pass the
    ones your consumers live in, or those checks cannot tell a missing checkout from
    a passing one.

Unknown options are an error rather than being silently ignored.

### **Run**

Runs the three checks as subtests.  Called for you by
`run_consumer_contract()`.

### **Run\_Consumer\_Contract**

```perl
my $contract = run_consumer_contract(%declaration);
```

Builds the contract and runs it, returning the object.

### **Workspace\_Present**

True when every distribution named in `require_workspace` is in the workspace.

### **Sets\_Key**

```
$contract->sets_key($source_text, 'database')
```

True when the text assigns the key, in any of the spellings a producer might
use: `key => value`, `'key' => value`, `$obj->{'key'} = value`.

### **Strip**

Returns the source with POD and comments replaced by blank space, preserving
line numbers.

### **Reads\_of\_Results**

```perl
my @reads = $contract->reads_of_results($stripped_text);
```

Every `->{key}` and `->method()` read of a variable that holds a
result, as `[key, line, kind, sub]`.  A variable holds one if it is bound from a
`geocode()` or `reverse_geocode()` call, or if it is the first parameter of a
sub that this file calls with such a variable - so a helper that takes the result
still counts, whatever it names it.  One level of that is followed, which is
enough for an adapter; a deeper chain is a sign the read belongs in the
consumer's registry entry.

### **Documented\_Accessors**

```perl
my @names = $contract->documented_accessors($source);
```

Every name the value object's source documents as part of its interface: its
`=head2` (and deeper) headings and the public subs it defines.  `=head1`
headings are left out - they are NAME, VERSION, SEE ALSO and the rest of the
boilerplate, which document no accessor - and so are the private subs, whose
leading underscore keeps them out of the interface.  A method the value object
documents but implements through `AUTOLOAD` is found by its heading, which is
what makes this the list of what is documented rather than of what is compiled.

## Limitations

- The scanner is static and lexical.  It follows reads on variables bound
from a producing call plus one level of call into a helper; a result that is
stored in a hash, returned, or passed through two helpers is not followed.
- Discovery requires the file to name the source distribution.  A consumer
that is handed results without naming the distribution is not picked up; add it
to `consumers` by hand.
- Files in the `dist_root` distribution are not scanned for consumption -
its own sources are treated as the producer.  A consumer that lives in the
producing distribution is not discovered.
- The producer evidence is static: a producer that sets a key by a route
the three recognised spellings do not cover is reported as not setting it.
- `require_workspace` is what tells a missing checkout apart from a
passing one.  With nothing to require, a distribution checked on its own has no
sibling consumers to find and the discovery check will fail on finding none.
- The accessor check reads the value object's own file, so an accessor it
inherits, or documents in another file, is not seen.  A heading or sub that names
something which is not an accessor of a result - a constructor, a constant - has
to be listed in `not_accessors`, which is what that option is for; the check
then holds the entry to the value object, so a renamed or removed name fails
rather than sitting in the list unread.

## Author

Nigel Horne, `<njh at nigelhorne.com>`

## License and Copyright

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
