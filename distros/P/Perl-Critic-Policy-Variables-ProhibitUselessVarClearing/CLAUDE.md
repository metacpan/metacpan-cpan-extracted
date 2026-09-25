# CLAUDE.md

This file is the procedure for work in this repository.  The POD and the files
named below say what the code is and how it is written.

Perl-Critic-Policy-Variables-ProhibitUselessVarClearing is one Perl::Critic
policy.  It reports a statement that empties a `my` variable, such as
`%h = ();` or `undef $x;`, when nothing reads the variable again before the
end of the block that declares it.

The rule lives in two files.
`lib/Perl/Critic/Policy/Variables/ProhibitUselessVarClearing.pm` is the policy,
and its POD is the specification.  `t/main.t` holds a table of snippets that
must be reported and a table of snippets that must not.  A change to the rule
changes both files.

## Read the code before you change it

Before you answer a question about the code here, look for something in it, or
edit it, invoke `perl-slop:reading-perl`.

Most of the code here is older than the conversation about it.  A line that
looks pointless is usually the scar of something that went wrong once.  The
reason is in the commit, not in the file.  So read before the first edit, not
after the tests fail.

The same pass asks whether the code that you want to write is already here,
under a name that you did not search for.  Two subs that do one job are a
defect, whichever one is better.

## What perl this runs on

Every module and every test says `use 5.014`, and `perl:` in
`prereqs.yml` says the same.  `.perlcriticrc` depends on it.  The header of
that file names the policies that this version of perl makes unnecessary.  So
if you raise or lower the floor, change the profile as well as the `use` lines.

## Where it is written down

| | |
|---|---|
| `perldoc Perl::Critic::Policy::Variables::ProhibitUselessVarClearing` | what this is for and how a caller uses it |
| `.perlcriticrc` | the policies, which are the house style made enforceable |
| `Changes` | what changed and when, per release |
| `dist.ini` | the build, and what has to be installed to run it |

| `t/main.t` | the cases that the policy must report, and the cases that it must leave alone |

## Finishing a changeset

Before you commit, apply these skills in this order:

1. `perl-slop:data-perl`: make sure that the data is defined, coerced,
   validated and scoped in the way that perl expects.
2. `perl-slop:testing-perl`: make sure that each behavior that you added or
   changed has a test, and that the test is the right kind.
3. `perl-slop:reviewing-perl`: read the whole diff back against it.  This pass
   finds a second copy of something that the library already does.  It also
   finds a call out to the shell, and a comment that belongs in the commit
   message.

Then run `podchecker` on each changed file.  Run `perl -Ilib -c` on each
changed script that no test loads, because the tests do not compile it.

The pre-commit hook does the rest.  It tidies the Perl that you staged, runs
perlcritic on it, and runs the tests.  If a step fails, the hook stops the
commit and prints the reason.  Do not run `perltidy` or `perlcritic` yourself,
and do not run the tests to decide whether a change is ready to commit.

The hook names each test that failed.  Its output does not say why.  If a test
fails, run that file yourself with `-v`, and read the output:

```
prove -lv t/<file>.t
```

Do the same to see a new test fail before you fix what it tests.

In each clone that you commit from, install the hook once.  Git does not
install it for you, and without the hook the tree drifts from its style:

```
cp git-hooks/pre-commit .git/hooks/
```

## When something is slow

Use `perl-slop:profiling-perl`.  Measure before you conclude anything, and
measure again after a change.  "It is just slow" is not a finding.  A line
number and a percentage is a finding.

## Releasing

`perl-slop:packaging-perl` made this distribution, and it explains what
`dist.ini` means.  It also lists the problems that stop `dzil release` with no
clear error.  Read it before the first release, not during it.

```
dzil authordeps --missing | cpanm --notest
dzil build && dzil test
```

## Commits and pull requests

Make a branch.  Do not commit to the default branch.

A commit message here says what was wrong and why the change fixes it.  Write
it in prose and in the imperative mood.  Name the behavior, not the diff, for
example "Ask the pool whether it takes O_DIRECT, rather than guessing from its
name".  The message has a job.  `perl-slop:reading-perl` describes a person who
finds your line with `git blame` two years from now.  The message is the only
thing that can still tell that person why.  For the same reason, the why goes
in the message and not in a comment.

After you make sure that something works, say what you ran and what it said.
A claim that the tests pass needs the line that shows them passing.  A claim
about your own work needs its evidence too, such as the URL from `gh pr
create` or the sha from `git push`.  A PR number that nobody can open is worse
than no number.

If the code of a branch depends on another branch, stack it on that branch.
If only a test of it depends on the other branch, do not stack it.  A change
whose tests need a fix from somebody else is still an independent change.
Open it against the default branch, and say in the description what must
merge first.  A stacked branch merges into its base, whatever that base is.
If the base reached the default branch by another route, the stacked change
reaches nowhere, and nothing says so.
