# Lifespan Shutdown Test

Manual test for verifying lifespan.shutdown runs correctly with multiple workers.

## Test

```bash
pagi-server --app app.pl --port 5089 -w 2
# Press Ctrl-C
```

**Expected:** See `[PID] lifespan.shutdown` for each worker

## Background

This example was created to debug an issue where Ctrl-C with 2+ workers didn't
trigger `lifespan.shutdown`. The root cause was that Ctrl-C sends SIGINT to the
entire process group, and workers would exit before the parent could coordinate
graceful shutdown via SIGTERM.

**Fix (v0.001010):** Workers now ignore SIGINT, following Gunicorn's convention
where the parent coordinates shutdown by sending SIGTERM to workers.
