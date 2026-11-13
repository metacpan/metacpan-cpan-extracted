---
name: review-cleanup
description: Remove git refs that review-helper keeps for closed reviews and for reviews whose file is gone. Use when the user asks to clean up review-helper refs or old reviews.
allowed-tools: Bash(review-helper prune) Bash(review-helper prune *)
---

# Cleaning up reviews

Each review iteration pins its commits under `refs/review-helper/`, so old
iterations stay viewable. `prune` removes the refs of reviews that are closed
or whose review file no longer exists. It never deletes review files, takes
no ref or path arguments, and is safe to run at any time.

## Prune

```
review-helper prune
```

Run `review-helper prune --dry-run` first only if the user asks to see what
would go. `prune` prints each ref it removed; no output means nothing needed
removing. Report what it removed to the user.

To clean up a review that is still open, the user closes it in the page or
with `review-helper close FILE`; do that only when they ask. Stop the
review's server if you started one in this session.
