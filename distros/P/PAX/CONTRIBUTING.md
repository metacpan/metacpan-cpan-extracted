# Contributing

## Contribution Standard

PAX changes should improve a reusable class of Perl projects. Avoid
application-specific patches when a structural compiler, packaging, loader, or
runtime fix is locally possible.

## What to Include

Useful contributions normally include at least one of:

- a focused reproducer
- a regression test
- a benchmark fixture
- documentation updates for changed behavior

When a change affects operator-visible behavior, update:

- `README.md`
- `lib/PAX.pm`
- `Changes`

## Performance Reports

Performance reports are easiest to investigate when they include:

- the stock Perl command or script
- the `pax build` command
- the standalone runtime command
- timings for each step
- whether the workload is startup-heavy, IO-heavy, or numeric/hot-loop-heavy

That makes it possible to separate packaging cost, startup cost, helper
dispatch cost, and native-lowering coverage gaps.
