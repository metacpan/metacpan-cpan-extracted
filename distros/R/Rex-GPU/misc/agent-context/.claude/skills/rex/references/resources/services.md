# Services, activation, and health

## Separate running state, boot state, and health

A service can be running but disabled at boot, enabled but failed, or active while
the application is unhealthy. The inspected `service` implementation delegates to
a selected provider. Its ensure path can manage boot behavior; `no_boot` changes
that path. Its change report compares running status before and after and should
not be treated as a complete audit of every unit property.

```perl
# Mutating example: service name and provider must match the target.
service 'exampled', ensure => 'started';
```

The legacy two-argument form has its own return behavior. A start checks current
status, a restart deliberately executes, and errors can be logged with a false
return. Do not assume an exception is the only way a service operation can fail.
Provider selection matters on non-systemd systems, containers without an init system,
and targets whose distribution uses a different service name.

## Activation procedure

**Practice:** validate the new configuration before changing the active service.
Choose reload only if the application's documented reload applies the changed
settings; otherwise a restart may be necessary. Define separate health checks for
process status, readiness, and application-level correctness. Bound startup and
stabilization waits. A TCP listener alone may be insufficient for a database or
cluster node that is still recovering.

When multiple files change, aggregate them into one activation event. Do not restart
once per line or template. Avoid issuing `daemon-reload` for every unrelated file;
when unit definitions change, the platform-specific manager procedure belongs in
a tested adapter rather than an assumption baked into all tasks.

## Failure and rollout handling

Retain the old configuration and know whether restoration is safe. A failed restart
can leave the service down; capture status and bounded logs before another attempt.
Do not automatically downgrade or revert a service whose data format changed.
Stop fleet progression on failed readiness even if the Rex task itself returned
success. A load balancer drain, service activation, health gate, and rejoin sequence
is an application rollout design, not a feature automatically provided by `service`.

Test unchanged apply, configuration change, failed validation, failed reload,
failed restart, delayed readiness, and provider mismatch in a disposable target.

## Evidence and scope

- [lib/Rex/Commands/Service.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex/Commands/Service.pm)
- [Rex::Commands::Service (release documentation)](https://metacpan.org/pod/Rex::Commands::Service)
- [Rex::Commands::File (release documentation)](https://metacpan.org/pod/Rex::Commands::File)
