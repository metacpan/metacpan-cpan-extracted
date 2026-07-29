# CI pin maintenance

`.github/workflows/ci.yml` pins every `PerlToolsTeam/github_workflows`
reference to a commit SHA rather than `@main`.

## Why pinned

Tracking `@main` meant upstream could change this repository's CI with no
commit here. That is not hypothetical: PDF-Reuse lost Windows CI for six
months to an upstream regression, and the eventual fix arrived the same way.
Neither event produced a commit in any of these repositories, and both were
found only by re-measuring months later.

## Why this needs a human

**Dependabot does not maintain these pins.** It advances a SHA-pinned GitHub
Actions ref only when the upstream repository publishes tags — see
`github_actions/lib/dependabot/github_actions/update_checker.rb` in
dependabot-core, where `latest_commit_sha` returns early unless
`latest_version_tag` is present. `PerlToolsTeam/github_workflows` has no
tags, so no update PR is ever opened for these refs.

The `.github/dependabot.yml` in this repo is still useful — it covers tagged
`actions/*` refs — but it is inert for the pins below.

## What the pin does and does not freeze

Frozen: the `PerlToolsTeam/github_workflows` files themselves (the composite
action and the reusable workflows).

Not frozen:

- Actions invoked *inside* the pinned upstream files, which use tag refs.
  In the composite action: `actions/checkout@v5`,
  `shogo82148/actions-setup-perl@v1`, `ilammy/msvc-dev-cmd@v1`,
  `actions/upload-artifact@v5`. In the coverage and perlcritic reusable
  workflows: `actions/checkout@v7`. Tags can move.
- Container images in the coverage and perlcritic workflows
  (`davorg/perl-coveralls:latest`, `davorg/perl-perlcritic`), which float.

So the pin is a boundary around one upstream repository, not a full CI lock.
It removes the failure mode that actually bit us; it does not make CI
bit-for-bit reproducible.

## How to review the pin

Roughly quarterly, or when CI behaves unexpectedly:

    gh api repos/PerlToolsTeam/github_workflows/commits/main \
      --jq '"\(.sha)  \(.commit.author.date)  \(.commit.message|split("\n")[0])"'

Compare against the SHA in `ci.yml`. To see what changed since the pin:

    gh api "repos/PerlToolsTeam/github_workflows/commits?sha=main&since=<pin-date>" \
      --jq '.[] | "\(.commit.author.date)  \(.sha[0:8])  \(.commit.message|split("\n")[0])"'

To advance: update all three refs in `ci.yml` plus the trailing
`# main @ <date>` comments, push to a branch, and let the PR's own CI run be
the verification. Do not advance a pin without a green run — the point of the
pin is that upstream changes arrive as a reviewable event rather than a
surprise.

Keep the same SHA across all five distributions (PDF-Reuse, PDF-Reuse-Barcode,
PDF-Reuse-OverlayChart, PDF-Reuse-Tutorial, Business-US-USPS-IMB) so a
divergence between them is always a signal rather than noise.
