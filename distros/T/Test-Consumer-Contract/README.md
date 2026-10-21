## Name

Test::Consumer::Contract - check that code reading a result only reads the fields that are always there

## Version

Version 0.04

## Synopsis

### 1. The Usual Case: Results Are Hashes, Readers Live in Other Distributions

A geocoder hands back a hash.  `x` and `y` are always in it; `colour` is
only sometimes there.  This test fails if any reader in the workspace reads
`colour` without saying why that is safe.

```perl
use Test::Most;
use Test::Consumer::Contract qw(run_consumer_contract);

run_consumer_contract(
    source      => 'Widget::Maker',       # readers mention this name
    methods     => [qw(geocode)],         # the call that returns a result
    guaranteed  => [qw(x y)],             # always set
    conditional => { colour => 'only the painted path sets it' },
    producers   => { 'lib/Widget/Maker.pm' => [qw(x y colour)] },
    consumers   => { 'Widget-User/lib/Widget/User.pm' => {} },
    require_workspace => ['Widget-User'],
);

done_testing();
```

### 2. Allowing One Reader to Read an Optional Field

The reader in `render()` reads `colour` on purpose, and handles it being
missing.  Say so, with the reason, under the name of the sub that reads it:

```perl
consumers => {
    'Widget-User/lib/Widget/User.pm' => {
        may_rely_on => {
            render => { colour => 'defaults to undef on purpose' },
        },
    },
},
```

### 3. Results That Are Objects With Accessor Methods

When a result is an object, readers call methods (`$entry->memo`) instead
of reading hash keys.  Name the methods a reader may call, and let the checker
compare that list with what the class documents:

```perl
run_consumer_contract(
    source        => 'Ledger::Entry',
    methods       => ['Ledger::Entry->new', 'entry'],  # 'Class->new': only this class
    list_methods  => ['results'],                      # returns a list of results
    value_object  => {
        class   => 'Ledger::Entry',
        from    => { amount => 7 },       # build one like this...
        derives => { cents => 700 },      # ...and expect these values
    },
    guaranteed    => [qw(amount memo cents)],
    accessors     => [qw(amount memo cents)],
    not_accessors => { new => 'the constructor' },
    inspection    => [qw(can isa DOES)],
    conditional   => { note => 'only some entries carry a note' },
    include       => ['Ledger-Store/lib'],
    own_consumers => 1,                   # this distribution reads them too
    consumers     => { 'Ledger-UI/lib/Ledger/UI.pm' => {} },
    require_workspace => ['Ledger-UI'],
);
```

### 4. A Call That Returns Many Results at Once

`geocode_many()` returns one hash: the results under their names, plus counts.
The counts are not fields of a result, so name the call in `batch_methods`:

```perl
methods       => [qw(geocode geocode_many)],
batch_methods => ['geocode_many'],
```

### 5. Using the Scanner Yourself

The object's methods can be used outside a test, for example to see what the
checker finds in one file:

```perl
my $contract = Test::Consumer::Contract->new(
    source => 'Widget::Maker', methods => ['geocode'], guaranteed => [],
);
my $code = $contract->strip($source_text);       # drop POD and comments
foreach my $read (@{ $contract->reads_of_results($code) }) {
    my ($key, $line, $kind, $sub) = @{$read};
    print "line $line, in $sub: reads $key ($kind)\n";
}
```

### 6. Changing the Wording of the Messages

```perl
# For every contract built after this line:
$Test::Consumer::Contract::config{'messages'}{'skip.siblings'}
    = 'Geschwister fehlen: {missing}';

# For one contract only:
run_consumer_contract(%declaration, messages => {
    'check.producers' => 'les producteurs posent toujours les cles promises',
});
```

## Description

### The Problem

One piece of code (the _producer_) makes a _result_: a hash or an object
with named fields.  Other code (the _consumers_, or readers) reads those
fields.  Some fields are always set.  Others are set only on some paths - for
example, only when a lookup found a postcode.

A reader that reads an only-sometimes field works in testing and then fails
for the one input where the field is missing.  This module finds those reads
before that happens, by reading the source code of every reader.

### Words Used in This Document

```
producer      code that makes a result (for example geocode())
result        the hash or object the producer hands back
value object  the class of a result, when the result is an object
key, field    one named value in a result: $r->{'x'} or $r->x
guaranteed    a key every result has
conditional   a key only some results have
consumer      a file that reads keys of a result
distribution  one project folder, such as Widget-Maker/
workspace     the folder that holds several distributions side by side
declaration   the options you pass to new() or run_consumer_contract()
```

A typical workspace:

```
workspace/
    Widget-Maker/       the producer and the value object
    Widget-User/        a consumer
    Widget-Contract/    holds t/contract.t, which declares the contract
                        (this is dist_root; it may also be Widget-Maker)
```

### The Five Checks

`run()` runs these checks.  Each one is a subtest in the TAP output.

- 1. the producers still set the keys the contract claims

    Each file in `producers` and `workspace_producers` must still contain an
    assignment to each key listed for it.  POD and comments do not count: a key
    shown in an example is not a key being set.  A workspace producer whose sibling
    distribution is not checked out is skipped, not failed; one whose sibling is
    there but whose file is not still fails.

- 2. the value object still derives what it promises

    Only when `value_object` has `derives`.  An object is built from `from`, and
    each method named in `derives` must return the value given.  If the class
    cannot be found, this check is skipped.  If the class is found but does not
    compile, or its constructor dies, the check fails.

- 3. registered consumers read only what every producer sets

    Each file in `consumers` is read.  Every read of a result is listed with its
    line and the sub it is in.  Reading a guaranteed key is fine.  Reading any
    other key fails, unless the consumer lists that key in `may_rely_on` under
    the name of the sub that reads it.  An entry in `may_rely_on` that the code
    no longer reads also fails, so the list stays true.

