# CLAUDE.md

How to work in this repository.  What the code *is* and how it is written are in
the POD and in the files pointed at below; this is the procedure.

Perl-Critic-Policy-BuiltinFunctions-ProhibitChainingSameListSub is one
Perl::Critic policy.  It reports a list function whose list is the result of
another call to the same function -- `map { ... } map { ... } @x`, `grep` into
`grep`, `sort` into `sort`, and the List::Util block functions -- because the two
blocks combine into one pass over the list.

The rule lives in two files.
`lib/Perl/Critic/Policy/BuiltinFunctions/ProhibitChainingSameListSub.pm`
is the policy, and its POD is the specification.  `t/main.t` holds tables of
snippets that must be reported and snippets that must not.  A change to the
rule changes both files.

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

## What perl this runs on

`use 5.014`, in every module and every test, and `perl:` in
`prereqs.yml` says the same thing.  `.perlcriticrc` assumes it: the header of
that file names the policies the version pays for, so raising or lowering the
floor is a change to the profile as well as to the `use` lines.

## Where it is written down

| | |
|---|---|
| `perldoc Perl::Critic::Policy::BuiltinFunctions::ProhibitChainingSameListSub` | what this is for and how a caller uses it |
| `.perlcriticrc` | the policies, which are the house style made enforceable |
| `Changes` | what changed and when, per release |
| `dist.ini` | the build, and what has to be installed to run it |

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
that the tests pass is worth the line that shows them passing.  So is a claim
about work you did: the URL `gh pr create` gave back, the sha `git push`
reported.  A PR number nobody can open is worse than no number.

Stack a branch on another only when the *code* depends on it, never when only
the verification does.  A change whose tests cannot go green until somebody
else's fix lands is still an independent change: open it against the default
branch and say in the description what has to land first.  Stacked, it merges
into whatever its base happens to be -- and if that base reached the default
branch by some other route, the child lands nowhere and nothing says so.
