# CLAUDE.md

How to work in this repository.  What the code *is* and how it is written are in
the POD and in the files pointed at below; this is the procedure.

SolusVM-Client is a client for the SolusVM 2 API, and nearly all of it is
generated: `lib/SolusVM/Client/Specification.pm` carries a distillation of the
vendor's own OpenAPI document, and `lib/SolusVM/Client.pm` installs one method
per operation out of it and knows how to hold a bearer token.  Read those two,
in that order, and `t/lib/Test/SolusVM/Client.pm`, which is the management node
the tests talk to.

Because the methods are generated, a missing endpoint is almost never a missing
method.  It is a spec that needs refetching -- see below -- or a name you have
not found yet, and `$client->catalog( like => qr/whatever/ )` is how to find it.

## Read the code before you change it

**When a request means consulting the code here at all -- answering a question
about it, tracking something down, or editing it -- invoke
`perl-slop:reading-perl` first.**

Most of what you will touch is older than the conversation about it, and the
line that looks pointless is usually the scar left by something that went wrong
once.  The reason is in the commit, not the file.  This is a reading pass, done
before the first edit rather than after the tests fail.

It is also the pass that asks whether the thing you are about to write is
already here under a name you did not think to search for.  Two subs doing one
job is the defect, whichever is better.

## Where it is written down

| | |
|---|---|
| `perldoc SolusVM-Client` | what this is for and how a caller uses it |
| `.perlcriticrc` | the policies, which are the house style made enforceable |
| `Changes` | what changed and when, per release |
| `dist.ini` | the build, and what has to be installed to run it |
| `perldoc SolusVM::Client::Specification` | where the operations come from, and how to refetch them |
| `t/SolusVM-Client-Live.t` | what it takes to run this against a real management node |
| <https://docs.solusvm.com/en/solusvm2/api-reference/api/> | the vendor's reference, which is the same document the spec is distilled from |

## Two things here are not the house default

**The perl floor is `v5.36`, not `use 5.041`.**  This is a distribution other
people install, and Ubuntu 24.04 ships 5.38.  Requiring a perl newer than any
current LTS would mean nobody could install it.  `[@TestingMania]` generates a
`minimum-version` test that will tell you if a construct creeps in that needs
more.

**`podchecker` fails on every file in `lib/`, and that is expected.**  `=method`
and `=func` are Pod::Weaver commands, not POD, and become `=head2` when the
distribution is built.  Check the built copy instead, or just run `dzil test`,
which runs a pod-syntax test over what a reader will actually get.

## Refetching the API

SolusVM's document is fetched, distilled and baked into the `__DATA__` section of
`Specification.pm`.  To take a newer one:

    perl -Ilib -MSolusVM::Client::Specification \
      -e 'print SolusVM::Client::Specification::fetch( dir => "/tmp" ), "\n"'

then replace everything after `__DATA__` with what it wrote.  Read the diff
rather than trusting it: an operation that disappears is a method that
disappears, and the vendor has shipped operations with a hex digest where the
name should be before now.

## Finishing a changeset

Before you commit, in this order:

1. **`perl-slop:data-perl`** -- is the data defined, coerced, validated and
   scoped the way perl wants it to be.
2. **`perl-slop:testing-perl`** -- does every behaviour you added or changed
   have a test, and is it the right kind.  Then run them.
3. **`perl-slop:reviewing-perl`** -- read the whole diff back against it.  This
   is the pass that catches the second copy of something the library already
   does, the shelling out, and the comment that belongs in the commit message.

Then the mechanical ones:

    perl -Ilib -c <each changed .pm or script>
    perlcritic --profile .perlcriticrc lib/ t/
    podchecker <each changed file>
    prove -lm -j8 t/

`perltidy` runs itself, if the hook is installed: `cp git-hooks/pre-commit
.git/hooks/`.  Do that once, in any checkout you intend to commit from -- git
does not do it for you, and a hook nobody installed is a tree that drifts.

## When something is slow

**`perl-slop:profiling-perl`.**  Measure before you conclude, and measure again
after you change something.  "It is just slow" is not a finding; a line number
and a percentage is.

## Releasing

**`perl-slop:packaging-perl`** is how this distribution was scaffolded and what
its `dist.ini` means.  It also has the half-dozen things that quietly stop
`dzil release` working, which are worth reading before the first one rather than
during it.

    dzil authordeps --missing | cpanm --notest
    dzil build && dzil test

## Commits and pull requests

Branch, never commit to the default branch.

A commit message here says what was wrong and why this is the fix -- in prose,
in the imperative, naming the behaviour rather than the diff ("Ask the pool
whether it takes O_DIRECT, rather than guessing from its name").  That is not
decoration: `perl-slop:reading-perl` is somebody arriving at your line in two
years with `git blame`, and the message is the only thing that will still be
able to tell them why.  Which is also why the *why* goes there rather than in a
comment.

When you have verified something, say what you ran and what it said.  A claim
that the tests pass is worth the line that shows them passing.
