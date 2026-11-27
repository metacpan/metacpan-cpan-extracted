---
description: The publish gate — nothing leaves the machine or speaks in the maintainer's name without an explicit go-ahead; the team's board is exempt.
---

# Publish gate — never without permission

Local work — build, test, commit — is fine anytime. Everything that leaves this machine or
speaks in the maintainer's name waits for the maintainer's explicit go-ahead, even when a
plan, ticket or status document lists it as the next step:

- releases and uploads — CPAN, npm, any package registry or store, `gh release`
- pushing commits or tags, publishing images, deploying, changing a repository's visibility
- any write on a public tracker — issues, pull requests, comments, reviews

A go-ahead covers what it names. Heading toward any of these: stop and ask.

**The team's board is not behind this gate.** Writing cards and syncing the board to its
remote is how agents hand work to each other, and it is durably authorized: never ask
first, never hold it back. A "don't push" in a plan or brief means commits and tags, not
the board.

**Public trackers are not a queue.** The team's board is the agents' working surface,
churned freely. Public issues and pull requests (GitHub, Codeberg, CPAN RT, …) carry real
people's reports under the maintainer's name: never list, read, comment on, close or create
one on your own initiative — only when the user names the specific issue or pull request to
handle.