- 4. the accessor lists match the value object

    Only when `value_object` is given and `accessors` or `not_accessors` is
    not empty.  Every name you list must exist in the class.  And every name the
    class documents (its `=head2` headings and public subs) must appear in
    `accessors`, `not_accessors` or `conditional`.  So when the class gains a
    new field, this check fails until the contract says what the field is.

- 5. every discovered consumer is registered

    Every `.pm`, `.t`, `.pl` file and every program (a file with no extension
    that starts with `#!`) in the other distributions of the workspace is read.
    A file that mentions `source` and reads a result must be listed in
    `consumers` or `ignored`.  So a new reader cannot be added without being
    checked.

Checks 3 and 5 need the other distributions.  If one named in
`require_workspace` is missing (for example when the module is installed from
CPAN), those checks are skipped with a message.

The checker only reads source code.  It never runs the producer or the
consumers.  See ["LIMITATIONS"](#limitations) for what it cannot see.

## Requirements

Load a test module ([Test::Most](https://metacpan.org/pod/Test%3A%3AMost) or [Test::More](https://metacpan.org/pod/Test%3A%3AMore)) before calling, and call
`done_testing()` after.  This module adds subtests; it does not start or end
the test plan.

Perl 5.14 or later.

## Configuration

`%Test::Consumer::Contract::config` holds settings shared by all contracts.
It has the shape [Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure) produces.  Each contract copies it when
`new()` is called, so a change made later does not affect a contract that
already exists.

```perl
Key                Meaning                                      Default
-----------------  -------------------------------------------  ---------------------
sibling_dirs       folders read in another distribution         lib bin t
own_dirs           folders read in dist_root (own_consumers)    lib bin scripts
source_extensions  file extensions that hold Perl code          pm t pl PL pm6
skipped_dirs       folder names never entered                   blib xt inc local
                                                                node_modules .git
                                                                .build
messages           message key => text, replacing the built-in  (empty)
```

`new()` does not call ["configure" in Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure#configure) itself, because that
would let an environment variable change a contract that should be written in
code.

## Common Pitfalls

- **undef means "use the default".**

    Giving an optional option the value `undef` is the same as not giving it.
    For a required option (`source`, `guaranteed`, `methods`), `undef` is an
    error.  Inside lists and hashes, `undef` is not cleaned up: an `undef` in
    `guaranteed` is a key that no read can match.

- **Nothing is merged deeply.**

    An option you give replaces the default completely; it is not merged with it.
    A message you give in `messages` replaces the whole built-in message.  If the
    built-in message has several forms (`one`, `other`), your replacement must
    give every form you need, or it is used for all counts.

- **The contract keeps your lists, it does not copy them.**

    The arrays and hashes you pass are used as they are.  If you change them after
    `new()`, the contract changes too.  Build the declaration first, then call
    `new()`.

- **`%config` is copied only one level deep.**

    A new contract gets its own copy of each list and of the `messages` hash.
    But a message that is itself a hash of forms is shared.  Replace such an entry;
    do not change it in place.

- **Paths always use `/`.**

    Write `'Widget-User/lib/Widget/User.pm'`, also on Windows.  Consumer and
    ignored paths are relative to the workspace.  Producer paths are relative to
    `dist_root`, unless they are given in `workspace_producers`.

- **An `ignored` rule is a plain prefix.**

    `'Widget-List'` also ignores `Widget-Listing/`.  End the prefix with `/`
    to ignore exactly one folder.

- **A bare `new` in `methods` matches every constructor.**

    `methods => ['new']` makes `Any::Class->new(...)` a result.  Write
    `'Widget->new'` so that only that class counts.

- **Reads outside any sub belong to `(file scope)`.**

    A program's main code is not in a sub.  To allow a read there, use the name
    `'(file scope)'` in `may_rely_on`.

- **With an empty `require_workspace`, check 5 may fail.**

    If no other distribution is present, check 5 finds no consumer at all, and
    fails rather than pass on nothing.  Name the distributions your consumers are
    in.

- **Variable names count for the whole file.**

    If `$point` holds a result in one sub, every `$point` in the same file is
    treated as a result.  Use different names for different things.

- **List context or scalar context.**

    `reads_of_results()` and `documented_accessors()` return a list when called
    in list context and an array reference in scalar context.
    `my $n = $contract->reads_of_results($t)` is a reference, not a count.

- **`include` changes `@INC` for the whole program.**

    The last directory listed ends up first.  The change stays after the contract
    is gone.

- **Other tests may match the English text.**

    The test names and messages are part of the output.  If you change their
    wording with `messages`, anything that searches the output for the English
    text will stop matching.

## Encoding

- **Source files are read as bytes.**

    Files are not decoded.  Any bytes - UTF-8, Latin-1, emoji - may appear in
    strings, comments and POD of the files that are read; they do no harm.

- **Keys and method names must be ASCII to be found.**

    A read is found only when the key or method name is made of `A-Z`, `a-z`,
    `0-9` and `_`.  A read of `$r->{'grosse'}` is found; a read of a key
    with a non-ASCII letter in it is **not** found, so it can never fail check 3.
    The same is true of producer keys passed to `sets_key()` for check 1 when the
    text is bytes and the key is a character string.

- **`strip()`, `reads_of_results()` and `documented_accessors()`
accept bytes or characters.**

    If you pass them text you decoded yourself (for example with
    `:encoding(UTF-8)`), non-ASCII letters count as word characters, and
    non-ASCII keys are found.

- **`sets_key()` compares the key and the text exactly.**

    Give both as bytes, or both as decoded characters.  Mixing them can make a key
    that is in the text appear to be missing.

- **`source` is compared with the file's bytes.**

    Keep it ASCII (a Perl package name always is).

- **Paths should be ASCII.**

    Paths are passed to the operating system as they are.  On Unix a non-ASCII
    path works when it is given as UTF-8 bytes.  On Windows non-ASCII paths may not
    be found.

- **Messages may use any Unicode text, including emoji.**

    Message templates, reasons in `conditional`, `may_rely_on` and `ignored`,
    and the arguments to `i18n()` may be any character strings.  When they
    contain characters above 255, Test::Builder prints a `Wide character`
    warning unless its output handles have an encoding layer:

    ```perl
    binmode(Test::More->builder->$_, ':encoding(UTF-8)')
        for qw(output failure_output todo_output);
    ```

## Methods

### New

```perl
my $contract = Test::Consumer::Contract->new(%declaration);
```

#### Purpose

Builds a contract from a declaration, validating it before any check runs.

#### Arguments

A list of pairs, or one hashref.  `source`, `guaranteed` and `methods` are
required; every other option has a default.  An optional option given as
`undef` takes its default, as if it had not been given.

- `source` (string, required)

    The name that marks a file as one that may consume results: a file that does
    not contain it is not scanned during discovery.  Usually the producer's class.

- `guaranteed` (arrayref, required)

    The keys every producer sets on every result.  A read of one of these is
    always safe.

- `methods` (arrayref, required)

    The calls that hand a result to the caller, as your producer spells them:
    `[qw(geocode reverse_geocode)]` for a geocoder, `[qw(fetch find)]` for a
    store.  There is no default: the checker cannot guess what your producer calls
    its lookups, and a name it guessed would quietly find nothing.  A name may be
    written with its class, `'Widget->new'` or `'Widget::new'`, and then only
    that class's call matches.  A variable bound from one of these is followed, as
    is a variable passed to a sub that this file calls with it.

- `batch_methods` (arrayref)

    The producing methods that return a batch of results rather than one result;
    none by default.  A batch's keys are the results, plus counts about the batch
    itself, so a variable bound from a batch method is not treated as a result -
    `$batch->{'lookups'}` is not a read of one - while
    `my $point = $batch->{$value}` makes `$point` a result.

- `list_methods` (arrayref)

    The producing methods that hand back a list of results rather than one - a
    report's `results()`, the checks a runner ran; none by default.  The variable
    that takes a result out of the list is a result like any other: the loop
    variable of `for my $entry (@{ $report->results() })`, of a list assigned
    from that call first, and the topic of a `map` or `grep` block over it.

- `value_object` (hashref)

    `{ class => 'Widget', from => {...}, derives => {...} }`.  `class` is
    required when this is given and must be a module name.  `from` is what an
    object is built from for check 2, `derives` the accessor => value pairs it
    must then return.

- `conditional` (hashref)

    Key => why it is not guaranteed, used in the failure messages and accepted by
    check 4 as accounting for a documented accessor.

- `producers` (hashref)

    Path => arrayref of keys the file must still set.  Paths are relative to
    `dist_root`, or absolute.

- `workspace_producers` (hashref)

    Like `producers`, but paths are relative to the workspace: producers in a
    sibling distribution that this distribution's value object comes from.  The
    first component of the path names that sibling; when it is not in the
    workspace, the file's checks are skipped (`skip.producer`), so a declaration
    that names one still passes on a CPAN install.

- `consumers` (hashref)

    Workspace-relative (or, for `own_consumers`, `dist_root`-relative) path =>
    `{ may_rely_on => { sub_name => { key => why } } }`.  A read outside any
    named sub is registered under the sub name `(file scope)`.

- `ignored` (arrayref)

    `[prefix, reason]` pairs: a discovered file whose path starts with the prefix
    is not a consumer.  Each rule must be an arrayref whose first element is the
    prefix.

- `accessors` (arrayref)

    Documented accessors a consumer may call on a result.

- `not_accessors` (hashref)

    Documented accessors of the value object that are not a slot of one result -
    the constructor, a class constant - as name => why, so that the accessor check
    can be satisfied by saying what a name is instead of listing it as something a
    consumer may read.  A name here that the value object does not document fails,
    as an entry in `accessors` would.

- `inspection` (arrayref)

    Methods such as `can`, `isa` and `DOES` that may be called on a result
    without being a read of a field.

- `own_consumers` (boolean)

    True when the distribution being checked is one of its own value object's
    readers; false by default.  Its `lib`, `bin` and `scripts` are then scanned
    for consumers and discovered like a sibling's, but not its `t/` and `xt/`: its
    tests are the proof of the value object rather than readers of it.  Its paths
    are named relative to the distribution, the way a producer's are, so they still
    point at the right file when the distribution is installed under a versioned
    directory name.

- `dist_root` (string)

    The distribution being checked.  Defaults to the parent of the directory
    holding the running test file, falling back to the current directory when that
    is not a distribution root.  When given, it must be an existing directory.

- `workspace` (string)

    The directory holding the sibling distributions.  Defaults to the parent of
    `dist_root`.  When given, it must be an existing directory.

- `include` (arrayref)

    Workspace-relative lib directories to put at the front of `@INC`, so a value
    object is read from the checkout in the workspace rather than from an
    installed copy.

- `require_workspace` (arrayref)

    Sibling distribution names that must exist for checks 3 and 5 to run.  Pass the
    ones your consumers live in, or those checks cannot tell a missing checkout
    from a passing one.

- `messages` (hashref)

    Message key => template, overriding the catalogue for this object only.  See
    ["i18n"](#i18n).

Every path in a declaration is written with `/` between the directories,
whatever separator the platform itself uses, and the checks name files the
same way, so a path can be copied from a failure message into the declaration.

#### Returns

The new object.

#### Side Effects

Each existing `include` directory is moved to the front of `@INC` (through
[lib](https://metacpan.org/pod/lib), so it appears there once however many contracts name it); the last one
listed ends up first.  `@INC` is process-wide: the change outlives the
object.

#### Example

```perl
my $contract = Test::Consumer::Contract->new({
    source      => 'Warehouse::Stock',
    methods     => [qw(fetch scan)],
    guaranteed  => [qw(grams name)],
    conditional => { bin => 'only scan() knows the bin' },
});
```

#### Api Specification

##### Input

```perl
{
    source              => { type => 'string', min => 1 },
    guaranteed          => { type => 'arrayref' },
    methods             => { type => 'arrayref' },
    dist_root           => { type => 'string', optional => 1 },
    workspace           => { type => 'string', optional => 1 },
    include             => { type => 'arrayref', optional => 1 },
    value_object        => { type => 'hashref', optional => 1 },
    conditional         => { type => 'hashref', optional => 1 },
    producers           => { type => 'hashref', optional => 1 },
    workspace_producers => { type => 'hashref', optional => 1 },
    consumers           => { type => 'hashref', optional => 1 },
    ignored             => { type => 'arrayref', optional => 1 },
    accessors           => { type => 'arrayref', optional => 1 },
    not_accessors       => { type => 'hashref', optional => 1 },
    inspection          => { type => 'arrayref', optional => 1 },
    batch_methods       => { type => 'arrayref', optional => 1 },
    list_methods        => { type => 'arrayref', optional => 1 },
    own_consumers       => { type => 'boolean', optional => 1 },
    require_workspace   => { type => 'arrayref', optional => 1 },
    messages            => { type => 'hashref', optional => 1 },
}
```

##### Output

```perl
{ type => 'object', isa => 'Test::Consumer::Contract' }
```

#### Messages

```perl
Message                                         Meaning / Resolution
----------------------------------------------  ----------------------------------------
"...::new() does not know the option(s): X"     An option is misspelt or unknown.  Fix
                                                the name; nothing is silently ignored.
"...::new() needs a 'X'"                        A required option is missing or undef.
"...::new(): <validator message>"               An option has the wrong type, for
                                                example a string where an arrayref is
                                                expected.
"...::new(): each 'ignored' rule must be        An 'ignored' entry is not an arrayref
 [prefix, reason], not X"                       starting with a prefix.  Write
                                                ['Dist/', 'why'].
"...::new(): consumer 'X' must be {...}"        A consumers entry is not a hashref, or
                                                its may_rely_on is not sub => {key=>why}.
"...::new(): value_object needs a 'class'       value_object without a valid module name
 that is a module name, not 'X'"                in 'class'.
"...::new(): dist_root 'X' is not a             An explicit dist_root or workspace does
 directory: <OS error>"                         not exist; the OS error says why.
```

#### Pseudocode

```
normalise the arguments into one hash
croak on any option outside the schema
croak on any required option that is undef
validate the types; croak with the validator's reason on failure
croak on malformed ignored rules, consumer entries or value_object class
croak on an explicit dist_root or workspace that is not a directory
fill in defaults, take a copy of %config
put the include directories at the front of @INC
return the object
```

### Run

```
$contract->run();
```

#### Purpose

Runs the five checks described in ["DESCRIPTION"](#description), each as a subtest.  Called
for you by `run_consumer_contract()`.

#### Arguments

None.

#### Returns

The object, so calls can be chained.

#### Side Effects

Emits TAP through [Test::Builder](https://metacpan.org/pod/Test%3A%3ABuilder).  Loads the value object's class.

#### Example

```
Test::Consumer::Contract->new(%declaration)->run();
done_testing();
```

#### Api Specification

##### Input

```
{}
```

##### Output

```perl
{ type => 'object', isa => 'Test::Consumer::Contract' }
```

#### Messages

None of its own: each check's messages are listed in ["DIAGNOSTICS"](#diagnostics).

### Run\_Consumer\_Contract

```perl
my $contract = run_consumer_contract(%declaration);
```

#### Purpose

Builds the contract and runs it: `new(...)->run()` as one exportable call.

#### Arguments

The declaration, as for ["new"](#new).

#### Returns

The object.

#### Side Effects

Those of ["new"](#new) and ["run"](#run).

#### Example

```perl
use Test::Most;
use Test::Consumer::Contract qw(run_consumer_contract);

run_consumer_contract(source => 'S', methods => ['fetch'], guaranteed => ['id']);
done_testing();
```

#### Api Specification

##### Input

As for ["new"](#new).

##### Output

```perl
{ type => 'object', isa => 'Test::Consumer::Contract' }
```

#### Messages

Those of ["new"](#new).

### Workspace\_Present

```
if($contract->workspace_present()) { ... }
```

#### Purpose

Says whether every distribution named in `require_workspace` is in the
workspace, which is what checks 3 and 5 need to run.

#### Arguments

None.

#### Returns

1 when every one is there, otherwise 0.

#### Side Effects

Caches the answer in the object.

#### Example

```perl
plan skip_all => 'no siblings' unless $contract->workspace_present();
```

#### Api Specification

##### Input

```
{}
```

##### Output

```perl
{ type => 'boolean' }
```

#### Messages

None.

### i18n

```perl
my $text = $contract->i18n('check.producers');
my $text = Test::Consumer::Contract->i18n('skip.siblings', { missing => 'X' });
```

#### Purpose

Turns a message key and its arguments into the text the user sees.  Every
diagnostic, test name and error this module produces goes through here, so all
of them can be reworded or translated.

#### Arguments

- `$key` (string, required)

    The message key, such as `check.producers`.

- `\%args` (hashref)

    The values for the template's placeholders.  `{name}` is replaced by the
    value; `{name:%.2f}` formats it with that `sprintf` conversion (only the
    conversions `s d f g e E x X o b u`, with their flags, are honoured).  An
    arrayref value is joined with `, `.  A placeholder with no value is left as
    written, so a missing argument shows rather than vanishes.  `package`
    defaults to this module's name.

    When the template is a hash of forms, `context` picks one by name (a gender,
    say), and otherwise `count` picks `zero` (if present), `one` or `other`.

The template is looked up in the object's `messages` option, then in
`$config{messages}`, then in the built-in catalogue.

#### Returns

The message text.

#### Side Effects

None.

#### Example

```perl
local $Test::Consumer::Contract::config{'messages'}{'check.producers'}
    = 'die Erzeuger setzen noch die zugesagten Schluessel';

my $contract = Test::Consumer::Contract->new(%declaration, messages => {
    'skip.siblings' => { one => 'missing: {missing}', other => 'missing ({count}): {missing}' },
});

print $contract->i18n('skip.siblings', { missing => 'A, B', count => 2 });
# missing (2): A, B
```

#### Api Specification

##### Input

```perl
{
    key  => { type => 'string', min => 1, position => 0 },
    args => { type => 'hashref', optional => 1, position => 1 },
}
```

##### Output

```perl
{ type => 'string' }
```

#### Messages

```
Message                          Meaning / Resolution
-------------------------------  ---------------------------------------------
"no message called 'X'"          The key is in no catalogue.  This is a
                                 programming error and is raised with confess,
                                 so the stack trace shows the caller.
"...::i18n() needs a 'key'"      The key is missing or undef.
```

#### Pseudocode

```perl
validate the key and the arguments
add package => this module's name under the caller's arguments
take the first template defined in: object messages, %config messages, built-in
confess if there is none
if the template is a hash of forms, choose one by context, else by count
replace each {name} or {name:%fmt} that has a value; leave the rest
return the text
```

### Sets\_Key

```
$contract->sets_key($source_text, 'database')
```

#### Purpose

Says whether the text assigns the key, in any of the spellings a producer might
use: `key => value`, `'key' => value`, `$obj->{'key'} = value`,
`$obj->{'key'} ||= value` and `$obj->{'key'} //= value`.

#### Arguments

- `$text` (string, required) - source, normally passed through ["strip"](#strip).
- `$key` (string, required) - the key.

#### Returns

1 or 0.

#### Side Effects

None.

#### Example

```perl
my $text = $contract->strip($source);
ok($contract->sets_key($text, 'colour'), 'the producer still sets colour');
```

#### Api Specification

##### Input

```perl
{
    text => { type => 'string', position => 0 },
    key  => { type => 'string', min => 1, position => 1 },
}
```

##### Output

```perl
{ type => 'boolean' }
```

#### Messages

```
Message                                      Meaning / Resolution
-------------------------------------------  ----------------------------------
"...::sets_key(): <validator message>"       An argument has the wrong type.
"...::sets_key() needs a 'X'"                An argument is missing or undef.
```

### Strip

```perl
my $code = $contract->strip($source);
```

#### Purpose

Removes what is not code, so that prose about a key is not mistaken for a use
of it: POD (to its `=cut`, or to the end of the file when it has none),
whole-line comments, and everything after `__END__` or `__DATA__`.

#### Arguments

- `$text` (string, required) - Perl source.

#### Returns

The source with POD and comments blanked.  The lines are kept, so a line
number found in the result is the line number in the file.

#### Side Effects

None.

#### Example

```perl
my $code = $contract->strip("=head1 X\n\n\$w->{'pod'}\n\n=cut\nmy \$x = 1;\n");
# "\n\n\n\n\nmy \$x = 1;\n"
```

#### Api Specification

##### Input

```perl
{ text => { type => 'string', position => 0 } }
```

##### Output

```perl
{ type => 'string' }
```

#### Messages

```
Message                                      Meaning / Resolution
-------------------------------------------  ----------------------------------
"...::strip() needs a 'text'"                The text is missing or undef.
```

### Scanner\_Capabilities

```perl
my $seam = Test::Consumer::Contract->scanner_capabilities();
my @rules = sort keys %{$seam};
```

#### Purpose

Every rule the scanner applies to source beyond reading the file, as rule name
&#x3d;> the name of the sub the rule is exercised through.  `shebang_programs` is
an extensionless program being a consumer; `accessor_headings` is where a
value object documents an accessor; `code_not_prose` is producer evidence
having to be code.  The list is here so that the tests and the code cannot
drift apart: `t/contract.t` mutates each named sub back to its behaviour
before the rule existed, and fails when a rule here has no mutation subtest,
when a mutation names a rule that is not here, and when a row names a sub this
module does not define.  A rule therefore cannot be added without the test
that shows what it catches.

#### Arguments

None.  May be called on the class or an object.

#### Returns

A new hashref, in any context: a list of names where a hash of names to seams
was asked for would leave every seam undef.  The caller may change it freely.

#### Side Effects

None.

#### Example

```perl
my $seam = Test::Consumer::Contract->scanner_capabilities();
print "$_ -> $seam->{$_}\n" for sort keys %{$seam};
```

#### Api Specification

##### Input

```
{}
```

##### Output

```perl
{ type => 'hashref' }
```

#### Messages

None.

### Reads\_of\_Results

```perl
my @reads = $contract->reads_of_results($stripped_text);
my $reads = $contract->reads_of_results($stripped_text);
```

#### Purpose

Finds every place in the text that reads a field of a result: a hash key,
`$r->{'key'}`, or a method call, `$r->key` or `$r->key()`.

First it works out which variables hold a result.  A variable holds a result
when:

- it is set from a call named in `methods`:
`my $r = $maker->geocode(...)`;
- it takes one result at a time from a call named in `list_methods`:
`for my $r (@{ $report->results })`, or `$_` in a `map` or `grep`
over that call;
- it is set from one entry of a batch (a call named in
`batch_methods`): `my $r = $batch->{$name}`.  A batch entry also counts
when it is put into a hash, or returned from a sub - the callers of that sub
then get results too;
- it is the parameter of a sub that this file calls with a result.  For
a method call (`$self->show($r)`) that is the parameter after `$self`.

Then it lists every read of those variables.

#### Arguments

- `$text` (string, required) - source, normally passed through ["strip"](#strip).

#### Returns

In list context, the reads; in scalar context, an arrayref of them.  Each read
is `[key, line, kind, sub]`: `kind` is `key` or `accessor`, `sub` is the
enclosing sub or `(file scope)`.  They are in line order.

#### Side Effects

None.

#### Example

```perl
my $reads = $contract->reads_of_results($contract->strip(<<'CODE'));
my $w = $maker->make(size => 2);
return $w->{'colour'};
CODE
# [ ['colour', 2, 'key', '(file scope)'] ]
```

#### Api Specification

##### Input

```perl
{ text => { type => 'string', position => 0 } }
```

##### Output

```perl
{
    type    => 'arrayref',
    element => { type => 'arrayref' },   # [key, line, kind, sub]
}
```

#### Messages

```
Message                                      Meaning / Resolution
-------------------------------------------  ----------------------------------
"...::reads_of_results() needs a 'text'"     The text is missing or undef.
```

#### Pseudocode

```perl
batches  := variables assigned from a batch method call
bound    := variables assigned from a producing call, minus batches
add the loop variables and topics over a list method's results
add the variables assigned a value selected out of a batch
sinks    := hashes holding batch values; subs returning one
for each sub returning a batch value:
    add the variables assigned from a call to it
    record reads written straight off a call to it
repeat until nothing new: add the parameter that receives a bound variable
record reads off every bound variable
record reads straight off a batch selection
record reads through an element of a hash that holds results
sort the reads by line
```

### Consumer\_Path

```perl
my $path = $contract->consumer_path($relative);
```

#### Purpose

Where a registered consumer is, as a path on this platform.  A consumer in a
sibling distribution is named relative to `workspace`; one in the
distribution being checked is named the way a producer is, relative to
`dist_root`, because the directory a distribution is installed under is not
the name the contract spells.

#### Arguments

- `$relative` (string, required) - the path as the contract spells it.

#### Returns

The workspace path when a file is there, otherwise the `dist_root` path
(whether or not that exists).

#### Side Effects

None.

#### Example

```perl
my $path = $contract->consumer_path('Widget-User/lib/Widget/User.pm');
```

#### Api Specification

##### Input

```perl
{ relative => { type => 'string', min => 1, position => 0 } }
```

##### Output

```perl
{ type => 'string' }
```

#### Messages

```
Message                                         Meaning / Resolution
----------------------------------------------  ----------------------------------
"...::consumer_path() needs a 'relative'"       The path is missing or undef.
```

### Documented\_Accessors

```perl
my @names = $contract->documented_accessors($source);
my $names = $contract->documented_accessors($source);
```

#### Purpose

Every name the value object's source documents as part of its interface: its
`=head2` headings and the public subs it defines.  `=head1` headings are left
out (NAME, VERSION and the rest of the boilerplate), as are deeper headings,
which are sections about the accessor above them rather than accessors, and
private subs.  A method implemented through `AUTOLOAD` is found by its
heading, which is what makes this the list of what is documented rather than
of what is compiled.

#### Arguments

- `$text` (string, required) - the value object's source, POD included.

#### Returns

The names, sorted and unique: a list in list context, an arrayref in scalar
context.

#### Side Effects

None.

#### Example

```perl
my $names = $contract->documented_accessors("=head2 x\n\n=head3 PURPOSE\n\n=cut\n\nsub y {}\n");
# ['x', 'y']
```

#### Api Specification

##### Input

```perl
{ text => { type => 'string', position => 0 } }
```

##### Output

```perl
{ type => 'arrayref', element => { type => 'string' } }
```

#### Messages

```
Message                                          Meaning / Resolution
-----------------------------------------------  ----------------------------------
"...::documented_accessors() needs a 'text'"     The text is missing or undef.
```

## Diagnostics

Every message is a key in the catalogue (see ["i18n"](#i18n)); the English text is
summarised below.  Diagnostics after a failed assertion are indented a tab.

```
Key                  Meaning / Resolution
-------------------  ---------------------------------------------------------
file.unreadable      A producer, consumer or value object could not be read;
                     the OS error says why.  Fix the path in the declaration.
producer.sets        (test name) A producer no longer sets the key.  Set it
                     again, or take it out of the producer's list.
class.unavailable    (skip) The value object is not in @INC.  Add its lib to
                     'include', or accept the skip on a CPAN install.
class.compiles       (test name) The value object is in @INC but does not
                     load; the error follows.  Fix the class.
derivation.made      (test name) The constructor died or returned false; the
                     error follows.
consumer.offender    A consumer reads a key not every producer sets.  Stop
                     reading it, or register it in may_rely_on with why.
consumer.stale       A may_rely_on entry is no longer read.  Remove it.
skip.siblings        (skip) A require_workspace distribution is absent.
skip.producer        (skip) A workspace producer's sibling is absent.
accessor.documented  (test name) A name in accessors/not_accessors is not
                     documented or defined by the value object.
accessor.drift       The value object documents a name the contract does not
                     mention.  Put it in accessors, conditional or
                     not_accessors.
discovery.header     A file reads a result and is neither registered nor
                     ignored.  Register it, or ignore it with a reason.
```

## Limitations

- The scanner is lexical, not syntactic.  It reads Perl with regular
expressions, so a read inside a string or a heredoc can be taken for code, a
trailing comment is not removed (only whole-line comments are), and an unusual
layout can hide a read.  [PPI](https://metacpan.org/pod/PPI) is the tool that would parse the code properly;
moving the scanner onto it is the change that would retire most of the items
below, at the cost of speed and a heavier dependency.
- Variables are matched by name across the whole file.  A `$point`
bound from a producing call in one sub makes every `$point` in every other sub
a result too, and a `map` or `grep` over a list method makes `$_` a result
file-wide.
- A sub is found only when `sub NAME` starts in column 0, and it ends at
the next `}` in column 0 (or on its own line, when its braces close there).
Subs inside an indented `package NAME { ... }` block, or closed by an indented
brace, are reported as file scope.  Signatures (`sub f ($self, $r)`) are not
read, so a helper declared with one is not followed.
- A single result stored in a hash or returned is not followed; only a
value out of a batch is.  Helpers are followed by variable name until nothing
new is found.
- Discovery requires the file to contain the `source` string.  A
consumer that is handed results without naming it is not picked up; add it to
`consumers` by hand.
- Extensionless files are discovered by their shebang.  A program
without one - a compiled binary, a file run through an explicit interpreter -
is not seen.  `xt/` is never scanned, in any distribution.
- The producer evidence is static: a producer that sets a key by a route
the recognised spellings do not cover (`$hash{key} = ...`, a key computed at
run time) is reported as not setting it.
- `require_workspace` is what tells a missing checkout apart from a
passing one.  With nothing to require, a distribution checked on its own has
no sibling consumers to find and the discovery check fails on finding none.
- The accessor check reads the value object's own file, so an accessor
it inherits, or documents in another file, is not seen unless `can()` finds
it.  A heading or sub that names something which is not an accessor of a
result has to be listed in `not_accessors`.
- `consumer_path()` looks in the workspace first, so a dist-relative
consumer whose path also exists under the workspace is read from the
workspace.
- `include` changes `@INC` for the whole process, not for the object.
- The private subs are wrapped by [Sub::Private](https://metacpan.org/pod/Sub%3A%3APrivate) in `enforce` mode,
and the `_check_*` subs by [Sub::Protected](https://metacpan.org/pod/Sub%3A%3AProtected).  Enforce mode is a process-wide
setting of Sub::Private, so loading this module switches any other module that
uses `:Private` into enforce mode too.  Calls from outside the package croak
unless `$Sub::Private::BYPASS` or `HARNESS_ACTIVE` is set.
- Each line number is counted from the start of the file, so a file with
very many reads is scanned in quadratic time.
- The end-to-end tests match the English wording of the messages; a
translation passed through `messages` is for users, not for this module's own
test suite.

## Author

Nigel Horne, `<njh at nigelhorne.com>`

## Formal Specification

These schemas use the Z notation.  They say exactly what each public method
promises, for readers who want that; nothing else in this document depends
on them.

### Types and State

```perl
[PATH, KEY, NAME, SUBNAME, OPTION, VALUE, RULE, CHAR, VAR]
FILES : ℙ PATH                           -- the files that exist
KIND ::= key | accessor
LOADSTATE ::= loaded | missing | broken

┌─ CONTRACT ────────────────────────────────────────────────
│ options : OPTION ⇸ VALUE
│ dist_root, workspace : PATH
│ missing_siblings : ℙ NAME              -- cache, filled on first use
│ cached : 𝔹
│ class_state : NAME ⇸ LOADSTATE         -- cache of loaded classes
├───────────────────────────────────────────────────────────
│ {source, guaranteed, methods} ⊆ dom options
│ ∀ o : dom options • options(o) ≠ undef
└───────────────────────────────────────────────────────────

┌─ InitCONTRACT ────────────────────────────────────────────
│ CONTRACT'
├───────────────────────────────────────────────────────────
│ ¬ cached' ∧ class_state' = ∅
└───────────────────────────────────────────────────────────
```

### New

```
┌─ New ─────────────────────────────────────────────────────
│ spec? : OPTION ⇸ VALUE
│ contract! : CONTRACT
├───────────────────────────────────────────────────────────
│ dom spec? ⊆ KNOWN_OPTIONS
│ {source, guaranteed, methods} ⊆ dom spec?
│ ∀ o : dom spec? • spec?(o) ∈ TYPE(o)
│ ∀ d : {dist_root, workspace} ∩ dom spec? • spec?(d) ∈ DIRECTORY
│ contract!.options = DEFAULTS ⊕ spec?
│ INC' = rev(includes(spec?)) ⁀ (INC ∖ ran includes(spec?))
└───────────────────────────────────────────────────────────
```

### Run

```
┌─ Run ─────────────────────────────────────────────────────
│ ΞCONTRACT
│ tap! : seq SUBTEST
├───────────────────────────────────────────────────────────
│ tap! = producers ⁀ derivation ⁀ consumers ⁀ accessors ⁀ discovery
│ #tap! ≤ 5
└───────────────────────────────────────────────────────────
```

### Run\_Consumer\_Contract

```
RunConsumerContract ≙ New ⨾ Run
```

### Workspace\_Present

```
┌─ WorkspacePresent ────────────────────────────────────────
│ ΞCONTRACT
│ present! : 𝔹
├───────────────────────────────────────────────────────────
│ present! ⇔ ran require_workspace ⊆ dirs(workspace)
└───────────────────────────────────────────────────────────
```

### i18n

```
┌─ I18n ────────────────────────────────────────────────────
│ key? : KEY
│ args? : NAME ⇸ VALUE
│ text! : seq CHAR
├───────────────────────────────────────────────────────────
│ catalogue = BUILTIN ⊕ config.messages ⊕ self.messages
│ key? ∈ dom catalogue
│ text! = interpolate(choose(catalogue(key?), args?), {package ↦ PACKAGE} ⊕ args?)
└───────────────────────────────────────────────────────────
```

### Sets\_Key

```perl
┌─ SetsKey ─────────────────────────────────────────────────
│ text? : seq CHAR
│ key? : seq₁ CHAR
│ sets! : 𝔹
├───────────────────────────────────────────────────────────
│ sets! ⇔ (∃ q : {ε, ', "} • q⁀key?⁀q⁀"=>" in text?)
│       ∨ (∃ q : {ε, ', "}; op : {"=", "||=", "//="} •
│             "->{"⁀q⁀key?⁀q⁀"}"⁀op in text?)
│ -- "==" and "=~" are comparisons, not assignments
└───────────────────────────────────────────────────────────
```

### Strip

```
┌─ Strip ───────────────────────────────────────────────────
│ text?, code! : seq CHAR
├───────────────────────────────────────────────────────────
│ let n == #lines(text? before __END__/__DATA__)
│ #lines(code!) = n
│ ∀ i : 1 ‥ n • lines(code!)(i) ∈ {ε, lines(text?)(i)}
│ ∀ i : pod(text?) ∪ comments(text?) • lines(code!)(i) = ε
└───────────────────────────────────────────────────────────
```

### Scanner\_Capabilities

```
┌─ ScannerCapabilities ─────────────────────────────────────
│ seam! : RULE ⇸ SUBNAME
├───────────────────────────────────────────────────────────
│ seam! = SCANNER_RULE_SEAM
│ ran seam! ⊆ dom SUBS(Test::Consumer::Contract)
└───────────────────────────────────────────────────────────
```

### Reads\_of\_Results

```
┌─ ReadsOfResults ──────────────────────────────────────────
│ ΞCONTRACT
│ text? : seq CHAR
│ reads! : seq (KEY × ℕ₁ × KIND × SUBNAME)
├───────────────────────────────────────────────────────────
│ holds = μ H : ℙ VAR | H = bound(text?) ∪ helpers(text?, H)
│ ran reads! = { k, l, kind, s | (∃ v : holds ∖ batches(text?) •
│                  read(text?, v, k, kind) at l in s) }
│ ∀ i, j : dom reads! | i < j • line(reads!(i)) ≤ line(reads!(j))
└───────────────────────────────────────────────────────────
```

### Consumer\_Path

```
┌─ ConsumerPath ────────────────────────────────────────────
│ ΞCONTRACT
│ rel? : PATH
│ path! : PATH
├───────────────────────────────────────────────────────────
│ workspace ⁄ rel? ∈ FILES ⇒ path! = workspace ⁄ rel?
│ workspace ⁄ rel? ∉ FILES ⇒ path! = dist_root ⁄ rel?
└───────────────────────────────────────────────────────────
```

### Documented\_Accessors

```
┌─ DocumentedAccessors ─────────────────────────────────────
│ text? : seq CHAR
│ names! : seq NAME
├───────────────────────────────────────────────────────────
│ ran names! = head2(text?) ∪ { s : subs(text?) | s(1) ≠ '_' }
│ names! is sorted ∧ names! ∈ iseq NAME
└───────────────────────────────────────────────────────────
```

## State Diagram

A contract object moves through these states.  Square brackets are states,
arrows are triggers, and the lines under each arrow are what happens.

```
(no object)
     |
     | new(%declaration)
     |   - checks every option; croaks on the first mistake
     |     (no object is made, @INC is not changed)
     |   - copies %config; fills in defaults
     |   - puts 'include' directories at the front of @INC
     v
[CONSTRUCTED]  caches empty: sibling list unknown, no class loaded
     |
     |  workspace_present()   - fills the sibling cache, returns 1 or 0
     |  i18n(), strip(), sets_key(), reads_of_results(),
     |  documented_accessors(), consumer_path(),
     |  scanner_capabilities()  - read only; the state does not change
     |
     | run()  (or run_consumer_contract(), which is new() then run())
     v
[CHECKING PRODUCERS] ---- no producers declared ----------+
     |  subtest 1: one ok() per file read and per key     |
     |    a producer's sibling missing -> its tests skip  |
     v                                                    v
[CHECKING DERIVATION] --- no 'derives' ------------------+
     |  loads the value object class (cached)             |
     |    class file not found  -> subtest skipped        |
     |    class does not compile -> subtest fails         |
     |    constructor dies       -> subtest fails         |
     v                                                    v
[CHECKING CONSUMERS] ---- no consumers declared ---------+
     |  fills the sibling cache if empty                  |
     |    a required sibling missing -> subtest skipped   |
     v                                                    v
[CHECKING ACCESSORS] ---- no value_object, or no lists --+
     |  uses the cached class state (skip / fail / run)   |
     v                                                    v
[CHECKING DISCOVERY]  (always runs)
     |  a required sibling missing -> subtest skipped
     |  otherwise walks the workspace and reads files
     v
[CHECKED]  run() returns the object
     |
     | run() again
     |   - the same checks run again; the cached sibling list
     |     and class state are reused, files are read again
     v
[CHECKED]
```

A failed check never stops the run: each later check still runs.  An error
in a check's own code (a bug in this module) ends that subtest only.

## License and Copyright

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
