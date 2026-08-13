# AI Policy

> **TL;DR** — AI tools assist this project at every stage. A human maintainer remains in control of every decision, every review, and every release.

---

## Overview

This document describes how artificial intelligence tools are used in the maintenance and development of Perl::Critic::Policy::PreferredModules. It is intended to be transparent with contributors, users, and the broader open-source community about the role AI plays — and, equally importantly, the role it does **not** play.

We believe in honest, clear communication about AI-assisted workflows. This policy will be updated as our practices evolve.

---

## Our Guiding Principle

**AI assists. Humans decide.**

The maintainer remains fully responsible for every line of code that ships. AI tools extend the capacity to review, research, and improve — they do not replace human judgment, expertise, or accountability.

---

## How AI Is Used in This Project

This distribution is developed with heavy AI assistance, and we would rather say so plainly than bury it. A large share of the changes in recent releases started life as an AI-drafted pull request. Every one of them was read, questioned, and merged by a human. Where AI contributed materially, the commit carries a `Co-authored-by` trailer naming the tool, so the extent of its involvement is visible in `git log` rather than a matter of trust.

### 1. Code and Issue Analysis

AI tools help process and understand incoming issues, pull requests, and code changes:

- Summarising issue reports and identifying patterns across similar bugs
- Analysing code diffs for potential problems, regressions, or style inconsistencies
- Surfacing relevant context from the codebase, documentation, and prior discussions
- Flagging potential security concerns for human review

This analysis is **always** used as input to human decision-making, never as a substitute for it.

### 2. Draft Pull Requests

AI may generate draft pull requests as a starting point for a fix, a refactor, or an improvement. Such drafts typically arrive from a bot fork of this repository and:

- Are identifiable as AI-drafted, both on the pull request and in the commit trailers
- Represent a first pass only — they are never considered complete or correct without human review
- May be substantially reworked, rejected, or replaced entirely by the maintainer

Think of these drafts the way you would think of a junior contributor's first attempt: useful raw material that still needs experienced eyes.

### 3. Human Review of Every Pull Request

**Every pull request — whether AI-drafted or human-authored — is reviewed by a human maintainer before it can be merged.**

During review, the maintainer actively uses AI as a tool to assist their own thinking:

- Asking AI to explain or justify specific implementation choices
- Challenging AI-generated code and requesting alternative approaches
- Using AI to research edge cases, relevant standards, or upstream behaviour
- Requesting targeted rewrites of individual sections based on review feedback

The maintainer's judgment always takes precedence. AI answers are treated as input to be verified, not conclusions to be accepted.

### 4. Test Coverage and Defect Detection

AI helps improve the quality and completeness of the test suite by:

- Suggesting test cases for edge conditions and failure modes
- Identifying gaps in existing test coverage
- Proposing tests that target known classes of defects or security issues
- Helping reproduce and characterise reported bugs

All suggested tests are reviewed and validated by the maintainer before being committed. A behaviour change is expected to come with a test that fails without it.

### 5. Security Review

AI tools assist in identifying potential security issues, including:

- Common vulnerability patterns (injection, insecure defaults, deprecated APIs, etc.)
- Dependencies with known CVEs
- Code paths that may warrant closer scrutiny

Security findings from AI are **always** verified by a human maintainer. We do not act on AI-flagged security issues without independent assessment. See [SECURITY.md](SECURITY.md) for how to report a vulnerability — those reports are handled by a human.

---

## What AI Does Not Do

To be explicit about the limits of AI involvement in this project:

| ❌ AI does not… | ✅ A human maintainer does… |
|---|---|
| Approve or merge pull requests | Review and decide on every PR |
| Make architectural decisions | Own all design and direction choices |
| Triage and close issues autonomously | Assess and respond to all issues |
| Publish releases | Tag, build, and release manually |
| Represent the project publicly | Communicate on behalf of the project |

---

## Releases

Releases are performed manually by the maintainer. The release process — including changelog review, version tagging, and publication to CPAN — uses standard Perl ecosystem tooling (here, [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla)) but involves no AI-driven automation. Every release is initiated, supervised, and published by a human.

AI may assist in drafting changelog entries or release notes, but these are always reviewed and edited before publication.

---

## Attribution and Transparency

Where AI has played a material role in generating code or content, the commit records it with a `Co-authored-by` trailer, and the pull request description says so. We do not consider AI the author of any contribution — the maintainer who reviewed and approved the work takes responsibility for it.

---

## Why We Do This

Open-source software is built on trust. Our users and downstream dependants trust us to ship correct, secure, and well-considered code. That matters particularly for a Perl::Critic policy: it runs inside other people's build and CI pipelines, and a false positive costs somebody else time. AI tools help us do that work better — but they do not change who is responsible for the outcome.

We use AI because it makes maintenance more effective, not because it replaces the maintainer.

---

## Questions and Feedback

If you have questions about our use of AI, or concerns about a specific pull request or change, please [open an issue](https://github.com/cpan-authors/Perl-Critic-Policy-PreferredModules/issues) or start a discussion. We are committed to being open about our process.

---

*Last updated: 2026-08-12*
*This policy is maintained by the project maintainer and subject to revision as AI tooling and community norms evolve.*
